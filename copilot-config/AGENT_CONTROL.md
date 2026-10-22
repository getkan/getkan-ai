For every request handled by this agent, append a log entry containing the
number of tokens used.

Use this exact format: "Request made to control-ai agent. Token usage: [number of tokens used]."

Store the log at `$HOME/logs/agent_getkan_usage.log`, outside the repository.
Create the directory and file if needed; always append and never overwrite
existing entries.