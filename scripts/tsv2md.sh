#!/bin/bash
# tsv2md: convert TSV to a GitHub-flavored markdown table.
#
# Usage:
#   tsv2md < file.tsv
#   tsv2md file.tsv [more.tsv ...]
#   some_command | tsv2md
#
# First row is treated as the header; a separator row is inserted after it.

exec awk -F'\t' '
    NR==1 { n = NF }
    {
        printf "|"
        for (i = 1; i <= NF; i++) {
            gsub(/\|/, "\\|", $i)
            printf " %s |", $i
        }
        print ""
    }
    NR==1 {
        printf "|"
        for (i = 1; i <= n; i++) printf " --- |"
        print ""
    }
' "$@"
