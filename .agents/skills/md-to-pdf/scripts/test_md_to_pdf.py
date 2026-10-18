import base64
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import md_to_pdf


SCRIPT = Path(md_to_pdf.__file__).resolve()
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
    "/x8AAwMCAO+jRZkAAAAASUVORK5CYII="
)
PDF_TOOLS = (
    shutil.which("pandoc")
    and any(shutil.which(name) for name in md_to_pdf.BROWSERS)
    and shutil.which("pdftotext")
    and shutil.which("pdfimages")
)


class ConverterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.first = self.root / "first chapter" / "notes.md"
        self.second = self.root / "second chapter" / "notes.md"
        for source in (self.first, self.second):
            source.parent.mkdir()
            (source.parent / "diagram.png").write_bytes(PNG)
        self.documents = {self.first: "doc-1-", self.second: "doc-2-"}

    def invoke(self, *arguments):
        return subprocess.run(
            [sys.executable, str(SCRIPT), *map(str, arguments)],
            cwd=self.root, capture_output=True, text=True, timeout=180,
        )

    def test_markdown_urls_and_duplicate_heading_names(self):
        self.assertEqual(
            md_to_pdf.rebase_url("./diagram.png", self.first, self.documents, image=True),
            str(self.first.parent / "diagram.png"),
        )
        self.assertEqual(
            md_to_pdf.rebase_url("#shared", self.first, self.documents), "#doc-1-shared"
        )
        self.assertEqual(
            md_to_pdf.rebase_url(
                "../second%20chapter/notes.md#shared", self.first, self.documents
            ),
            "#doc-2-shared",
        )
        self.assertEqual(
            md_to_pdf.rebase_url("https://example.com/x", self.first, self.documents),
            "https://example.com/x",
        )
        self.assertEqual(
            md_to_pdf.rebase_url(
                (self.first.parent / "diagram.png").as_uri(),
                self.first, self.documents, image=True,
            ),
            str(self.first.parent / "diagram.png"),
        )

    def test_html_images_and_code_are_not_confused(self):
        code = '<img src="./missing.png">'
        nodes = [
            {"t": "Header", "c": [1, ["shared", [], []], [{"t": "Str", "c": "Shared"}]]},
            {"t": "CodeBlock", "c": [["", [], []], code]},
            {"t": "RawBlock", "c": ["html", '<img alt="A > B &amp; C" src="diagram.png">']},
        ]
        md_to_pdf.rewrite(nodes, self.first, self.documents)
        self.assertEqual(nodes[0]["c"][1][0], "doc-1-shared")
        self.assertEqual(nodes[1]["c"][1], code)
        self.assertIn(str(self.first.parent / "diagram.png"), nodes[2]["c"][1])
        self.assertIn('alt="A > B &amp; C"', nodes[2]["c"][1])

    def test_missing_asset_is_an_error(self):
        with self.assertRaisesRegex(ValueError, "missing image"):
            md_to_pdf.rebase_url("missing.png", self.first, self.documents, image=True)

    def test_output_is_protected_and_invalid_inputs_are_reported(self):
        self.first.write_text("# Notes\n", encoding="utf-8")
        output = self.root / "existing.pdf"
        output.write_bytes(b"original")
        result = self.invoke(self.first, "-o", output)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--overwrite", result.stderr)
        self.assertEqual(output.read_bytes(), b"original")
        result = self.invoke(self.root / "missing.md", "-o", self.root / "new.pdf")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing.md", result.stderr)

    def test_renderer_failure_does_not_replace_output_and_cleans_temporary_files(self):
        self.first.write_text("# Notes\n", encoding="utf-8")
        output = self.root / "existing.pdf"
        output.write_bytes(b"original")
        document = {"pandoc-api-version": [1, 23, 1], "meta": {}, "blocks": []}
        with patch.object(
            md_to_pdf, "run",
            side_effect=[json.dumps(document), "", RuntimeError("renderer failed")],
        ):
            with self.assertRaisesRegex(RuntimeError, "renderer failed"):
                md_to_pdf.convert([self.first], output, "Notes", "browser")
        self.assertEqual(output.read_bytes(), b"original")
        self.assertEqual(list(self.root.glob(".md-to-pdf-*")), [])

    def test_loading_existing_skill_from_unrelated_directory_does_not_mutate_it(self):
        original = SCRIPT.read_bytes()
        spec = importlib.util.spec_from_file_location("existing_converter", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.assertEqual(module.__file__, str(SCRIPT))
        self.assertEqual(SCRIPT.read_bytes(), original)
        result = self.invoke("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--overwrite", result.stdout)

    @unittest.skipUnless(PDF_TOOLS, "PDF integration requires Pandoc, Chromium and Poppler")
    def test_single_and_combined_pdfs_preserve_content_and_images(self):
        self.first.write_text(
            '# Shared\n\nFirst chapter sentinel.\n\n'
            '![Diagram](diagram.png)\n\n'
            '```html\n<img src="literal-only.png">\n```\n\n'
            '| Column | Value |\n| --- | --- |\n| Capacity | 12345 |\n\n'
            '[Next](../second%20chapter/notes.md#shared)\n',
            encoding="utf-8",
        )
        self.second.write_text(
            '# Shared\n\nLast chapter sentinel.\n\n'
            '<img src="./diagram.png" alt="Second diagram">\n\n'
            '[Local anchor](#shared)\n',
            encoding="utf-8",
        )
        for sources, name, image_count in (
            ([self.first], "single.pdf", 1),
            ([self.first, self.second], "combined.pdf", 2),
        ):
            with self.subTest(name=name):
                output = self.root / name
                result = self.invoke(*sources, "-o", output, "--title", "Test Notes")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(output.read_bytes().startswith(b"%PDF-"))
                text = subprocess.check_output(
                    ["pdftotext", "-layout", str(output), "-"], text=True
                )
                self.assertIn("First chapter sentinel.", text)
                self.assertIn('<img src="literal-only.png">', text)
                self.assertIn("12345", text)
                if len(sources) == 2:
                    self.assertIn("Last chapter sentinel.", text)
                    self.assertLess(
                        text.index("First chapter sentinel."),
                        text.index("Last chapter sentinel."),
                    )
                images = subprocess.check_output(
                    ["pdfimages", "-list", str(output)], text=True
                )
                self.assertEqual(
                    sum(" image " in line for line in images.splitlines()), image_count
                )
                result = self.invoke(*sources, "-o", output, "--overwrite")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(list(self.root.glob(".md-to-pdf-*")), [])


if __name__ == "__main__":
    unittest.main()
