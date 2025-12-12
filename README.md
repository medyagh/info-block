# info-block
GitHub Action to print detailed runner information (OS, CPU, memory, virtualization, storage, network, uptime, and security) before your jobs run.

## Usage
Add a step to your workflow:

```yaml
      - uses: medyagh/info-block@v1
```

The action detects `RUNNER_OS` and prints either the macOS or Linux diagnostics shown in the runner logs.

## Notes
- Some Linux checks use `sudo`; they are marked `|| true` so the workflow continues even if permissions are limited.
- No inputs or outputs are required; this action is purely informational.
