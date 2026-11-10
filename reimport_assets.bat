@echo off
setlocal EnableExtensions
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
cd /d "%PROJECT_DIR%"

set "GODOT="
if exist "%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64_console.exe" set "GODOT=%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64_console.exe"
if not defined GODOT if exist "%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe" set "GODOT=%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.3-stable_win64_console.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.3-stable_win64_console.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.3-stable_win64.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.3-stable_win64.exe"
if not defined GODOT (
    for /f "delims=" %%i in ('where godot 2^>nul') do (
        set "GODOT=%%i"
        goto :found
    )
)
:found

if not defined GODOT (
    echo Godot executable not found.
    echo Install Godot 4.3 or newer, or put it at .tools\godot\
    pause
    exit /b 1
)

echo Reimporting assets for "%PROJECT_DIR%" ...
echo Godot: "%GODOT%"
"%GODOT%" --headless --path "%PROJECT_DIR%" --import
echo.
echo Done. Check the log above for "ERROR" or "Failed to load".
pause
