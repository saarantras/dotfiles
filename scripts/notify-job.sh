#!/usr/bin/env bash
set -euo pipefail

server="${NTFY_SERVER:-https://ntfy.sh}"
topic="${NTFY_TOPIC:-saarantras}"
title="${NTFY_TITLE:-Job notification}"
priority="${NTFY_PRIORITY:-default}"
tags="${NTFY_TAGS:-}"

if [ $# -lt 1 ]; then
    echo "Usage: notify-job <message>" >&2
    exit 1
fi

message="$*"

args=(
    -fsSL
    -H "Title: $title"
    -H "Priority: $priority"
    -d "$message"
)

if [ -n "$tags" ]; then
    args+=(-H "Tags: $tags")
fi

curl "${args[@]}" "$server/$topic" >/dev/null
