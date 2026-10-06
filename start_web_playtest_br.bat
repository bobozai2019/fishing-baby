@echo off
setlocal
chcp 65001 >nul

set "PROJECT_ROOT=%~dp0"
set "WEB_DIR=%PROJECT_ROOT%build\web_playtest_br"
set "SERVER_SCRIPT=%PROJECT_ROOT%tools\serve_web.py"
set "PORT=8012"

if not exist "%WEB_DIR%\index.html.br" (
    echo [start] Brotli release not found: %WEB_DIR%
    echo [start] Run build.bat first.
    pause
    exit /b 1
)

if not exist "%SERVER_SCRIPT%" (
    echo [start] Server script not found: %SERVER_SCRIPT%
    pause
    exit /b 1
)

set "PYTHON_EXE=%PROJECT_ROOT%tools\.build_venv\Scripts\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=python"

echo [start] Opening http://127.0.0.1:%PORT%/index.html
echo [start] Press Ctrl+C or close this window to stop the server.
"%PYTHON_EXE%" "%SERVER_SCRIPT%" --directory "%WEB_DIR%" --port "%PORT%" --open-browser

if errorlevel 1 pause
exit /b %errorlevel%
