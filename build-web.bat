@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

echo [build-web] Building raw and Brotli Web releases...
call "%~dp0build.bat" %*
set "BUILD_EXIT=%errorlevel%"

if not "%BUILD_EXIT%"=="0" (
    echo [build-web] Build failed.
    exit /b %BUILD_EXIT%
)

echo [build-web] Raw release:     %~dp0build\web_playtest
echo [build-web] Brotli release: %~dp0build\web_playtest_br
exit /b 0
