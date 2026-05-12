@echo off
title OpenCode + Ollama + Gemma4
color 0A

echo ==========================================
echo      INICIANDO GEMMA4 LOCAL IA
echo ==========================================
echo.

:: Verifica Ollama
where ollama >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Ollama no esta instalado
    echo https://ollama.com
    pause
    exit
)

:: Verifica OpenCode
where opencode >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: OpenCode no esta instalado
    pause
    exit
)

echo Iniciando servidor Ollama...
start /min cmd /c "ollama serve"

timeout /t 5 >nul

echo.
echo Verificando modelo gemma4:latest...
ollama list | findstr "gemma4:latest" >nul

if %errorlevel% neq 0 (
    echo.
    echo Descargando modelo gemma4:latest...
    ollama pull gemma4:latest
)

echo.
echo ==========================================
echo        TODO LISTO
echo ==========================================
echo.

:: Ir a la carpeta donde esta el BAT
cd /d "%~dp0"

:: Variables para OpenCode
set OPENAI_BASE_URL=http://127.0.0.1:11434/v1
set OPENAI_API_KEY=ollama
set OPENCODE_MODEL=gemma4:latest

echo Abriendo OpenCode con Gemma4...
echo.

opencode

pause