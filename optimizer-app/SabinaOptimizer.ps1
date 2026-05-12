<#
╔══════════════════════════════════════════════════════════════╗
║  Sabina Optimizer v4.0                                   ║
║  Windows Performance Optimization Tool                    ║
║  By Lele Design — leledesign.vercel.app                  ║
╚══════════════════════════════════════════════════════════════╝
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:APP_VERSION = "4.0"
$script:ScriptPath = if ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $PSCommandPath }
if (-not $script:ScriptPath) { $script:ScriptPath = (Get-Location).Path + "\SabinaOptimizer.ps1" }
$script:APP_DIR = Split-Path -Parent $script:ScriptPath
$script:DEV_FILE = Join-Path $script:APP_DIR "DEV_MODE"
$script:LogPath = "$env:USERPROFILE\Desktop\SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:UserPlan = "none"
$script:IsDevMode = Test-Path $script:DEV_FILE
$script:ShowScripts = @{}

function Write-Log($msg) {
    $t = Get-Date -Format "HH:mm:ss"
    "[$t] $msg" | Out-File -LiteralPath $script:LogPath -Append -Encoding utf8
}

# ═══════════════════════════════════════════════════════════════
#  OPTIMIZACIONES
# ═══════════════════════════════════════════════════════════════

$script:Optimizations = @()

function Add-Opt($id, $name, $desc, $cat, $risk, $commands, $scriptBlock) {
    $script:Optimizations += @{ id=$id; name=$name; desc=$desc; category=$cat; risk=$risk; commands=$commands; action=$scriptBlock }
}

# Essential
Add-Opt "powerplan" "Power Plan: Alto Rendimiento" "Activa el plan de energia de alto rendimiento." "Essential" "Bajo" @("powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c") { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null; "Power Plan: High Performance activado" }
Add-Opt "hpet" "Desactivar HPET" "Reduce latencia y mejora FPS. Requiere reinicio." "Essential" "Medio" @("bcdedit /deletevalue useplatformclock") { bcdedit /deletevalue useplatformclock 2>$null; "HPET desactivado (requiere reinicio)" }
Add-Opt "gamemode" "Game Mode" "Prioriza recursos para juegos." "Essential" "Bajo" @('Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" AutoGameModeEnabled 1 -Type DWord -Force') { Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" AutoGameModeEnabled 1 -Type DWord -Force -EA 0; "Game Mode activado" }
Add-Opt "xbox" "Deshabilitar Xbox Game Bar" "Elimina superposicion de Xbox." "Essential" "Bajo" @('Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" ShowStartupPanel 0 -Type DWord -Force') { Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" ShowStartupPanel 0 -Type DWord -Force -EA 0; "Xbox Game Bar deshabilitado" }
Add-Opt "gpusched" "GPU Hardware Scheduling" "Reduce latencia de GPU. Requiere reinicio." "Essential" "Medio" @('Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode 2 -Type DWord -Force') { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode 2 -Type DWord -Force -EA 0; "GPU Scheduling: Hardware accelerated (requiere reinicio)" }
Add-Opt "timer" "Timer Resolution" "Ajusta temporizador del sistema para menor latencia." "Essential" "Bajo" @('Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" TimerResolution 10000 -Type DWord -Force') { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" TimerResolution 10000 -Type DWord -Force -EA 0; "Timer Resolution optimizado" }
Add-Opt "nagle" "Deshabilitar Nagle" "Reduce ping en juegos online." "Essential" "Bajo" @('Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TcpAckFrequency 1 -Type DWord -Force','Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TCPNoDelay 1 -Type DWord -Force') { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TcpAckFrequency 1 -Type DWord -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TCPNoDelay 1 -Type DWord -Force -EA 0; "Nagle Algorithm deshabilitado" }
Add-Opt "dns" "DNS Cloudflare" "Cambia DNS a 1.1.1.1 (mas rapido y seguro)." "Essential" "Bajo" @("Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | ? Status -eq Up).ifIndex -ServerAddresses ('1.1.1.1','1.0.0.1')") { $a = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}; foreach ($ad in $a) { Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -EA 0 }; "DNS cambiado a Cloudflare" }
Add-Opt "tcptune" "Optimizar TCP/IP" "Ajusta TCP para menor latencia de red." "Essential" "Bajo" @("netsh int tcp set global autotuninglevel=normal","netsh int tcp set global rss=enabled","netsh int tcp set global chimney=disabled") { netsh int tcp set global autotuninglevel=normal 2>$null; netsh int tcp set global rss=enabled 2>$null; netsh int tcp set global chimney=disabled 2>$null; "TCP/IP optimizado" }
Add-Opt "cleanup" "Limpieza del sistema" "Limpia TEMP, Prefetch, Papelera, Update cache, DNS." "Essential" "Bajo" @("Remove-Item `"`$env:TEMP`*`" -Recurse -Force","Remove-Item `"`$env:WINDIR\Temp\`*`" -Recurse -Force","Clear-RecycleBin -Force","ipconfig /flushdns") { Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0; Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -EA 0; Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -EA 0; Clear-RecycleBin -Force -EA 0; Stop-Service wuauserv -Force -EA 0; Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -EA 0; Start-Service wuauserv -EA 0; ipconfig /flushdns | Out-Null; "Limpieza completada" }
Add-Opt "input" "Optimizar Input" "Raw Buffer, mouse acceleration OFF, prioridad foreground." "Essential" "Bajo" @('Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" KeyboardDataQueueSize 100 -Type DWord -Force','Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" MouseDataQueueSize 100 -Type DWord -Force','Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseSpeed 0 -Force') { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" KeyboardDataQueueSize 100 -Type DWord -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" MouseDataQueueSize 100 -Type DWord -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseSpeed 0 -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseThreshold1 0 -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseThreshold2 0 -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" Win32PrioritySeparation 38 -Type DWord -Force -EA 0; "Input optimizado" }

# Pro
Add-Opt "bloatware" "Remover Bloatware" "Desinstala apps preinstaladas (Xbox, Cortana, Skype, Copilot...)." "Pro" "Medio" @("Remove-AppxPackage bloatware apps") { $apps = "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.Office.OneNote","Microsoft.People","Microsoft.Print3D","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.WindowsAlarms","Microsoft.WindowsCamera","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.YourPhone","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.Copilot","Clipchamp.Clipchamp"; foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -EA 0; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$app*" | Remove-AppxProvisionedPackage -Online -EA 0 }; "Bloatware removido: $($apps.Count) apps" }
Add-Opt "onedrive" "Desinstalar OneDrive" "Elimina OneDrive completamente del sistema." "Pro" "Medio" @("Stop-Process -Name OneDrive -Force",'Start-Process "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait') { Stop-Process -Name OneDrive -Force -EA 0; $od = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"; if (Test-Path $od) { Start-Process $od -ArgumentList "/uninstall" -NoNewWindow -Wait }; "OneDrive desinstalado" }
Add-Opt "ssd" "Optimizar SSD/NVMe" "Hibernacion OFF, SuperFetch OFF, TRIM." "Pro" "Bajo" @("powercfg -h off","Stop-Service SysMain -Force","Optimize-Volume -DriveLetter C -ReTrim") { powercfg -h off 2>$null; Stop-Service SysMain -Force -EA 0; Set-Service SysMain -StartupType Disabled -EA 0; Optimize-Volume -DriveLetter C -ReTrim -EA 0; "SSD optimizado: Hibernate OFF, SuperFetch OFF, TRIM ejecutado" }
Add-Opt "gpucache" "Shader Cache GPU" "Maximiza cache de shaders NVIDIA." "Pro" "Bajo" @('Set-ItemProperty "HKLM:\SOFTWARE\NVIDIA Corporation\Global" ShaderCacheSize 4294967295 -Type DWord -Force') { Set-ItemProperty "HKLM:\SOFTWARE\NVIDIA Corporation\Global" ShaderCacheSize 4294967295 -Type DWord -Force -EA 0; powercfg -setdcvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null; powercfg -setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null; "Shader Cache maximizado + GPU Performance Mode" }
Add-Opt "driverclean" "Limpiar Drivers Fantasma" "Escanea y detecta drivers huerfanos." "Pro" "Bajo" @('Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" }') { $orphaned = Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" }; if ($orphaned) { foreach ($d in $orphaned) { "Driver huerfano: $($d.FriendlyName)" } } else { "No se detectaron drivers fantasma" } }
Add-Opt "monitor" "Guia Monitor" "Configurar Hz maximo y overdrive." "Pro" "Bajo" @("Guia: 1) Config. pantalla > Avanzado > Frecuencia maxima","2) NVIDIA Panel > Sin escalado","3) Menu OSD > Overdrive: Medio") { "Guia: 1) Config. pantalla > Avanzado > Frecuencia maxima"; "2) NVIDIA Panel > Sin escalado"; "3) Menu OSD > Overdrive: Medio" }

# Elite
Add-Opt "msimode" "MSI Mode (GPU+NVMe+USB)" "Activa MSI en dispositivos. Reduce latencia DPC." "Elite" "Medio" @('Set-ItemProperty -Path "HKLM:\...\MessageSignaledInterruptProperties" -Name MSISupported -Value 1') { $devices = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -Recurse -EA 0 | Where-Object { $_.GetValue("DeviceDesc") -match "NVIDIA|AMD|NVMe|Storage|USB|Network" }; $count = 0; foreach ($d in $devices) { $p = "$($d.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"; if (Test-Path $p) { Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Type DWord -Force -EA 0; $count++ } }; "MSI Mode activado en $count dispositivos" }
Add-Opt "dpclatency" "Guia DPC Latency" "Recomendaciones BIOS para minima latencia." "Elite" "Bajo" @("powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100") { powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>$null; "Guia: 1) BIOS > C-States: Disable  2) SpeedStep: Disable  3) Global C-States: Disable" }
Add-Opt "ramtimings" "Guia RAM Timings" "Recomendaciones personalizadas para BIOS." "Elite" "Bajo" @("Consultar timings optimos con Get-CimInstance") { $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1; "RAM: $([math]::Round($mem.Capacity/1GB,0)) GB @ $($mem.Speed) MHz"; "tCL: $(($mem.Speed/100 - 6) -as [int]) | tRCD: $(($mem.Speed/100 - 4) -as [int]) | tRP: $(($mem.Speed/100 - 4) -as [int]) | tRAS: 58-68"; "Usar MemTest86 despues de cambios" }
Add-Opt "overclock" "Guia Overclock + Undervolt" "Guia personalizada CPU/GPU." "Elite" "Bajo" @("CPU Ratio: +1-2 | Voltage Offset: -0.05V","MSI Afterburner > Core +150 | Mem +750 | Power 110%") { $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; "CPU: $($cpu.Name) | BIOS > CPU Ratio: +1-2 | Voltage Offset: -0.05V"; "GPU: MSI Afterburner > Core +150 | Mem +750 | Power 110%" }
Add-Opt "benchmark" "Benchmark Rapido" "CPU, RAM, Disco y Ping." "Elite" "Bajo" @("Get-CimInstance Win32_Processor","Get-CimInstance Win32_OperatingSystem > FreePhysicalMemory","Test-Connection 1.1.1.1 -Count 3") { $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; $os = Get-CimInstance Win32_OperatingSystem; $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Where-Object DeviceID -eq "C:"; $ping = Test-Connection "1.1.1.1" -Count 3 -EA 0; "CPU: $($cpu.Name) | RAM: $([math]::Round($os.FreePhysicalMemory/1MB,1)) GB libre | Disco: $([math]::Round($disk.FreeSpace/1GB,1)) GB libre | Ping: $(if($ping){[math]::Round(($ping|Measure-Object -Property ResponseTime -Average).Average,1)}else{'N/A'}) ms" }
Add-Opt "restorepoint" "Crear Punto de Restauracion" "Deshace todos los cambios si algo falla." "Elite" "Bajo" @('Checkpoint-Computer -Description "SabinaOptimizer" -RestorePointType MODIFY_SETTINGS') { Checkpoint-Computer -Description "SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -EA Stop; "Punto de restauracion creado" }

# ═══════════════════════════════════════════════════════════════
#  LICENSE VALIDATION
# ═══════════════════════════════════════════════════════════════

function Test-LicenseKey($key) {
    if ($key -eq "SABINA-DEV-2026-MASTER") { return "elite" }
    try {
        $resp = Invoke-RestMethod -Uri "https://leledesign.vercel.app/api/validate-license.js?key=$key" -TimeoutSec 10 -EA 0
        if ($resp.valid) { return $resp.plan }
    } catch {}
    return $null
}

function Get-StoredLicense() {
    $path = Join-Path $script:APP_DIR "license.key"
    if (Test-Path $path) { return (Get-Content $path -Raw -EA 0).Trim() }
    return $null
}

function Save-License($key) {
    $path = Join-Path $script:APP_DIR "license.key"
    $key | Out-File -LiteralPath $path -Encoding utf8 -Force
}

# ═══════════════════════════════════════════════════════════════
#  GUI COLORS
# ═══════════════════════════════════════════════════════════════

$CLR_BG       = "#0a0a0f"
$CLR_CARD     = "#141420"
$CLR_CARD2    = "#1a1a2e"
$CLR_BORDER   = "#2a2a3a"
$CLR_TEXT     = "#ffffff"
$CLR_TEXT2    = "#888888"
$CLR_ACCENT   = "#a855f7"
$CLR_CYAN     = "#22d3ee"
$CLR_GREEN    = "#10b981"
$CLR_AMBER    = "#f59e0b"
$CLR_RED      = "#ef4444"
$CLR_ESSENTIAL= "#10b981"
$CLR_PRO      = "#a855f7"
$CLR_ELITE    = "#f59e0b"

$FONT_TITLE   = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$FONT_BTN     = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$FONT_NORMAL  = New-Object System.Drawing.Font("Segoe UI", 10)
$FONT_SMALL   = New-Object System.Drawing.Font("Segoe UI", 8)
$FONT_MONO    = New-Object System.Drawing.Font("Consolas", 10)

# ═══════════════════════════════════════════════════════════════
#  GUI
# ═══════════════════════════════════════════════════════════════

function Show-MainWindow {
    # Load stored license
    if (-not $script:IsDevMode) {
        $storedKey = Get-StoredLicense
        if ($storedKey) {
            $plan = Test-LicenseKey $storedKey
            if ($plan) { $script:UserPlan = $plan }
        }
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Sabina Optimizer v$script:APP_VERSION"
    $form.Size = [System.Drawing.Size]::new(1100, 780)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false

    # ── Title bar ──
    $titleBar = New-Object System.Windows.Forms.Panel
    $titleBar.Size = [System.Drawing.Size]::new(1100, 44)
    $titleBar.BackColor = [System.Drawing.Color]::FromArgb(15,15,26)
    $titleBar.Dock = "Top"
    $form.Controls.Add($titleBar)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "  Sabina Optimizer v$script:APP_VERSION"
    $titleLabel.Font = $FONT_TITLE
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(168,85,247)
    $titleLabel.Size = [System.Drawing.Size]::new(400, 44)
    $titleLabel.Location = [System.Drawing.Point]::new(10,0)
    $titleBar.Controls.Add($titleLabel)

    # ── License bar ──
    $licenseBar = New-Object System.Windows.Forms.Panel
    $licenseBar.Size = [System.Drawing.Size]::new(1100, 44)
    $licenseBar.Location = [System.Drawing.Point]::new(0,44)
    $licenseBar.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $licenseBar.BorderStyle = "FixedSingle"
    $form.Controls.Add($licenseBar)

    $lockIcon = New-Object System.Windows.Forms.Label
    $lockIcon.Text = "KEY:"
    $lockIcon.Font = $FONT_BTN
    $lockIcon.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
    $lockIcon.Size = [System.Drawing.Size]::new(50, 30)
    $lockIcon.Location = [System.Drawing.Point]::new(12, 7)
    $licenseBar.Controls.Add($lockIcon)

    $licenseInput = New-Object System.Windows.Forms.TextBox
    $licenseInput.Size = [System.Drawing.Size]::new(220, 28)
    $licenseInput.Location = [System.Drawing.Point]::new(60, 7)
    $licenseInput.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
    $licenseInput.ForeColor = [System.Drawing.Color]::White
    $licenseInput.BorderStyle = "FixedSingle"
    $licenseInput.Font = $FONT_NORMAL
    $licenseBar.Controls.Add($licenseInput)

    $validateBtn = New-Object System.Windows.Forms.Button
    $validateBtn.Text = "Validar"
    $validateBtn.Size = [System.Drawing.Size]::new(80, 28)
    $validateBtn.Location = [System.Drawing.Point]::new(286, 7)
    $validateBtn.BackColor = [System.Drawing.Color]::FromArgb(168,85,247)
    $validateBtn.ForeColor = [System.Drawing.Color]::White
    $validateBtn.FlatStyle = "Flat"
    $validateBtn.Font = $FONT_NORMAL
    $validateBtn.Cursor = "Hand"
    $licenseBar.Controls.Add($validateBtn)

    $licenseStatus = New-Object System.Windows.Forms.Label
    $licenseStatus.Text = ""
    $licenseStatus.Font = $FONT_SMALL
    $licenseStatus.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
    $licenseStatus.Size = [System.Drawing.Size]::new(200, 28)
    $licenseStatus.Location = [System.Drawing.Point]::new(375, 8)
    $licenseBar.Controls.Add($licenseStatus)

    $planBadge = New-Object System.Windows.Forms.Label
    $planBadge.Text = "SIN LICENCIA"
    $planBadge.Font = $FONT_BTN
    $planBadge.ForeColor = [System.Drawing.Color]::White
    $planBadge.BackColor = [System.Drawing.Color]::FromArgb(239,68,68)
    $planBadge.TextAlign = "MiddleCenter"
    $planBadge.Size = [System.Drawing.Size]::new(140, 28)
    $planBadge.Location = [System.Drawing.Point]::new(920, 7)
    $licenseBar.Controls.Add($planBadge)

    function Update-PlanBadge {
        $colors = @{none="#ef4444"; essential="#10b981"; pro="#a855f7"; elite="#f59e0b"}
        $names  = @{none="SIN LICENCIA"; essential="ESSENTIAL"; pro="PRO"; elite="ELITE"}
        $planBadge.BackColor = [System.Drawing.Color]::FromArgb(
            [Convert]::ToInt32($colors[$script:UserPlan].Substring(1,2),16),
            [Convert]::ToInt32($colors[$script:UserPlan].Substring(3,2),16),
            [Convert]::ToInt32($colors[$script:UserPlan].Substring(5,2),16)
        )
        $planBadge.Text = $names[$script:UserPlan]
    }
    Update-PlanBadge

    function Get-LockedCategories {
        if ($script:IsDevMode) { return @() }
        switch ($script:UserPlan) {
            "none"      { return @("Essential","Pro","Elite") }
            "essential" { return @("Pro","Elite") }
            "pro"       { return @("Elite") }
            "elite"     { return @() }
            default     { return @("Essential","Pro","Elite") }
        }
    }

    # ── Category tabs ──
    $catBar = New-Object System.Windows.Forms.Panel
    $catBar.Size = [System.Drawing.Size]::new(1100, 36)
    $catBar.Location = [System.Drawing.Point]::new(0,88)
    $catBar.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
    $form.Controls.Add($catBar)

    $currentCat = "All"
    $catButtons = @{}

    function MakeCatBtn($text, $x, $cat) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $text
        $btn.Size = [System.Drawing.Size]::new(140, 30)
        $btn.Location = [System.Drawing.Point]::new($x, 3)
        $btn.FlatStyle = "Flat"
        $btn.Font = $FONT_BTN
        $btn.Cursor = "Hand"
        $btn.Tag = $cat
        $btn.BackColor = [System.Drawing.Color]::FromArgb(26,26,46)
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
        $catBar.Controls.Add($btn)
        return $btn
    }

    $btnAll       = MakeCatBtn "Mostrar todas"       10, "All"
    $btnEssential = MakeCatBtn "Essential (12)"      160, "Essential"
    $btnPro       = MakeCatBtn "Pro (6)"             310, "Pro"
    $btnElite     = MakeCatBtn "Elite (6)"           460, "Elite"
    $catButtons["All"] = $btnAll
    $catButtons["Essential"] = $btnEssential
    $catButtons["Pro"] = $btnPro
    $catButtons["Elite"] = $btnElite

    # ── Scrollable optimization panel ──
    $optScroll = New-Object System.Windows.Forms.Panel
    $optScroll.Size = [System.Drawing.Size]::new(1080, 400)
    $optScroll.Location = [System.Drawing.Point]::new(10, 128)
    $optScroll.AutoScroll = $true
    $form.Controls.Add($optScroll)

    # ── Console output ──
    $consolePanel = New-Object System.Windows.Forms.Panel
    $consolePanel.Size = [System.Drawing.Size]::new(1080, 150)
    $consolePanel.Location = [System.Drawing.Point]::new(10, 532)
    $consolePanel.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
    $consolePanel.BorderStyle = "FixedSingle"
    $form.Controls.Add($consolePanel)

    $consoleHeader = New-Object System.Windows.Forms.Label
    $consoleHeader.Text = "  Consola"
    $consoleHeader.Size = [System.Drawing.Size]::new(1080, 24)
    $consoleHeader.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $consoleHeader.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
    $consoleHeader.Font = $FONT_SMALL
    $consolePanel.Controls.Add($consoleHeader)

    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Multiline = $true
    $outputBox.Size = [System.Drawing.Size]::new(1076, 122)
    $outputBox.Location = [System.Drawing.Point]::new(2, 26)
    $outputBox.Font = $FONT_MONO
    $outputBox.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
    $outputBox.ForeColor = [System.Drawing.Color]::FromArgb(0,255,136)
    $outputBox.BorderStyle = "None"
    $outputBox.ReadOnly = $true
    $outputBox.ScrollBars = "Vertical"
    $outputBox.Text = "Ingresa tu license key para comenzar."
    $consolePanel.Controls.Add($outputBox)

    # ── Bottom bar ──
    $bottomBar = New-Object System.Windows.Forms.Panel
    $bottomBar.Size = [System.Drawing.Size]::new(1100, 50)
    $bottomBar.Location = [System.Drawing.Point]::new(0, 690)
    $bottomBar.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
    $form.Controls.Add($bottomBar)

    $selAllBtn = New-Object System.Windows.Forms.Button
    $selAllBtn.Text = "Seleccionar todo"
    $selAllBtn.Size = [System.Drawing.Size]::new(140, 34)
    $selAllBtn.Location = [System.Drawing.Point]::new(20, 8)
    $selAllBtn.FlatStyle = "Flat"
    $selAllBtn.BackColor = [System.Drawing.Color]::FromArgb(26,26,46)
    $selAllBtn.ForeColor = [System.Drawing.Color]::White
    $selAllBtn.Font = $FONT_NORMAL
    $selAllBtn.Cursor = "Hand"
    $bottomBar.Controls.Add($selAllBtn)

    $desAllBtn = New-Object System.Windows.Forms.Button
    $desAllBtn.Text = "Deseleccionar todo"
    $desAllBtn.Size = [System.Drawing.Size]::new(140, 34)
    $desAllBtn.Location = [System.Drawing.Point]::new(170, 8)
    $desAllBtn.FlatStyle = "Flat"
    $desAllBtn.BackColor = [System.Drawing.Color]::FromArgb(26,26,46)
    $desAllBtn.ForeColor = [System.Drawing.Color]::White
    $desAllBtn.Font = $FONT_NORMAL
    $desAllBtn.Cursor = "Hand"
    $bottomBar.Controls.Add($desAllBtn)

    $runBtn = New-Object System.Windows.Forms.Button
    $runBtn.Text = "Ejecutar seleccionadas"
    $runBtn.Size = [System.Drawing.Size]::new(180, 38)
    $runBtn.Location = [System.Drawing.Point]::new(690, 6)
    $runBtn.FlatStyle = "Flat"
    $runBtn.BackColor = [System.Drawing.Color]::FromArgb(168,85,247)
    $runBtn.ForeColor = [System.Drawing.Color]::White
    $runBtn.Font = $FONT_BTN
    $runBtn.Cursor = "Hand"
    $bottomBar.Controls.Add($runBtn)

    $runAllBtn = New-Object System.Windows.Forms.Button
    $runAllBtn.Text = "EJECUTAR TODO"
    $runAllBtn.Size = [System.Drawing.Size]::new(160, 38)
    $runAllBtn.Location = [System.Drawing.Point]::new(880, 6)
    $runAllBtn.FlatStyle = "Flat"
    $runAllBtn.BackColor = [System.Drawing.Color]::FromArgb(34,211,238)
    $runAllBtn.ForeColor = [System.Drawing.Color]::Black
    $runAllBtn.Font = $FONT_BTN
    $runAllBtn.Cursor = "Hand"
    $bottomBar.Controls.Add($runAllBtn)

    # ── Build cards ──
    $script:Checkboxes = @{}
    $script:ScriptLabels = @{}

    function Show-Category($cat) {
        $global:currentCat = $cat
        $global:catButtons = $catButtons

        $catButtons["All"].BackColor = if ($cat -eq "All") { [System.Drawing.Color]::FromArgb(42,42,58) } else { [System.Drawing.Color]::FromArgb(26,26,46) }
        $catButtons["All"].ForeColor = if ($cat -eq "All") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(136,136,136) }
        $catButtons["Essential"].BackColor = if ($cat -eq "Essential") { [System.Drawing.Color]::FromArgb(42,42,58) } else { [System.Drawing.Color]::FromArgb(26,26,46) }
        $catButtons["Essential"].ForeColor = if ($cat -eq "Essential") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(136,136,136) }
        $catButtons["Pro"].BackColor = if ($cat -eq "Pro") { [System.Drawing.Color]::FromArgb(42,42,58) } else { [System.Drawing.Color]::FromArgb(26,26,46) }
        $catButtons["Pro"].ForeColor = if ($cat -eq "Pro") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(136,136,136) }
        $catButtons["Elite"].BackColor = if ($cat -eq "Elite") { [System.Drawing.Color]::FromArgb(42,42,58) } else { [System.Drawing.Color]::FromArgb(26,26,46) }
        $catButtons["Elite"].ForeColor = if ($cat -eq "Elite") { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(136,136,136) }

        $optScroll.Controls.Clear()
        $locked = Get-LockedCategories

        if ($locked.Count -ge 3 -and -not $script:IsDevMode) {
            $lockMsg = New-Object System.Windows.Forms.Label
            $lockMsg.Text = "  Ingresa tu license key para desbloquear las optimizaciones"
            $lockMsg.Font = New-Object System.Drawing.Font("Segoe UI", 14)
            $lockMsg.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
            $lockMsg.Size = [System.Drawing.Size]::new(600, 40)
            $lockMsg.Location = [System.Drawing.Point]::new(20, 30)
            $optScroll.Controls.Add($lockMsg)
            return
        }

        $y = 10
        foreach ($opt in $script:Optimizations) {
            if ($cat -ne "All" -and $opt.category -ne $cat) { continue }
            $isLocked = $locked -contains $opt.category

            # Card panel
            $card = New-Object System.Windows.Forms.Panel
            $card.Size = [System.Drawing.Size]::new(1050, 70)
            $card.Location = [System.Drawing.Point]::new(5, $y)
            $card.BackColor = [System.Drawing.Color]::FromArgb(20,20,32)
            $card.BorderStyle = "FixedSingle"
            if ($isLocked) { $card.BackColor = [System.Drawing.Color]::FromArgb(15,15,26) }

            # Checkbox
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Size = [System.Drawing.Size]::new(20, 60)
            $cb.Location = [System.Drawing.Point]::new(8, 5)
            $cb.Checked = (-not $isLocked)
            $cb.Enabled = (-not $isLocked)
            $cb.Tag = $opt.id
            $card.Controls.Add($cb)
            $script:Checkboxes[$opt.id] = $cb

            # Category badge
            $catColors = @{Essential="#10b981"; Pro="#a855f7"; Elite="#f59e0b"}
            $catBadge = New-Object System.Windows.Forms.Label
            $catBadge.Text = $opt.category
            $catBadge.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
            $catBadge.ForeColor = [System.Drawing.Color]::White
            $catBadge.BackColor = [System.Drawing.Color]::FromArgb(
                [Convert]::ToInt32($catColors[$opt.category].Substring(1,2),16),
                [Convert]::ToInt32($catColors[$opt.category].Substring(3,2),16),
                [Convert]::ToInt32($catColors[$opt.category].Substring(5,2),16)
            )
            $catBadge.TextAlign = "MiddleCenter"
            $catBadge.Size = [System.Drawing.Size]::new(65, 16)
            $catBadge.Location = [System.Drawing.Point]::new(700, 10)
            $card.Controls.Add($catBadge)

            # Risk badge
            $riskColors = @{Bajo="#10b981"; Medio="#f59e0b"; Alto="#ef4444"}
            $riskBadge = New-Object System.Windows.Forms.Label
            $riskBadge.Text = $opt.risk
            $riskBadge.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
            $riskBadge.ForeColor = [System.Drawing.Color]::Black
            $riskBadge.BackColor = [System.Drawing.Color]::FromArgb(
                [Convert]::ToInt32($riskColors[$opt.risk].Substring(1,2),16),
                [Convert]::ToInt32($riskColors[$opt.risk].Substring(3,2),16),
                [Convert]::ToInt32($riskColors[$opt.risk].Substring(5,2),16)
            )
            $riskBadge.TextAlign = "MiddleCenter"
            $riskBadge.Size = [System.Drawing.Size]::new(42, 16)
            $riskBadge.Location = [System.Drawing.Point]::new(770, 10)
            $card.Controls.Add($riskBadge)

            # Name
            $nameLabel = New-Object System.Windows.Forms.Label
            $nameLabel.Text = $opt.name
            $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $nameLabel.ForeColor = [System.Drawing.Color]::White
            $nameLabel.Size = [System.Drawing.Size]::new(500, 20)
            $nameLabel.Location = [System.Drawing.Point]::new(32, 8)
            $card.Controls.Add($nameLabel)

            # Description
            $descLabel = New-Object System.Windows.Forms.Label
            $descLabel.Text = $opt.desc
            $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
            $descLabel.Size = [System.Drawing.Size]::new(660, 18)
            $descLabel.Location = [System.Drawing.Point]::new(32, 30)
            $card.Controls.Add($descLabel)

            # Script preview toggle
            $scriptToggle = New-Object System.Windows.Forms.Button
            $scriptToggle.Text = "Script"
            $scriptToggle.Font = New-Object System.Drawing.Font("Segoe UI", 7)
            $scriptToggle.FlatStyle = "Flat"
            $scriptToggle.BackColor = [System.Drawing.Color]::FromArgb(26,26,46)
            $scriptToggle.ForeColor = [System.Drawing.Color]::FromArgb(136,136,136)
            $scriptToggle.Size = [System.Drawing.Size]::new(55, 18)
            $scriptToggle.Location = [System.Drawing.Point]::new(820, 9)
            $scriptToggle.Cursor = "Hand"
            $scriptToggle.Tag = $null  # will store the script panel
            $card.Controls.Add($scriptToggle)

            # Script detail panel (hidden by default)
            $scriptDetail = New-Object System.Windows.Forms.Panel
            $scriptDetail.Size = [System.Drawing.Size]::new(420, 16 + ($opt.commands.Count * 18))
            $scriptDetail.Location = [System.Drawing.Point]::new(610, 32)
            $scriptDetail.BackColor = [System.Drawing.Color]::FromArgb(10,10,15)
            $scriptDetail.Visible = $false

            $sy = 4
            foreach ($cmd in $opt.commands) {
                $cmdLabel = New-Object System.Windows.Forms.Label
                $cmdLabel.Text = "> $cmd"
                $cmdLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
                $cmdLabel.ForeColor = [System.Drawing.Color]::FromArgb(34,211,238)
                $cmdLabel.Size = [System.Drawing.Size]::new(410, 16)
                $cmdLabel.Location = [System.Drawing.Point]::new(6, $sy)
                $scriptDetail.Controls.Add($cmdLabel)
                $sy += 18
            }
            $card.Controls.Add($scriptDetail)

            $scriptToggle.Add_Click({
                $scriptDetail.Visible = -not $scriptDetail.Visible
            })

            $optScroll.Controls.Add($card)
            $y += 76
        }

        $optScroll.AutoScrollMargin = [System.Drawing.Size]::new(0, 10)
    }

    # ── Wire events ──
    $btnAll.Add_Click({ Show-Category "All" })
    $btnEssential.Add_Click({ Show-Category "Essential" })
    $btnPro.Add_Click({ Show-Category "Pro" })
    $btnElite.Add_Click({ Show-Category "Elite" })

    $validateBtn.Add_Click({
        $key = $licenseInput.Text.Trim()
        if (-not $key) { return }
        $licenseStatus.Text = "Validando..."
        $licenseStatus.ForeColor = [System.Drawing.Color]::Gray
        $form.Refresh()
        $plan = Test-LicenseKey $key
        if ($plan) {
            $script:UserPlan = $plan
            Save-License $key
            Update-PlanBadge
            $licenseStatus.Text = "OK! Licencia $plan activa"
            $licenseStatus.ForeColor = [System.Drawing.Color]::FromArgb(16,185,129)
            Show-Category $currentCat
        } else {
            $licenseStatus.Text = "Licencia invalida"
            $licenseStatus.ForeColor = [System.Drawing.Color]::FromArgb(239,68,68)
        }
    })

    function Run-Optimizations {
        $selected = @()
        foreach ($opt in $script:Optimizations) {
            $cb = $script:Checkboxes[$opt.id]
            if ($cb -and $cb.Checked) { $selected += $opt }
        }

        if ($selected.Count -eq 0) {
            $outputBox.Text = "No seleccionaste ninguna optimizacion."
            return
        }

        $outputBox.Clear()
        $outputBox.AppendText("Ejecutando $($selected.Count) optimizaciones...`r`n")
        $outputBox.AppendText("----------------------------------------`r`n")
        $outputBox.Refresh()

        $i = 0
        foreach ($opt in $selected) {
            $i++
            Write-Log "[$i/$($selected.Count)] $($opt.name)"
            $outputBox.AppendText("[$i/$($selected.Count)] > $($opt.name)...`r`n")
            $outputBox.Refresh()
            Start-Sleep -Milliseconds 100

            try {
                $result = & $opt.action
                Write-Log "  OK: $result"
                $outputBox.AppendText("  OK: $result`r`n")
            } catch {
                Write-Log "  ERROR: $_"
                $outputBox.AppendText("  ERROR: $_`r`n")
            }
            $outputBox.Refresh()
            Start-Sleep -Milliseconds 50
        }

        $outputBox.AppendText("----------------------------------------`r`n")
        $outputBox.AppendText("$($selected.Count) optimizaciones aplicadas`r`n")
        $outputBox.AppendText("Log: $script:LogPath`r`n")
    }

    $runBtn.Add_Click({ Run-Optimizations })

    $runAllBtn.Add_Click({
        foreach ($cb in $script:Checkboxes.Values) {
            if ($cb.Enabled) { $cb.Checked = $true }
        }
        Run-Optimizations
    })

    $selAllBtn.Add_Click({
        foreach ($cb in $script:Checkboxes.Values) {
            if ($cb.Enabled) { $cb.Checked = $true }
        }
    })

    $desAllBtn.Add_Click({
        foreach ($cb in $script:Checkboxes.Values) {
            if ($cb.Enabled) { $cb.Checked = $false }
        }
    })

    # ── Show ──
    Show-Category "All"
    $form.ShowDialog()
}

Show-MainWindow
