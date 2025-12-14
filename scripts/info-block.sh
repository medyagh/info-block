#!/usr/bin/env bash

# Dispatch to OS-specific script, sharing common helpers.
FAIL_ON_ERROR="${1:-false}"

start_ts=$(date +%s)

case "${RUNNER_OS}" in
  "macOS")
    bash "${BASH_SOURCE%/*}/info-block-macos.sh" "${FAIL_ON_ERROR}"
    ;;
  "Linux")
    bash "${BASH_SOURCE%/*}/info-block-linux.sh" "${FAIL_ON_ERROR}"
    ;;
  "Windows")
    bash "${BASH_SOURCE%/*}/info-block-windows.sh" "${FAIL_ON_ERROR}"
    ;;
  *)
    echo "Unsupported runner OS: ${RUNNER_OS:-unknown}"
    ;;
esac

end_ts=$(date +%s)
duration_seconds=$((end_ts - start_ts))
echo "info-block duration (s): ${duration_seconds}"
echo "duration_seconds=${duration_seconds}" >> "$GITHUB_OUTPUT"
