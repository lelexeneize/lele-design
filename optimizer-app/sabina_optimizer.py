import os, sys, json, threading, subprocess, datetime, time
import urllib.request, urllib.error, urllib.parse
import tkinter as tk
from tkinter import messagebox

# ── Config ──────────────────────────────────────────────────────────
APP_VERSION = "4.0"
APP_DIR = os.path.dirname(os.path.abspath(__file__))
DEV_FILE = os.path.join(APP_DIR, "DEV_MODE")
LICENSE_FILE = os.path.join(APP_DIR, "license.key")
LOG_PATH = os.path.join(os.environ["USERPROFILE"], "Desktop",
    f"SabinaOptimizer_{datetime.datetime.now():%Y%m%d_%H%M%S}.log")
MASTER_KEY = "SABINA-DEV-2026-MASTER"
LICENSE_URL = "https://leleoficial.vercel.app/api/validate-license.js?key="

IS_DEV_MODE = os.path.exists(DEV_FILE)
user_plan = "none"

# ── Colors ──────────────────────────────────────────────────────────
BG         = "#0a0a0f"
CARD       = "#141420"
CARD2      = "#1a1a2e"
BORDER     = "#2a2a3a"
TEXT       = "#ffffff"
TEXT2      = "#888888"
ACCENT     = "#a855f7"
ACCENT2    = "#22d3ee"
GREEN      = "#10b981"
RED        = "#ef4444"
DARK_INPUT = "#0f0f1a"

# ── Optimizations ───────────────────────────────────────────────────
optimizations = []

def add_opt(id_, name, desc, cat, risk, commands):
    optimizations.append(dict(id=id_, name=name, desc=desc, category=cat,
                              risk=risk, commands=commands))

# ── Essential ───────────────────────────────────────────────────────
add_opt("powerplan", "Power Plan: Alto Rendimiento",
    "Activa el plan de energia de alto rendimiento.", "Essential", "Bajo",
    ['powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'])
add_opt("hpet", "Desactivar HPET",
    "Reduce latencia y mejora FPS. Requiere reinicio.", "Essential", "Medio",
    ['bcdedit /deletevalue useplatformclock'])
add_opt("gamemode", "Game Mode",
    "Prioriza recursos para juegos.", "Essential", "Bajo",
    ['Set-ItemProperty "HKCU:\\Software\\Microsoft\\GameBar" AutoGameModeEnabled 1 -Type DWord -Force'])
add_opt("xbox", "Deshabilitar Xbox Game Bar",
    "Elimina superposicion de Xbox.", "Essential", "Bajo",
    ['Set-ItemProperty "HKCU:\\Software\\Microsoft\\GameBar" ShowStartupPanel 0 -Type DWord -Force'])
add_opt("gpusched", "GPU Hardware Scheduling",
    "Reduce latencia de GPU. Requiere reinicio.", "Essential", "Medio",
    ['Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers" HwSchMode 2 -Type DWord -Force'])
add_opt("timer", "Timer Resolution",
    "Ajusta temporizador del sistema para menor latencia.", "Essential", "Bajo",
    ['Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\kernel" TimerResolution 10000 -Type DWord -Force'])
add_opt("nagle", "Deshabilitar Nagle",
    "Reduce ping en juegos online.", "Essential", "Bajo",
    ['Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\*" TcpAckFrequency 1 -Type DWord -Force',
     'Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\*" TCPNoDelay 1 -Type DWord -Force'])
add_opt("dns", "DNS Cloudflare",
    "Cambia DNS a 1.1.1.1 (mas rapido y seguro).", "Essential", "Bajo",
    ['$a = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}; foreach ($ad in $a) { Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -EA 0 }'])
add_opt("tcptune", "Optimizar TCP/IP",
    "Ajusta TCP para menor latencia de red.", "Essential", "Bajo",
    ['netsh int tcp set global autotuninglevel=normal',
     'netsh int tcp set global rss=enabled',
     'netsh int tcp set global chimney=disabled'])
add_opt("cleanup", "Limpieza del sistema",
    "Limpia TEMP, Prefetch, Papelera, Update cache, DNS.", "Essential", "Bajo",
    ['Remove-Item "$env:TEMP\\*" -Recurse -Force -EA 0',
     'Remove-Item "$env:WINDIR\\Temp\\*" -Recurse -Force -EA 0',
     'Clear-RecycleBin -Force -EA 0',
     'ipconfig /flushdns | Out-Null'])
add_opt("telemetry", "Telemetria y Rastreo",
    "Apaga servicios de diagnostico de Windows que envian datos a Microsoft. Libera CPU, RAM y disco.", "Essential", "Bajo",
    ['Stop-Service DiagTrack -Force -EA 0; Set-Service DiagTrack -StartupType Disabled -EA 0',
     'Stop-Service dmwappushservice -Force -EA 0; Set-Service dmwappushservice -StartupType Disabled -EA 0',
     'Set-ItemProperty "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection" AllowTelemetry 0 -Type DWord -Force -EA 0',
     'Set-ItemProperty "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection" AllowTelemetry 0 -Type DWord -Force -EA 0'])
add_opt("visualfx", "Efectos Visuales Ultrarrápidos",
    "Desactiva animaciones lentas (minimizar/maximizar, taskbar). Mantiene fuentes suaves y aspecto visual.", "Essential", "Medio",
    ['Set-ItemProperty "HKCU:\\Control Panel\\Desktop\\WindowMetrics" MinAnimate 0 -Type DWord -Force -EA 0',
     'Set-ItemProperty "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" TaskbarAnimations 0 -Type DWord -Force -EA 0'])
add_opt("input", "Optimizar Input",
    "Raw Buffer, mouse acceleration OFF, prioridad foreground.", "Essential", "Bajo",
    ['Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Keyboard" KeyboardDataQueueSize 100 -Type DWord -Force -EA 0',
     'Set-ItemProperty "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Mouse" MouseDataQueueSize 100 -Type DWord -Force -EA 0',
     'Set-ItemProperty "HKCU:\\Control Panel\\Mouse" MouseSpeed 0 -Force -EA 0'])

# ── Pro ─────────────────────────────────────────────────────────────
add_opt("bloatware", "Remover Bloatware",
    "Desinstala apps preinstaladas (Xbox, Cortana, Skype, Copilot...).", "Pro", "Medio",
    ['$apps = "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.Office.OneNote","Microsoft.People","Microsoft.Print3D","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.WindowsAlarms","Microsoft.WindowsCamera","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.WindowsSoundRecorder","Microsoft.YourPhone","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.Copilot","Clipchamp.Clipchamp"; foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -EA 0; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "$app*" | Remove-AppxProvisionedPackage -Online -EA 0 }'])
add_opt("onedrive", "Desinstalar OneDrive",
    "Elimina OneDrive completamente del sistema.", "Pro", "Medio",
    ['Stop-Process -Name OneDrive -Force -EA 0; $od = "$env:SYSTEMROOT\\SysWOW64\\OneDriveSetup.exe"; if (Test-Path $od) { Start-Process $od -ArgumentList "/uninstall" -NoNewWindow -Wait }'])
add_opt("ssd", "Optimizar SSD/NVMe",
    "Hibernacion OFF, SuperFetch OFF, TRIM.", "Pro", "Bajo",
    ['powercfg -h off 2>$null',
     'Stop-Service SysMain -Force -EA 0; Set-Service SysMain -StartupType Disabled -EA 0',
     'Optimize-Volume -DriveLetter C -ReTrim -EA 0'])
add_opt("gpucache", "Shader Cache GPU",
    "Maximiza cache de shaders NVIDIA.", "Pro", "Bajo",
    ['Set-ItemProperty "HKLM:\\SOFTWARE\\NVIDIA Corporation\\Global" ShaderCacheSize 4294967295 -Type DWord -Force -EA 0',
     'powercfg -setdcvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null',
     'powercfg -setacvalueindex SCHEME_CURRENT SUB_GRAPHICS GPUPREFERENCE 1 2>$null'])
add_opt("driverclean", "Limpiar Drivers Fantasma",
    "Escanea y detecta drivers huerfanos.", "Pro", "Bajo",
    ['Get-PnpDevice | Where-Object { $_.Problem -eq 22 -and $_.Class -ne "SoftwareDevice" } | ForEach-Object { "Driver huerfano: $($_.FriendlyName)" }'])
add_opt("monitor", "Guia Monitor",
    "Configurar Hz maximo y overdrive.", "Pro", "Bajo",
    ['Write-Output "Guia: 1) Config. pantalla > Avanzado > Frecuencia maxima"',
     'Write-Output "2) NVIDIA Panel > Sin escalado"',
     'Write-Output "3) Menu OSD > Overdrive: Medio"'])
add_opt("bgapps", "Bloquear Apps en Segundo Plano",
    "Impide que aplicaciones innecesarias se ejecuten en segundo plano consumiendo recursos.", "Pro", "Bajo",
    ['Set-ItemProperty "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications" GlobalUserDisabled 1 -Type DWord -Force -EA 0',
     'Set-ItemProperty "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AppPrivacy" LetAppsRunInBackground 2 -Type DWord -Force -EA 0'])

# ── Elite ───────────────────────────────────────────────────────────
add_opt("msimode", "MSI Mode (GPU+NVMe+USB)",
    "Activa MSI en dispositivos. Reduce latencia DPC.", "Elite", "Medio",
    ['$devices = Get-ChildItem "HKLM:\\SYSTEM\\CurrentControlSet\\Enum\\PCI" -Recurse -EA 0 | Where-Object { $_.GetValue("DeviceDesc") -match "NVIDIA|AMD|NVMe|Storage|USB|Network" }; $count = 0; foreach ($d in $devices) { $p = "$($d.PSPath)\\Device Parameters\\Interrupt Management\\MessageSignaledInterruptProperties"; if (Test-Path $p) { Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Type DWord -Force -EA 0; $count++ } }; Write-Output "MSI Mode activado en $count dispositivos"'])
add_opt("dpclatency", "Guia DPC Latency",
    "Recomendaciones BIOS para minima latencia.", "Elite", "Bajo",
    ['Write-Output "Guia: 1) BIOS > C-States: Disable   2) SpeedStep: Disable   3) Global C-States: Disable"'])
add_opt("ramtimings", "Guia RAM Timings",
    "Recomendaciones personalizadas para BIOS.", "Elite", "Bajo",
    ['$mem = Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1; Write-Output "RAM: $([math]::Round($mem.Capacity/1GB,0)) GB @ $($mem.Speed) MHz"; Write-Output "tCL: $(($mem.Speed/100 - 6) -as [int]) | tRCD: $(($mem.Speed/100 - 4) -as [int]) | tRP: $(($mem.Speed/100 - 4) -as [int]) | tRAS: 58-68"'])
add_opt("overclock", "Guia Overclock + Undervolt",
    "Guia personalizada CPU/GPU.", "Elite", "Bajo",
    ['$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; Write-Output "CPU: $($cpu.Name) | BIOS > CPU Ratio: +1-2 | Voltage Offset: -0.05V"; Write-Output "GPU: MSI Afterburner > Core +150 | Mem +750 | Power 110%"'])
add_opt("benchmark", "Benchmark Rapido",
    "CPU, RAM, Disco y Ping.", "Elite", "Bajo",
    ["$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1; $os = Get-CimInstance Win32_OperatingSystem; $disk = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Where-Object DeviceID -eq 'C:'; $ping = Test-Connection '1.1.1.1' -Count 3 -EA 0; Write-Output \"CPU: $($cpu.Name) | RAM: $([math]::Round($os.FreePhysicalMemory/1MB,1)) GB libre | Disco: $([math]::Round($disk.FreeSpace/1GB,1)) GB libre | Ping: $(if($ping){[math]::Round(($ping|Measure-Object -Property ResponseTime -Average).Average,1)}else{'N/A'}) ms\""])
add_opt("restorepoint", "Crear Punto de Restauracion",
    "Deshace todos los cambios si algo falla.", "Elite", "Bajo",
    ['Checkpoint-Computer -Description "SabinaOptimizer" -RestorePointType MODIFY_SETTINGS'])

# ── License ─────────────────────────────────────────────────────────
def validate_license(key):
    key = key.strip()
    if key == MASTER_KEY:
        return "elite"
    try:
        req = urllib.request.Request(LICENSE_URL + urllib.parse.quote(key),
                                     headers={"User-Agent": "SabinaOptimizer/4.0"})
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read().decode())
            if data.get("valid"):
                return data.get("plan")
    except Exception:
        pass
    return None

def get_stored_license():
    if os.path.exists(LICENSE_FILE):
        with open(LICENSE_FILE, "r", encoding="utf-8") as f:
            return f.read().strip()
    return None

def save_license(key):
    with open(LICENSE_FILE, "w", encoding="utf-8") as f:
        f.write(key.strip())

# ── Restore Point ───────────────────────────────────────────────────
def create_restore_point():
    desc = f"SabinaOptimizer_{datetime.datetime.now():%Y%m%d_%H%M%S}"
    # Intentar metodo directo primero (mas compatible)
    ps_direct = f"Checkpoint-Computer -Description '{desc}' -RestorePointType MODIFY_SETTINGS -EA SilentlyContinue"
    try:
        r = subprocess.run(["powershell", "-NoProfile", "-Command", ps_direct],
                           capture_output=True, text=True, timeout=60)
        if r.returncode == 0:
            return (True, f"Punto de restauracion '{desc}' creado correctamente")
    except subprocess.TimeoutExpired:
        return (False, "Timeout al crear punto de restauracion")
    except:
        pass
    # Fallback: intentar con WMI
    ps_wmi = (
        "$sr = Get-CimInstance -ClassName SystemRestore -Filter \"Drive='C'\" -ErrorAction SilentlyContinue; "
        f"Checkpoint-Computer -Description '{desc}' -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue"
    )
    try:
        r = subprocess.run(["powershell", "-NoProfile", "-Command", ps_wmi],
                           capture_output=True, text=True, timeout=60)
        if r.returncode == 0:
            return (True, f"Punto de restauracion '{desc}' creado correctamente")
        err = r.stderr.strip()
        if "0x80041010" in err:
            return (False, "Restaurar sistema no esta disponible. Activalo desde 'Crear punto de restauracion' en Windows.")
        return (False, err or "Error desconocido")
    except subprocess.TimeoutExpired:
        return (False, "Timeout al crear punto de restauracion")
    except Exception as e:
        return (False, f"No se pudo crear: {e}")

# ── Log ─────────────────────────────────────────────────────────────
def write_log(msg):
    t = datetime.datetime.now().strftime("%H:%M:%S")
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(f"[{t}] {msg}\n")

# ═══════════════════════════════════════════════════════════════════
#  GUI
# ═══════════════════════════════════════════════════════════════════

CAT_COLORS = {"Essential": "#22c55e", "Pro": "#3b82f6", "Elite": ACCENT}
RISK_COLORS = {"Bajo": GREEN, "Medio": "#eab308"}
PLAN_COLORS = {"essential": "#22c55e", "pro": "#3b82f6", "elite": ACCENT}
PLAN_RANKS  = {"essential": 1, "pro": 2, "elite": 3}

class SabinaApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Sabina Optimizer")
        self.root.configure(bg=BG)
        self.root.resizable(False, False)
        self.root.attributes("-topmost", True)
        self.root.attributes("-topmost", False)

        win_w, win_h = 1100, 740
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        self.root.geometry(f"{win_w}x{win_h}+{(sw-win_w)//2}+{(sh-win_h)//2}")

        self.current_cat = "All"
        self.checkboxes = {}
        self.script_details = {}
        self.running = False
        self.cat_buttons = {}

        self._build_title_bar()
        self._build_license_bar()
        self._build_category_bar()
        self._build_cards_area()
        self._build_console()
        self._build_bottom_bar()

        self.lic_entry.focus_set()

        if IS_DEV_MODE:
            global user_plan
            user_plan = "elite"

        stored = get_stored_license()
        if stored:
            self.lic_entry.delete(0, tk.END)
            self.lic_entry.insert(0, stored)
            self._do_validate(stored)

        self._show_category("All")
        self.root.mainloop()

    # ── Helpers ─────────────────────────────────────────────────────
    def _lbl(self, parent, text, fg=TEXT, size=12, bold=False, bg=BG):
        w = "bold" if bold else "normal"
        return tk.Label(parent, text=text, fg=fg, bg=bg,
                        font=("Segoe UI", size, w), anchor="w")

    def _btn(self, parent, text, cmd, bg=CARD2, fg=TEXT, size=12, bold=False):
        w = "bold" if bold else "normal"
        return tk.Button(parent, text=text, command=cmd, bg=bg, fg=fg,
                         font=("Segoe UI", size, w), relief="flat", bd=0,
                         activebackground=BORDER, activeforeground=TEXT,
                         cursor="hand2")

    def _can_access(self, opt):
        if IS_DEV_MODE:
            return True
        ur = PLAN_RANKS.get(user_plan, 0)
        or_ = PLAN_RANKS.get(opt["category"].lower(), 0)
        return ur >= or_

    # ── Title Bar ───────────────────────────────────────────────────
    def _build_title_bar(self):
        bar = tk.Frame(self.root, bg="#0f0f1a", height=44)
        bar.place(x=0, y=0, width=1100, height=44)
        bar.pack_propagate(False)
        self._lbl(bar, "Sabina Optimizer v4.0", ACCENT, 16, True,
                  "#0f0f1a").place(x=10, y=8)
        tk.Button(bar, text="X", command=self.root.destroy,
                  bg="#0f0f1a", fg=TEXT2, font=("Segoe UI", 11, "bold"),
                  relief="flat", bd=0, activebackground=RED,
                  activeforeground=TEXT, cursor="hand2"
                  ).place(x=1060, y=8, width=30, height=28)

    # ── License Bar ─────────────────────────────────────────────────
    def _build_license_bar(self):
        bar = tk.Frame(self.root, bg="#141428", height=44)
        bar.place(x=0, y=44, width=1100, height=44)
        bar.pack_propagate(False)

        # Separator lines
        tk.Frame(bar, bg="#2a2a3a", height=1).place(x=0, y=0, width=1100)
        tk.Frame(bar, bg="#2a2a3a", height=1).place(x=0, y=43, width=1100)

        tk.Label(bar, text="Clave:", fg=TEXT2, bg="#141428",
                 font=("Segoe UI", 12)).place(x=12, y=8, width=50, height=28)

        self.lic_entry = tk.Entry(bar, bg="#1a1a2e", fg=TEXT,
                                   font=("Segoe UI", 12),
                                   relief="solid", bd=1,
                                   highlightbackground="#3a3a5a",
                                   highlightcolor=ACCENT,
                                   insertbackground=TEXT)
        self.lic_entry.place(x=65, y=6, width=240, height=32)

        self.lic_btn = self._btn(bar, "Validar", self._on_validate,
                                  ACCENT, bold=True, size=12)
        self.lic_btn.place(x=312, y=6, width=90, height=32)

        self.lic_status = self._lbl(bar, "Ingresa tu license key", TEXT2,
                                     12, False, "#141428")
        self.lic_status.place(x=415, y=8, width=220, height=28)

        self.plan_badge = tk.Label(bar, text="SIN LICENCIA", fg=TEXT, bg="#444",
                                    font=("Segoe UI", 11, "bold"))
        self.plan_badge.place(x=920, y=7, width=140, height=28)

    def _on_validate(self):
        key = self.lic_entry.get().strip()
        if key:
            self.lic_status.config(text="Validando...", fg=TEXT2)
            self.root.update()
            self._do_validate(key)

    def _do_validate(self, key):
        global user_plan
        plan = validate_license(key)
        if plan:
            user_plan = plan
            save_license(key)
            c = PLAN_COLORS.get(plan, RED)
            self.plan_badge.config(text=f"PLAN {plan.upper()}", bg=c)
            self.lic_status.config(text="OK! Licencia activa", fg=GREEN)
            self._show_category(self.current_cat)
        else:
            self.lic_status.config(text="Licencia invalida", fg=RED)

    # ── Category Bar ────────────────────────────────────────────────
    def _build_category_bar(self):
        bar = tk.Frame(self.root, bg=BG, height=36)
        bar.place(x=0, y=88, width=1100, height=36)
        bar.pack_propagate(False)
        counts = {"All": len(optimizations)}
        for c in ("Essential", "Pro", "Elite"):
            counts[c] = sum(1 for o in optimizations if o["category"] == c)
        for i, name in enumerate(("All", "Essential", "Pro", "Elite")):
            label = f"{name} ({counts[name]})" if name != "All" else f"Todo ({counts['All']})"
            btn = self._btn(bar, label, lambda n=name: self._on_cat(n),
                             CARD2, TEXT2, 11)
            btn.place(x=i*200, y=3, width=170, height=30)
            self.cat_buttons[name] = btn

    def _on_cat(self, name):
        self.current_cat = name
        self._show_category(name)

    # ── Scrollable Cards ────────────────────────────────────────────
    def _build_cards_area(self):
        c = tk.Frame(self.root, bg=BG)
        c.place(x=10, y=128, width=1080, height=400)
        self.canvas = tk.Canvas(c, bg=BG, highlightthickness=0)
        sb = tk.Scrollbar(c, orient="vertical", command=self.canvas.yview)
        self.card_frame = tk.Frame(self.canvas, bg=BG)
        self.card_frame.bind("<Configure>",
            lambda e: self.canvas.configure(
                scrollregion=self.canvas.bbox("all")))
        self.canvas.create_window((0, 0), window=self.card_frame,
                                   anchor="nw", width=1060)
        self.canvas.configure(yscrollcommand=sb.set)
        self.canvas.pack(side="left", fill="both", expand=True)
        sb.pack(side="right", fill="y")
        # Mouse wheel
        def _mw(e):
            self.canvas.yview_scroll(-1*(e.delta//120), "units")
        self.canvas.bind_all("<MouseWheel>", _mw)

    def _build_card(self, opt):
        f = tk.Frame(self.card_frame, bg=CARD, height=76)
        f.pack(fill="x", pady=4)
        f.pack_propagate(False)

        locked = not self._can_access(opt)

        var = tk.BooleanVar()
        cb = tk.Checkbutton(f, variable=var, bg=CARD, activebackground=CARD,
                             fg=TEXT, selectcolor=CARD,
                             disabledforeground=TEXT2)
        cb.place(x=8, y=5, width=20, height=60)
        if locked:
            cb.config(state="disabled")
        self.checkboxes[opt["id"]] = (var, cb)

        # Category badge
        tk.Label(f, text=opt["category"], fg=TEXT,
                 bg=CAT_COLORS.get(opt["category"], RED),
                 font=("Segoe UI", 9, "bold")
                 ).place(x=700, y=8, width=72, height=20)
        # Risk badge
        tk.Label(f, text=opt["risk"], fg="#000",
                 bg=RISK_COLORS.get(opt["risk"], RED),
                 font=("Segoe UI", 9, "bold")
                 ).place(x=780, y=8, width=48, height=20)

        self._lbl(f, opt["name"], TEXT, 12, True, CARD
                  ).place(x=32, y=6, width=500, height=24)
        self._lbl(f, opt["desc"], TEXT2, 10, False, CARD
                  ).place(x=32, y=32, width=660, height=20)

        # Script toggle
        self._btn(f, "Script", lambda o=opt: self._toggle_script(o),
                  CARD2, TEXT2, 10).place(x=850, y=8, width=60, height=20)

        # Script detail (hidden)
        dtxt = "\n".join(f"PS> {c}" for c in opt["commands"])
        detail = tk.Text(f, bg=DARK_INPUT, fg="#22d3ee",
                          font=("Consolas", 10), relief="flat",
                          height=len(opt["commands"]), wrap="none")
        detail.insert("1.0", dtxt)
        detail.config(state="disabled")
        self.script_details[opt["id"]] = detail

    def _toggle_script(self, opt):
        d = self.script_details.get(opt["id"])
        if d is None:
            return
        if d.winfo_viewable():
            d.pack_forget()
        else:
            d.pack(fill="x", padx=610, pady=(0, 4))

    def _show_category(self, cat):
        self.current_cat = cat
        for name, btn in self.cat_buttons.items():
            btn.config(bg="#2a2a3a" if name == cat else CARD2,
                       fg=TEXT if name == cat else TEXT2)
        for w in self.card_frame.winfo_children():
            w.destroy()
        self.checkboxes.clear()
        self.script_details.clear()
        for opt in optimizations:
            if cat != "All" and opt["category"] != cat:
                continue
            self._build_card(opt)
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    # ── Console ─────────────────────────────────────────────────────
    def _build_console(self):
        p = tk.Frame(self.root, bg=BG)
        p.place(x=10, y=532, width=1080, height=150)
        self._lbl(p, "Consola de salida", TEXT2, 10, False,
                  "#141428").place(x=0, y=0, width=1080, height=26)

        self.output = tk.Text(p, bg=DARK_INPUT, fg="#00ff88",
                               font=("Consolas", 12), relief="flat",
                               state="disabled", wrap="word")
        self.output.place(x=2, y=26, width=1076, height=122)
        sb = tk.Scrollbar(p, orient="vertical", command=self.output.yview)
        sb.place(x=1058, y=26, width=18, height=122)
        self.output.config(yscrollcommand=sb.set)
        self.output.tag_config("ok", foreground=GREEN)
        self.output.tag_config("err", foreground=RED)
        self.output.tag_config("info", foreground="#22d3ee")
        self.output.tag_config("hdr", foreground=ACCENT)

    def _log(self, msg, tag=None):
        self.output.config(state="normal")
        self.output.insert(tk.END, msg + "\n", tag) if tag else self.output.insert(tk.END, msg + "\n")
        self.output.see(tk.END)
        self.output.config(state="disabled")
        self.root.update()

    def _clear(self):
        self.output.config(state="normal")
        self.output.delete("1.0", tk.END)
        self.output.config(state="disabled")

    # ── Bottom Bar ──────────────────────────────────────────────────
    def _build_bottom_bar(self):
        bar = tk.Frame(self.root, bg="#141428", height=50)
        bar.place(x=0, y=690, width=1100, height=50)
        bar.pack_propagate(False)

        self._btn(bar, "Seleccionar todo", self._sel_all, CARD2
                  ).place(x=20, y=8, width=140, height=34)
        self._btn(bar, "Deseleccionar todo", self._des_all, CARD2
                  ).place(x=170, y=8, width=140, height=34)
        self._btn(bar, "Punto restauracion", self._restore, CARD2
                  ).place(x=330, y=8, width=150, height=34)
        self._btn(bar, "Ejecutar seleccionadas", self._run, ACCENT,
                  bold=True).place(x=690, y=6, width=180, height=38)
        self._btn(bar, "EJECUTAR TODO", self._run_all, ACCENT2,
                  "#000", bold=True).place(x=880, y=6, width=160, height=38)

    def _sel_all(self):
        for var, cb in self.checkboxes.values():
            var.set(True)

    def _des_all(self):
        for var, cb in self.checkboxes.values():
            var.set(False)

    def _restore(self):
        self._clear()
        self._log("Creando punto de restauracion...", "info")
        self.root.update()
        ok, msg = create_restore_point()
        self._log(f"  {'OK' if ok else 'ERROR'}: {msg}", "ok" if ok else "err")

    def _run(self):
        if self.running:
            return
        sel = [o for o in optimizations if o["id"] in self.checkboxes
               and self.checkboxes[o["id"]][0].get()
               and self.checkboxes[o["id"]][1].cget("state") != "disabled"]
        if not sel:
            self._log("No seleccionaste ninguna optimizacion.", "err")
            return
        self._confirm(sel)

    def _run_all(self):
        if self.running:
            return
        sel = [o for o in optimizations if o["id"] in self.checkboxes
               and self.checkboxes[o["id"]][1].cget("state") != "disabled"]
        if not sel:
            self._log("No hay optimizaciones disponibles.", "err")
            return
        self._confirm(sel)

    def _confirm(self, sel):
        ans = messagebox.askyesnocancel(
            "Restaurar Sistema",
            "RECOMENDADO: Crear un punto de restauracion antes de continuar?\n\n"
            "Esto permite deshacer todos los cambios si algo falla.")
        if ans is None:
            return
        if ans:
            self._clear()
            self._log("Creando punto de restauracion...", "info")
            self.root.update()
            ok, msg = create_restore_point()
            self._log(f"  {msg}", "ok" if ok else "err")
            self._log("-"*40, "hdr")
        t = threading.Thread(target=self._worker, args=(sel,), daemon=True)
        self.running = True
        t.start()

    def _worker(self, sel):
        self.root.after(0, lambda: self._log(f"Ejecutando {len(sel)} optimizaciones...", "hdr"))
        self.root.after(0, lambda: self._log("-"*40, "hdr"))
        for i, opt in enumerate(sel):
            self.root.after(0, lambda n=opt["name"]: self._log(f"> {n}...", "info"))
            for cmd in opt["commands"]:
                try:
                    r = subprocess.run(["powershell", "-NoProfile", "-Command", cmd],
                                       capture_output=True, text=True, timeout=120)
                    out = r.stdout.strip() or r.stderr.strip() or "OK"
                    write_log(f"  OK: {out}")
                    self.root.after(0, lambda m=out: self._log(f"  OK: {m}", "ok"))
                except subprocess.TimeoutExpired:
                    write_log(f"  TIMEOUT: {cmd[:50]}")
                    self.root.after(0, lambda: self._log("  TIMEOUT", "err"))
                except Exception as e:
                    write_log(f"  ERROR: {e}")
                    self.root.after(0, lambda m=str(e): self._log(f"  ERROR: {m}", "err"))
                time.sleep(0.05)
        self.root.after(0, lambda: self._log("-"*40, "hdr"))
        self.root.after(0, lambda: self._log("Optimizaciones completadas", "ok"))
        self.root.after(0, lambda: self._log(f"Log: {LOG_PATH}", "info"))
        self.running = False

if __name__ == "__main__":
    SabinaApp()
