@echo off
title OpenCode + Ollama Local IA
color 0A

echo ==========================================
echo      INICIANDO OLLAMA + OPENCODE
echo ==========================================
echo.

:: Verifica si Ollama esta instalado
where ollama >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Ollama no esta instalado.
    echo Descargalo desde:
    echo https://ollama.com
    pause
    exit
)

:: Verifica si OpenCode esta instalado
where opencode >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: OpenCode no esta instalado.
    echo Instalalo con:
    echo curl -fsSL https://opencode.ai/install ^| bash
    pause
    exit
)

echo Iniciando servidor Ollama...
start /min cmd /c "ollama serve"

timeout /t 5 >nul

echo.
echo Verificando modelo qwen2.5-coder:7b...
ollama list | findstr "qwen2.5-coder:7b" >nul

if %errorlevel% neq 0 (
    echo.
    echo Modelo no encontrado.
    echo Descargando qwen2.5-coder:7b...
    ollama pull qwen2.5-coder:7b
)

echo.
echo ==========================================
echo        TODO LISTO
echo ==========================================
echo.

:: Entrar en carpeta actual
cd /d "%~dp0"

:: Ejecutar OpenCode usando Ollama
set OPENAI_BASE_URL=http://127.0.0.1:11434/v1
set OPENAI_API_KEY=ollama

echo Abriendo OpenCode...
echo.

opencode

pause