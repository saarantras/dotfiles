# Accounts And sbatch Patterns

Check the current machine first:

```bash
hostname
```

The hostname helps determine whether examples should target Bouchet or McCleary.

## Accounts

| Item | Meaning |
| --- | --- |
| Partition | Chooses the queue and hardware class |
| Account (`-A`) | Chooses the Slurm account used for access, priority, and charging context |
| `prio_skr2` | Priority Tier account name, not a partition name |

Priority Tier account naming documented by YCRC:

| Pattern | Meaning |
| --- | --- |
| `prio_groupname` | Priority Tier account for a Slurm group |
| `prio_groupname_projectid` | Project-specific Priority Tier account |

## Common sbatch templates

### Standard CPU job

```bash
#!/bin/bash
#SBATCH -J myjob
#SBATCH -p day
#SBATCH -t 08:00:00
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH -o slurm-%j.out

set -euo pipefail

python myscript.py
```

### McCleary YCGA job

```bash
#!/bin/bash
#SBATCH -J ycga-job
#SBATCH -p ycga
#SBATCH -t 12:00:00
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH -o slurm-%j.out

set -euo pipefail

python analysis.py
```

### Priority Tier CPU job

```bash
#!/bin/bash
#SBATCH -J fast-cpu
#SBATCH -p priority
#SBATCH -A prio_skr2
#SBATCH -t 12:00:00
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -o slurm-%j.out

set -euo pipefail

python train.py
```

### Priority Tier GPU job

```bash
#!/bin/bash
#SBATCH -J fast-gpu
#SBATCH -p priority_gpu
#SBATCH -A prio_skr2
#SBATCH -t 08:00:00
#SBATCH -c 8
#SBATCH --mem=64G
#SBATCH --gpus=1
#SBATCH -o slurm-%j.out

set -euo pipefail

python train_gpu.py
```

### Bouchet MPI job

```bash
#!/bin/bash
#SBATCH -J mpi-job
#SBATCH -p mpi
#SBATCH -t 24:00:00
#SBATCH -N 4
#SBATCH --ntasks-per-node=64
#SBATCH --exclusive
#SBATCH -o slurm-%j.out

set -euo pipefail

srun ./my_mpi_program
```

## Translation table

| User says... | Likely Slurm setting |
| --- | --- |
| "run it on YCGA" | `-p ycga` |
| "use my priority access" | `-A prio_skr2` plus a `priority*` partition |
| "interactive debug" | `salloc -p devel ...` or `salloc -p gpu_devel ...` |
| "high memory" | `-p bigmem` or `-p ycga_bigmem` |
| "MPI job" | `-p mpi` or `-p priority_mpi` on Bouchet |
| "cheap if available" | `-p scavenge` or `-p scavenge_gpu` |

## Sanity checks before finalizing a script

| Check | Why |
| --- | --- |
| Confirm cluster with `hostname` | Avoid using Bouchet-only or McCleary-only partitions on the wrong system |
| Confirm account vs partition | Prevent mistakes like treating `prio_skr2` as a queue |
| Request GPUs explicitly | GPU-capable partitions do not always allocate GPUs by default |
| Keep runtime realistic | Better fit improves scheduling |
| Use the smallest suitable partition | Reduces queue friction and wasted allocation |

## Post-submit check

After running `sbatch`, it is usually worth waiting briefly and then checking whether the job failed immediately.

Typical quick checks:

```bash
sbatch job.sh
sleep 5
squeue -u "$USER"
```

If the job exits immediately, inspect the Slurm output file and, if needed, `sacct` for the failure reason.

## Sources

- https://docs.ycrc.yale.edu/clusters/bouchet/
- https://docs.ycrc.yale.edu/clusters/mccleary/
- https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/priority-tier/
