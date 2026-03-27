#!/bin/bash
# prio-cost.sh — show Priority Tier spending for prio_skr2
ACCOUNT="${1:-prio_skr2}"
getusage -g "$ACCOUNT"
