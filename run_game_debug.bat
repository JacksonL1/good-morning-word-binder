@echo off
setlocal EnableExtensions
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
cd /d "%PROJECT_DIR%"

rem Keep Godot's user:// (logs, shader cache) inside the project. This makes
rem the launcher work even when %APPDATA% is not writable (restricted user,
rem sandbox, company policy) instead of crashing with 0xC0000005.
set "USERDATA_DIR=%PROJECT_DIR%\.godot_userdata"
if not exist "%USERDATA_DIR%" mkdir "%USERDATA_DIR%" 2>nul
if not exist "%USERDATA_DIR%" (
    set "USERDATA_DIR=%TEMP%\GoodMorningUserData"
    mkdir "%USERDATA_DIR%" 2>nul
)
if not exist "%USERDATA_DIR%\.gdignore" type nul > "%USERDATA_DIR%\.gdignore"
set "APPDATA=%USERDATA_DIR%"

set "GODOT=%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64_console.exe"
if not exist "%GODOT%" set "GODOT=%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe"
if not exist "%GODOT%" (
    echo Godot not found at %PROJECT_DIR%\.tools\godot\
    pause
    exit /b 1
)

echo Running with console output (close the game window to return)...
echo User data: %APPDATA%\Godot
if not exist "%PROJECT_DIR%\.godot\imported" (
    echo First run: importing assets...
    "%GODOT%" --headless --path "%PROJECT_DIR%" --import
)
"%GODOT%" --path "%PROJECT_DIR%"
echo.
echo Exit code: %ERRORLEVEL%
pause
