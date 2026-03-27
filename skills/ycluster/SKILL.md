---
name: ycluster
description: Use when the user is writing, debugging, or reviewing Slurm sbatch or salloc commands for Yale YCRC clusters, especially Bouchet and McCleary, including partition selection, YCGA usage, Priority Tier account selection such as prio_skr2, and Yale-specific resource defaults.
---

# ycluster

Use this skill for Yale cluster job-submission work.

## First step

Start by identifying the current host:

```bash
hostname
```

Use the hostname to infer whether the user is currently on Bouchet, McCleary, or another machine before choosing partitions, paths, or examples. If the hostname is ambiguous, say so and proceed with a cluster-specific assumption only after stating it.

## Workflow

1. Check whether the job is for `sbatch`, `salloc`, or a shell one-liner.
2. Check the cluster with `hostname` when possible.
3. Choose the partition from the tables in [`references/partitions.md`](references/partitions.md).
4. Choose the account from [`references/accounts-and-patterns.md`](references/accounts-and-patterns.md).
5. Write a minimal script with only the resources the job actually needs.
6. Prefer cluster-native names and defaults over generic Slurm advice.
7. After submitting with `sbatch`, wait briefly and check whether the job fails immediately.

## Yale-specific rules

- Treat `ycga` as a McCleary partition for YCGA-related jobs.
- Treat names like `prio_skr2` as Slurm account names, not partition names.
- When using a Priority Tier account, pair it with a Priority Tier partition such as `priority`, `priority_gpu`, or `priority_mpi` where supported.
- If the user asks for the "right partition", recommend the smallest suitable partition first, then mention faster or larger alternatives only if warranted.
- If the request is underspecified, ask only for the missing job characteristics that materially affect partition choice: runtime, CPU count, memory, GPU type/count, and whether the workload is tightly-coupled MPI.
- After `sbatch`, it is usually worth waiting briefly, then checking queue state or output files to catch immediate failures such as bad paths, invalid accounts, missing modules, or impossible resource requests.

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
