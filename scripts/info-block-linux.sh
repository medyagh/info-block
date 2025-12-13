#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/common.sh" "${FAIL_ON_ERROR}"

echo "::group::=== Kernel and OS ==="
run "uname -a"
run "cat /etc/os-release"
echo "::endgroup::"

echo "::group::=== CPU ==="
cpu_cores="$(nproc 2>/dev/null || echo 0)"
echo "CPU cores: ${cpu_cores}"
echo "cpu_cores=${cpu_cores}" >> "$GITHUB_OUTPUT"
run "nproc"
run "grep -m1 'model name' /proc/cpuinfo" || true
run "grep -m1 '^Hardware' /proc/cpuinfo" || true
run "grep -m1 '^flags' /proc/cpuinfo" || true
run "lscpu"
run "lscpu | grep -i 'hypervisor\\|virt' || true"
echo "::endgroup::"

echo "::group::=== Memory ==="
mem_kb="$(grep MemTotal /proc/meminfo | awk '{print $2}' 2>/dev/null || echo 0)"
mem_gb=$((mem_kb / 1024 / 1024))
echo "MemTotal (kB): ${mem_kb}"
echo "MemTotal (GB): ${mem_gb}"
echo "memory_gb=${mem_gb}" >> "$GITHUB_OUTPUT"
run "free -h"
echo "::endgroup::"

echo "::group::=== Virtualization ==="
run "systemd-detect-virt"
run "egrep -c '(vmx|svm)' /proc/cpuinfo || true"
run "lsmod | grep -E '(^kvm|kvm_(intel|amd))' || true"
if [ -f /sys/module/kvm_intel/parameters/nested ]; then
  run "echo -n \"kvm_intel nested: \"; cat /sys/module/kvm_intel/parameters/nested"
fi
if [ -f /sys/module/kvm_amd/parameters/nested ]; then
  run "echo -n \"kvm_amd nested: \"; cat /sys/module/kvm_amd/parameters/nested"
fi
run "sudo journalctl -k | grep -i kvm | tail -n 100"
if command -v virt-host-validate >/dev/null 2>&1; then
  run "sudo virt-host-validate"
fi
echo "::endgroup::"

echo "::group::=== Hardware Inventory ==="
run "sudo dmidecode -s system-manufacturer"
run "sudo dmidecode -s system-product-name"
run "sudo dmidecode -t bios -t system -t processor -t memory | sed -n '1,200p'"
run "sudo lshw -short"
run "lspci -nn"
run "command -v lsusb >/dev/null 2>&1 && lsusb || echo 'lsusb not available'"
echo "::endgroup::"

echo "::group::=== Storage ==="
run "lsblk -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT,FSTYPE"
run "df -h"
echo "::endgroup::"

echo "::group::=== Network ==="
echo "${HTTP_PROXY:-}"
run "ip addr show"
run "ip route"
run "ip -s link"
run "ifconfig"
echo "::endgroup::"

echo "::group::=== Cgroups ==="
run "stat -fc %T /sys/fs/cgroup"
echo "::endgroup::"

echo "::group::=== Uptime ==="
run "uptime"
run "who -b"
run "awk '{printf \"Uptime (seconds): %s\\n\", \$1}' /proc/uptime 2>/dev/null"
echo "::endgroup::"

echo "::group::=== Load ==="
run "top -b -n1 | head -n 10"
run "cat /proc/loadavg"
load_avg="$(awk '{print $1}' /proc/loadavg 2>/dev/null || true)"
if [[ -z "${load_avg}" ]]; then
  load_avg="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | tr -d ' ')"
fi
echo "Load average (1m): ${load_avg:-unknown}"
echo "load_average=${load_avg:-unknown}" >> "$GITHUB_OUTPUT"
echo "::endgroup::"
