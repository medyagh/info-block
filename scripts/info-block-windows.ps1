param (
    [string]$FailOnError = "false"
)

$ErrorActionPreference = "Continue"
if ($FailOnError -eq "true") {
    $ErrorActionPreference = "Stop"
}

function Run-Command {
    param (
        [string]$Command
    )
    Write-Host "+ $Command"
    try {
        Invoke-Expression $Command
    }
    catch {
        if ($FailOnError -eq "true") {
            throw $_
        }
        Write-Error $_
    }
}

function Write-Group {
    param ([string]$Name)
    Write-Host "::group::=== $Name ==="
}

function End-Group {
    Write-Host "::endgroup::"
}

# --- Cache Common Objects ---
try {
    $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
} catch {}

try {
    $csInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
} catch {}

try {
    $procInfo = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue 
    if ($procInfo -is [array]) {
        $procInfoFirst = $procInfo[0]
    } else {
        $procInfoFirst = $procInfo
    }
} catch {}

# --- Start Output ---
Write-Host "=== Info Block for Windows (FailOnError=$FailOnError) ==="

# === Kernel and OS ===
Write-Group "Kernel and OS"
Run-Command "uname -a"
# Removed systeminfo - it's very slow (~2.6s) and redundant with CimInstance calls
if ($osInfo) {
    $osInfo | Select-Object Caption,Version,BuildNumber,OSArchitecture,InstallDate,SystemDirectory | Format-List | Out-Host
} else {
    Run-Command "Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,InstallDate,SystemDirectory | Format-List"
}
End-Group

# === CPU ===
Write-Group "CPU"
$cpuCores = 0
if ($procInfoFirst) {
    if ($procInfoFirst.NumberOfCores) {
        $cpuCores = $procInfoFirst.NumberOfCores
    }
}

Write-Host "CPU cores: $cpuCores"
if ($env:GITHUB_OUTPUT) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "cpu_cores=$cpuCores"
}

if ($procInfo) {
    $procInfo | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions | Format-List | Out-Host
    $procInfo | Select-Object Name,Manufacturer,SocketDesignation,MaxClockSpeed | Format-List | Out-Host
} else {
    Run-Command "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions | Format-List"
    Run-Command "Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,SocketDesignation,MaxClockSpeed | Format-List"
}
End-Group

# === Memory ===
Write-Group "Memory"
if ($osInfo) {
    $osInfo | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List | Out-Host
    $memKb = $osInfo.TotalVisibleMemorySize
    $memFreeKb = $osInfo.FreePhysicalMemory
} else {
    # Fallback if cached object failed (unlikely)
    Run-Command "Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List"
    $memKb = 0
    $memFreeKb = 0
}

if (-not $memKb) { $memKb = 0 }
if (-not $memFreeKb) { $memFreeKb = 0 }

try {
    $memGb = [math]::Floor($memKb / 1024 / 1024)
    $memFreeMb = [math]::Floor($memFreeKb / 1024)
} catch {
    $memGb = 0
    $memFreeMb = 0
}

Write-Host "TotalVisibleMemorySize (kB): $memKb"
Write-Host "TotalVisibleMemorySize (GB): $memGb"
Write-Host "FreePhysicalMemory (kB): $memFreeKb"
Write-Host "FreePhysicalMemory (MB): $memFreeMb"

if ($env:GITHUB_OUTPUT) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "memory_gb=$memGb"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "free_mem=$memFreeMb"
}

Run-Command "Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer,PartNumber,Capacity,Speed | Format-Table -AutoSize"
End-Group

# === Virtualization ===
Write-Group "Virtualization"
# Use cached CIM objects instead of slow Get-ComputerInfo (~2.5s)
$virtProps = [ordered]@{}
if ($csInfo) {
    $virtProps["HyperVisorPresent"] = $csInfo.HypervisorPresent
}
if ($procInfoFirst) {
    if ($null -ne $procInfoFirst.VirtualizationFirmwareEnabled) {
        $virtProps["VirtualizationFirmwareEnabled"] = $procInfoFirst.VirtualizationFirmwareEnabled
    }
    if ($null -ne $procInfoFirst.SecondLevelAddressTranslationExtensions) {
        $virtProps["SecondLevelAddressTranslationExtensions"] = $procInfoFirst.SecondLevelAddressTranslationExtensions
    }
}

if ($virtProps.Count -gt 0) {
    $virtProps | Format-List | Out-Host
} else {
    Write-Host "Could not retrieve Virtualization details."
}

# Removed Get-WindowsOptionalFeature - slow and not critical for info display
End-Group

# === Hardware Inventory ===
Write-Group "Hardware Inventory"
if ($csInfo) {
    $csInfo | Select-Object Manufacturer,Model,SystemType,TotalPhysicalMemory | Format-List | Out-Host
} else {
    Run-Command "Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,SystemType,TotalPhysicalMemory | Format-List"
}

Run-Command "Get-CimInstance Win32_BaseBoard | Format-List Manufacturer,Product,SerialNumber"
Run-Command "Get-CimInstance Win32_BIOS | Format-List Manufacturer,SMBIOSBIOSVersion,ReleaseDate"
End-Group

# === Storage ===
Write-Group "Storage"
Run-Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,FileSystem,FreeSpace,Size,VolumeName | Format-Table -AutoSize"
# Removed Get-PhysicalDisk (~2.5s) and Get-Volume (~1.4s) - they are slow and not critical
# Win32_LogicalDisk already provides key storage info
End-Group

# === Network ===
Write-Group "Network"
if ($env:HTTP_PROXY) {
    Write-Host $env:HTTP_PROXY
}
Run-Command "ipconfig /all"
# Removed slow route print and netstat -rn commands - not critical for basic info
Run-Command "Get-NetAdapter | Format-Table -AutoSize"
Run-Command "Get-DnsClientServerAddress | Format-Table -AutoSize"
End-Group

# === Uptime ===
Write-Group "Uptime"
# Use cached objects if available? Win32_PerfFormattedData_PerfOS_System changes often, so don't cache.
Run-Command "(Get-CimInstance Win32_PerfFormattedData_PerfOS_System).SystemUpTime"
if ($osInfo) {
    Write-Host $osInfo.LastBootUpTime
} else {
    Run-Command "(Get-CimInstance win32_operatingsystem).LastBootUpTime"
}
End-Group

# === Load ===
Write-Group "Load"
# Removed Get-Counter with 1 second sample interval - too slow for info gathering

try {
    # Use cached CimInstance for current load
    if ($procInfo) {
        $loadInfo = $procInfo | Measure-Object -Property LoadPercentage -Average
        $loadAvg = $loadInfo.Average
    } else {
        $loadInfo = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $loadAvg = $loadInfo.Average
    }
} catch {
    $loadAvg = "unknown"
}

Write-Host "CPU Load Percentage (current): $loadAvg"
if ($env:GITHUB_OUTPUT) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "load_average=$loadAvg"
}
End-Group

# === Security ===
Write-Group "Security"
Run-Command "Get-MpComputerStatus | Select-Object AMServiceEnabled,AntivirusEnabled,BehaviorMonitorEnabled,RealTimeProtectionEnabled | Format-List"
Run-Command "Get-BitLockerVolume | Format-Table -AutoSize"
End-Group

# === Processes ===
Write-Group "Processes"
try {
    $processList = Get-Process | Sort-Object Id | Select-Object Id,ProcessName,Path | ConvertTo-Csv -NoTypeInformation | Out-String
    # Trim output
    $processList = $processList.Trim()
    
    Write-Host $processList
    
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "procs<<EOF"
        Add-Content -Path $env:GITHUB_OUTPUT -Value $processList
        Add-Content -Path $env:GITHUB_OUTPUT -Value "EOF"
    }
} catch {
    Write-Error "Failed to get process list"
}
End-Group
