# Yale Cluster Partitions

This file is a compact reference for writing `sbatch` scripts on Yale YCRC clusters.

Check the current cluster first with:

```bash
hostname
```

Use the output to determine whether you are on Bouchet, McCleary, or a non-cluster host before selecting partitions.

## Bouchet

Public partitions documented by YCRC:

| Partition | Use case | Notes |
| --- | --- | --- |
| `day` | Default CPU batch work | General-purpose queue; default if omitted |
| `day_amd` | CPU jobs targeting AMD nodes | Use only when AMD-specific placement matters |
| `devel` | Interactive/debug jobs | Short walltime, low per-user limits |
| `week` | Longer CPU jobs | Use when `day` is too short |
| `gpu_rtx6000` | GPU jobs on RTX 5000 Ada nodes | Good for moderate GPU work and development |
| `gpu_h200` | GPU jobs on H200 nodes | High-end GPU queue |
| `gpu_devel` | Interactive/debug GPU jobs | Short-lived GPU debugging |
| `bigmem` | High-memory CPU jobs | For jobs that exceed standard node memory |
| `mpi` | Tightly-coupled MPI jobs | Dedicated MPI-oriented partition |
| `scavenge` | Preemptable overflow work | Lower priority, can be interrupted |
| `scavenge_gpu` | Preemptable GPU overflow work | Request GPUs explicitly |

Common defaults and limits called out in the docs:

| Partition | Default request shape | Key limit or characteristic |
| --- | --- | --- |
| `day` | `--time=01:00:00 --nodes=1 --ntasks=1 --cpus-per-task=1 --mem-per-cpu=5120` | Max walltime `1-00:00:00` |
| `devel` | same as `day` | Max walltime `06:00:00` |
| `mpi` | `--time=01:00:00 --nodes=1 --ntasks=1 --cpus-per-task=1 --exclusive --mem=498688` | Max walltime `2-00:00:00`, up to 32 nodes/user |
| `scavenge` | same as `day` | Preemptable; GPU jobs still need `--gpus` |

## McCleary

Public partitions documented by YCRC:

| Partition | Use case | Notes |
| --- | --- | --- |
| `day` | Default CPU batch work | General-purpose queue |
| `devel` | Interactive/debug jobs | Short-lived interactive work |
| `week` | Longer CPU jobs | More walltime than `day` |
| `long` | Very long CPU jobs | Use only when long runtime is required |
| `gpu` | Standard GPU jobs | Request GPUs explicitly |
| `gpu_devel` | Interactive/debug GPU jobs | Short GPU sessions |
| `bigmem` | High-memory CPU jobs | For jobs exceeding standard memory |
| `scavenge` | Preemptable CPU/GPU overflow work | Request GPUs explicitly if needed |
| `scavenge_gpu` | Preemptable GPU overflow work | Max walltime `1-00:00:00` |

## McCleary YCGA partitions

These are the partitions most relevant to your stated access pattern:

| Partition | Use case | Notes |
| --- | --- | --- |
| `ycga` | YCGA-related jobs | Prefer this for YCGA work on McCleary |
| `ycga_admins` | Admin-only YCGA queue | Usually not for general user submission |
| `ycga_bigmem` | High-memory YCGA jobs | YCGA-specific big-memory queue |

Selected defaults from the docs:

| Partition | Default request shape | Notes |
| --- | --- | --- |
| `ycga` | Same general default pattern used by other CPU queues: `--time=01:00:00 --nodes=1 --ntasks=1 --cpus-per-task=1 --mem-per-cpu=5120` | Use for standard YCGA workloads |
| `ycga_bigmem` | `--time=01:00:00 --nodes=1 --ntasks=1 --cpus-per-task=1 --mem-per-cpu=5120` | Use when YCGA jobs need large memory |

## Priority Tier partitions

YCRC documents these cross-cluster Priority Tier partitions:

| Partition | Similar to | Bouchet | McCleary |
| --- | --- | --- | --- |
| `priority` | `day`-like CPU queue | Yes | Yes |
| `priority_gpu` | `gpu`-like GPU queue | Yes | Yes |
| `priority_mpi` | `mpi`-like queue | Yes | No |

Priority Tier notes:

| Item | Value |
| --- | --- |
| Account naming | `prio_groupname` or `prio_groupname_projectid` |
| Example account | `prio_skr2` |
| Max walltime at launch | `7-00:00:00` |
| Interactive jobs | Allowed |

## Partition selection heuristics

| If the job is... | Prefer... |
| --- | --- |
| Normal CPU batch work | `day` |
| Needs more than 1 day but not special hardware | `week` |
| Very long CPU runtime on McCleary | `long` |
| Interactive compile/debug | `devel` |
| Standard GPU work | `gpu`, `gpu_rtx6000`, or `gpu_h200` depending on cluster and GPU need |
| Interactive GPU debugging | `gpu_devel` |
| Large-memory CPU work | `bigmem` or `ycga_bigmem` |
| Tightly-coupled MPI on Bouchet | `mpi` or `priority_mpi` |
| YCGA workload on McCleary | `ycga` |
| Cheap/flexible overflow work | `scavenge` or `scavenge_gpu` |

## Sources

- Bouchet docs: https://docs.ycrc.yale.edu/clusters/bouchet/
- McCleary docs: https://docs.ycrc.yale.edu/clusters/mccleary/
- Priority Tier docs: https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/priority-tier/
- Migration notice dated March 10, 2026: https://research.computing.yale.edu/posts/2026-03-10-migrating-to-bouchet-we-are-here-to-help
