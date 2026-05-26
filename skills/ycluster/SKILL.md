---
name: ycluster
description: Use when the user is writing, debugging, or reviewing Slurm sbatch or salloc commands for Yale YCRC clusters, especially Bouchet and McCleary, including partition selection, YCGA usage, Priority Tier account selection such as prio_skr2, and Yale-specific resource defaults.
---

# ycluster

Use this skill for Yale cluster job-submission work.

## First step

Identify which cluster the user is on:

```bash
scontrol show config 2>/dev/null | awk '/^ClusterName/{print $3}'
```

This works on login nodes and compute nodes alike. `hostname` alone is not reliable because compute node names (e.g. `c01n05`) do not encode the cluster. If `scontrol` is unavailable or returns nothing, ask the user which cluster before proceeding.

## Workflow

1. Check whether the job is for `sbatch`, `salloc`, or a shell one-liner.
2. Determine the cluster with `scontrol show config | grep ClusterName`.
3. Choose the partition from the tables in [`references/partitions.md`](references/partitions.md).
4. Choose the account from [`references/accounts-and-patterns.md`](references/accounts-and-patterns.md).
5. Write a minimal script with only the resources the job actually needs.
6. Prefer cluster-native names and defaults over generic Slurm advice.
7. After submitting with `sbatch`, wait briefly and check whether the job fails immediately. For longer-running follow-ups, use the Lindy polling helper (see below) instead of hand-picking sleep intervals.

## Python / conda environments

On Yale clusters, `conda` is not available by default. Load it with:

```bash
module load miniconda
```

After loading, `conda activate <env>` and `conda create` work as expected. This applies to both interactive sessions and sbatch scripts.

## Yale-specific rules

- Treat `ycga` as a McCleary partition for YCGA-related jobs.
- Treat names like `prio_skr2` as Slurm account names, not partition names.
- When using a Priority Tier account, pair it with a Priority Tier partition such as `priority`, `priority_gpu`, or `priority_mpi` where supported.
- If the user asks for the "right partition", recommend the smallest suitable partition first, then mention faster or larger alternatives only if warranted.
- If the request is underspecified, ask only for the missing job characteristics that materially affect partition choice: runtime, CPU count, memory, GPU type/count, and whether the workload is tightly-coupled MPI.
- After `sbatch`, it is usually worth waiting briefly, then checking queue state or output files to catch immediate failures such as bad paths, invalid accounts, missing modules, or impossible resource requests.

## Polling a running job (Lindy heuristic)

For waits longer than a few seconds, use the `cron` skill (per global guideline) rather than `sleep`. To pick the next-poll interval, do NOT compute it yourself - call `job-lindy <jobid>` (installed at `~/.local/bin/job-lindy`, source: `dotfiles/scripts/job-lindy.sh`). It does all the work and prints `eval`-safe `key="value"` lines.

```bash
eval "$(job-lindy 12345)"
echo "$summary"
# $next_poll_seconds: integer seconds until next check (0 if terminal)
# $terminal:          "1" if job is finished/failed/cancelled/etc.
# $state:             short code (PD, R, CD, F, CA, TO, OOM, ...)
```

Loop logic:
1. Run `job-lindy $JOBID`, eval the output.
2. If `$terminal == 1`, stop and report `$summary` plus `.out`/`.err` tail.
3. Otherwise schedule the next check via cron with delay `$next_poll_seconds`.

The script encodes the schedule (so future edits go in one place):

| Job age | Next poll | Why |
|---|---|---|
| PENDING | 15 s | Queue usually drains quickly here |
| R, <2 min | 30 s | Bad path / account / module - fails fast |
| R, 2-10 min | 2 min | Early OOM, I/O, module-load failures |
| R, 10-60 min | 10 min | Settled into compute |
| R, 1-6 h | 30 min | Stable; spot-check |
| R, 6+ h | 60 min (cap) | Strong Lindy - likely runs to completion |
| terminal | 0 | Stop |

While in `R`, the next interval is also capped at `max(remaining_walltime/4, 30s)` so polling doesn't sleep past the job's end.

## Checking Priority Tier spending

The user has a script `prio-cost` installed at `~/.local/bin/prio-cost` (source: `dotfiles/scripts/prio-cost.sh`). Run it when the user asks about Priority Tier costs:

```bash
prio-cost              # prio_skr2 (default)
prio-cost prio_other   # different account
```

This wraps `getusage` and shows monthly SU-hours and dollar charges.

## References

- Partition and queue tables: [`references/partitions.md`](references/partitions.md)
- Accounts, `sbatch` patterns, and examples: [`references/accounts-and-patterns.md`](references/accounts-and-patterns.md)
