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

Use `notify-job` in two modes:

**Attached to scripts** — add notifications to a script the user is working on for completion/failure/milestone alerts.

**Direct invocation by AI assistants** — Claude or other agents can call `notify-job` directly (not inside a script) to send the user a status update, milestone report, or summary message mid-task. This is especially useful for long-running agentic workflows where the user may not be watching the terminal.

`notify-job` is particularly well-suited for long-term monitoring: send a notification on each key milestone, on failure, and on final success. Don't limit notifications to just start/end.

`notify-job` also works as a text message — agents may write long, detailed messages (multi-line, markdown-style prose) to give the user a full picture of what happened. Don't over-compress; a thorough message is better than a terse one.

Prefer adding notifications at:

- successful completion
- error or non-zero exit
- key milestones during a long-running task
- unexpected crash paths where the language/runtime makes that practical

## Wake-up alerts

If the user says things like "wake me up", "make it loud", "server down style", or otherwise wants an alert strong enough to wake them:

- Prefer `NTFY_PRIORITY=max`.
- Prefer alert-style tags such as `rotating_light,alarm_clock`.
- Send repeated notifications rather than a single notification, for example `3` to `5` messages spaced `15` to `30` seconds apart.
- Tell the user that phone/app notification settings control the actual sound/vibration pattern; `notify-job` can request urgency, but it cannot force volume or DND bypass.
- If reliability matters overnight, recommend a one-shot test notification first.
- If the user wants the strongest possible escalation, mention ntfy phone-call notifications as a separate option if their setup supports it.

## Titles

All notifications share the `saarantras` topic, so **every notification must have an informative `NTFY_TITLE`** that clearly identifies which task, job, or agent sent it. Vague titles like "Done" or "Job finished" are not acceptable.

Good titles: `"train.py run #3 — epoch 50/100"`, `"PR review agent — claude-code#482 complete"`, `"data-pipeline: stage 2 of 4 done"`

If the job name or context is not obvious from the conversation, ask the user for a short identifying label before proceeding.

## Implementation guidance

- Keep changes minimal and local to the script the user is working on.
- Do not add notifications unless the user asked for them or invoked this skill.
- Reuse `notify-job`; do not introduce direct `curl` calls unless the helper is unavailable.
- Always set `NTFY_TITLE` to something that uniquely identifies the task (see Titles above).
- Messages may be long — include script name, host, failure status, relevant output, and any other detail that helps the user understand what happened without needing to check the terminal.
- Avoid duplicate notification blocks if the script already has equivalent logic.
- For wake-up alerts, default to repeated `NTFY_PRIORITY=max` notifications unless the user asks for something quieter.

## Language patterns

- Bash: use `trap` for failure notifications when appropriate, plus an explicit success notification at the end. For wake-up alerts, a short `for` loop that sends repeated high-priority notifications is acceptable.
- Python: use `try`/`except`/`finally` only if needed; prefer the smallest clear change.
- Other languages: follow the local style and add the simplest reliable success/failure hooks available.
