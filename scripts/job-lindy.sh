#!/usr/bin/env bash
# job-lindy: report Slurm job state + Lindy-style next-poll interval.
#
# Output: key="value" lines on stdout, safe to `eval`.
# Keys: state, state_long, elapsed_seconds, elapsed_human,
#       remaining_seconds, remaining_human, next_poll_seconds,
#       next_poll_human, terminal, exit_code, summary.
#
# Lindy schedule (RUNNING):
#   <2m  -> 30s    (startup fragility)
#   <10m -> 2m     (early OOM / module / I/O failures)
#   <1h  -> 10m
#   <6h  -> 30m
#   else -> 1h    (cap)
# PENDING -> 15s flat (queue usually drains quickly).
# Terminal states -> 0 (stop polling).
# Wall-time cap: next_poll <= max(remaining/4, 30s) when in RUNNING.

set -euo pipefail

jobid="${1:-}"
if [[ -z "$jobid" ]]; then
    echo "usage: job-lindy <jobid>" >&2
    exit 2
fi

# Parse [DD-]HH:MM:SS, HH:MM:SS, or MM:SS into seconds.
parse_time() {
    local t="$1"
    case "$t" in ""|UNLIMITED|N/A|INVALID|"NOT_SET") echo ""; return ;; esac
    local days=0 rest="$t"
    if [[ "$rest" == *-* ]]; then
        days="${rest%%-*}"; rest="${rest#*-}"
    fi
    local IFS=:; local parts=()
    read -ra parts <<< "$rest"
    local h=0 m=0 s=0
    case "${#parts[@]}" in
        3) h="${parts[0]}"; m="${parts[1]}"; s="${parts[2]}" ;;
        2) m="${parts[0]}"; s="${parts[1]}" ;;
        1) s="${parts[0]}" ;;
        *) echo ""; return ;;
    esac
    echo $(( 10#$days*86400 + 10#$h*3600 + 10#$m*60 + 10#$s ))
}

humanize() {
    local s="${1:-0}"
    [[ "$s" -le 0 ]] && { echo "0s"; return; }
    local d=$((s/86400)) h=$(( (s%86400)/3600 )) m=$(( (s%3600)/60 )) sec=$((s%60))
    if   (( d>0 )); then printf "%dd%dh\n" "$d" "$h"
    elif (( h>0 )); then printf "%dh%dm\n" "$h" "$m"
    elif (( m>0 )); then printf "%dm%ds\n" "$m" "$sec"
    else                 printf "%ds\n"    "$sec"
    fi
}

state_long=""; elapsed_s=""; remaining_s=""; exit_code=""; terminal=0

# Try squeue first (active / queued).
sq=$(squeue -j "$jobid" -h -O 'State:30,Elapsed:30,TimeLeft:30' 2>/dev/null | head -1 || true)
if [[ -n "${sq// }" ]]; then
    read -r state_long elapsed_raw timeleft_raw <<< "$sq"
    elapsed_s=$(parse_time "$elapsed_raw")
    remaining_s=$(parse_time "$timeleft_raw")
else
    # Fall back to sacct for finished jobs.
    sa=$(sacct -j "$jobid" -X -n -P -o State,Elapsed,ExitCode 2>/dev/null | head -1 || true)
    if [[ -z "${sa// }" ]]; then
        cat <<EOF
state="UNKNOWN"
state_long="UNKNOWN"
elapsed_seconds="0"
elapsed_human="0s"
remaining_seconds="0"
remaining_human="0s"
next_poll_seconds="0"
next_poll_human="0s"
terminal="1"
exit_code=""
summary="job $jobid not found in squeue or sacct"
EOF
        exit 1
    fi
    IFS='|' read -r state_long elapsed_raw exit_code <<< "$sa"
    state_long="${state_long%% *}"  # strip "CANCELLED by uid N"
    elapsed_s=$(parse_time "$elapsed_raw")
fi

state=""
case "$state_long" in
    PENDING)        state=PD ;;
    RUNNING)        state=R ;;
    COMPLETED)      state=CD;  terminal=1 ;;
    FAILED)         state=F;   terminal=1 ;;
    CANCELLED)      state=CA;  terminal=1 ;;
    TIMEOUT)        state=TO;  terminal=1 ;;
    OUT_OF_MEMORY)  state=OOM; terminal=1 ;;
    NODE_FAIL)      state=NF;  terminal=1 ;;
    BOOT_FAIL)      state=BF;  terminal=1 ;;
    DEADLINE)       state=DL;  terminal=1 ;;
    PREEMPTED)      state=PR;  terminal=1 ;;
    REVOKED)        state=RV;  terminal=1 ;;
    SPECIAL_EXIT)   state=SE;  terminal=1 ;;
    SUSPENDED)      state=S ;;
    CONFIGURING)    state=CF ;;
    COMPLETING)     state=CG ;;
    *)              state="$state_long" ;;
esac

lindy_running() {
    local e="$1"
    if   (( e < 120 ));   then echo 30
    elif (( e < 600 ));   then echo 120
    elif (( e < 3600 ));  then echo 600
    elif (( e < 21600 )); then echo 1800
    else                       echo 3600
    fi
}

next=0
if (( terminal )); then
    next=0
elif [[ "$state" == "PD" ]]; then
    next=15
elif [[ "$state" == "R" ]]; then
    next=$(lindy_running "${elapsed_s:-0}")
    if [[ -n "$remaining_s" && "$remaining_s" -gt 0 ]]; then
        cap=$(( remaining_s / 4 ))
        (( cap < 30 )) && cap=30
        (( next > cap )) && next=$cap
    fi
else
    next=60  # CF, CG, S, unknown non-terminal
fi

elapsed_human=$(humanize "${elapsed_s:-0}")
remaining_human=$(humanize "${remaining_s:-0}")
next_human=$(humanize "$next")

summary="$state ${elapsed_human} elapsed"
[[ -n "$remaining_s" && "$remaining_s" -gt 0 ]] && summary+=" | ${remaining_human} left"
if (( terminal )); then
    summary+=" | terminal"
    [[ -n "$exit_code" ]] && summary+=" (exit $exit_code)"
else
    summary+=" | next poll in $next_human"
fi

cat <<EOF
state="$state"
state_long="$state_long"
elapsed_seconds="${elapsed_s:-0}"
elapsed_human="$elapsed_human"
remaining_seconds="${remaining_s:-0}"
remaining_human="$remaining_human"
next_poll_seconds="$next"
next_poll_human="$next_human"
terminal="$terminal"
exit_code="$exit_code"
summary="$summary"
EOF
