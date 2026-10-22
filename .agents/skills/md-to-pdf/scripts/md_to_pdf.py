#!/usr/bin/env python3
"""Render one or more Markdown files through Pandoc and headless Chromium."""

import argparse
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import unquote, urlsplit


BROWSERS = ("chromium", "chromium-browser", "google-chrome", "chrome", "msedge")
HTML_ATTRIBUTE = re.compile(
    r"""(?P<start>\s(?:src|href)\s*=\s*)(?:"(?P<double>[^"]*)"|'(?P<single>[^']*)'|(?P<bare>[^\s>]+))""",
    re.IGNORECASE,
)


def run(command: list[str], *, text: str | None = None) -> str:
    result = subprocess.run(
        command, input=text, capture_output=True, text=True, timeout=180
    )
    if result.returncode:
        raise RuntimeError(
            f"{command[0]} failed ({result.returncode}):\n{result.stderr.strip()}"
        )
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr)
    return result.stdout


def browser_command(requested: str | None) -> str:
    if requested:
        found = shutil.which(requested)
        if not found:
            raise ValueError(f"Browser executable not found: {requested}")
        return found
    for name in BROWSERS:
        found = shutil.which(name)
        if found:
            return found
    raise ValueError("Chromium/Chrome not found; supply --browser PATH")


def rebase_url(
    value: str, source: Path, documents: dict[Path, str], *, image: bool = False
) -> str:
    url = urlsplit(value)
    if url.scheme or url.netloc:
        if image and url.scheme == "file":
            target = Path(unquote(url.path))
            if not target.is_file():
                raise ValueError(f"{source}: missing image {value}")
            return str(target) + (f"#{url.fragment}" if url.fragment else "")
        return value
    if not url.path:
        return f"#{documents[source]}{unquote(url.fragment)}" if url.fragment else value
    target = (source.parent / unquote(url.path)).resolve()
    if image and not target.is_file():
        raise ValueError(f"{source}: missing image {value}")
    if not image and target in documents:
        return f"#{documents[target]}{unquote(url.fragment)}"
    suffix = f"?{url.query}" if url.query else ""
    suffix += f"#{url.fragment}" if url.fragment else ""
    return (str(target) if image else target.as_uri()) + suffix


def rewrite_html(value: str, source: Path, documents: dict[Path, str]) -> str:
    def replace_tag(tag: re.Match[str]) -> str:
        def replace_attribute(match: re.Match[str]) -> str:
            raw = next(
                item for item in (match["double"], match["single"], match["bare"])
                if item is not None
            )
            rebased = rebase_url(
                html.unescape(raw), source, documents,
                image=match["start"].strip().lower().startswith("src"),
            )
            return f'{match["start"]}"{html.escape(rebased, quote=True)}"'

        return HTML_ATTRIBUTE.sub(replace_attribute, tag.group(0))

    return re.sub(r"""<[A-Za-z](?:[^"'<>]|"[^"]*"|'[^']*')*>""", replace_tag, value)


def rewrite(node, source: Path, documents: dict[Path, str]) -> None:
    if isinstance(node, list):
        for item in node:
            rewrite(item, source, documents)
    elif isinstance(node, dict):
        kind = node.get("t")
        content = node.get("c")
        if kind == "Header":
            content[1][0] = documents[source] + content[1][0]
        elif kind in ("Link", "Image"):
            content[2][0] = rebase_url(
                content[2][0], source, documents, image=kind == "Image"
            )
        elif kind in ("RawInline", "RawBlock") and content[0] == "html":
            content[1] = rewrite_html(content[1], source, documents)
        if content is not None:
            rewrite(content, source, documents)


def convert(inputs: list[Path], output: Path, title: str, browser: str) -> None:
    documents = {source: f"doc-{index}-" for index, source in enumerate(inputs, 1)}
    combined = None
    for source in inputs:
        document = json.loads(run([
            "pandoc", "--from=gfm+tex_math_dollars", "--to=json",
            "--fail-if-warnings", str(source),
        ]))
        rewrite(document["blocks"], source, documents)
        section = {
            "t": "Div",
            "c": [
                [documents[source], ["source-document"], []],
                document["blocks"],
            ],
        }
        if combined is None:
            combined = document
            combined["blocks"] = []
            combined["meta"] = {}
        combined["blocks"].append(section)
    with tempfile.TemporaryDirectory(prefix=".md-to-pdf-", dir=output.parent) as temp:
        work = Path(temp)
        html_path = work / "document.html"
        pdf_path = work / "document.pdf"
        run([
            "pandoc", "--from=json", "--to=html5", "--standalone",
            "--embed-resources", "--fail-if-warnings", "--mathml",
            "--toc", "--toc-depth=2", "--metadata", f"title={title}",
            "--metadata", "toc-title=Contents", "--metadata", "lang=en",
            "--variable",
            'header-includes=<meta http-equiv="Content-Security-Policy" '
            'content="script-src \'none\'; object-src \'none\'">',
            "--css", str(Path(__file__).resolve().with_name("print.css")),
            "--output", str(html_path),
        ], text=json.dumps(combined))
        run([
            browser, "--headless", "--disable-gpu", "--disable-extensions",
            "--disable-background-networking", "--no-first-run",
            f"--user-data-dir={work / 'browser-profile'}",
            "--no-pdf-header-footer", f"--print-to-pdf={pdf_path}",
            html_path.as_uri(),
        ])
        if not pdf_path.is_file() or not pdf_path.read_bytes().startswith(b"%PDF-"):
            raise RuntimeError("Browser did not produce a valid PDF")
        os.replace(pdf_path, output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="+", type=Path, help="Markdown files in order")
    parser.add_argument("-o", "--output", required=True, type=Path)
    parser.add_argument("--title", help="Cover title (defaults to the output filename)")
    parser.add_argument("--browser", help="Chromium/Chrome executable or path")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    try:
        inputs = [path.resolve(strict=True) for path in args.inputs]
        for path in inputs:
            if not path.is_file() or path.suffix.lower() not in (".md", ".markdown"):
                raise ValueError(f"Expected a Markdown file: {path}")
        if len(set(inputs)) != len(inputs):
            raise ValueError("Duplicate input files are not supported")
        output = args.output.absolute()
        if output.suffix.lower() != ".pdf":
            raise ValueError("Output must have a .pdf extension")
        if not output.parent.is_dir():
            raise ValueError(f"Output directory does not exist: {output.parent}")
        if output.exists() and not args.overwrite:
            raise ValueError(f"Output already exists; use --overwrite: {output}")
        if not shutil.which("pandoc"):
            raise ValueError("Pandoc not found on PATH")
        convert(inputs, output, args.title or output.stem, browser_command(args.browser))
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"md-to-pdf: {error}", file=sys.stderr)
        return 1
    print(f"Created {output} from {len(inputs)} Markdown file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
