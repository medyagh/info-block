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
mem_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
echo "Memory (bytes): ${mem_bytes}"
echo "Memory (GB): ${mem_gb}"
echo "memory_gb=${mem_gb}" >> "$GITHUB_OUTPUT"
page_size="$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)"
echo "Page size: ${page_size}"
physmem_line="$(top -l 1 | grep PhysMem | head -n1 2>/dev/null || true)"
echo "PhysMem line: ${physmem_line}"
free_mb="$(printf "%s\n" "${physmem_line}" | awk 'match($0, /([0-9]+)([GM])[^0-9]+(unused|free)/, m) {val=m[1]; if(m[2]==\"G\") val*=1024; print val; exit}')"
if [[ -z "${free_mb}" || "${free_mb}" == "0" ]]; then
  vm_stat_output="$(vm_stat 2>/dev/null || true)"
  echo "${vm_stat_output}"
  free_pages="$(printf "%s\n" "${vm_stat_output}" | awk '
    /Pages free/ {f=$3}
    /Pages inactive/ {i=$3}
    /Pages speculative/ {s=$3}
    END {
      gsub("[^0-9]", "", f);
      gsub("[^0-9]", "", i);
      gsub("[^0-9]", "", s);
      f += 0; i += 0; s += 0;
      printf "%d", f + i + s
    }')"
  free_bytes=$((free_pages * page_size))
  free_mb=$((free_bytes / 1024 / 1024))
fi
echo "Free memory (MB, approx): ${free_mb:-unknown}"
echo "free_mem=${free_mb:-unknown}" >> "$GITHUB_OUTPUT"
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

echo "::group::=== Uptime ==="
run "uptime"
run "sysctl kern.boottime"
echo "::endgroup::"

echo "::group::=== Load ==="
run "top -l 1 -n 0 | head -n 10"
load_avg="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}' | tr -d '{},' || true)"
echo "Load average (1m): ${load_avg:-unknown}"
echo "load_average=${load_avg:-unknown}" >> "$GITHUB_OUTPUT"
echo "::endgroup::"

echo "::group::=== Security ==="
run "spctl --status"
run "csrutil status"
echo "::endgroup::"

echo "::group::=== Processes ==="
process_list="$(ps -Ao pid,ppid,state,command 2>/dev/null || true)"
printf "%s\n" "${process_list}"
printf "procs<<'EOF'\n%s\nEOF\n" "${process_list}" >> "$GITHUB_OUTPUT"
echo "::endgroup::"
