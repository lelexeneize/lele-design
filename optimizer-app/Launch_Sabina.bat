@echo off
title Sabina Optimizer - Launcher
cd /d "%~dp0"

:: Auto-elevate to admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell start -verb runas '%0' 2>nul
    exit /b
)

:: Set PowerShell execution policy and run
echo ============================================
echo   Sabina Optimizer v1.0
echo   Iniciando...
echo ============================================
timeout /t 2 /nobreak >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SabinaOptimizer.ps1"

echo.
echo Presiona cualquier tecla para salir...
pause >nul
