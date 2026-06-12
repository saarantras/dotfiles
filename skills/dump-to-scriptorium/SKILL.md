---
name: dump-to-scriptorium
description: Use when the user wants to move a directory (typically large scratch sim trees) off-device to the scriptorium Globus cold-storage endpoint, free up scratch, or relocate data before a scratch purge. Handles the globus transfer, leaves a MOVED.txt tombstone, and deletes the source only after the transfer is verified.
---

# dump-to-scriptorium

Relocates a directory to the `scriptorium` Globus collection (cold storage), leaves a
`MOVED.txt` tombstone at the source documenting where it went and how to pull it back,
then deletes the source contents to free scratch.

This is **destructive** (it removes the source after transfer). It is also outward-facing
(data leaves the cluster). Get explicit user sign-off on the source path and destination
name before deleting anything, and never delete before the transfer is verified SUCCEEDED.

## Fixed facts

- Destination collection: `scriptorium`, endpoint UUID `9d56dbeb-48ec-11f1-beeb-0ea3589134b3`
- Destination path convention: `/mnt/visiting_data/sims/<name>/`, where `<name>` is
  usually the source's parent dir name (e.g. `design_space_sims`, `capiti`). Confirm the
  name with the user; do not invent a scheme.
- scriptorium is NTFS-backed: always transfer with `--sync-level size` (no timestamp
  preservation). Do not use `mtime`/`checksum` sync levels.
- Globus CLI module: `Globus-CLI/3.34.0-GCCcore-13.3.0`.

## Workflow

1. **Cluster + allocation self-check.** Confirm the cluster
   (`scontrol show config | grep ClusterName`). If you are inside a Slurm job
   (`$SLURM_JOB_ID` set), do not run heavy directory walks or large `grep`s on a small
   partition like `devel` -- they can OOM the allocation. Globus does the heavy lifting
   server-side, so the transfer itself is cheap to launch.

2. **Confirm scope with the user.** Get the exact source path(s), the destination
   `<name>`, and explicit confirmation that the source may be deleted afterward. Report
   the size first (`du -sh <src>`) so the user knows what is moving.

3. **Load Globus CLI and authenticate.** Authentication is interactive; ask the user to
   run the login in-session with the `!` prefix if you are not already authed:
   ```bash
   module load Globus-CLI/3.34.0-GCCcore-13.3.0
   globus session update yale.edu     # refresh Yale identity if needed
   globus whoami                       # verify authenticated
   ```
   If `globus login` is needed, the user must run `! globus login` themselves.

4. **Identify the SOURCE endpoint.** This is the Yale cluster collection for the
   filesystem the data lives on, and it differs by cluster (McCleary vs Bouchet) and by
   filesystem. Do NOT hardcode or guess it. Find it and confirm with the user:
   ```bash
   globus endpoint search --filter-scope my-endpoints
   globus endpoint search "Yale"
   ```
   Once confirmed, save it to memory as a `reference` so future runs skip the lookup.

5. **Pre-flight the source permissions.** Globus' directory scan stalls or cancels on
   unreadable files (this sank the first two capiti attempts). Make the tree group- and
   self-readable before transferring:
   ```bash
   chmod -R u+rX,g+rX <src>
   ```
   If any files are owned by another user and unreadable, that owner must fix them (or
   the offending subtree must be excluded with `--exclude` or removed if regenerable).

6. **Launch the transfer.** One `globus transfer` per source tree:
   ```bash
   globus transfer --recursive --sync-level size \
     --label "dump <name> $(date +%Y%m%d)" \
     <SOURCE_UUID>:<src> \
     9d56dbeb-48ec-11f1-beeb-0ea3589134b3:/mnt/visiting_data/sims/<name>/
   ```
   Capture the returned **Task ID**.

7. **Wait for and verify success.** Do not poll with `sleep` in-conversation; use the
   `cron` skill for waits over ~10s, or block on the task with Globus itself:
   ```bash
   globus task wait <TASK_ID>           # returns when done
   globus task show <TASK_ID>           # confirm Status: SUCCEEDED, files/bytes moved
   ```
   Only proceed if Status is `SUCCEEDED`. On `FAILED`/`CANCELED`, inspect
   `globus task event-list <TASK_ID>` and fix (usually a permission/scandir issue from
   step 5) before retrying. Do not delete the source.

8. **Write the tombstone** at the source, before deletion (see template below). Include
   the destination, the task ID, the original size, the sync mode, and any pointer to
   aggregated outputs that live in a repo.

9. **Delete the source contents.** Only after SUCCEEDED and tombstone written:
   ```bash
   # delete contents but keep the dir + MOVED.txt
   find <src> -mindepth 1 -not -name MOVED.txt -delete
   ```
   Report freed space and the destination path back to the user.

## MOVED.txt template

```
This directory's contents were moved to cold storage on <ISO-8601 timestamp>.

Destination:
  Globus endpoint: scriptorium (9d56dbeb-48ec-11f1-beeb-0ea3589134b3)
  Path:            /mnt/visiting_data/sims/<name>/

Transfer details:
  Globus task ID:  <TASK_ID>
  Original size:   ~<SIZE>
  Sync mode:       size (NTFS-safe; no timestamp preservation)

To browse or pull data back:
  module load Globus-CLI/3.34.0-GCCcore-13.3.0
  globus ls 9d56dbeb-48ec-11f1-beeb-0ea3589134b3:/mnt/visiting_data/sims/<name>/
  globus transfer 9d56dbeb-48ec-11f1-beeb-0ea3589134b3:/mnt/visiting_data/sims/<name>/ <yale-endpoint>:<dest> --recursive --sync-level size

<optional: pointer to aggregated outputs still in the repo>
```

## Notes

- Prior relocations used this exact pattern; their tombstones are good worked examples:
  `/nfs/roberts/scratch/pi_skr2/mcn26/design_space_sims/MOVED.txt` and
  `/nfs/roberts/scratch/pi_skr2/mcn26/capiti/MOVED.txt`.
- For multiple sibling source dirs (e.g. `..._pow` and `..._pw`), you can transfer each
  into one shared destination `<name>/` so they pull back together. Confirm the layout
  with the user.
- Regenerable subtrees (git clones, public DBs) need not be archived -- exclude them and
  note re-fetch instructions in the tombstone instead, rather than burning transfer time.
- This skill only moves data off-device. It does not decide what to move; pair it with
  `scratch-check` to find purge-eligible directories.
