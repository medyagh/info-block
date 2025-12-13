#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/common.sh" "${FAIL_ON_ERROR}"

echo "::group::=== Kernel and OS ==="
run "uname -a"
run "sw_vers"
run "sysctl kern.osrelease kern.osversion kern.version"
echo "::endgroup::"

echo "::group::=== CPU ==="
cpu_cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 0)"
echo "CPU cores: ${cpu_cores}"
echo "cpu_cores=${cpu_cores}" >> "$GITHUB_OUTPUT"
run "sysctl -n machdep.cpu.brand_string"
run "sysctl -n hw.ncpu"
run "sysctl -n machdep.cpu.core_count"
run "sysctl -n machdep.cpu.thread_count"
run "sysctl -n machdep.cpu.features"
run "sysctl -n machdep.cpu.leaf7_features 2>/dev/null || true"
if [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)" == *"Intel"* ]]; then
  run "sysctl -n machdep.cpu.extfeatures"
fi
echo "::endgroup::"

echo "::group::=== Memory ==="
run "sysctl -n hw.memsize"
mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
echo "Memory (bytes): ${mem_bytes}"
echo "Memory (GB): ${mem_gb}"
echo "memory_gb=${mem_gb}" >> "$GITHUB_OUTPUT"
run "sysctl -n hw.pagesize"
run "vm_stat"
echo "::endgroup::"

echo "::group::=== Virtualization ==="
run "sysctl -n kern.hv_vmm_present"
run "sysctl -n kern.hv_support" || true
run "sysctl -n machdep.cpu.features | grep -i vmx" || true
echo "::endgroup::"

echo "::group::=== Hardware Inventory ==="
run "sysctl hw.model"
run "system_profiler SPHardwareDataType"
echo "::endgroup::"

echo "::group::=== Storage ==="
run "diskutil list"
run "df -h"
run "system_profiler SPStorageDataType | sed -n '1,200p'"
echo "::endgroup::"

echo "::group::=== Network ==="
echo "${HTTP_PROXY:-}"
run "ifconfig"
run "networksetup -listallhardwareports"
run "scutil --get HostName"
run "scutil --get LocalHostName"
run "scutil --get ComputerName"
run "route -n get default"
run "netstat -rn"
run "scutil --dns"
echo "::endgroup::"

echo "::group::=== Uptime and Load ==="
run "uptime"
run "sysctl kern.boottime"
run "top -l 1 -n 0 | head -n 10"
echo "::endgroup::"

echo "::group::=== Security ==="
run "spctl --status"
run "csrutil status"
echo "::endgroup::"
