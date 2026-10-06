@echo off
setlocal
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR=%SCRIPT_DIR%godot"
set "PROFILE=%SCRIPT_DIR%fishing_baby_2d.gdbuild"
set "OUTPUT_DIR=%SCRIPT_DIR%..\web_templates"
set "EMSDK_DIR=%GODOT_WEB_EMSDK%"
if not defined EMSDK_DIR set "EMSDK_DIR=D:\godot\emsdk"

if not exist "%SOURCE_DIR%\.git" (
    echo [template] Missing clean Godot source: %SOURCE_DIR%
    exit /b 1
)
if not exist "%PROFILE%" (
    echo [template] Missing build profile: %PROFILE%
    exit /b 1
)
if not exist "%EMSDK_DIR%\emsdk_env.bat" (
    echo [template] Missing Emscripten SDK: %EMSDK_DIR%
    exit /b 1
)

for /f %%C in ('git -C "%SOURCE_DIR%" status --porcelain') do (
    echo [template] Refusing to build from a dirty Godot source tree.
    exit /b 1
)
for /f %%C in ('git -C "%SOURCE_DIR%" rev-parse HEAD') do set "SOURCE_COMMIT=%%C"
if /i not "%SOURCE_COMMIT%"=="a13da4feb8d8aefc283c3763d33a2f170a18d541" (
    echo [template] Unexpected Godot source commit: %SOURCE_COMMIT%
    exit /b 1
)

call "%EMSDK_DIR%\emsdk_env.bat" >nul
if errorlevel 1 exit /b 1

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
echo [template] Building Godot 4.7.1 pure-2D Web release template...
scons -C "%SOURCE_DIR%" -j%NUMBER_OF_PROCESSORS% platform=web target=template_release production=yes optimize=size_extra lto=full threads=no dlink_enabled=no deprecated=no debug_symbols=no build_profile="%PROFILE%"
if errorlevel 1 exit /b 1

set "BUILT_ZIP=%SOURCE_DIR%\bin\godot.web.template_release.wasm32.nothreads.zip"
if not exist "%BUILT_ZIP%" (
    echo [template] Expected template zip not found: %BUILT_ZIP%
    exit /b 1
)
copy /y "%BUILT_ZIP%" "%OUTPUT_DIR%\godot-4.7.1-2d-release.zip" >nul
if errorlevel 1 exit /b 1

echo [template] Completed: %OUTPUT_DIR%\godot-4.7.1-2d-release.zip
exit /b 0
