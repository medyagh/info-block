#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/common.sh" "${FAIL_ON_ERROR}"

echo "::group::=== Kernel and OS ==="
run "uname -a"
run "systeminfo"
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber | Format-List\""
echo "::endgroup::"

echo "::group::=== CPU ==="
cpu_cores=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty NumberOfCores)" 2>/dev/null | tr -d $'\r' || true)
cpu_cores=${cpu_cores:-0}
echo "CPU cores: ${cpu_cores}"
echo "cpu_cores=${cpu_cores}" >> "$GITHUB_OUTPUT"
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions | Format-List\""
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,SocketDesignation,MaxClockSpeed | Format-List\""
echo "::endgroup::"

echo "::group::=== Memory ==="
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List\""
mem_kb=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize" 2>/dev/null | tr -d $'\r' || true)
mem_kb=${mem_kb:-0}
mem_gb=$((mem_kb / 1024 / 1024))
mem_free_kb=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory" 2>/dev/null | tr -d $'\r' || true)
mem_free_kb=${mem_free_kb:-0}
mem_free_gb=$((mem_free_kb / 1024 / 1024))
echo "TotalVisibleMemorySize (kB): ${mem_kb}"
echo "TotalVisibleMemorySize (GB): ${mem_gb}"
echo "FreePhysicalMemory (kB): ${mem_free_kb}"
echo "FreePhysicalMemory (GB): ${mem_free_gb}"
echo "memory_gb=${mem_gb}" >> "$GITHUB_OUTPUT"
echo "free_mem=${mem_free_gb}" >> "$GITHUB_OUTPUT"
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,Capacity,Speed | Format-Table -AutoSize\""
echo "::endgroup::"

echo "::group::=== Virtualization ==="
run "powershell.exe -NoProfile -Command \"Get-ComputerInfo | Select-Object HyperVisorPresent,HyperVRequirementDataExecutionPreventionAvailable,HyperVRequirementSecondLevelAddressTranslation,HyperVRequirementVirtualizationFirmwareEnabled | Format-List\""
run "powershell.exe -NoProfile -Command \"Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All\""
echo "::endgroup::"

echo "::group::=== Hardware Inventory ==="
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,SystemType,TotalPhysicalMemory | Format-List\""
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_BaseBoard | Format-List Manufacturer,Product,SerialNumber\""
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_BIOS | Format-List Manufacturer,SMBIOSBIOSVersion,ReleaseDate\""
echo "::endgroup::"

echo "::group::=== Storage ==="
run "powershell.exe -NoProfile -Command \"Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,FileSystem,FreeSpace,Size,VolumeName | Format-Table -AutoSize\""
run "powershell.exe -NoProfile -Command \"Get-PhysicalDisk | Select FriendlyName,Model,SerialNumber,MediaType,Size,BusType | Format-Table -AutoSize\""
run "powershell.exe -NoProfile -Command \"Get-Volume | Select-Object DriveLetter,FileSystemLabel,FileSystem,SizeRemaining,Size | Format-Table -AutoSize\""
echo "::endgroup::"

echo "::group::=== Network ==="
echo "${HTTP_PROXY:-}"
run "cmd.exe /c ipconfig /all"
run "cmd.exe /c route print"
run "cmd.exe /c netstat -rn"
run "powershell.exe -NoProfile -Command \"Get-NetAdapter | Format-Table -AutoSize\""
run "powershell.exe -NoProfile -Command \"Get-DnsClientServerAddress | Format-Table -AutoSize\""
echo "::endgroup::"

echo "::group::=== Uptime ==="
run "powershell.exe -NoProfile -Command \"(Get-CimInstance Win32_PerfFormattedData_PerfOS_System).SystemUpTime\""
run "powershell.exe -NoProfile -Command \"(Get-CimInstance win32_operatingsystem).LastBootUpTime\""
echo "::endgroup::"

echo "::group::=== Load ==="
run "powershell.exe -NoProfile -Command \"Get-Counter -Counter \\\"\\\\Processor(_Total)\\\\% Processor Time\\\" -SampleInterval 1 -MaxSamples 1\""
load_avg=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average" 2>/dev/null | tr -d '\r' || true)
echo "CPU Load Percentage (current): ${load_avg:-unknown}"
echo "load_average=${load_avg:-unknown}" >> "$GITHUB_OUTPUT"
echo "::endgroup::"

echo "::group::=== Security ==="
run "powershell.exe -NoProfile -Command \"Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,BehaviorMonitorEnabled,RealTimeProtectionEnabled | Format-List\""
run "powershell.exe -NoProfile -Command \"Get-BitLockerVolume | Format-Table -AutoSize\""
echo "::endgroup::"
