---
name: ai
description: "AI Infrastructure CLI. Trigger this skill when the user runs the `ai` command, checks AI status, queries MSN agents, sends messages to Lyra, restarts systemd services, or needs memory/telemetry statistics."
---
# AI Infrastructure CLI Skill

Use this skill to monitor and control all AI systems. You can run the `ai` wrapper script using the `run_command` tool.

## Executable Path
The unified `ai` wrapper script is located at:
`/home/tehlappy/.local/bin/ai`

## Subcommands and Usage

To run a subcommand, execute:
```bash
/home/tehlappy/.local/bin/ai <command> [args...]
```

### 1. Unified Status Monitor (`ai status` and `ai status-v`)
- Check health, telemetry, port bindings, VRAM utilization, and services:
  ```bash
  /home/tehlappy/.local/bin/ai status
  ```
- Use `status-v` for verbose JSON/raw telemetry output:
  ```bash
  /home/tehlappy/.local/bin/ai status-v
  ```

### 2. Lyra Dialogue System Interface (`ai lyra`)
- Send prompts directly to the Lyra dialogue agent:
  ```bash
  /home/tehlappy/.local/bin/ai lyra "Your message here"
  ```

### 3. MSN Swarm Management (`ai msn`)
- List all active MSN agents, their Sephira wave, and IDs:
  ```bash
  /home/tehlappy/.local/bin/ai msn
  ```
- Query a specific MSN agent's endpoint status:
  ```bash
  /home/tehlappy/.local/bin/ai msn <agent_id> [/path]
  ```
  *(Example: `/home/tehlappy/.local/bin/ai msn nssp /status`)*

### 4. Service Control Manager (`ai service`)
- Manage systemd background services (e.g. `msn-router`, `lyra-api`, `lilith-api`, `ollama`):
  ```bash
  /home/tehlappy/.local/bin/ai service <start|stop|restart|status> <service_name>
  ```
  *(Example: `/home/tehlappy/.local/bin/ai service restart msn-router`)*

### 5. Hermes & Antigravity CLIs (`ai hermes` and `ai agy`)
- Run commands inside the Hermes venv:
  ```bash
  /home/tehlappy/.local/bin/ai hermes "sessions list"
  ```
- Run agy command line directly:
  ```bash
  /home/tehlappy/.local/bin/ai agy "trigger cleanup-skill"
  ```

### 6. Memory & Log Retrieval (`ai memory`)
- Retrieve recent episodic, semantic, ephemeral, archetypal, or axiomatic entries from `golem_diary.db`:
  ```bash
  /home/tehlappy/.local/bin/ai memory [limit]
  ```

### 7. Custom Shell Execution (`ai shell`)
- Execute a shell command within the environment cautiously:
  ```bash
  /home/tehlappy/.local/bin/ai shell "command"
  ```

### 8. Metaconscious Desktop Control (`ai metaconscious`)
- Trigger a lightning strike and post an overlay message on the interactive PyQt6 wallpaper:
  ```bash
  /home/tehlappy/.local/bin/ai metaconscious "[message]" [color]
  ```
  *(Example: `/home/tehlappy/.local/bin/ai metaconscious "LILITH: Systems fully synchronized." gold`)*
