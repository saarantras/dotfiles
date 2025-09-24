import os
import re
import subprocess
import statistics
from tqdm import tqdm
from datetime import timedelta

# Regex to match slurm job files
job_file_re = re.compile(r"slurm-(\d+_\d+)\.out")

# Metrics to extract from bar chart
metric_names = [
    "CPU utilization",
    "CPU memory usage",
    "GPU utilization",
    "GPU memory usage"
]

# Extract all job IDs
job_ids = []
for fname in os.listdir():
    match = job_file_re.match(fname)
    if match:
        job_ids.append(match.group(1))

if not job_ids:
    print("No matching slurm job output files found.")
    exit(1)

# Initialize metrics
metrics = {name: [] for name in metric_names}
runtime_fractions = []

# Helper to convert H:MM:SS or HH:MM:SS to seconds
def parse_time(hms):
    parts = list(map(int, hms.strip().split(":")))
    if len(parts) == 2:
        return parts[0] * 60 + parts[1]
    elif len(parts) == 3:
        return parts[0] * 3600 + parts[1] * 60 + parts[2]
    else:
        raise ValueError(f"Unexpected time format: {hms}")

# Process jobs with progress bar
for job_id in tqdm(job_ids, desc="Processing jobs", unit="job"):
    try:
        output = subprocess.check_output(["jobstats", job_id], text=True)
    except subprocess.CalledProcessError:
        print(f"Failed to run jobstats for job {job_id}")
        continue

    # Extract bar metrics
    for name in metric_names:
        pattern = rf"{re.escape(name)}\s+\[\|*\s*(\d+)%\]"
        match = re.search(pattern, output)
        if match:
            metrics[name].append(int(match.group(1)))
        else:
            print(f"Warning: Couldn't find {name} for job {job_id}")

    # Extract run time and time limit
    run_match = re.search(r"Run Time:\s+([\d:]+)", output)
    lim_match = re.search(r"Time Limit:\s+([\d:]+)", output)
    if run_match and lim_match:
        try:
            run_sec = parse_time(run_match.group(1))
            lim_sec = parse_time(lim_match.group(1))
            if lim_sec > 0:
                runtime_fractions.append(run_sec / lim_sec)
        except Exception as e:
            print(f"Failed to parse run time for job {job_id}: {e}")
    else:
        print(f"Warning: Couldn't find run time or time limit for job {job_id}")

# Report bar metrics
print("\nSummary of Overall Utilization Metrics")
print("=======================================")
for name in metric_names:
    values = metrics[name]
    if values:
        print(f"{name:20s} | min: {min(values):>3d}%  max: {max(values):>3d}%  avg: {statistics.mean(values):5.1f}%")
    else:
        print(f"{name:20s} | No data")

# Report runtime fraction
if runtime_fractions:
    print(f"\nRun Time / Time Limit")
    print("======================")
    print(f"min: {min(runtime_fractions):.2f}  max: {max(runtime_fractions):.2f}  avg: {statistics.mean(runtime_fractions):.3f}")
else:
    print("\nNo run time data available.")
