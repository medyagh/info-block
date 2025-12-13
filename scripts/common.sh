#!/usr/bin/env bash

FAIL_ON_ERROR="${1:-false}"
set -o pipefail
if [[ "$FAIL_ON_ERROR" == "true" ]]; then
  set -e
else
  set +e
fi

run() {
  if [[ "$FAIL_ON_ERROR" == "true" ]]; then
    bash -x -c "$1"
  else
    bash -x -c "$1" || true
  fi
}

# Mute xtrace for echo so group headers don't pollute output.
echo() {
  local _restore=0
  case "$-" in *x*) _restore=1;; esac
  { set +x; } 2>/dev/null
  builtin echo "$@"
  if [[ $_restore -eq 1 ]]; then set -x; fi
}

# Expose helpers and arguments to sub-scripts
export FAIL_ON_ERROR
export -f run echo

echo "=== Info Block for ${RUNNER_OS:-unknown} (fail_on_error=${FAIL_ON_ERROR}) ==="
