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

Write-Host "=== Info Block for Windows (FailOnError=$FailOnError) ==="

# === Kernel and OS ===
Write-Group "Kernel and OS"
Run-Command "uname -a"
Run-Command "systeminfo"
Run-Command "Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber | Format-List"
End-Group

# === CPU ===
Write-Group "CPU"
try {
    $cpuCores = Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty NumberOfCores
} catch {
    $cpuCores = 0
}
Write-Host "CPU cores: $cpuCores"
if ($env:GITHUB_OUTPUT) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "cpu_cores=$cpuCores"
}

Run-Command "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled,SecondLevelAddressTranslationExtensions | Format-List"
Run-Command "Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,SocketDesignation,MaxClockSpeed | Format-List"
End-Group

# === Memory ===
Write-Group "Memory"
Run-Command "Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List"

try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $memKb = $osInfo.TotalVisibleMemorySize
    $memGb = [math]::Floor($memKb / 1024 / 1024)
    $memFreeKb = $osInfo.FreePhysicalMemory
    $memFreeMb = [math]::Floor($memFreeKb / 1024)
} catch {
    $memKb = 0
    $memGb = 0
    $memFreeKb = 0
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
Run-Command "Get-ComputerInfo | Select-Object HyperVisorPresent,HyperVRequirementDataExecutionPreventionAvailable,HyperVRequirementSecondLevelAddressTranslation,HyperVRequirementVirtualizationFirmwareEnabled | Format-List"
Run-Command "Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All"
End-Group

# === Hardware Inventory ===
Write-Group "Hardware Inventory"
Run-Command "Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,SystemType,TotalPhysicalMemory | Format-List"
Run-Command "Get-CimInstance Win32_BaseBoard | Format-List Manufacturer,Product,SerialNumber"
Run-Command "Get-CimInstance Win32_BIOS | Format-List Manufacturer,SMBIOSBIOSVersion,ReleaseDate"
End-Group

# === Storage ===
Write-Group "Storage"
Run-Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,FileSystem,FreeSpace,Size,VolumeName | Format-Table -AutoSize"
Run-Command "Get-PhysicalDisk | Select FriendlyName,Model,SerialNumber,MediaType,Size,BusType | Format-Table -AutoSize"
Run-Command "Get-Volume | Select-Object DriveLetter,FileSystemLabel,FileSystem,SizeRemaining,Size | Format-Table -AutoSize"
End-Group

# === Network ===
Write-Group "Network"
if ($env:HTTP_PROXY) {
    Write-Host $env:HTTP_PROXY
}
Run-Command "ipconfig /all"
Run-Command "route print"
Run-Command "netstat -rn"
Run-Command "Get-NetAdapter | Format-Table -AutoSize"
Run-Command "Get-DnsClientServerAddress | Format-Table -AutoSize"
End-Group

# === Uptime ===
Write-Group "Uptime"
Run-Command "(Get-CimInstance Win32_PerfFormattedData_PerfOS_System).SystemUpTime"
Run-Command "(Get-CimInstance win32_operatingsystem).LastBootUpTime"
End-Group

# === Load ===
Write-Group "Load"
Run-Command "Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1"

try {
    $loadAvg = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
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
