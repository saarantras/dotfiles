#!/usr/bin/env python3
"""
slurm_run_stats.py

Scans a directory for slurm/worker log files, queries SLURM for
comprehensive resource usage statistics, and writes a detailed
report to a timestamped file in that directory.

Usage:
    runstats [directory]

    If directory is omitted, uses the current working directory.
"""

import os
import re
import sys
import json
import subprocess
from datetime import datetime
from pathlib import Path

# ── patterns ───────────────────────────────────────────────────────────────────
SLURM_LOG_RE = re.compile(r"slurm-(\d+)\.(out|err)$")
WORKER_LOG_RE = re.compile(r"worker_(\d+)\.out$")

SACCT_FIELDS = [
    "JobID", "JobName", "State", "Partition", "Account", "QOS", "Cluster",
    "NodeList", "NNodes", "AllocCPUS", "ReqMem",
    "Submit", "Start", "End", "Elapsed", "Timelimit",
    "TotalCPU", "UserCPU", "SystemCPU", "CPUTime",
    "MaxRSS", "AveRSS", "MaxVMSize", "AveVMSize",
    "MaxDiskRead", "MaxDiskWrite", "AveDiskRead", "AveDiskWrite",
    "NTasks", "ExitCode",
]


# ── helpers ────────────────────────────────────────────────────────────────────
def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        return e.output or ""
    except FileNotFoundError:
        return f"[command not found: {cmd[0]}]\n"


def find_job_ids(directory):
    slurm_ids, worker_ids = set(), set()
    for fname in os.listdir(directory):
        m = SLURM_LOG_RE.match(fname)
        if m:
            slurm_ids.add(m.group(1))
        m = WORKER_LOG_RE.match(fname)
        if m:
            worker_ids.add(m.group(1))
    return sorted(slurm_ids), sorted(worker_ids)


def get_sacct(job_id):
    return run(["sacct", "-j", job_id,
                "--format=" + ",".join(SACCT_FIELDS),
                "--parsable2"])


def get_jobstats_text(job_id):
    return run(["jobstats", "--no-color", job_id])


def get_jobstats_json(job_id):
    raw = run(["jobstats", "--json", job_id])
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return {"error": "could not parse JSON", "raw": raw}


def get_node_info(node_name):
    return run(["scontrol", "show", "node", node_name])


def extract_nodes_from_sacct(sacct_text):
    """Extract individual node names from parsable2 sacct NodeList column."""
    nodes = set()
    for line in sacct_text.splitlines():
        parts = line.split("|")
        if len(parts) > 7:
            nodelist = parts[7]
            if nodelist and nodelist not in ("None", "", "NodeList"):
                # handles individual nodes and bracket-expanded lists
                for n in re.split(r"[,\s]", nodelist):
                    n = re.sub(r"[\[\]]", "", n).strip()
                    if re.match(r"[a-zA-Z]", n):
                        nodes.add(n)
    return nodes


def read_log_snippet(path, head_n=20, tail_n=50):
    try:
        text = Path(path).read_text(errors="replace").splitlines()
        head = text[:head_n]
        tail = text[-(tail_n):] if len(text) > head_n + tail_n else text[head_n:]
        return head, tail, len(text)
    except Exception as e:
        return [], [str(e)], 0


def hr(char="=", width=80):
    return char * width


def section(title, char="="):
    return f"\n{hr(char)}\n  {title}\n{hr(char)}\n"


def subsection(title, width=78):
    pad = width - len(title) - 4
    return f"\n── {title} {'─' * max(pad, 2)}"


# ── main ───────────────────────────────────────────────────────────────────────
directory = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")  # fallback only

slurm_ids, worker_ids = find_job_ids(directory)
all_ids_ordered = slurm_ids + [w for w in worker_ids if w not in set(slurm_ids)]

if not all_ids_ordered:
    print("No slurm-*.out/err or worker_*.out files found in:", directory)
    sys.exit(1)

# Use the submit time of the first main job as the timestamp (falls back to now)
job_timestamp = None
if slurm_ids:
    raw = run(["sacct", "-j", slurm_ids[0], "--format=Submit", "--parsable2", "--noheader"])
    for line in raw.splitlines():
        line = line.strip().split("|")[0]
        try:
            job_timestamp = datetime.strptime(line, "%Y-%m-%dT%H:%M:%S").strftime("%Y%m%d_%H%M%S")
            break
        except ValueError:
            continue
if job_timestamp is None:
    job_timestamp = timestamp

out_path = directory / f"run_stats_{job_timestamp}.txt"

print(f"Found {len(slurm_ids)} main job(s), {len(worker_ids)} worker job(s).")
print(f"Writing report to: {out_path}")

lines = []
lines += [
    hr(),
    "  SLURM Run Statistics Report",
    f"  Generated : {datetime.now().isoformat()}",
    f"  Directory : {directory}",
    f"  Main jobs : {', '.join(slurm_ids) or 'none'}",
    f"  Workers   : {', '.join(worker_ids) or 'none'}",
    hr(),
]

# ── per-job ────────────────────────────────────────────────────────────────────
all_nodes = set()

for job_id in all_ids_ordered:
    tag = "MAIN" if job_id in set(slurm_ids) else "WORKER"
    lines.append(section(f"Job {job_id}  [{tag}]"))

    # jobstats — human readable (avg + peak CPU/mem, node, efficiency)
    lines.append(subsection("jobstats — human-readable (avg/peak utilization)"))
    lines.append(get_jobstats_text(job_id))

    # jobstats — JSON (raw numbers: used_memory, total_memory, total_time per node)
    lines.append(subsection("jobstats — JSON"))
    lines.append(json.dumps(get_jobstats_json(job_id), indent=2))

    # sacct — full accounting record including peak RSS, disk I/O, CPU breakdown
    lines.append(subsection("sacct — full accounting record"))
    sacct = get_sacct(job_id)
    lines.append("Fields: " + "|".join(SACCT_FIELDS))
    lines.append(sacct)

    all_nodes |= extract_nodes_from_sacct(sacct)

# ── hardware ───────────────────────────────────────────────────────────────────
lines.append(section("Node Hardware (scontrol show node)"))
for node in sorted(all_nodes):
    lines.append(subsection(node))
    lines.append(get_node_info(node))

# ── log file snapshots ─────────────────────────────────────────────────────────
lines.append(section("Log File Snapshots"))
log_files = sorted(
    f for f in os.listdir(directory)
    if re.match(r"(slurm-\d+\.(out|err)|worker_\d+\.out)$", f)
)
for fname in log_files:
    head, tail, total = read_log_snippet(directory / fname)
    lines.append(subsection(f"{fname}  ({total} lines total)"))
    if head:
        lines.append(f"[first {len(head)} lines]")
        lines.extend(head)
    if tail:
        lines.append(f"[last {len(tail)} lines]")
        lines.extend(tail)

# ── write ──────────────────────────────────────────────────────────────────────
out_path.write_text("\n".join(lines) + "\n")
print(f"Done. Report saved to: {out_path}")
