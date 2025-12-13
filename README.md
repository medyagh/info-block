# info-block
GitHub Action to print detailed runner information (OS, CPU, memory, virtualization, storage, network, uptime, and security) before your jobs run.

## Features
- Folded log groups per section (Kernel/CPU/Memory/etc.) for quick scanning
- Exposes outputs for downstream steps (see [Outputs](#outputs))


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
      - id: info-block
        uses: medyagh/info-block@v1

      # Example conditional action based on info-block outputs
      - name: Run this step only if memory is more than 8GBs
        if: ${{ steps.info-block.outputs.memory_gb > 8 }}
        run: |
          echo "memory_gb: ${{ steps.info-block.outputs.memory_gb }}"
          echo "yay! it is more than 8 gb"
```

The action detects `RUNNER_OS` and prints diagnostics tailored for macOS, Linux, or Windows runners.

### Outputs
- `memory_gb`: Total memory in GB (integer).
- `cpu_cores`: Number of CPU cores (integer).
Contribute more outputs by opening a PR!

### Fail on any error
By default the action is best-effort. To make it fail if any command errors, set `fail_on_error: true`:

```yaml
      - uses: medyagh/info-block@v1
        with:
          fail_on_error: true
```
