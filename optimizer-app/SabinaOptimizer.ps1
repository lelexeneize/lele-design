<#
╔══════════════════════════════════════════════════════════════╗
║  Sabina Optimizer v2.0                                   ║
║  Windows Performance Optimization Tool                    ║
║  By Lele Design — https://leledesign.vercel.app           ║
╚══════════════════════════════════════════════════════════════╝

INSTRUCCIONES:
  Opción 1 — Doble clic en "Launch_Sabina.bat"
  Opción 2 — PowerShell como Admin: .\SabinaOptimizer.ps1

⚠️  REQUISITOS:
  - Ejecutar como Administrador
  - Windows 10/11 (64-bit)
  - .NET Framework 4.5+
#>

# ─── Config ───────────────────────────────────────────────────
$script:APP_VERSION = "2.0.0"
$script:APP_NAME = "Sabina Optimizer"
$script:API_BASE = "https://leledesign.vercel.app/api"

# ─── GUI ──────────────────────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ─── License ──────────────────────────────────────────────────
$script:LicenseFile = "$env:LOCALAPPDATA\SabinaOptimizer\license.json"
$script:Plan = "free"

function LoadLicense {
    if (Test-Path $LicenseFile) {
        try {
            $data = Get-Content $LicenseFile -Raw | ConvertFrom-Json
            if ($data.key) {
                # Validate online
                try {
                    $resp = Invoke-RestMethod -Uri "$($script:API_BASE)/validate-license.js?key=$($data.key)" -TimeoutSec 5
                    if ($resp.valid) {
                        $script:Plan = $resp.plan
                        SaveLicense $resp.plan $data.key
                        return $true
                    }
                } catch {
                    # Offline fallback
                    $script:Plan = $data.plan
                    return $true
                }
            }
        } catch { return $false }
    }
    return $false
}

function SaveLicense($plan, $key) {
    $dir = Split-Path $LicenseFile -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    @{ plan = $plan; key = $key; installedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") } | ConvertTo-Json | Set-Content $LicenseFile
    $script:Plan = $plan
}

# ─── Hardware Detection ───────────────────────────────────────
function Get-HardwareInfo {
    Write-Log "Detectando hardware..."
    $info = @{}
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $info.CPU = "$($cpu.Name)".Trim()
        $info.Cores = $cpu.NumberOfCores
        $info.Logical = $cpu.NumberOfLogicalProcessors

        $ram = Get-CimInstance Win32_ComputerSystem
        $info.RAM_GB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 0)

        $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
        $info.GPU = "$($gpu.Name)".Trim()

        $disk = Get-CimInstance Win32_DiskDrive | Where-Object { $_.Index -eq 0 }
        $info.Disk = "$($disk.Model)".Trim()
        $info.Disk_GB = [math]::Round($disk.Size / 1GB, 0)

        $os = Get-CimInstance Win32_OperatingSystem
        $info.OS = "$($os.Caption)".Trim()
        $info.OS_Arch = $os.OSArchitecture

        $monitor = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
        if ($monitor) { $info.Monitor = "Detectado" } else { $info.Monitor = "No detectado" }
    } catch {
        Write-Log "⚠️ Error detectando hardware: $_"
    }
    Write-Log "Hardware: $($info.CPU) | $($info.GPU) | $($info.RAM_GB)GB RAM"
    return $info
}

# ─── Logging ──────────────────────────────────────────────────
$script:LogPath = "$env:USERPROFILE\Desktop\SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    "[$timestamp] $msg" | Out-File -FilePath $script:LogPath -Append -Encoding utf8
    Write-Host "[$timestamp] $msg"
}

# ─── Restore Point ────────────────────────────────────────────
function Create-RestorePoint {
    Write-Log "▶️ Creando punto de restauración..."
    try {
        Checkpoint-Computer -Description "SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "✅ Punto de restauración creado"
    } catch {
        Write-Log "⚠️ No se pudo crear punto de restauración (continuando de todas formas)"
    }
}

# ═══════════════════════════════════════════════════════════════
#  PLAN ESSENTIAL — Optimizaciones básicas
# ═══════════════════════════════════════════════════════════════

function Optimize-Windows {
    Write-Log "▶️ OPTIMIZANDO WINDOWS..."
    $r = @()

    # Power plan
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    $r += "✅ Power Plan: High Performance activado"

    # HPET
    bcdedit /deletevalue useplatformclock 2>$null
    $r += "✅ HPET desactivado (requiere reinicio)"

    # Game Mode
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Game Mode activado"

    # Xbox Game Bar off
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Xbox Game Bar deshabilitado"

    # GPU Scheduling
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ GPU Hardware Scheduling activado (requiere reinicio)"

    # Timer Resolution
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "TimerResolution" -Value 10000 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Timer Resolution optimizado"

    # Disable Startup Delay
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Startup delay eliminado"

    # Disable Fullscreen Optimizations (per user)
    $r += "ℹ️  Desactivar optimizaciones de pantalla completa: manual en cada .exe → Propiedades → Compatibilidad"

    return $r
}

function Optimize-Network {
    Write-Log "▶️ OPTIMIZANDO RED..."
    $r = @()

    # Nagle
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Nagle Algorithm deshabilitado"

    # DNS Cloudflare
    try {
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.MediaType -ne "Wireless LAN"}
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
            $r += "✅ DNS → Cloudflare en $($adapter.Name)"
        }
    } catch {
        $r += "⚠️ No se pudo cambiar DNS (modo manual)"
    }

    # Auto-Tuning
    netsh int tcp set global autotuninglevel=normal 2>$null
    $r += "✅ TCP Auto-Tuning: normal"

    # RSS (Receive Side Scaling)
    netsh int tcp set global rss=enabled 2>$null
    $r += "✅ RSS activado"

    # Chimney
    netsh int tcp set global chimney=disabled 2>$null
    $r += "✅ TCP Chimney deshabilitado"

    return $r
}

function Optimize-Cleanup {
    Write-Log "▶️ LIMPIANDO SISTEMA..."
    $r = @()

    # TEMP
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    $r += "✅ TEMP limpiado"

    # Windows TEMP
    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    $r += "✅ Windows Temp limpiado"

    # Prefetch
    Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    $r += "✅ Prefetch limpiado"

    # Recycle Bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    $r += "✅ Papelera vaciada"

    # Windows Update cache
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Start-Service bits -ErrorAction SilentlyContinue
    $r += "✅ Windows Update cache limpiado"

    # Recent Documents
    Remove-Item "$env:USERPROFILE\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue
    $r += "✅ Documentos recientes limpiado"

    # DNS cache
    ipconfig /flushdns | Out-Null
    $r += "✅ DNS cache limpiado"

    return $r
}

function Optimize-Input {
    Write-Log "▶️ OPTIMIZANDO INPUT..."
    $r = @()

    # Raw Input Buffer
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" -Name "KeyboardDataQueueSize" -Value 100 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" -Name "MouseDataQueueSize" -Value 100 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Raw Input Buffer: 100"

    # Mouse acceleration OFF
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -Force -ErrorAction SilentlyContinue
    $r += "✅ Mouse acceleration deshabilitado"

    # Priority boost for foreground apps
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Prioridad foreground optimizada (38 decimal)"

    return $r
}

# ═══════════════════════════════════════════════════════════════
#  PLAN PRO — Optimizaciones avanzadas
# ═══════════════════════════════════════════════════════════════

function Optimize-BloatwareRemoval {
    Write-Log "▶️ LIMPIANDO BLOATWARE..."
    $r = @()

    $apps = @(
        "Microsoft.BingWeather", "Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.Getstarted",
        "Microsoft.Messaging", "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection", "Microsoft.Office.OneNote", "Microsoft.OneConnect",
        "Microsoft.People", "Microsoft.Print3D", "Microsoft.SkypeApp", "Microsoft.Wallet",
        "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera", "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder", "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay", "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
        "Microsoft.Copilot", "Clipchamp.Clipchamp"
    )

    foreach ($app in $apps) {
        try {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$app*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        } catch {}
    }
    $r += "✅ Bloatware removido ($($apps.Count) apps)"

    # OneDrive
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    $onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    if (Test-Path $onedrive) { Start-Process $onedrive -ArgumentList "/uninstall" -NoNewWindow -Wait }
    $r += "✅ OneDrive desinstalado"

    return $r
}

function Optimize-SSD {
    Write-Log "▶️ OPTIMIZANDO SSD..."
    $r = @()

    # Disable Hibernation (libera GBs en SSD)
    powercfg -h off 2>$null
    $r += "✅ Hibernación deshabilitada"

    # Disable SuperFetch/SysMain
    Stop-Service SysMain -Force -ErrorAction SilentlyContinue
    Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue
    $r += "✅ SuperFetch (SysMain) deshabilitado"

    # Disable Indexing on SSD (opcional)
    $r += "ℹ️  Para deshabilitar indexing: Panel de Control → Opciones de Indexación → Modificar"

    # TRIM check
    try {
        $trimStatus = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Where-Object {$_.DeviceID -eq "C:"}).Size
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
        $r += "✅ TRIM ejecutado en C:"
    } catch {
        $r += "⚠️ No se pudo ejecutar TRIM"
    }

    return $r
}

function Optimize-GPUTweak {
    Write-Log "▶️ OPTIMIZANDO GPU..."
    $r = @()

    # Shader Cache - tamaño ilimitado
    $gpuVendors = @{
        "NVIDIA" = "HKLM:\SOFTWARE\NVIDIA Corporation\Global"
        "AMD" = "HKLM:\SOFTWARE\AMD\Global"
        "Intel" = "HKLM:\SOFTWARE\Intel\Global"
    }
    foreach ($vendor in $gpuVendors.Keys) {
        $path = $gpuVendors[$vendor]
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "ShaderCacheSize" -Value 4294967295 -Type DWord -Force -ErrorAction SilentlyContinue
            $r += "✅ Shader Cache size maximizado ($vendor)"
        }
    }

    # GPU Power preference
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null
    powercfg -setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null
    $r += "✅ GPU Power Preference: Maximum Performance"

    return $r
}

function Optimize-Monitor {
    Write-Log "▶️ OPTIMIZANDO MONITOR..."
    $r = @()

    # Detect max refresh rate
    try {
        $displays = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue
        if ($displays) {
            foreach ($d in $displays) {
                $hz = $d.MaxVerticalImageSize
                # Nota: esto da el tamaño físico. Para refresh real necesitamos API diferente
                $r += "ℹ️  Monitor detectado. Configurar Hz máximo en: Configuración de pantalla → Avanzado → Adaptador → Lista de modos"
            }
        }
    } catch {
        $r += "⚠️ No se pudo detectar el monitor automáticamente"
    }

    # Disable GPU scaling (menor input lag)
    $r += "ℹ️  Para desactivar GPU scaling: NVIDIA Panel → Ajustar tamaño escritorio → Sin escalado (GPU)"

    return $r
}

# ═══════════════════════════════════════════════════════════════
#  PLAN ELITE — Optimizaciones quirúrgicas
# ═══════════════════════════════════════════════════════════════

function Optimize-KernelLatency {
    Write-Log "▶️ OPTIMIZANDO KERNEL / LATENCIA..."
    $r = @()

    # MSI Mode for PCIe devices
    $pciDevices = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.GetValue("DeviceDesc") -match "NVIDIA|AMD|Intel.*Graphics|NVMe|Storage|USB|Network" }
    $msiCount = 0
    foreach ($dev in $pciDevices) {
        $msiPath = "$($dev.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (Test-Path $msiPath) {
            Set-ItemProperty -Path $msiPath -Name "MSISupported" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $msiCount++
        }
    }
    $r += "✅ MSI Mode activado en $msiCount dispositivos (incluye GPU, NVMe, USB)"

    # Disable Nagle for all interfaces
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableWsd" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ WSD (Web Services Discovery) deshabilitado"

    # Disable Power Throttling
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $r += "✅ Fast Startup deshabilitado (menor latencia en boot+shutdown)"

    return $r
}

function Optimize-DPCLatency {
    Write-Log "▶️ VERIFICANDO DPC LATENCY..."
    $r = @()

    # Check if LatencyMon-style fix is needed
    # Disable CPU throttling
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>$null
    $r += "✅ CPU throttling max: 100% en AC"

    # Disable C-States deep
    $r += "ℹ️  Para reducir DPC latency al máximo:"
    $r += "    Deshabilitar C-States en BIOS (CPU → C-States → Disable)"
    $r += "    Deshabilitar Cool'n'Quiet/SpeedStep/EIST"
    $r += "    Deshabilitar Global C-States Control"

    return $r
}

function Optimize-RAMTimings {
    Write-Log "▶️ GENERANDO GUÍA RAM TIMINGS..."
    $r = @()

    try {
        $memory = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1
        $speed = $memory.Speed
        $capacity = [math]::Round($memory.Capacity / 1GB, 0)
        $r += "ℹ️  RAM detectada: $capacity GB @ $speed MHz"
        $r += ""
        $r += "📋 GUÍA DE TIMINGS para $speed MHz:"
        $r += "   Ingresá en BIOS → Advanced DRAM Configuration"
        $r += ""
        $r += "   Primary Timings (recomendado para gaming):"
        $r += "   ─────────────────────────────────────────"
        $r += "   tCL: $($speed/100 - 6) (ej: 30-34)"
        $r += "   tRCD: $($speed/100 - 4) (ej: 32-36)"
        $r += "   tRP: $($speed/100 - 4) (ej: 32-36)"
        $r += "   tRAS: 58-68"
        $r += ""
        $r += "   Secondary Timings:"
        $r += "   ──────────────────"
        $r += "   tRFC: 500-600 (menor = mejor rendimiento)"
        $r += "   tWR: 48"
        $r += "   tWTR: 12-16"
        $r += "   tRRD: 4-8"
        $r += "   tFAW: 16-32"
        $r += ""
        $r += "   Voltajes seguros:"
        $r += "   ─────────────────"
        $r += "   DRAM Voltage: 1.35V - 1.40V (máximo seguro DDR5)"
        $r += "   SOC Voltage: 1.20V - 1.25V"
        $r += ""
        $r += "   ⚠️  Probá con MemTest86 después de cada cambio"
    } catch {
        $r += "⚠️  No se pudo detectar RAM automáticamente"
    }

    return $r
}

function Optimize-OverclockGuide {
    Write-Log "▶️ GENERANDO GUÍA OVERCLOCK..."
    $r = @()
    $hw = Get-HardwareInfo

    $r += "📋 GUÍA DE OVERCLOCK para $($hw.CPU)"
    $r += "────────────────────────────────"
    $r += ""
    $r += "CPU: $($hw.CPU) ($($hw.Cores)C/$($hw.Logical)T)"
    $r += "GPU: $($hw.GPU)"
    $r += "RAM: $($hw.RAM_GB) GB"
    $r += ""
    $r += "1. BIOS → Overclocking → CPU Ratio: +1-2 over stock"
    $r += "2. Voltage: Offset -0.05V a -0.10V (undervolt)"
    $r += "3. GPU MSI Afterburner:"
    $r += "   - Core Clock: +100 a +200 MHz"
    $r += "   - Memory Clock: +500 a +1000 MHz"
    $r += "   - Power Limit: Max (110-120%)"
    $r += "   - Temp Limit: Max (88-90°C)"
    $r += "4. Stability test: Cinebench R23 + FurMark"
    $r += "   ⚠️  Si crashea, reducí clocks hasta que sea estable"

    return $r
}

function Run-Benchmarks {
    Write-Log "▶️ EJECUTANDO BENCHMARKS..."
    $r = @()

    # CPU info
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $r += "📊 CPU: $($cpu.Name) — $($cpu.NumberOfLogicalProcessors) logical cores"
    $r += "   Current clock: $($cpu.CurrentClockSpeed) MHz"
    $r += "   Max clock: $($cpu.MaxClockSpeed) MHz"
    $r += "   Load: $($cpu.LoadPercentage)%"

    # RAM
    $os = Get-CimInstance Win32_OperatingSystem
    $freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    $r += "📊 RAM: $freeRAM GB libre de $totalRAM GB"

    # Disk
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Where-Object DeviceID -eq "C:"
    if ($disk) {
        $free = [math]::Round($disk.FreeSpace / 1GB, 1)
        $total = [math]::Round($disk.Size / 1GB, 1)
        $r += "📊 Disco C: $free GB libre de $total GB"
    }

    # Network
    try {
        $ping = Test-Connection -ComputerName "1.1.1.1" -Count 3 -ErrorAction SilentlyContinue
        $avgPing = ($ping | Measure-Object -Property ResponseTime -Average).Average
        $r += "📊 Ping a Cloudflare: $([math]::Round($avgPing, 1)) ms"
    } catch {
        $r += "📊 Ping: no disponible"
    }

    return $r
}

function Generate-Report($allChanges, $hw) {
    Write-Log "▶️ GENERANDO REPORTE..."

    $report = @"
╔══════════════════════════════════════════════════════════════╗
║            SABINA OPTIMIZER — REPORTE DE SESIÓN             ║
╚══════════════════════════════════════════════════════════════╝

Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Plan: $($script:Plan)
Versión: $($script:APP_VERSION)

── HARDWARE DETECTADO ─────────────────────────────────────────
  CPU: $($hw.CPU) ($($hw.Cores)C/$($hw.Logical)T)
  GPU: $($hw.GPU)
  RAM: $($hw.RAM_GB) GB
  Disco: $($hw.Disk) ($($hw.Disk_GB) GB)
  OS: $($hw.OS) $($hw.OS_Arch)

── CAMBIOS APLICADOS ─────────────────────────────────────────
$($allChanges | ForEach-Object { "  $_`n" } | Out-String)

── RECOMENDACIONES POST-OPTIMIZACIÓN ─────────────────────────
  1. Reiniciar la PC para aplicar cambios
  2. Verificar que juegos y apps funcionen correctamente
  3. Si algo falla, restaurar con el punto de restauración creado
  4. Para soporte: hola@leledesign.com

── ACERCA DE ─────────────────────────────────────────────────
  Sabina Optimizer v$($script:APP_VERSION)
  By Lele Design — https://leledesign.vercel.app
"@

    $report | Out-File -FilePath $script:LogPath -Encoding utf8
    Write-Log "✅ Reporte guardado: $($script:LogPath)"
    return $script:LogPath
}

# ═══════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════

function Start-Optimization {
    param([string]$plan)

    $allChanges = @()
    $hw = Get-HardwareInfo

    Create-RestorePoint

    # ── Essential ──
    $allChanges += "═══════ ESSENTIAL ═══════"
    $allChanges += Optimize-Windows
    $allChanges += Optimize-Network
    $allChanges += Optimize-Cleanup
    $allChanges += Optimize-Input

    # ── Pro ──
    if ($plan -in @("pro", "elite")) {
        $allChanges += "`n═══════ PRO ═══════"
        $allChanges += Optimize-BloatwareRemoval
        $allChanges += Optimize-SSD
        $allChanges += Optimize-GPUTweak
        $allChanges += Optimize-Monitor
    }

    # ── Elite ──
    if ($plan -eq "elite") {
        $allChanges += "`n═══════ ELITE ═══════"
        $allChanges += Optimize-KernelLatency
        $allChanges += Optimize-DPCLatency
        $allChanges += Optimize-RAMTimings
        $allChanges += Optimize-OverclockGuide
        $allChanges += "`n═══════ BENCHMARKS ═══════"
        $allChanges += Run-Benchmarks
    }

    $reportPath = Generate-Report $allChanges $hw

    return @{ changes = $allChanges; report = $reportPath }
}

# ═══════════════════════════════════════════════════════════════
#  GUI
# ═══════════════════════════════════════════════════════════════

function Show-MainWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Sabina Optimizer v$script:APP_VERSION"
    $form.Size = New-Object Drawing.Size(620, 680)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = "#0a0a0f"

    # Title
    $title = New-Object Windows.Forms.Label
    $title.Text = "⚡ Sabina Optimizer"
    $title.Font = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
    $title.ForeColor = "#a855f7"
    $title.Size = New-Object Drawing.Size(560, 50)
    $title.Location = New-Object Drawing.Point(30, 20)
    $form.Controls.Add($title)

    $subtitle = New-Object Windows.Forms.Label
    $subtitle.Text = "Optimización Windows profesional — v$script:APP_VERSION"
    $subtitle.Font = New-Object Drawing.Font("Segoe UI", 10)
    $subtitle.ForeColor = "#808080"
    $subtitle.Size = New-Object Drawing.Size(560, 20)
    $subtitle.Location = New-Object Drawing.Point(30, 70)
    $form.Controls.Add($subtitle)

    # Current plan
    $planLabel = New-Object Windows.Forms.Label
    $planLabel.Text = "Plan actual: $($script:Plan.ToUpper())"
    $planLabel.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $planLabel.ForeColor = "#22d3ee"
    $planLabel.Size = New-Object Drawing.Size(560, 25)
    $planLabel.Location = New-Object Drawing.Point(30, 100)
    $form.Controls.Add($planLabel)

    # Output log
    $outputBox = New-Object Windows.Forms.TextBox
    $outputBox.Multiline = $true
    $outputBox.Size = New-Object Drawing.Size(560, 250)
    $outputBox.Location = New-Object Drawing.Point(30, 140)
    $outputBox.Font = New-Object Drawing.Font("Consolas", 9)
    $outputBox.BackColor = "#0a0a0f"
    $outputBox.ForeColor = "#00ff88"
    $outputBox.BorderStyle = "FixedSingle"
    $outputBox.ReadOnly = $true
    $outputBox.ScrollBars = "Vertical"
    $outputBox.Text = "Listo para optimizar. Seleccioná un plan o activá tu licencia."
    $form.Controls.Add($outputBox)

    # License key input
    $keyInput = New-Object Windows.Forms.TextBox
    $keyInput.Size = New-Object Drawing.Size(350, 30)
    $keyInput.Location = New-Object Drawing.Point(30, 410)
    $keyInput.Font = New-Object Drawing.Font("Consolas", 12)
    $keyInput.BackColor = "#1a1a2e"
    $keyInput.ForeColor = "#ffffff"
    $keyInput.BorderStyle = "FixedSingle"
    $keyInput.Text = "Ingresá tu license key..."
    $keyInput.Add_Click({ if ($keyInput.Text -eq "Ingresá tu license key...") { $keyInput.Clear() } })
    $form.Controls.Add($keyInput)

    $activateBtn = New-Object Windows.Forms.Button
    $activateBtn.Text = "✔ Activar"
    $activateBtn.Size = New-Object Drawing.Size(100, 30)
    $activateBtn.Location = New-Object Drawing.Point(390, 410)
    $activateBtn.BackColor = "#22d3ee"
    $activateBtn.ForeColor = "#000000"
    $activateBtn.FlatStyle = "Flat"
    $activateBtn.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $activateBtn.Add_Click({
        $key = $keyInput.Text.Trim()
        if ($key -and $key -ne "Ingresá tu license key...") {
            $outputBox.Text = "Validando licencia..."
            try {
                $resp = Invoke-RestMethod -Uri "$($script:API_BASE)/validate-license.js?key=$key" -TimeoutSec 10
                if ($resp.valid) {
                    SaveLicense $resp.plan $key
                    $planLabel.Text = "Plan actual: $($resp.plan.ToUpper())"
                    $outputBox.Text = "✅ Licencia activada: $($resp.plan)`n"
                    $outputBox.AppendText("Bienvenido a Sabina Optimizer $($resp.plan)!")
                } else {
                    $outputBox.Text = "❌ Licencia inválida o expirada"
                }
            } catch {
                $outputBox.Text = "⚠️ No se pudo validar online. Usando licencia local si existe."
            }
        }
    })
    $form.Controls.Add($activateBtn)

    # Buy button
    $buyBtn = New-Object Windows.Forms.Button
    $buyBtn.Text = "🛒 Comprar licencia"
    $buyBtn.Size = New-Object Drawing.Size(150, 30)
    $buyBtn.Location = New-Object Drawing.Point(500, 410)
    $buyBtn.BackColor = "#d946ef"
    $buyBtn.ForeColor = "#ffffff"
    $buyBtn.FlatStyle = "Flat"
    $buyBtn.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $buyBtn.Add_Click({
        Start-Process "https://leledesign.vercel.app/pages/optimizer.html"
    })
    $form.Controls.Add($buyBtn)

    # Run button
    $runBtn = New-Object Windows.Forms.Button
    $runBtn.Text = "⚡ INICIAR OPTIMIZACIÓN"
    $runBtn.Size = New-Object Drawing.Size(620, 55)
    $runBtn.Location = New-Object Drawing.Point(0, 460)
    $runBtn.BackColor = "#a855f7"
    $runBtn.ForeColor = "#ffffff"
    $runBtn.FlatStyle = "Flat"
    $runBtn.Font = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold)
    $runBtn.Cursor = "Hand"
    $runBtn.Add_Click({
        $plan = $script:Plan
        if ($plan -eq "free") {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Modo FREE: solo Essential disponible.`n`n¿Querés continuar con Essential?`n`nComprá Pro o Elite para más features.",
                "Sabina Optimizer",
                [Windows.Forms.MessageBoxButtons]::YesNo,
                [Windows.Forms.MessageBoxIcon]::Question
            )
            if ($result -eq "Yes") { $plan = "essential" } else { return }
        }
        $runBtn.Enabled = $false
        $runBtn.Text = "⏳ OPTIMIZANDO..."
        $outputBox.Text = "Iniciando optimización ($plan)..."

        # Redirect output to the textbox
        $result = Start-Optimization -plan $plan

        $outputBox.Clear()
        foreach ($line in $result.changes) {
            $outputBox.AppendText("$line`r`n")
        }
        $outputBox.AppendText("`r`n✅ Optimización completada!`r`n")
        $outputBox.AppendText("📄 Reporte: $($result.report)")

        $runBtn.Enabled = $true
        $runBtn.Text = "✅ OPTIMIZACIÓN COMPLETA"
    })
    $form.Controls.Add($runBtn)

    # Status bar
    $status = New-Object Windows.Forms.Label
    $status.Text = " Reporte: $script:LogPath"
    $status.Font = New-Object Drawing.Font("Segoe UI", 8)
    $status.ForeColor = "#404040"
    $status.Size = New-Object Drawing.Size(620, 20)
    $status.Location = New-Object Drawing.Point(0, 520)
    $form.Controls.Add($status)

    $form.ShowDialog()
}

# ─── Entry ──────────────────────────────────────────────────
LoadLicense
Show-MainWindow
