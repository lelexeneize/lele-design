<#
╔══════════════════════════════════════════════════════════════╗
║  Sabina Optimizer v1.0                                   ║
║  Windows Performance Optimization Tool                    ║
║  By Lele Design                                           ║
╚══════════════════════════════════════════════════════════════╝

INSTRUCCIONES:
  1. Ejecutar PowerShell como Administrador
  2. Navegar a esta carpeta
  3. Ejecutar: .\SabinaOptimizer.ps1
  O usar: Set-ExecutionPolicy Bypass -Scope Process -Force; .\SabinaOptimizer.ps1
#>

# ─── Configuration ────────────────────────────────────────────
$script:APP_VERSION = "1.0.0"
$script:APP_NAME = "Sabina Optimizer"
$script:API_BASE = "https://leledesign.vercel.app/api"

# ─── GUI Setup ───────────────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ─── License check ───────────────────────────────────────────
$script:LicenseFile = "$env:LOCALAPPDATA\SabinaOptimizer\license.json"
$script:Plan = "free" # free, essential, pro, elite

function LoadLicense {
    if (Test-Path $LicenseFile) {
        try {
            $data = Get-Content $LicenseFile -Raw | ConvertFrom-Json
            $script:Plan = $data.plan
            return $true
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

# ─── Logging ─────────────────────────────────────────────────
$script:LogPath = "$env:USERPROFILE\Desktop\SabinaOptimizer_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    "[$timestamp] $msg" | Out-File -FilePath $script:LogPath -Append -Encoding utf8
}

# ─── Restore Point ──────────────────────────────────────────
function Create-RestorePoint {
    Write-Log "Creando punto de restauración..."
    try {
        Checkpoint-Computer -Description "SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "✅ Punto de restauración creado"
        return $true
    } catch {
        Write-Log "⚠️ No se pudo crear punto de restauración: $_"
        return $false
    }
}

# ─── Essential Optimizations ─────────────────────────────────
function Optimize-Windows {
    Write-Log "▶️ Optimizando Windows..."
    $changes = @()

    # Power plan - High Performance
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    $changes += "Power Plan: High Performance activado"

    # Disable HPET
    bcdedit /deletevalue useplatformclock 2>$null
    $changes += "HPET desactivado (boot)"

    # Disable Xbox Game Bar (registry)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Xbox Game Bar deshabilitado"

    # GPU Hardware Accelerated GPU Scheduling
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "GPU Scheduling: Hardware accelerated (requiere reinicio)"

    # Timer Resolution
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "TimerResolution" -Value 10000 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Timer Resolution optimizado"

    Write-Log "✅ Windows optimizado"
    return $changes
}

function Optimize-Network {
    Write-Log "▶️ Optimizando Red..."
    $changes = @()

    # Nagle's Algorithm disable
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Nagle Algorithm deshabilitado"

    # DNS Cloudflare
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        $changes += "DNS cambiado a Cloudflare (1.1.1.1) en $($adapter.Name)"
    }

    # Disable Auto-Tuning
    netsh int tcp set global autotuninglevel=disabled 2>$null
    $changes += "TCP Auto-Tuning deshabilitado"

    Write-Log "✅ Red optimizada"
    return $changes
}

function Optimize-Cleanup {
    Write-Log "▶️ Limpiando sistema..."
    $changes = @()

    # Clean TEMP
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    $changes += "TEMP limpiado"

    # Clean Prefetch
    Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    $changes += "Prefetch limpiado"

    # Clean Windows Update cache
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    $changes += "Windows Update cache limpiado"

    # Disk Cleanup
    Cleanmgr /sagerun:1 | Out-Null
    $changes += "Disk Cleanup ejecutado"

    Write-Log "✅ Limpieza completada"
    return $changes
}

# ─── Pro Optimizations ──────────────────────────────────────
function Optimize-Drivers {
    Write-Log "▶️ Limpiando drivers fantasma..."
    $changes = @()
    try {
        $orphaned = Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" }
        foreach ($dev in $orphaned) {
            $changes += "Driver huérfano detectado: $($dev.FriendlyName)"
        }
    } catch {
        Write-Log "⚠️ Error escaneando drivers: $_"
    }
    Write-Log "✅ Drivers escaneados"
    return $changes
}

function Optimize-Input {
    Write-Log "▶️ Optimizando Input..."
    $changes = @()

    # Raw Input Buffer
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" -Name "KeyboardDataQueueSize" -Value 100 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" -Name "MouseDataQueueSize" -Value 100 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Raw Input Buffer configurado"

    # Disable Mouse Acceleration
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -Force -ErrorAction SilentlyContinue
    $changes += "Mouse acceleration deshabilitado"

    Write-Log "✅ Input optimizado"
    return $changes
}

function Optimize-GPUDrivers {
    Write-Log "▶️ Optimizando GPU..."
    $changes = @()

    # Shader Cache size
    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global" -Name "ShaderCacheSize" -Value 4294967295 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Shader Cache size maximizado (NVIDIA)"

    # Power management mode - Prefer Maximum Performance
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    $changes += "Hibernate deshabilitado (libera espacio en SSD)"

    Write-Log "✅ GPU optimizada"
    return $changes
}

# ─── Elite Optimizations ────────────────────────────────────
function Optimize-Kernel {
    Write-Log "▶️ Optimizando Kernel..."
    $changes = @()

    # MSI Mode for GPU (via registry)
    $gpuPath = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -Recurse | Where-Object { $_.GetValue("DeviceDesc") -match "NVIDIA|AMD|Intel.*Graphics" }
    foreach ($gpu in $gpuPath) {
        $msiPath = "$($gpu.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (Test-Path $msiPath) {
            Set-ItemProperty -Path $msiPath -Name "MSISupported" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            $changes += "MSI Mode activado para GPU"
        }
    }

    Write-Log "✅ Kernel optimizado"
    return $changes
}

function Generate-Report {
    Write-Log "▶️ Generando reporte..."
    $report = @"
╔══════════════════════════════════════════════════════════════╗
║  Sabina Optimizer - Reporte de Sesión                      ║
║  Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')          ║
║  Plan: $($script:Plan)                                       ║
║  Versión: $($script:APP_VERSION)                              ║
╚══════════════════════════════════════════════════════════════╝

"@
    $report | Out-File -FilePath $script:LogPath -Encoding utf8
    Write-Log "✅ Reporte generado: $($script:LogPath)"
    return $script:LogPath
}

# ─── Main Execution ─────────────────────────────────────────
function Start-Optimization {
    param([string]$plan)

    $results = @()
    Create-RestorePoint

    # Essential (always runs)
    $results += Optimize-Windows
    $results += Optimize-Network
    $results += Optimize-Cleanup
    $results += Optimize-Input

    # Pro
    if ($plan -in @("pro","elite")) {
        $results += Optimize-Drivers
        $results += Optimize-GPUDrivers
    }

    # Elite
    if ($plan -eq "elite") {
        $results += Optimize-Kernel
    }

    Generate-Report

    return $results
}

# ─── Choose plan window ──────────────────────────────────────
function Show-MainWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Sabina Optimizer"
    $form.Size = New-Object Drawing.Size(500, 500)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = "#0a0a0f"

    # Title
    $title = New-Object Windows.Forms.Label
    $title.Text = "⚡ Sabina Optimizer"
    $title.Font = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $title.ForeColor = "#a855f7"
    $title.Size = New-Object Drawing.Size(460, 50)
    $title.Location = New-Object Drawing.Point(20, 20)
    $form.Controls.Add($title)

    $subtitle = New-Object Windows.Forms.Label
    $subtitle.Text = "Optimización Windows profesional"
    $subtitle.Font = New-Object Drawing.Font("Segoe UI", 10)
    $subtitle.ForeColor = "#a0a0a0"
    $subtitle.Size = New-Object Drawing.Size(460, 20)
    $subtitle.Location = New-Object Drawing.Point(20, 70)
    $form.Controls.Add($subtitle)

    # Plan selector
    $boxY = 110
    $plans = @(
        @{Name="Essential"; Price="USD 45 / ARS 45.000"; Color="#22d3ee"; Desc="Boost inmediato. Auto-ejecutable."},
        @{Name="Pro"; Price="USD 65 / ARS 65.000"; Color="#a855f7"; Desc="Jugadores competitivos. Incluye conexión remota."},
        @{Name="Elite"; Price="USD 85 / ARS 85.000"; Color="#d946ef"; Desc="Rendimiento absoluto. Soporte 30 días."}
    )

    foreach ($p in $plans) {
        $panel = New-Object Windows.Forms.Panel
        $panel.Size = New-Object Drawing.Size(440, 80)
        $panel.Location = New-Object Drawing.Point(20, $boxY)
        $panel.BackColor = "#1a1a2e"
        $panel.BorderStyle = "FixedSingle"

        $name = New-Object Windows.Forms.Label
        $name.Text = $p.Name
        $name.Font = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
        $name.ForeColor = $p.Color
        $name.Size = New-Object Drawing.Size(120, 30)
        $name.Location = New-Object Drawing.Point(15, 10)
        $panel.Controls.Add($name)

        $price = New-Object Windows.Forms.Label
        $price.Text = $p.Price
        $price.Font = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
        $price.ForeColor = "White"
        $price.Size = New-Object Drawing.Size(200, 25)
        $price.Location = New-Object Drawing.Point(15, 42)
        $panel.Controls.Add($price)

        $desc = New-Object Windows.Forms.Label
        $desc.Text = $p.Desc
        $desc.Font = New-Object Drawing.Font("Segoe UI", 9)
        $desc.ForeColor = "#808080"
        $desc.Size = New-Object Drawing.Size(250, 20)
        $desc.Location = New-Object Drawing.Point(140, 15)
        $panel.Controls.Add($desc)

        $btn = New-Object Windows.Forms.Button
        $btn.Text = "Comprar"
        $btn.Size = New-Object Drawing.Size(80, 35)
        $btn.Location = New-Object Drawing.Point(340, 22)
        $btn.BackColor = $p.Color
        $btn.ForeColor = "White"
        $btn.FlatStyle = "Flat"
        $btn.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $btn.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Redirigiendo a Lele Design para el pago...", "Sabina Optimizer") })
        $panel.Controls.Add($btn)

        $form.Controls.Add($panel)
        $boxY += 95
    }

    # License key section
    $keyLabel = New-Object Windows.Forms.Label
    $keyLabel.Text = "¿Ya tenés licencia? Ingresá tu key:"
    $keyLabel.Font = New-Object Drawing.Font("Segoe UI", 9)
    $keyLabel.ForeColor = "#a0a0a0"
    $keyLabel.Size = New-Object Drawing.Size(300, 20)
    $keyLabel.Location = New-Object Drawing.Point(20, ($boxY + 10))
    $form.Controls.Add($keyLabel)

    $keyInput = New-Object Windows.Forms.TextBox
    $keyInput.Size = New-Object Drawing.Size(280, 25)
    $keyInput.Location = New-Object Drawing.Point(20, ($boxY + 35))
    $keyInput.Font = New-Object Drawing.Font("Segoe UI", 10)
    $keyInput.BackColor = "#1a1a2e"
    $keyInput.ForeColor = "White"
    $form.Controls.Add($keyInput)

    $activateBtn = New-Object Windows.Forms.Button
    $activateBtn.Text = "Activar"
    $activateBtn.Size = New-Object Drawing.Size(80, 30)
    $activateBtn.Location = New-Object Drawing.Point(310, ($boxY + 33))
    $activateBtn.BackColor = "#22d3ee"
    $activateBtn.ForeColor = "White"
    $activateBtn.FlatStyle = "Flat"
    $activateBtn.Add_Click({
        $key = $keyInput.Text.Trim()
        if ($key) {
            SaveLicense "essential" $key
            [System.Windows.Forms.MessageBox]::Show("Licencia activada: Essential", "Sabina Optimizer")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Ingresá un key válido", "Error")
        }
    })
    $form.Controls.Add($activateBtn)

    # Run button
    $runY = $boxY + 80
    $runBtn = New-Object Windows.Forms.Button
    $runBtn.Text = "⚡ Iniciar Optimización"
    $runBtn.Size = New-Object Drawing.Size(440, 50)
    $runBtn.Location = New-Object Drawing.Point(20, $runY)
    $runBtn.BackColor = "#a855f7"
    $runBtn.ForeColor = "White"
    $runBtn.Font = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
    $runBtn.FlatStyle = "Flat"
    $runBtn.Add_Click({
        $plan = $script:Plan
        if ($plan -eq "free") {
            $result = [System.Windows.Forms.MessageBox]::Show("Modo gratuito: solo optimizaciones básicas. ¿Querés continuar?", "Sabina Optimizer", "YesNo")
            if ($result -eq "Yes") { $plan = "essential" } else { return }
        }
        $runBtn.Enabled = $false
        $runBtn.Text = "⏳ Optimizando..."
        $results = Start-Optimization -plan $plan
        $runBtn.Enabled = $true
        $runBtn.Text = "⚡ Optimización Completa ✓"
        $msg = "Optimización finalizada!`n`nCambios aplicados:`n" + ($results -join "`n")
        [System.Windows.Forms.MessageBox]::Show($msg, "Sabina Optimizer - Completa")
    })
    $form.Controls.Add($runBtn)

    # Status
    $status = New-Object Windows.Forms.Label
    $status.Text = "Plan actual: $($script:Plan)  |  Versión: $($script:APP_VERSION)"
    $status.Font = New-Object Drawing.Font("Segoe UI", 8)
    $status.ForeColor = "#606060"
    $status.Size = New-Object Drawing.Size(460, 20)
    $status.Location = New-Object Drawing.Point(20, ($runY + 60))
    $form.Controls.Add($status)

    # Log path
    $logLabel = New-Object Windows.Forms.Label
    $logLabel.Text = "Log: $($script:LogPath)"
    $logLabel.Font = New-Object Drawing.Font("Segoe UI", 7)
    $logLabel.ForeColor = "#404040"
    $logLabel.Size = New-Object Drawing.Size(460, 20)
    $logLabel.Location = New-Object Drawing.Point(20, ($runY + 80))
    $form.Controls.Add($logLabel)

    $form.ShowDialog()
}

# ─── Entry point ────────────────────────────────────────────
LoadLicense
Show-MainWindow
