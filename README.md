# info-block
GitHub Action to print detailed runner information 

- Kernel and OS, CPU, Memory, Virtualization, Hardware Inventory, Storage, Network,Cgroups, Uptime and Load Average.
- Folded log groups per section for quick scanning
- Exposes outputs for downstream steps (see [supported outputs](#outputs))


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

      # Example: ensure at least 4GB free before a heavy job
      - name: Run heavy job only if free memory is available
        if: ${{ steps.info-block.outputs.free_mem > 4 }}
        run: echo "free_mem: ${{ steps.info-block.outputs.free_mem }}"

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
- `free_mem`: Free/available memory in GB (integer).
Contribute more outputs by opening a PR!

### Fail on any error
By default the action is best-effort. To make it fail if any command errors, set `fail_on_error: true`:

```yaml
      - uses: medyagh/info-block@v1
        with:
          fail_on_error: true
```
