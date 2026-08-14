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

This works on login nodes and compute nodes alike. `hostname` alone is not reliable because compute node names (e.g. `c01n05`) do not encode the cluster. If `scontrol` returns nothing, you are running locally, not on a cluster - see below for how to reach one.

## Working from a local session

When `scontrol` is absent you are on the user's laptop or workstation. You can still reach the clusters over ssh, but **every fresh connection requires interactive Duo confirmation - a push notification the user has to physically approve on their phone.** Piggy-backing on an already-authenticated connection avoids that entirely, and is strongly preferred: it costs the user nothing and needs no interaction.

Check for a live master before connecting:

```bash
ssh -O check bouchet.ycrc.yale.edu
```

- `Master running (pid=NNNN)` - a session is already authenticated. Run commands freely; they reuse that connection and cost no authentication.
- `No such file or directory` - no master. **The next connection triggers a Duo push to the user's phone.** Ask before opening one rather than firing an unexpected prompt at them.

With a master live, run remote commands normally:

```bash
ssh bouchet.ycrc.yale.edu 'mydirectories'
ssh bouchet.ycrc.yale.edu 'bash -s' <<'EOF'
squeue -u "$USER"
EOF
```

The master persists 8h after the last client exits. After a network change the socket can go stale and connections hang; `ssh -O exit <host>` drops it. Config lives in `dotfiles/.ssh/config.d/ycrc`, and its `Host` patterns lead with `*` so specific login nodes (`login2.mccleary.ycrc.yale.edu`) multiplex as well as the round-robin names.

Multiplexing is only established when the master connection is opened, so a session started before the config existed has no socket and cannot be adopted after the fact. If `ssh -O check` fails on a host the user says they are logged into, that is usually why - ask them to reconnect rather than opening a second authenticated session yourself.

Remember that a login node is shared. Heavy work belongs in `sbatch`, not in an ssh one-liner.

## Workflow

1. Check whether the job is for `sbatch`, `salloc`, or a shell one-liner.
2. Determine the cluster with `scontrol show config | grep ClusterName`.
3. Choose the partition from the tables in [`references/partitions.md`](references/partitions.md).
4. Choose the account from [`references/accounts-and-patterns.md`](references/accounts-and-patterns.md).
5. Write a minimal script with only the resources the job actually needs.
6. Prefer cluster-native names and defaults over generic Slurm advice.
7. After submitting with `sbatch`, wait briefly and check whether the job fails immediately. For longer-running follow-ups, use the Lindy polling helper (see below) instead of hand-picking sleep intervals.

## Know your own allocation

Check whether you are running inside a Slurm allocation before doing heavy work. If `$SLURM_JOB_ID` is set, you are in a job. Inspect your own resources with `scontrol show job $SLURM_JOB_ID` (CPUs, memory, timelimit, partition, nodelist) or read the env directly (`$SLURM_CPUS_PER_TASK`, `$SLURM_MEM_PER_NODE`, `$SLURM_TIMELIMIT`).

Offload work that is too large for your allocation - or that should run asynchronously - to `sbatch`. Do not monopolize your own job's CPUs and memory on subprocesses that could be separate jobs.

## Storage

The two clusters use different filesystems *and* different group names - `pi_skr2` on Bouchet, `reilly` on McCleary. Never carry a path from one to the other. `mydirectories` prints the canonical paths and `getquota` the live limits; prefer running them over trusting this table if anything looks off. `getquota` is a heavy query against the filesystem - run it once and reuse the answer, never in a loop (see below).

**Bouchet** (Roberts filesystem, successor to Gibbs/Palmer):

| Tier | Full path | Shortcut | Group quota | Backup | Purge |
|---|---|---|---|---|---|
| home | `/nfs/roberts/home/mcn26` | `~` | 125 GiB / 500k files (personal) | Yes | No |
| project | `/nfs/roberts/project/pi_skr2/mcn26` | `~/project_pi_skr2` | 4 TiB / 5M files | Yes | No |
| scratch | `/nfs/roberts/scratch/pi_skr2/mcn26` | `~/scratch_pi_skr2` | 10 TiB / 15M files | No | **30 days** |
| PI long-term | `/nfs/roberts/pi/pi_skr2` | none | 10 TiB / 10M files | No | No |

The Bouchet shortcuts point at the *group* root; the user's own directory is one level deeper under `mcn26`.

**McCleary** (Palmer + Gibbs; being decommissioned through 2026 into early 2027):

| Tier | Full path | Shortcut | Group quota | Backup | Purge |
|---|---|---|---|---|---|
| home | `/vast/palmer/home.mccleary/mcn26` | `~` | 125 GiB / 500k files (personal) | Yes | No |
| project | `/gpfs/gibbs/project/reilly/mcn26` | `~/project` | 4 TiB / 5M files | Yes | No |
| scratch60 | `/vast/palmer/scratch/reilly/mcn26` | `~/palmer_scratch` | 10 TiB / 15M files | No | **60 days** |
| PI long-term | `/vast/palmer/pi/reilly` | `~/varef` (points at `VariantEffects/`) | 20 TiB / 10M files | No | No |
| YCGA work | `/gpfs/ycga/work/reilly/mcn26` | `~/ycga_work` | 4 TiB / 5M files | Yes | No |

Choosing a tier:

- **scratch** for job working directories and intermediates. Largest and fastest, but purged, so nothing there is safe to leave. Extending expiration artificially is against YCRC policy.
- **project** for inputs, results, and anything worth keeping. Backed up on both clusters.
- **PI long-term** for finished datasets that must persist and are too large for project. Not backed up - it is capacity, not safety.
- **home** for configs and small scripts only. It is a personal quota, so filling it blocks only the user, but it is small.

Watch the **file count** limits as closely as the byte limits - pipelines that write many small files hit those first. Bouchet project was at 84% of its file limit when this was written.

## Submitting scripts

Do not use `dirname "$0"` to locate a script when submitting it. `cd` to the directory and submit it from there.

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

## Don't hammer shared services

`squeue`, `sacct`, `getquota`, and `getusage` all hit a shared resource - the Slurm controller or the filesystem metadata servers - on behalf of every user on the cluster. Frequent polling degrades it for everyone and can get an account rate-limited.

**One minute is a hard floor, and a few minutes is the sensible default.** Rules of thumb:

- `getquota` and `getusage` are heavy filesystem/accounting queries. Run once, reuse the answer, and do not re-run within a few minutes. Never in a loop.
- Broad `squeue`/`sacct` queries (whole queue, whole account, long history) are the same - a few minutes minimum.
- Query once and reuse the result rather than re-running it for each thing you want to know, and prefer one call to several narrow ones.
- Watching a single known job right after submission is the one case that justifies the 1 min floor, since a `squeue -j <jobid>` lookup is cheap and startup failures show up fast. Use the Lindy schedule below for that rather than inventing your own loop.
- Never wrap any of these in a `while` loop with a short `sleep`.

## Polling a running job (Lindy heuristic)

To pick the next-poll interval, do NOT compute it yourself - call `job-lindy <jobid>` (installed at `~/.local/bin/job-lindy`, source: `dotfiles/scripts/job-lindy.sh`). It does all the work and prints `eval`-safe `key="value"` lines.

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
3. Otherwise schedule the next check after `$next_poll_seconds`.

The script encodes the schedule (so future edits go in one place):

| Job age | Next poll | Why |
|---|---|---|
| PENDING | 1 min | Queue usually drains quickly here |
| R, <2 min | 1 min | Bad path / account / module - fails fast |
| R, 2-10 min | 2 min | Early OOM, I/O, module-load failures |
| R, 10-60 min | 10 min | Settled into compute |
| R, 1-6 h | 30 min | Stable; spot-check |
| R, 6+ h | 60 min (cap) | Strong Lindy - likely runs to completion |
| terminal | 0 | Stop |

1 min is the floor everywhere - nothing in the schedule polls faster than that. While in `R`, the next interval is also capped at `max(remaining_walltime/4, 60s)` so polling doesn't sleep past the job's end.

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
