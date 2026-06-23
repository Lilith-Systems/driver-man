---
name: codex
description: "Codex Agent CLI. Trigger this skill when the user wants to run a Codex command, execute a Codex CLI operation, run a code review, manage Codex plugins/MCP servers, or run sandbox commands."
---
# Codex Agent CLI Skill

Use this skill to execute commands using the Codex CLI. You can run the `codex` CLI using the `run_command` tool.

## Executable Path
The `codex` CLI is located at:
`/home/tehlappy/.local/bin/codex`

## Subcommands and Usage

To run a Codex command, execute:
```bash
/home/tehlappy/.local/bin/codex <command> [args...]
```

### Common Commands:
- **`codex exec <prompt>`**: Run Codex non-interactively to perform a specific task.
- **`codex review`**: Run a code review non-interactively on the current directory.
- **`codex plugin`**: Manage Codex plugins (list, install, update, remove).
- **`codex mcp`**: Manage Model Context Protocol (MCP) servers for Codex.
- **`codex doctor`**: Diagnose local Codex installation, configuration, credentials, and runtime health.
- **`codex apply`**: Apply the latest diff produced by the Codex agent to the workspace.
- **`codex resume`**: Resume a previous session (or use `--last` to continue the most recent one).
- **`codex sandbox`**: Run commands within a Codex-provided sandboxed shell environment.

### Examples:
- Start an interactive session with a prompt:
  ```bash
  /home/tehlappy/.local/bin/codex "Review my Python code for bugs"
  ```
- Override model or configurations:
  ```bash
  /home/tehlappy/.local/bin/codex -m o3 "Analyze workspace database"
  ```
