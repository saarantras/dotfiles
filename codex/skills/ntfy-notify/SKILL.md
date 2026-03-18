---
name: ntfy-notify
description: Use when the user wants ntfy notifications, mentions notify-job, or asks Codex to add lightweight job-completion or failure notifications to a script or command workflow.
---

# ntfy Notify

This skill exposes a lightweight notification helper already installed by the dotfiles bootstrap.

## Available helper

Use `notify-job` to send a message to the shared ntfy topic.

- Default server: `https://ntfy.sh`
- Default topic: `saarantras`
- Installed path: `~/.local/bin/notify-job`

Basic usage:

```bash
notify-job "job finished"
```

Optional metadata:

```bash
NTFY_TITLE="Job failed" NTFY_TAGS="warning,x" notify-job "train.py exited with code 1"
```

## When to use it

Use `notify-job` when the user asks for notifications, when a script is clearly long-running, or when completion/failure alerts would materially help the workflow.

Prefer adding notifications at:

- successful completion
- error or non-zero exit
- unexpected crash paths where the language/runtime makes that practical

## Implementation guidance

- Keep changes minimal and local to the script the user is working on.
- Do not add notifications unless the user asked for them or invoked this skill.
- Reuse `notify-job`; do not introduce direct `curl` calls unless the helper is unavailable.
- Include concise, high-signal messages with script name, host, and failure status when useful.
- Avoid duplicate notification blocks if the script already has equivalent logic.

## Language patterns

- Bash: use `trap` for failure notifications when appropriate, plus an explicit success notification at the end.
- Python: use `try`/`except`/`finally` only if needed; prefer the smallest clear change.
- Other languages: follow the local style and add the simplest reliable success/failure hooks available.
