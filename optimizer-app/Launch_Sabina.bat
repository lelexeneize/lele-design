@echo off
title Sabina Optimizer v4.0 - Launcher
cd /d "%~dp0"

:: Auto-elevate to admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell start -verb runas '%0' 2>nul
    exit /b
)

:: Run .exe (PyInstaller) or fallback to .ps1
if exist "%~dp0SabinaOptimizer.exe" (
    start "" "%~dp0SabinaOptimizer.exe"
) else if exist "%~dp0SabinaOptimizer.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SabinaOptimizer.ps1"
) else (
    echo ERROR: No se encuentra SabinaOptimizer.exe ni .ps1
    pause
)
