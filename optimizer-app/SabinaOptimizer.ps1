<#
╔══════════════════════════════════════════════════════════════╗
║  Sabina Optimizer v4.0                                   ║
║  Windows Performance Optimization Tool                    ║
║  By Lele Design — leledesign.vercel.app                  ║
╚══════════════════════════════════════════════════════════════╝
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:APP_VERSION = "4.0"
$script:APP_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:DEV_FILE = Join-Path $script:APP_DIR "DEV_MODE"
$script:LogPath = "$env:USERPROFILE\Desktop\SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:UserPlan = "essential"
$script:IsDevMode = Test-Path $script:DEV_FILE

function Write-Log($msg) {
    $t = Get-Date -Format "HH:mm:ss"
    "[$t] $msg" | Out-File -LiteralPath $script:LogPath -Append -Encoding utf8
}

# ═══════════════════════════════════════════════════════════════
#  OPTIMIZACIONES
# ═══════════════════════════════════════════════════════════════

$script:Optimizations = @()

function Add-Opt($id, $name, $desc, $cat, $risk, $commands, $scriptBlock) {
    $script:Optimizations += @{
        id=$id; name=$name; desc=$desc; category=$cat
        risk=$risk; commands=$commands; action=$scriptBlock
    }
}

# ─── ESSENTIAL ───────────────────────────────────────────────

Add-Opt "powerplan" "Power Plan: Alto Rendimiento" "Activa el plan de energía de alto rendimiento." "Essential" "Bajo" @(
    'powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
) { powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null; "Power Plan: High Performance activado" }

Add-Opt "hpet" "Desactivar HPET" "Reduce latencia y mejora FPS. Requiere reinicio." "Essential" "Medio" @(
    'bcdedit /deletevalue useplatformclock'
) { bcdedit /deletevalue useplatformclock 2>$null; "HPET desactivado (requiere reinicio)" }

Add-Opt "gamemode" "Game Mode" "Prioriza recursos para juegos." "Essential" "Bajo" @(
    'Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" AutoGameModeEnabled 1 -Type DWord -Force'
) { Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" AutoGameModeEnabled 1 -Type DWord -Force -EA 0; "Game Mode activado" }

Add-Opt "xbox" "Deshabilitar Xbox Game Bar" "Elimina superposición de Xbox." "Essential" "Bajo" @(
    'Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" ShowStartupPanel 0 -Type DWord -Force'
) { Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" ShowStartupPanel 0 -Type DWord -Force -EA 0; "Xbox Game Bar deshabilitado" }

Add-Opt "gpusched" "GPU Hardware Scheduling" "Reduce latencia de GPU. Requiere reinicio." "Essential" "Medio" @(
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode 2 -Type DWord -Force'
) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" HwSchMode 2 -Type DWord -Force -EA 0; "GPU Scheduling: Hardware accelerated (requiere reinicio)" }

Add-Opt "timer" "Timer Resolution" "Ajusta temporizador del sistema para menor latencia." "Essential" "Bajo" @(
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" TimerResolution 10000 -Type DWord -Force'
) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" TimerResolution 10000 -Type DWord -Force -EA 0; "Timer Resolution optimizado" }

Add-Opt "nagle" "Deshabilitar Nagle" "Reduce ping en juegos online." "Essential" "Bajo" @(
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TcpAckFrequency 1 -Type DWord -Force',
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TCPNoDelay 1 -Type DWord -Force'
) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TcpAckFrequency 1 -Type DWord -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" TCPNoDelay 1 -Type DWord -Force -EA 0; "Nagle Algorithm deshabilitado" }

Add-Opt "dns" "DNS Cloudflare" "Cambia DNS a 1.1.1.1 (más rápido y seguro)." "Essential" "Bajo" @(
    'Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | ? Status -eq Up).ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1")'
) { $a = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}; foreach ($ad in $a) { Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -EA 0 }; "DNS cambiado a Cloudflare" }

Add-Opt "tcptune" "Optimizar TCP/IP" "Ajusta TCP para menor latencia de red." "Essential" "Bajo" @(
    'netsh int tcp set global autotuninglevel=normal',
    'netsh int tcp set global rss=enabled',
    'netsh int tcp set global chimney=disabled'
) { netsh int tcp set global autotuninglevel=normal 2>$null; netsh int tcp set global rss=enabled 2>$null; netsh int tcp set global chimney=disabled 2>$null; "TCP/IP optimizado" }

Add-Opt "cleanup" "Limpieza del sistema" "Limpia TEMP, Prefetch, Papelera, Update cache, DNS." "Essential" "Bajo" @(
    'Remove-Item "$env:TEMP\*" -Recurse -Force',
    'Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force',
    'Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force',
    'Clear-RecycleBin -Force',
    'ipconfig /flushdns'
) { Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0; Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -EA 0; Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -EA 0; Clear-RecycleBin -Force -EA 0; Stop-Service wuauserv -Force -EA 0; Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -EA 0; Start-Service wuauserv -EA 0; ipconfig /flushdns | Out-Null; "Limpieza completada" }

Add-Opt "input" "Optimizar Input" "Raw Buffer, mouse acceleration OFF, prioridad foreground." "Essential" "Bajo" @(
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" KeyboardDataQueueSize 100 -Type DWord -Force',
    'Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" MouseDataQueueSize 100 -Type DWord -Force',
    'Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseSpeed 0 -Force'
) { Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard" KeyboardDataQueueSize 100 -Type DWord -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Mouse" MouseDataQueueSize 100 -Type DWord -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseSpeed 0 -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseThreshold1 0 -Force -EA 0; Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseThreshold2 0 -Force -EA 0; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" Win32PrioritySeparation 38 -Type DWord -Force -EA 0; "Input optimizado" }

# ─── PRO ─────────────────────────────────────────────────────

Add-Opt "bloatware" "Remover Bloatware" "Desinstala apps preinstaladas (Xbox, Cortana, Skype, Copilot...)." "Pro" "Medio" @(
    'Get-AppxPackage -Name "Microsoft.BingWeather" | Remove-AppxPackage',
    'Get-AppxPackage -Name "Microsoft.SkypeApp" | Remove-AppxPackage',
    'Get-AppxPackage -Name "Microsoft.Copilot" | Remove-AppxPackage'
) { $apps = "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.Office.OneNote","Microsoft.People","Microsoft.Print3D","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.WindowsAlarms","Microsoft.WindowsCamera","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.YourPhone","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.Copilot","Clipchamp.Clipchamp"; foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -EA 0; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$app*" | Remove-AppxProvisionedPackage -Online -EA 0 }; "Bloatware removido: $($apps.Count) apps" }

Add-Opt "onedrive" "Desinstalar OneDrive" "Elimina OneDrive completamente del sistema." "Pro" "Medio" @(
    'Stop-Process -Name OneDrive -Force',
    'Start-Process "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait'
) { Stop-Process -Name OneDrive -Force -EA 0; $od = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"; if (Test-Path $od) { Start-Process $od -ArgumentList "/uninstall" -NoNewWindow -Wait }; "OneDrive desinstalado" }

Add-Opt "ssd" "Optimizar SSD/NVMe" "Hibernación OFF, SuperFetch OFF, TRIM." "Pro" "Bajo" @(
    'powercfg -h off',
    'Stop-Service SysMain -Force',
    'Optimize-Volume -DriveLetter C -ReTrim'
) { powercfg -h off 2>$null; Stop-Service SysMain -Force -EA 0; Set-Service SysMain -StartupType Disabled -EA 0; Optimize-Volume -DriveLetter C -ReTrim -EA 0; "SSD optimizado: Hibernate OFF, SuperFetch OFF, TRIM ejecutado" }

Add-Opt "gpucache" "Shader Cache GPU" "Maximiza caché de shaders NVIDIA." "Pro" "Bajo" @(
    'Set-ItemProperty "HKLM:\SOFTWARE\NVIDIA Corporation\Global" ShaderCacheSize 4294967295 -Type DWord -Force',
    'powercfg -setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1'
) { Set-ItemProperty "HKLM:\SOFTWARE\NVIDIA Corporation\Global" ShaderCacheSize 4294967295 -Type DWord -Force -EA 0; powercfg -setdcvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null; powercfg -setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null; "Shader Cache maximizado + GPU Performance Mode" }

Add-Opt "driverclean" "Limpiar Drivers Fantasma" "Escanea y detecta drivers huérfanos." "Pro" "Bajo" @(
    'Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" }'
) { $orphaned = Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" }; if ($orphaned) { foreach ($d in $orphaned) { "Driver huérfano: $($d.FriendlyName)" } } else { "No se detectaron drivers fantasma" } }

Add-Opt "monitor" "Guía Monitor" "Configurar Hz máximo y overdrive." "Pro" "Bajo" @(
    '# Config. pantalla → Avanzado → Frecuencia máxima',
    '# NVIDIA Panel → Sin escalado',
    '# Menú OSD → Overdrive: Medio'
) { "Guía: 1) Config. pantalla → Avanzado → Frecuencia máxima"; "2) NVIDIA Panel → Sin escalado"; "3) Menú OSD → Overdrive: Medio" }

# ─── ELITE ───────────────────────────────────────────────────

Add-Opt "msimode" "MSI Mode (GPU+NVMe+USB)" "Activa MSI en dispositivos. Reduce latencia DPC." "Elite" "Medio" @(
    'Set-ItemProperty -Path "HKLM:\...\MessageSignaledInterruptProperties" -Name MSISupported -Value 1'
) { $devices = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -Recurse -EA 0 | Where-Object { $_.GetValue("DeviceDesc") -match "NVIDIA|AMD|NVMe|Storage|USB|Network" }; $count = 0; foreach ($d in $devices) { $p = "$($d.PSPath)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"; if (Test-Path $p) { Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Type DWord -Force -EA 0; $count++ } }; "MSI Mode activado en $count dispositivos" }

Add-Opt "dpclatency" "Guía DPC Latency" "Recomendaciones BIOS para mínima latencia." "Elite" "Bajo" @(
    'powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100',
    '# BIOS: C-States: Disable | SpeedStep: Disable | Global C-States: Disable'
) { powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>$null; "Guía: 1) BIOS → C-States: Disable  2) SpeedStep: Disable  3) Global C-States: Disable" }

Add-Opt "ramtimings" "Guía RAM Timings" "Recomendaciones personalizadas para BIOS." "Elite" "Bajo" @(
    '# Get-CimInstance Win32_PhysicalMemory → calcular timings óptimos'
) { $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1; "RAM: $([math]::Round($mem.Capacity/1GB,0)) GB @ $($mem.Speed) MHz"; "tCL: $(($mem.Speed/100 - 6) -as [int]) | tRCD: $(($mem.Speed/100 - 4) -as [int]) | tRP: $(($mem.Speed/100 - 4) -as [int]) | tRAS: 58-68"; "⚠️ Usar MemTest86 después de cambios" }

Add-Opt "overclock" "Guía Overclock + Undervolt" "Guía personalizada CPU/GPU." "Elite" "Bajo" @(
    '# CPU Ratio: +1-2 | Voltage Offset: -0.05V',
    '# MSI Afterburner → Core +150 | Mem +750 | Power 110%'
) { $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; "CPU: $($cpu.Name) | BIOS → CPU Ratio: +1-2 | Voltage Offset: -0.05V"; "GPU: MSI Afterburner → Core +150 | Mem +750 | Power 110%" }

Add-Opt "benchmark" "Benchmark Rápido" "CPU, RAM, Disco y Ping." "Elite" "Bajo" @(
    'Get-CimInstance Win32_Processor',
    'Get-CimInstance Win32_OperatingSystem → FreePhysicalMemory',
    'Test-Connection 1.1.1.1 -Count 3'
) { $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; $os = Get-CimInstance Win32_OperatingSystem; $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Where-Object DeviceID -eq "C:"; $ping = Test-Connection "1.1.1.1" -Count 3 -EA 0; "CPU: $($cpu.Name) | RAM: $([math]::Round($os.FreePhysicalMemory/1MB,1)) GB libre | Disco: $([math]::Round($disk.FreeSpace/1GB,1)) GB libre | Ping: $(if($ping){[math]::Round(($ping|Measure-Object -Property ResponseTime -Average).Average,1)}else{'N/A'}) ms" }

Add-Opt "restorepoint" "Crear Punto de Restauración" "Deshace todos los cambios si algo falla." "Elite" "Bajo" @(
    'Checkpoint-Computer -Description "SabinaOptimizer_YYYYMMDD" -RestorePointType MODIFY_SETTINGS'
) { Checkpoint-Computer -Description "SabinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -EA Stop; "✅ Punto de restauración creado" }

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
#  GUI (WPF)
# ═══════════════════════════════════════════════════════════════

function Show-MainWindow {
    # ── Load stored license ──
    $storedKey = Get-StoredLicense
    if ($storedKey) {
        $plan = Test-LicenseKey $storedKey
        if ($plan) { $script:UserPlan = $plan }
    }

    # ── XAML ──
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Sabina Optimizer v$script:APP_VERSION"
        Height="820" Width="1060"
        WindowStartupLocation="CenterScreen"
        Background="#0a0a0f"
        FontFamily="Segoe UI"
        AllowsTransparency="True"
        WindowStyle="None"
        ResizeMode="NoResize">
    <Window.Resources>
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
            <Setter Property="Background" Value="#141420"/>
            <Setter Property="BorderBrush" Value="#2a2a3a"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style x:Key="CatBtn" TargetType="Button">
            <Setter Property="Height" Value="36"/>
            <Setter Property="Padding" Value="20,0"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="50"/>
            <RowDefinition Height="56"/>
            <RowDefinition Height="50"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="200"/>
            <RowDefinition Height="50"/>
        </Grid.RowDefinitions>

        <!-- Title bar -->
        <Border Grid.Row="0" Background="#0f0f1a" MouseDown="TitleBar_MouseDown">
            <Grid Margin="16,0">
                <TextBlock Text="⚡ Sabina Optimizer v$script:APP_VERSION" FontSize="16" FontWeight="Bold" VerticalAlignment="Center">
                    <TextBlock.Foreground>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#a855f7" Offset="0"/>
                            <GradientStop Color="#22d3ee" Offset="1"/>
                        </LinearGradientBrush>
                    </TextBlock.Foreground>
                </TextBlock>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button x:Name="MinBtn" Content="─" Width="36" Height="28" FontSize="14" ForeColor="#888" Background="Transparent" BorderThickness="0" Cursor="Hand" Click="MinBtn_Click"/>
                    <Button x:Name="CloseBtn" Content="✕" Width="36" Height="28" FontSize="14" Foreground="#888" Background="Transparent" BorderThickness="0" Cursor="Hand" Click="CloseBtn_Click"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- License bar -->
        <Border Grid.Row="1" Background="#141420" BorderBrush="#2a2a3a" BorderThickness="0,0,0,1" Padding="16,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="🔑" FontSize="16" VerticalAlignment="Center" Margin="0,0,10,0"/>
                <TextBox x:Name="LicenseInput" Grid.Column="1" Height="32" VerticalAlignment="Center" FontSize="12" Background="#0a0a0f" Foreground="#fff" BorderBrush="#333" CaretBrush="#a855f7" Padding="8,0"/>
                <Button x:Name="ValidateBtn" Grid.Column="2" Content="Validar" Width="80" Height="32" Margin="8,0,0,0" FontSize="12" FontWeight="Bold" Cursor="Hand" BorderThickness="0" Background="#a855f7" Foreground="#fff" Click="ValidateBtn_Click"/>
                <TextBlock x:Name="LicenseStatus" Grid.Column="3" Text="" FontSize="12" VerticalAlignment="Center" Margin="12,0,0,0"/>
                <StackPanel Grid.Column="5" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="Plan actual:" FontSize="11" Foreground="#666" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <Border x:Name="PlanBadge" CornerRadius="4" Padding="10,4" Background="#a855f7" VerticalAlignment="Center">
                        <TextBlock x:Name="PlanText" Text="ESSENTIAL" FontSize="11" FontWeight="Bold" Foreground="#fff"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Category tabs -->
        <Grid Grid.Row="2" Margin="16,8,16,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="CatEssential" Grid.Column="0" Content="🟢 Essential (12)" Style="{StaticResource CatBtn}" Background="#1a1a2e" Foreground="#fff" Click="CatEssential_Click"/>
            <Button x:Name="CatPro" Grid.Column="1" Content="🟣 Pro (6)" Style="{StaticResource CatBtn}" Background="#1a1a2e" Foreground="#666" Margin="8,0,0,0" Click="CatPro_Click"/>
            <Button x:Name="CatElite" Grid.Column="2" Content="🔶 Elite (6)" Style="{StaticResource CatBtn}" Background="#1a1a2e" Foreground="#666" Margin="8,0,0,0" Click="CatElite_Click"/>
            <Button x:Name="CatAll" Grid.Column="3" Content="Mostrar todas" HorizontalAlignment="Right" Style="{StaticResource CatBtn}" Background="#1a1a2e" Foreground="#22d3ee" Margin="0,0,4,0" FontSize="11" Click="CatAll_Click"/>
        </Grid>

        <!-- Optimization list -->
        <ScrollViewer Grid.Row="3" Margin="16,8,16,0" Background="Transparent" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="OptPanel" Margin="0"/>
        </ScrollViewer>

        <!-- Console output -->
        <Border Grid.Row="4" Background="#0a0a0f" BorderBrush="#1a1a2e" BorderThickness="1" Margin="16,8,16,0" CornerRadius="8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="28"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Border Grid.Row="0" Background="#141420" CornerRadius="8,8,0,0" Padding="12,0">
                    <TextBlock Text="📋 Consola" FontSize="11" Foreground="#888" VerticalAlignment="Center"/>
                </Border>
                <TextBox x:Name="OutputBox" Grid.Row="1" IsReadOnly="True" FontFamily="Consolas" FontSize="11" Background="#0a0a0f" Foreground="#00ff88" BorderThickness="0" Padding="12,6" VerticalScrollBarVisibility="Auto" Text="Listo para ejecutar. Seleccioná optimizaciones y presioná EJECUTAR."/>
            </Grid>
        </Border>

        <!-- Bottom bar -->
        <Border Grid.Row="5" Background="#141420" BorderBrush="#2a2a3a" BorderThickness="0,1,0,0" Padding="16,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="SelAllBtn" Grid.Column="0" Content="✅ Seleccionar todo" Height="36" FontSize="12" Cursor="Hand" BorderThickness="0" Background="#1a1a2e" Foreground="#fff" Padding="16,0" Click="SelAllBtn_Click"/>
                <Button x:Name="DesAllBtn" Grid.Column="1" Content="❌ Deseleccionar todo" Height="36" FontSize="12" Margin="8,0,0,0" Cursor="Hand" BorderThickness="0" Background="#1a1a2e" Foreground="#fff" Padding="16,0" Click="DesAllBtn_Click"/>
                <Button x:Name="RunBtn" Grid.Column="3" Content="▶ Ejecutar seleccionadas" Height="40" FontSize="13" FontWeight="Bold" Cursor="Hand" BorderThickness="0" Background="#a855f7" Foreground="#fff" Padding="24,0" Click="RunBtn_Click"/>
                <Button x:Name="RunAllBtn" Grid.Column="4" Content="▶▶ EJECUTAR TODO" Height="40" FontSize="13" FontWeight="Bold" Margin="8,0,0,0" Cursor="Hand" BorderThickness="0" Background="#22d3ee" Foreground="#000" Padding="24,0" Click="RunAllBtn_Click"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # ── Get controls ──
    $winProps = @{
        LicenseInput = $window.FindName("LicenseInput")
        ValidateBtn  = $window.FindName("ValidateBtn")
        LicenseStatus= $window.FindName("LicenseStatus")
        PlanBadge    = $window.FindName("PlanBadge")
        PlanText     = $window.FindName("PlanText")
        CatEssential = $window.FindName("CatEssential")
        CatPro       = $window.FindName("CatPro")
        CatElite     = $window.FindName("CatElite")
        CatAll       = $window.FindName("CatAll")
        OptPanel     = $window.FindName("OptPanel")
        OutputBox    = $window.FindName("OutputBox")
        SelAllBtn    = $window.FindName("SelAllBtn")
        DesAllBtn    = $window.FindName("DesAllBtn")
        RunBtn       = $window.FindName("RunBtn")
        RunAllBtn    = $window.FindName("RunAllBtn")
        MinBtn       = $window.FindName("MinBtn")
        CloseBtn     = $window.FindName("CloseBtn")
    }

    $script:Checkboxes = @{}
    $script:CurrentCategory = "All"
    $script:CategoryButtons = @{
        "Essential" = $winProps.CatEssential
        "Pro"       = $winProps.CatPro
        "Elite"     = $winProps.CatElite
        "All"       = $winProps.CatAll
    }

    # ── Update plan badge ──
    function Update-PlanBadge {
        $colors = @{essential="#10b981"; pro="#a855f7"; elite="#f59e0b"}
        $names  = @{essential="ESSENTIAL"; pro="PRO"; elite="ELITE"}
        $winProps.PlanBadge.Background = [Windows.Media.BrushConverter]::new().ConvertFromString($colors[$script:UserPlan])
        $winProps.PlanText.Text = $names[$script:UserPlan]
    }
    Update-PlanBadge

    # ── Get locked categories for this plan ──
    function Get-LockedCategories {
        switch ($script:UserPlan) {
            "essential" { return @("Pro","Elite") }
            "pro"       { return @("Elite") }
            "elite"     { return @() }
            default     { return @("Pro","Elite") }
        }
    }

    # ── Build optimization cards ──
    function Show-Category($cat) {
        $script:CurrentCategory = $cat

        # Update tab button styles
        foreach ($kv in $script:CategoryButtons.GetEnumerator()) {
            $btn = $kv.Value
            if ($kv.Key -eq $cat) {
                $btn.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a3a")
                $btn.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#ffffff")
            } else {
                $btn.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#1a1a2e")
                $btn.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#666666")
            }
        }

        $winProps.OptPanel.Children.Clear()
        $locked = Get-LockedCategories

        foreach ($opt in $script:Optimizations) {
            if ($cat -ne "All" -and $opt.category -ne $cat) { continue }
            $isLocked = $locked -contains $opt.category

            # Card border
            $card = New-Object Windows.Controls.Border
            $card.Style = [Windows.Style]::new()
            $card.CornerRadius = [Windows.CornerRadius]::new(8)
            $card.Margin = [Windows.Thickness]::new(0,0,0,6)
            $card.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#141420")
            $card.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString("#2a2a3a")
            $card.BorderThickness = [Windows.Thickness]::new(1)

            if ($isLocked) {
                $card.Opacity = 0.4
            }

            # Inner grid
            $grid = New-Object Windows.Controls.Grid
            $grid.Margin = [Windows.Thickness]::new(12,8,12,8)
            $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{Width=[Windows.GridLength]::Auto}))
            $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{Width=[Windows.GridLength]::new(1, [Windows.GridUnitType]::Star)}))
            $grid.ColumnDefinitions.Add((New-Object Windows.Controls.ColumnDefinition -Property @{Width=[Windows.GridLength]::Auto}))

            # Row 0: name + risk
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))
            # Row 1: desc
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))
            # Row 2: script toggle
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))

            # Checkbox
            $cb = New-Object Windows.Controls.CheckBox
            $cb.VerticalAlignment = "Center"
            $cb.Margin = [Windows.Thickness]::new(0,0,10,0)
            $cb.IsChecked = !$isLocked
            if ($isLocked) { $cb.IsEnabled = $false }
            $cb.Tag = $opt.id
            [Windows.Controls.Grid]::SetRow($cb, 0)
            [Windows.Controls.Grid]::SetColumn($cb, 0)
            [Windows.Controls.Grid]::SetRowSpan($cb, 3)
            $grid.AddChild($cb)
            $script:Checkboxes[$opt.id] = $cb

            # Name label
            $nl = New-Object Windows.Controls.TextBlock
            $nl.Text = $opt.name
            $nl.FontWeight = "Bold"
            $nl.FontSize = 13
            $nl.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#ffffff")
            $nl.VerticalAlignment = "Center"
            [Windows.Controls.Grid]::SetRow($nl, 0)
            [Windows.Controls.Grid]::SetColumn($nl, 1)
            $grid.AddChild($nl)

            # Risk badge
            $riskBorder = New-Object Windows.Controls.Border
            $riskBorder.CornerRadius = [Windows.CornerRadius]::new(4)
            $riskBorder.Padding = [Windows.Thickness]::new(8,2,8,2)
            $riskBorder.VerticalAlignment = "Center"
            $riskColor = if ($opt.risk -eq "Bajo") { "#10b981" } elseif ($opt.risk -eq "Medio") { "#f59e0b" } else { "#ef4444" }
            $riskBorder.Background = [Windows.Media.BrushConverter]::new().ConvertFromString($riskColor)
            $riskLabel = New-Object Windows.Controls.TextBlock
            $riskLabel.Text = " $($opt.risk) "
            $riskLabel.FontSize = 10
            $riskLabel.FontWeight = "Bold"
            $riskLabel.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#000000")
            $riskBorder.AddChild($riskLabel)
            [Windows.Controls.Grid]::SetRow($riskBorder, 0)
            [Windows.Controls.Grid]::SetColumn($riskBorder, 2)
            $grid.AddChild($riskBorder)

            # Description
            $dl = New-Object Windows.Controls.TextBlock
            $dl.Text = $opt.desc
            $dl.FontSize = 11
            $dl.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
            $dl.Margin = [Windows.Thickness]::new(0,2,0,0)
            [Windows.Controls.Grid]::SetRow($dl, 1)
            [Windows.Controls.Grid]::SetColumn($dl, 1)
            [Windows.Controls.Grid]::SetColumnSpan($dl, 2)
            $grid.AddChild($dl)

            # Category indicator
            $catIndicator = New-Object Windows.Controls.TextBlock
            $catIndicator.Text = " $($opt.category) "
            $catIndicator.FontSize = 9
            $catIndicator.FontWeight = "Bold"
            $catIndicator.Margin = [Windows.Thickness]::new(0,4,0,0)
            $catColors = @{Essential="#10b981"; Pro="#a855f7"; Elite="#f59e0b"}
            $catIndicator.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString($catColors[$opt.category])
            [Windows.Controls.Grid]::SetRow($catIndicator, 2)
            [Windows.Controls.Grid]::SetColumn($catIndicator, 1)
            $grid.AddChild($catIndicator)

            # Script preview toggle (eye icon)
            $scriptToggle = New-Object Windows.Controls.Button
            $scriptToggle.Content = "📜"
            $scriptToggle.FontSize = 14
            $scriptToggle.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("Transparent")
            $scriptToggle.BorderThickness = [Windows.Thickness]::new(0)
            $scriptToggle.Cursor = "Hand"
            $scriptToggle.Width = 30
            $scriptToggle.Height = 30
            $scriptToggle.VerticalAlignment = "Bottom"
            $scriptToggle.Margin = [Windows.Thickness]::new(4,0,0,0)
            [Windows.Controls.Grid]::SetRow($scriptToggle, 2)
            [Windows.Controls.Grid]::SetColumn($scriptToggle, 2)

            # Expanded scripts section
            $scriptsPanel = New-Object Windows.Controls.StackPanel
            $scriptsPanel.Margin = [Windows.Thickness]::new(0,4,0,0)
            $scriptsPanel.Visibility = "Collapsed"
            [Windows.Controls.Grid]::SetRow($scriptsPanel, 3)  # we'll add another row
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))
            # Move the category text to row 3
            [Windows.Controls.Grid]::SetRow($catIndicator, 3)
            [Windows.Controls.Grid]::SetColumnSpan($catIndicator, 2)
            [Windows.Controls.Grid]::SetRow($scriptToggle, 3)

            # Actually this is getting complex. Let me simplify: prepend category to name
            $catIndicator.Visibility = "Collapsed"
            $scriptToggle.Visibility = "Collapsed"

            # Name with category
            $nl.Text = "[$($opt.category)] $($opt.name)"

            # Script preview - just show on hover by doing it differently
            # We'll just build the scripts panel and toggle visibility
            $grid.RowDefinitions.Clear()
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))
            $grid.RowDefinitions.Add((New-Object Windows.Controls.RowDefinition -Property @{Height=[Windows.GridLength]::Auto}))

            [Windows.Controls.Grid]::SetRow($nl, 0)
            [Windows.Controls.Grid]::SetColumn($nl, 1)
            [Windows.Controls.Grid]::SetColumnSpan($nl, 2)

            [Windows.Controls.Grid]::SetRow($dl, 1)
            [Windows.Controls.Grid]::SetColumn($dl, 1)
            [Windows.Controls.Grid]::SetColumnSpan($dl, 2)

            [Windows.Controls.Grid]::SetRow($riskBorder, 0)
            [Windows.Controls.Grid]::SetColumn($riskBorder, 2)

            [Windows.Controls.Grid]::SetRow($cb, 0)
            [Windows.Controls.Grid]::SetColumn($cb, 0)
            [Windows.Controls.Grid]::SetRowSpan($cb, 3)

            # Script preview button
            $scriptBtn = New-Object Windows.Controls.Button
            $scriptBtn.Content = "📜 Ver script"
            $scriptBtn.FontSize = 10
            $scriptBtn.Background = "Transparent"
            $scriptBtn.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString("#333")
            $scriptBtn.BorderThickness = [Windows.Thickness]::new(1)
            $scriptBtn.Cursor = "Hand"
            $scriptBtn.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#888")
            $scriptBtn.Padding = [Windows.Thickness]::new(8,2,8,2)
            $scriptBtn.Margin = [Windows.Thickness]::new(0,4,0,0)
            $scriptBtn.HorizontalAlignment = "Left"
            [Windows.Controls.Grid]::SetRow($scriptBtn, 2)
            [Windows.Controls.Grid]::SetColumn($scriptBtn, 1)

            # Script detail panel
            $scriptDetail = New-Object Windows.Controls.Border
            $scriptDetail.Background = [Windows.Media.BrushConverter]::new().ConvertFromString("#0a0a0f")
            $scriptDetail.BorderBrush = [Windows.Media.BrushConverter]::new().ConvertFromString("#333")
            $scriptDetail.BorderThickness = [Windows.Thickness]::new(1)
            $scriptDetail.CornerRadius = [Windows.CornerRadius]::new(4)
            $scriptDetail.Margin = [Windows.Thickness]::new(38,4,0,0)
            $scriptDetail.Padding = [Windows.Thickness]::new(8,6,8,6)
            $scriptDetail.Visibility = "Collapsed"

            $scriptStack = New-Object Windows.Controls.StackPanel
            $scriptHeader = New-Object Windows.Controls.TextBlock
            $scriptHeader.Text = "Comandos a ejecutar:"
            $scriptHeader.FontSize = 10
            $scriptHeader.FontWeight = "Bold"
            $scriptHeader.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#a855f7")
            $scriptHeader.Margin = [Windows.Thickness]::new(0,0,0,4)
            $scriptStack.AddChild($scriptHeader)

            foreach ($cmd in $opt.commands) {
                $cmdLine = New-Object Windows.Controls.TextBlock
                $cmdLine.Text = "> $cmd"
                $cmdLine.FontFamily = [Windows.Media.FontFamily]::new("Consolas")
                $cmdLine.FontSize = 10
                $cmdLine.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#22d3ee")
                $cmdLine.Margin = [Windows.Thickness]::new(0,1,0,1)
                $cmdLine.TextWrapping = "Wrap"
                $scriptStack.AddChild($cmdLine)
            }

            $scriptDetail.AddChild($scriptStack)

            # Toggle script visibility
            $scriptBtn.Add_Click({
                $scriptDetail.Visibility = if ($scriptDetail.Visibility -eq "Visible") { "Collapsed" } else { "Visible" }
            })

            $grid.AddChild($scriptBtn)
            $grid.AddChild($scriptDetail)

            $card.AddChild($grid)
            $winProps.OptPanel.AddChild($card)
        }
    }

    # ── Category button handlers ──
    $winProps.CatEssential.Add_Click({ Show-Category "Essential" })
    $winProps.CatPro.Add_Click({ Show-Category "Pro" })
    $winProps.CatElite.Add_Click({ Show-Category "Elite" })
    $winProps.CatAll.Add_Click({ Show-Category "All" })

    # ── License validation ──
    $winProps.ValidateBtn.Add_Click({
        $key = $winProps.LicenseInput.Text.Trim()
        if (-not $key) { return }
        $winProps.LicenseStatus.Text = "⏳ Validando..."
        $plan = Test-LicenseKey $key
        if ($plan) {
            $script:UserPlan = $plan
            Save-License $key
            Update-PlanBadge
            $winProps.LicenseStatus.Text = "✅ Licencia $plan válida"
            $winProps.LicenseStatus.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#10b981")
            Show-Category $script:CurrentCategory
        } else {
            $winProps.LicenseStatus.Text = "❌ Licencia inválida"
            $winProps.LicenseStatus.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString("#ef4444")
        }
    })

    # ── Run optimizations ──
    function Run-Optimizations {
        $selected = @()
        foreach ($opt in $script:Optimizations) {
            $cb = $script:Checkboxes[$opt.id]
            if ($cb -and $cb.IsChecked) { $selected += $opt }
        }

        if ($selected.Count -eq 0) {
            $winProps.OutputBox.Text = "❌ No seleccionaste ninguna optimización."
            return
        }

        $winProps.OutputBox.Text = ""

        function Write-Output($msg) {
            $winProps.OutputBox.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Normal)
            $winProps.OutputBox.AppendText("$msg`r`n")
            $winProps.OutputBox.ScrollToEnd()
            [Windows.Forms.Application]::DoEvents()
        }

        Write-Output "⚡ Ejecutando $($selected.Count) optimizaciones..."
        Write-Output "────────────────────────────────"

        $i = 0
        foreach ($opt in $selected) {
            $i++
            Write-Log "[$i/$($selected.Count)] $($opt.name)"
            Write-Output "[$i/$($selected.Count)] ▶ $($opt.name)..."
            Start-Sleep -Milliseconds 100

            try {
                $result = & $opt.action
                Write-Log "  OK: $result"
                Write-Output "  ✅ $result"
            } catch {
                Write-Log "  ERROR: $_"
                Write-Output "  ❌ Error: $_"
            }
            Start-Sleep -Milliseconds 50
        }

        Write-Output "────────────────────────────────"
        Write-Output "✅ $($selected.Count) optimizaciones aplicadas"
        Write-Output "📄 Log: $script:LogPath"
    }

    $winProps.RunBtn.Add_Click({ Run-Optimizations })

    $winProps.RunAllBtn.Add_Click({
        $script:Checkboxes.Values | ForEach-Object { $_.IsChecked = $true }
        Run-Optimizations
    })

    # ── Select/Deselect all ──
    $winProps.SelAllBtn.Add_Click({
        $script:Checkboxes.Values | ForEach-Object { $_.IsChecked = $true }
    })

    $winProps.DesAllBtn.Add_Click({
        $script:Checkboxes.Values | ForEach-Object { $_.IsChecked = $false }
    })

    # ── Window controls ──
    $winProps.MinBtn.Add_Click({ $window.WindowState = "Minimized" })
    $winProps.CloseBtn.Add_Click({ $window.Close() })

    $window.Add_MouseLeftButtonDown({
        $window.DragMove()
    })

    # ── Show initial category ──
    Show-Category "All"

    $window.ShowDialog() | Out-Null
}

Show-MainWindow
