# info-block [![CI](https://github.com/medyagh/info-block/actions/workflows/test.yml/badge.svg)](https://github.com/medyagh/info-block/actions/workflows/test.yml)

GitHub Action to print detailed runner information 

- Kernel and OS, CPU, Memory, Virtualization, Hardware Inventory, Storage, Network,Cgroups, Uptime and Load Average.
- Folded log groups per section for quick scanning
- Exposes outputs for downstream steps (see [supported outputs](#outputs))
- Designed to finish quickly on normal runners; the checks are lightweight and avoid slowing your jobs.


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
          echo "This will ONLY run if the runner has more than 8GB memory"

      # Example: ensure at least 4000 MB free before a heavy job
      - name: Run heavy job only if free memory is available
        if: ${{ steps.info-block.outputs.free_mem > 4000 }}
        run: echo "This will ONLY run free memory is more than 4000mb"

      # Example: gate heavy tests if the 1-minute load average is below 2
      - name: Run tests only if load average is low
        if: ${{ steps.info-block.outputs.load_average != 'unknown' && fromJSON(steps.info-block.outputs.load_average) < 2 }}
        run: echo "load_average: ${{ steps.info-block.outputs.load_average }}"
```

The action detects `RUNNER_OS` and prints diagnostics tailored for macOS, Linux, or Windows runners.

### Outputs
- `memory_gb`: Total memory in GB (integer).
- `cpu_cores`: Number of CPU cores (integer).
- `load_average`: 1-minute load average on macOS/Linux; current CPU load percentage on Windows.
- `free_mem`: Free/available memory in MB (integer).
- `procs`: List of running processes on the runner.
Contribute more outputs by opening a PR!

### Fail on any error
By default the action is best-effort. To make it fail if any command errors, set `fail_on_error: true`:

```yaml
      - uses: medyagh/info-block@v1
        with:
          fail_on_error: true
```
