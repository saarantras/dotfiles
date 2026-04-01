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
7. After submitting with `sbatch`, wait briefly and check whether the job fails immediately.

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
