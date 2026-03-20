---
name: ntfy-notify
description: Use when the user wants ntfy notifications, mentions notify-job, asks to be woken up by a notification, or asks Codex to add lightweight job-completion or failure notifications to a script or command workflow.
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

Wake-up / urgent alert usage:

```bash
NTFY_TITLE="Cluster finished" NTFY_PRIORITY=max NTFY_TAGS="rotating_light,alarm_clock" notify-job "cluster finished on $(hostname)"
```

## When to use it

Use `notify-job` when the user asks for notifications, when a script is clearly long-running, when the user wants to be woken up by completion/failure, or when completion/failure alerts would materially help the workflow.

Prefer adding notifications at:

- successful completion
- error or non-zero exit
- unexpected crash paths where the language/runtime makes that practical

## Wake-up alerts

If the user says things like "wake me up", "make it loud", "server down style", or otherwise wants an alert strong enough to wake them:

- Prefer `NTFY_PRIORITY=max`.
- Prefer alert-style tags such as `rotating_light,alarm_clock`.
- Send repeated notifications rather than a single notification, for example `3` to `5` messages spaced `15` to `30` seconds apart.
- Tell the user that phone/app notification settings control the actual sound/vibration pattern; `notify-job` can request urgency, but it cannot force volume or DND bypass.
- If reliability matters overnight, recommend a one-shot test notification first.
- If the user wants the strongest possible escalation, mention ntfy phone-call notifications as a separate option if their setup supports it.

## Implementation guidance

- Keep changes minimal and local to the script the user is working on.
- Do not add notifications unless the user asked for them or invoked this skill.
- Reuse `notify-job`; do not introduce direct `curl` calls unless the helper is unavailable.
- Include concise, high-signal messages with script name, host, and failure status when useful.
- Avoid duplicate notification blocks if the script already has equivalent logic.
- For wake-up alerts, default to repeated `NTFY_PRIORITY=max` notifications unless the user asks for something quieter.

## Language patterns

- Bash: use `trap` for failure notifications when appropriate, plus an explicit success notification at the end. For wake-up alerts, a short `for` loop that sends repeated high-priority notifications is acceptable.
- Python: use `try`/`except`/`finally` only if needed; prefer the smallest clear change.
- Other languages: follow the local style and add the simplest reliable success/failure hooks available.
