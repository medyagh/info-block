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
    bash -c "$1"
  else
    bash -c "$1" || true
  fi
}

echo "=== Info Block for ${RUNNER_OS:-unknown} (fail_on_error=${FAIL_ON_ERROR}) ==="

if [[ "$RUNNER_OS" == "macOS" ]]; then
  set -x
  echo "=== Kernel and OS ==="
  run "uname -a"
  run "sw_vers"
  run "sysctl kern.osrelease kern.osversion kern.version"

  echo "=== CPU ==="
  run "sysctl -n machdep.cpu.brand_string"
  run "sysctl -n hw.ncpu"
  run "sysctl -n machdep.cpu.core_count"
  run "sysctl -n machdep.cpu.thread_count"
  run "sysctl -n machdep.cpu.features"
  run "sysctl -n machdep.cpu.leaf7_features 2>/dev/null || true"
  if [[ "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)" == *"Intel"* ]]; then
    run "sysctl -n machdep.cpu.extfeatures"
  fi

  echo "=== Memory ==="
  run "sysctl -n hw.memsize"
  run "echo \"\$(sysctl -n hw.memsize) / 1024 / 1024 / 1024\" | bc"
  run "sysctl -n hw.pagesize"
  run "vm_stat"

  echo "=== Virtualization ==="
  run "sysctl -n kern.hv_vmm_present"
  run "sysctl -n kern.hv_support" || true  # 1 means supported and zero means not supported
  run "sysctl -n machdep.cpu.features | grep -i vmx" || true 

  echo "=== Hardware Inventory ==="
  run "sysctl hw.model"
  run "system_profiler SPHardwareDataType"

  echo "=== Storage ==="
  run "diskutil list"
  run "df -h"
  run "system_profiler SPStorageDataType | sed -n '1,200p'"

  echo "=== Network ==="
  echo "${HTTP_PROXY:-}"
  run "ifconfig"
  run "networksetup -listallhardwareports"
  run "scutil --get HostName"
  run "scutil --get LocalHostName"
  run "scutil --get ComputerName"
  run "route -n get default"
  run "netstat -rn"
  run "scutil --dns"

  echo "=== Uptime and Load ==="
  run "uptime"
  run "sysctl kern.boottime"
  run "top -l 1 -n 0 | head -n 10"

  echo "=== Security ==="
  run "spctl --status"
  run "csrutil status"
elif [[ "$RUNNER_OS" == "Linux" ]]; then
  set -x
  echo "=== Kernel and OS ==="
  run "uname -a"
  run "cat /etc/os-release"

  echo "=== CPU ==="
  run "nproc"
  arch="$(uname -m || true)"
  run "grep -m1 'model name' /proc/cpuinfo" || true
  run "grep -m1 '^Hardware' /proc/cpuinfo" || true
  run "grep -m1 '^flags' /proc/cpuinfo" || true
  run "lscpu"
  run "lscpu | grep -i 'hypervisor\\|virt' || true"

  echo "=== Memory ==="
  run "grep MemTotal /proc/meminfo"
  run 'awk '\''/MemTotal/ {printf "%.2f\n", $2 / 1024 / 1024}'\'' /proc/meminfo'
  run "free -h"

  echo "=== Virtualization ==="
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

  echo "=== Hardware Inventory ==="
  run "sudo dmidecode -s system-manufacturer"
  run "sudo dmidecode -s system-product-name"
  run "sudo dmidecode -t bios -t system -t processor -t memory | sed -n '1,200p'"
  run "sudo lshw -short"
  run "lspci -nn"
  run "command -v lsusb >/dev/null 2>&1 && lsusb || echo 'lsusb not available'"

  echo "=== Storage ==="
  run "lsblk -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT,FSTYPE"
  run "df -h"

  echo "=== Network ==="
  echo "${HTTP_PROXY:-}"
  run "ip addr show"
  run "ip route"
  run "ip -s link"
  run "ifconfig"

  echo "=== Cgroups ==="
  run "stat -fc %T /sys/fs/cgroup"

  echo "=== Uptime and Load ==="
  run "uptime"
  run "who -b"
  run "top -b -n1 | head -n 10"
  run "cat /proc/loadavg"
  run 'awk '\''{printf "Uptime (seconds): %s\n", $1}'\'' /proc/uptime 2>/dev/null'
elif [[ "$RUNNER_OS" == "Windows" ]]; then
  set -x
  echo "=== Kernel and OS ==="
  run "uname -a"
  run "systeminfo"
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber | Format-List\""

  echo "=== CPU ==="
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions | Format-List\""
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,SocketDesignation,MaxClockSpeed | Format-List\""

  echo "=== Memory ==="
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List\""
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,Capacity,Speed | Format-Table -AutoSize\""

  echo "=== Virtualization ==="
  run "powershell.exe -NoProfile -Command \"Get-ComputerInfo | Select-Object HyperVisorPresent,HyperVRequirementDataExecutionPreventionAvailable,HyperVRequirementSecondLevelAddressTranslation,HyperVRequirementVirtualizationFirmwareEnabled | Format-List\""
  run "powershell.exe -NoProfile -Command \"Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All\""

  echo "=== Hardware Inventory ==="
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,SystemType,TotalPhysicalMemory | Format-List\""
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_BaseBoard | Format-List Manufacturer,Product,SerialNumber\""
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_BIOS | Format-List Manufacturer,SMBIOSBIOSVersion,ReleaseDate\""

  echo "=== Storage ==="
  run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,FileSystem,FreeSpace,Size,VolumeName | Format-Table -AutoSize\""
  run "powershell.exe -NoProfile -Command \"Get-PhysicalDisk | Select FriendlyName,Model,SerialNumber,MediaType,Size,BusType | Format-Table -AutoSize\""
  run "powershell.exe -NoProfile -Command \"Get-Volume | Select-Object DriveLetter,FileSystemLabel,FileSystem,SizeRemaining,Size | Format-Table -AutoSize\""

  echo "=== Network ==="
  echo "${HTTP_PROXY:-}"
  run "cmd.exe /c ipconfig /all"
  run "cmd.exe /c route print"
  run "cmd.exe /c netstat -rn"
  run "powershell.exe -NoProfile -Command \"Get-NetAdapter | Format-Table -AutoSize\""
  run "powershell.exe -NoProfile -Command \"Get-DnsClientServerAddress | Format-Table -AutoSize\""

  echo "=== Uptime and Load ==="
  run "powershell.exe -NoProfile -Command \"(Get-CimInstance Win32_PerfFormattedData_PerfOS_System).SystemUpTime\""
  run "powershell.exe -NoProfile -Command \"(Get-CimInstance win32_operatingsystem).LastBootUpTime\""
  run "powershell.exe -NoProfile -Command \"Get-Counter -Counter \\\"\\\\Processor(_Total)\\\\% Processor Time\\\" -SampleInterval 1 -MaxSamples 1\""

  echo "=== Security ==="
  run "powershell.exe -NoProfile -Command \"Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,BehaviorMonitorEnabled,RealTimeProtectionEnabled | Format-List\""
  run "powershell.exe -NoProfile -Command \"Get-BitLockerVolume | Format-Table -AutoSize\""
else
  echo "Unsupported runner OS: ${RUNNER_OS:-unknown}"
fi
