# info-block
GitHub Action to print detailed runner information (OS, CPU, memory, virtualization, storage, network, uptime, and security) before your jobs run.

## Usage
Add a step to your workflow:

```yaml
name: Demo Info
on: [workflow_dispatch]

jobs:
  info:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    steps:
      - uses: medyagh/info-block@v1
```

The action detects `RUNNER_OS` and prints diagnostics tailored for macOS, Linux, or Windows runners.

## Notes
- Some Linux checks use `sudo`; they are marked `|| true` so the workflow continues even if permissions are limited.
- No inputs or outputs are required; this action is purely informational.
