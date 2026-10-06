@echo off
setlocal
chcp 65001 >nul

set "PROJECT_ROOT=%~dp0"
set "BUILD_VENV=%PROJECT_ROOT%tools\.build_venv"
set "BUILD_PYTHON=%BUILD_VENV%\Scripts\python.exe"
set "OUTPUT_DIR=%PROJECT_ROOT%build\web_playtest"
set "PUBLISH_DIR=%PROJECT_ROOT%build\web_playtest_br"
set "TEMPLATE_PATH=%PROJECT_ROOT%tools\web_templates\godot-4.7.1-2d-release.zip"
set "TEMPLATE_PROVENANCE=%PROJECT_ROOT%tools\web_templates\godot-4.7.1-2d.provenance.json"
set "TEMPLATE_PROFILE=%PROJECT_ROOT%tools\godot_web_template\fishing_baby_2d.gdbuild"
set "EXPORT_PRESET=Web"
set "TEMPLATE_KIND=custom_release"
set "USE_BROTLI=1"

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--stock" (
    set "EXPORT_PRESET=Web Stock"
    set "TEMPLATE_KIND=stock"
    shift
    goto :parse_args
)
if /i "%~1"=="--no-brotli" (
    set "USE_BROTLI=0"
    shift
    goto :parse_args
)
echo [build] Unknown argument: %~1
goto :fail

:args_done

if not exist "%BUILD_PYTHON%" (
    echo [build] Creating the build Python environment...
    python -m venv "%BUILD_VENV%"
    if errorlevel 1 goto :fail
)

"%BUILD_PYTHON%" -c "import importlib.metadata as m; raise SystemExit(m.version('fonttools') != '4.63.0' or m.version('Brotli') != '1.1.0')" >nul 2>&1
if errorlevel 1 (
    echo [build] Installing pinned font and Brotli dependencies...
    "%BUILD_PYTHON%" -m pip install --disable-pip-version-check fonttools==4.63.0 Brotli==1.1.0
    if errorlevel 1 goto :fail
)

echo [build] Generating the runtime font subset...
"%BUILD_PYTHON%" "%PROJECT_ROOT%tools\subset_font.py" --project-root "%PROJECT_ROOT%."
if errorlevel 1 goto :fail

if /i "%TEMPLATE_KIND%"=="custom_release" (
    echo [build] Verifying the custom Web template...
    "%BUILD_PYTHON%" "%PROJECT_ROOT%tools\web_package.py" verify-template --template "%TEMPLATE_PATH%" --provenance "%TEMPLATE_PROVENANCE%" --profile "%TEMPLATE_PROFILE%"
    if errorlevel 1 goto :fail
)

set "GODOT_BIN=%GODOT_EXE%"
if not defined GODOT_BIN if exist "D:\godot\Godot_v4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe" set "GODOT_BIN=D:\godot\Godot_v4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe"
if not defined GODOT_BIN for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT_BIN set "GODOT_BIN=%%G"

if not defined GODOT_BIN (
    echo [build] Godot was not found. Set GODOT_EXE to the Godot 4.7 console executable.
    goto :fail
)

if /i not "%OUTPUT_DIR%"=="%PROJECT_ROOT%build\web_playtest" (
    echo [build] Refusing to clean an unexpected output path: %OUTPUT_DIR%
    goto :fail
)
if /i not "%PUBLISH_DIR%"=="%PROJECT_ROOT%build\web_playtest_br" (
    echo [build] Refusing to clean an unexpected publish path: %PUBLISH_DIR%
    goto :fail
)

if exist "%OUTPUT_DIR%" (
    echo [build] Cleaning %OUTPUT_DIR%...
    rmdir /s /q "%OUTPUT_DIR%"
    if exist "%OUTPUT_DIR%" goto :fail
)
mkdir "%OUTPUT_DIR%"
if errorlevel 1 goto :fail
if exist "%PUBLISH_DIR%" (
    echo [build] Cleaning %PUBLISH_DIR%...
    rmdir /s /q "%PUBLISH_DIR%"
    if exist "%PUBLISH_DIR%" goto :fail
)

echo [build] Exporting preset "%EXPORT_PRESET%" with template_kind=%TEMPLATE_KIND%...
"%BUILD_PYTHON%" "%PROJECT_ROOT%tools\export_godot_web.py" --project-root "%PROJECT_ROOT%." --godot "%GODOT_BIN%" --preset "%EXPORT_PRESET%" --output "%OUTPUT_DIR%\index.html" --template "%TEMPLATE_PATH%"
if errorlevel 1 goto :fail

set "PACKAGE_BROTLI_ARG="
if "%USE_BROTLI%"=="1" set "PACKAGE_BROTLI_ARG=--brotli"
echo [build] Packaging Web output...
"%BUILD_PYTHON%" "%PROJECT_ROOT%tools\web_package.py" package --directory "%OUTPUT_DIR%" --template-kind "%TEMPLATE_KIND%" %PACKAGE_BROTLI_ARG%
if errorlevel 1 goto :fail

if "%USE_BROTLI%"=="1" (
    echo [build] Creating Brotli-only release directory...
    "%BUILD_PYTHON%" "%PROJECT_ROOT%tools\web_package.py" publish-br --source "%OUTPUT_DIR%" --destination "%PUBLISH_DIR%"
    if errorlevel 1 goto :fail
    echo [build] Removing Brotli files from the raw release directory...
    "%BUILD_PYTHON%" "%PROJECT_ROOT%tools\web_package.py" finalize-split --source "%OUTPUT_DIR%" --destination "%PUBLISH_DIR%"
    if errorlevel 1 goto :fail
)

echo [build] Output files:
for %%F in ("%OUTPUT_DIR%\index.wasm" "%OUTPUT_DIR%\index.pck" "%OUTPUT_DIR%\index.js") do if exist "%%~F" echo   %%~nxF: %%~zF bytes
echo [build] Raw Web release completed: %OUTPUT_DIR%
if "%USE_BROTLI%"=="1" echo [build] Brotli Web release completed: %PUBLISH_DIR%
exit /b 0

:fail
echo [build] Failed.
exit /b 1
