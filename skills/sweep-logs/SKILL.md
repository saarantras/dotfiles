---
name: sweep-logs
description: Use when the user wants to clean up Slurm .out/.err log files from a job directory, summarize job resource usage before deleting logs, or run runstats/arraystat to generate a stats report.
---

# sweep-logs

Sweeps a Slurm job directory: generates a comprehensive resource report, then deletes the raw log files. The report is structured so a later agent can parse it into summary tables.

Requires the Yale cluster environment from the ycluster skill (sacct, jobstats, scontrol must be available).

## Workflow

1. **Identify the target directory.** Default is cwd. If the user names a path, use that.

2. **Inventory log files.** List what is present:
   ```bash
   ls slurm-*.out slurm-*.err worker_*.out 2>/dev/null
   ```
   Note whether these are array jobs (`slurm-N_M.out` pattern) or single jobs (`slurm-N.out`).

3. **Run `runstats`** to generate the report. This calls `~/.slurm_run_stats.py` and writes `run_stats_YYYYMMDD_HHMMSS.txt` to the directory:
   ```bash
   runstats [directory]
   ```
   Confirm the report file was written before proceeding.

4. **For array jobs**, also run `arraystat` from the target directory. It reads all `slurm-N_M.out` files and prints aggregate utilization (CPU%, GPU%, memory%, runtime fraction):
   ```bash
   cd [directory] && arraystat
   ```
   Capture its stdout and append it to the report file:
   ```bash
   echo "" >> run_stats_*.txt
   echo "== arraystat summary ==" >> run_stats_*.txt
   cd [directory] && arraystat >> run_stats_*.txt 2>&1
   ```

5. **Delete the raw log files** once the report exists:
   ```bash
   rm slurm-*.out slurm-*.err worker_*.out 2>/dev/null
   ```
   Tell the user how many files were deleted and the path to the report.

## What the report contains

`runstats` captures the following per job:
- **jobstats** human-readable: avg/peak CPU%, GPU%, memory%, node assignment, efficiency summary
- **jobstats JSON**: raw numbers (used_memory, total_memory, total_time) per node
- **sacct** full accounting: AllocCPUS, ReqMem, Elapsed, Timelimit, TotalCPU, MaxRSS, AveRSS, MaxVMSize, MaxDiskRead, MaxDiskWrite, ExitCode, and more
- **scontrol show node**: hardware spec for each node used -- CPU architecture, socket/core layout, total memory, GPU model if present
- **Log snippets**: first 20 + last 50 lines of each log file

`arraystat` appends: min/max/avg across all array tasks for CPU utilization, CPU memory, GPU utilization, GPU memory, and runtime-as-fraction-of-timelimit.

## Notes

- Do not delete log files until the report file is confirmed written.
- If `runstats` finds no log files (e.g., user already deleted them), abort and tell the user.
- If `jobstats` or `sacct` return errors for a job (job too old, purged from accounting), the report will contain the error text -- that is expected; still delete the logs.
- The `runstats` alias and `arraystat` alias are defined in `~/.bashrc`. If the shell does not have them, call the scripts directly: `python3 ~/.slurm_run_stats.py [dir]` and `python3 ~/.jobsum.py`.
