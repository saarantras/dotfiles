#!/usr/bin/env bash
set -euo pipefail

sleep 10

NTFY_TITLE="Skill invocation test" \
NTFY_TAGS="test,hourglass" \
notify-job "ntfy-notify skill invocation test from $(hostname)"
