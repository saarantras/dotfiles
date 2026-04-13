#!/bin/bash
# scratch-check: warn about files in scratch nearing Yale's 60-day purge.
#
# Usage:
#   scratch-check          print summary from snapshot (initial scan if needed)
#   scratch-check --list   list individual expiring files, sorted by age
#   scratch-check --scan   force a full rescan (updates snapshot)
#   scratch-check --motd   MOTD-safe: print warnings only if TTY; triggers a
#                          background rescan when snapshot is stale
#   scratch-check -h       show this help
#
# The snapshot (~/.cache/scratch-check-snapshot) stores per-file data so that
# --list, --motd, and default summary recompute ages arithmetically without
# touching the filesystem. Only --scan walks the tree.
#
# Config (env vars):
#   SCRATCH_WARN_DAYS       warn threshold in days (default 53, purge at 60)
#   SCRATCH_CACHE_AGE_HOURS max snapshot age before background rescan (default 24)
#   SCRATCH_FIND_TIMEOUT    find timeout in seconds (default 300)
#   SCRATCH_TIME_FIELD      ctime|mtime|atime (default ctime)
#   SCRATCH_DIRS            colon-separated list of scratch dirs (auto-detected)

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
SNAPSHOT="$CACHE_DIR/scratch-check-snapshot"
WARN_DAYS="${SCRATCH_WARN_DAYS:-53}"
MAX_CACHE_AGE_HOURS="${SCRATCH_CACHE_AGE_HOURS:-24}"
FIND_TIMEOUT="${SCRATCH_FIND_TIMEOUT:-300}"

TIME_FIELD="${SCRATCH_TIME_FIELD:-ctime}"
case "$TIME_FIELD" in ctime|mtime|atime) ;; *) TIME_FIELD=ctime ;; esac
case "$TIME_FIELD" in
    ctime) PRINTF_TIME='%C@' ;;
    atime) PRINTF_TIME='%A@' ;;
    mtime) PRINTF_TIME='%T@' ;;
esac

find_scratch_dirs() {
    if [ -n "${SCRATCH_DIRS:-}" ]; then
        printf '%s\n' "$SCRATCH_DIRS" | tr ':' '\n' | awk 'NF'
        return
    fi
    # Walk $HOME entries whose name contains "scratch". Resolve symlinks, then
    # prefer a $USER subdirectory if one exists -- scratch symlinks often point
    # at a group-shared parent (e.g. /nfs/.../scratch/pi_foo) containing every
    # lab member's dir. Without this narrowing, find recurses into multi-TB
    # trees belonging to other users.
    local d real
    shopt -s nullglob
    for d in "$HOME"/*scratch* "$HOME"/scratch*; do
        [ -e "$d" ] || continue
        real=$(readlink -f "$d" 2>/dev/null || printf '%s' "$d")
        if [ -d "$real/$USER" ]; then
            printf '%s\n' "$real/$USER"
        else
            printf '%s\n' "$real"
        fi
    done | sort -u
}

human_size() {
    local bytes="${1:-0}"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null || printf '%sB' "$bytes"
    else
        printf '%sB' "$bytes"
    fi
}

# ---------------------------------------------------------------------------
# scan: walk the tree, write per-file snapshot
# ---------------------------------------------------------------------------
scan() {
    mkdir -p "$CACHE_DIR"
    local tmp
    tmp=$(mktemp "$SNAPSHOT.XXXXXX") || return 1
    local dirs
    dirs=$(find_scratch_dirs)

    printf '# scratch-check snapshot\n' > "$tmp"
    printf '# scanned: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$tmp"
    printf '# time_field: %s\n' "$TIME_FIELD" >> "$tmp"

    if [ -z "$dirs" ]; then
        printf '# no scratch directories found\n' >> "$tmp"
    else
        while IFS= read -r d; do
            [ -z "$d" ] && continue
            [ -d "$d" ] || continue
            timeout "$FIND_TIMEOUT" find "$d" -xdev -user "$USER" \
                -type f -printf "%p\t${PRINTF_TIME}\t%s\n" 2>/dev/null >> "$tmp"
        done <<< "$dirs"
    fi
    mv "$tmp" "$SNAPSHOT"
}

# ---------------------------------------------------------------------------
# read_snapshot: emit "age_days\tsize_bytes\tpath" for files >= min_days old
# ---------------------------------------------------------------------------
read_snapshot() {
    local min_days="${1:-0}"
    [ -f "$SNAPSHOT" ] || return 0
    local now
    now=$(date +%s)
    awk -F'\t' -v now="$now" -v min="$min_days" '
        /^#/ { next }
        NF >= 3 {
            age = int((now - $2) / 86400)
            if (age >= min) print age "\t" $3 "\t" $1
        }
    ' "$SNAPSHOT"
}

snapshot_age_hours() {
    [ -f "$SNAPSHOT" ] || { echo 99999; return; }
    local ts now
    ts=$(stat -c %Y "$SNAPSHOT" 2>/dev/null || echo 0)
    now=$(date +%s)
    echo $(( (now - ts) / 3600 ))
}

snapshot_date() {
    grep '^# scanned:' "$SNAPSHOT" 2>/dev/null \
        | sed 's/^# scanned: *//' || echo 'never'
}

ensure_snapshot() {
    [ -f "$SNAPSHOT" ] && return 0
    scan
}

maybe_background_scan() {
    local age
    age=$(snapshot_age_hours)
    if [ "$age" -ge "$MAX_CACHE_AGE_HOURS" ]; then
        ( setsid "$0" --scan </dev/null >/dev/null 2>&1 & ) 2>/dev/null \
            || ( nohup "$0" --scan </dev/null >/dev/null 2>&1 & )
    fi
}

# ---------------------------------------------------------------------------
# print_summary: one-line status from snapshot (no FS access)
# ---------------------------------------------------------------------------
print_summary() {
    ensure_snapshot
    local data
    data=$(read_snapshot "$WARN_DAYS")
    local scanned
    scanned=$(snapshot_date)
    if [ -z "$data" ]; then
        printf 'OK: no files with %s >%dd (snapshot %s)\n' \
            "$TIME_FIELD" "$WARN_DAYS" "$scanned"
    else
        local count size oldest hsize
        count=$(printf '%s\n' "$data" | wc -l)
        size=$(printf '%s\n' "$data" | awk -F'\t' '{s+=$2} END{print s+0}')
        oldest=$(printf '%s\n' "$data" | awk -F'\t' 'NR==1||$1>m{m=$1} END{print m}')
        hsize=$(human_size "$size")
        printf 'WARN: %d file(s) with %s >%dd (%s), oldest %sd (snapshot %s)\n' \
            "$count" "$TIME_FIELD" "$WARN_DAYS" "$hsize" "$oldest" "$scanned"
    fi
}

# ---------------------------------------------------------------------------
# list_files: per-file listing sorted by age descending (no FS access)
# ---------------------------------------------------------------------------
list_files() {
    ensure_snapshot
    local data
    data=$(read_snapshot "$WARN_DAYS")
    if [ -z "$data" ]; then
        printf 'No files with %s >%dd\n' "$TIME_FIELD" "$WARN_DAYS"
        return
    fi
    printf '%s\n' "$data" | sort -t$'\t' -k1 -nr \
        | while IFS=$'\t' read -r age size path; do
            printf '%4dd  %8s  %s\n' "$age" "$(human_size "$size")" "$path"
        done
}

# ---------------------------------------------------------------------------
# motd: MOTD-safe output (TTY-gated, no FS walk, background refresh)
# ---------------------------------------------------------------------------
motd() {
    [ -t 1 ] || return 0
    if [ -f "$SNAPSHOT" ]; then
        local data
        data=$(read_snapshot "$WARN_DAYS")
        if [ -n "$data" ]; then
            local count size oldest hsize
            count=$(printf '%s\n' "$data" | wc -l)
            size=$(printf '%s\n' "$data" | awk -F'\t' '{s+=$2} END{print s+0}')
            oldest=$(printf '%s\n' "$data" | awk -F'\t' 'NR==1||$1>m{m=$1} END{print m}')
            hsize=$(human_size "$size")
            echo '--- scratch expiration warning ---'
            printf '%d file(s) with %s >%dd (%s), oldest %sd\n' \
                "$count" "$TIME_FIELD" "$WARN_DAYS" "$hsize" "$oldest"
            echo "('scratch-check --list' to see files, 'scratch-check --scan' to refresh)"
            echo
        fi
    fi
    maybe_background_scan
}

case "${1:-}" in
    --motd) motd ;;
    --scan) scan ;;
    --list) list_files ;;
    "")     print_summary ;;
    -h|--help)
        sed -n '2,11p' "$0"
        ;;
    *)  echo "Usage: $0 [--motd|--list|--scan]" >&2; exit 1 ;;
esac
