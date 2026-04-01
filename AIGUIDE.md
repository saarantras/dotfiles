# AI Assistant Guidelines

- Push back and suggest alternatives where appropriate. If the user is clearly doing something wrong, following an anti-pattern, or has otherwise missed something, say so. Don't feel the need to do this constantly — use judgement.
- Leave version control in the hands of the user. You can remind them to stage/push, or do it when explicitly prompted, but generally this will be done manually to keep the codebase clean.
- For monitoring, monitor at small increments during startup, as many failures happen during startup, then extend to longer timepoints.
- don't use ` dirname "$0"` when submitting slurm scripts. just cd there and submit it yourself.
- Avoid non-ASCII characters in code and output. No emoji, emdashes, fancy quotes, decorative Unicode separators, etc. Use plain ASCII equivalents (e.g. `--` not `—`, regular dashes for section separators). Exceptions: Unicode is fine where semantically necessary, such as SI unit symbols or internationalized text content.