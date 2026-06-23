---
name: hermes
description: "Hermes Agent CLI. Trigger this skill when the user wants to run a Hermes command, execute a Hermes CLI operation, run a Hermes skill, manage Hermes agents, or inspect the Hermes workspace."
---
# Hermes Agent CLI Skill

Use this skill to execute commands using the Hermes CLI. You can run the `hermes` CLI using the `run_command` tool.

## Executable Path
The `hermes` CLI script is located at:
`/home/tehlappy/.local/bin/hermes`

## Subcommands and Usage

To run a Hermes command, execute:
```bash
/home/tehlappy/.local/bin/hermes <command> [args...]
```

### Common Commands:
- **`hermes setup`**: Run the setup wizard.
- **`hermes config`**: View and edit configuration.
- **`hermes sessions list`**: List all past Hermes sessions.
- **`hermes sessions browse`**: Launch the interactive session picker.
- **`hermes logs`**: View the last 50 lines of `agent.log`.
- **`hermes logs -f`**: Follow logs in real time.
- **`hermes skills`**: Search, install, configure, and manage skills.
- **`hermes plugins`**: Manage plugins.
- **`hermes dashboard`**: Start the web UI dashboard (port 9119).
- **`hermes update`**: Update Hermes Agent to the latest version.

### Examples:
- Start an interactive oneshot session:
  ```bash
  /home/tehlappy/.local/bin/hermes -z "Query prompt here"
  ```
- Resume the most recent session:
  ```bash
  /home/tehlappy/.local/bin/hermes -c
  ```
- Run with preloaded skills:
  ```bash
  /home/tehlappy/.local/bin/hermes -s devops,email -z "Analyze system security"
  ```
