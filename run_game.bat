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

set "GODOT="
if exist "%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe" set "GODOT=%PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.3-stable_win64.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.3-stable_win64.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Programs\Godot\Godot_v4.3-stable_win64.exe" set "GODOT=%LOCALAPPDATA%\Programs\Godot\Godot_v4.3-stable_win64.exe"
if not defined GODOT (
    for /f "delims=" %%i in ('where godot 2^>nul') do (
        set "GODOT=%%i"
        goto :found
    )
)
:found

if not defined GODOT (
    echo Godot executable not found.
    echo Install Godot 4.3 or newer, or put it at:
    echo   %PROJECT_DIR%\.tools\godot\Godot_v4.3-stable_win64.exe
    echo Download: https://godotengine.org/download
    pause
    exit /b 1
)

echo ============================================================
echo  Good Morning! - Word Binder
echo  Godot:   %GODOT%
echo  Project: %PROJECT_DIR%
echo  User data: %USERDATA_DIR%\Godot
echo ============================================================

if not exist "%PROJECT_DIR%\.godot\imported" (
    echo First run: importing assets, please wait...
    "%GODOT%" --headless --path "%PROJECT_DIR%" --import
)

echo Launching game window...
echo Keep this console open (you can minimize it) until you finish playing.
echo The console staying on this line is normal: it waits for the game to close.
echo If you do not see the game window, press Alt+Tab or check the taskbar
echo for "Good Morning! - Word Binder".
rem Keep this console attached (/wait) so the game process is never orphaned.
start "" /wait /D "%PROJECT_DIR%" "%GODOT%" --path "%PROJECT_DIR%"
echo.
echo Game closed (exit code %ERRORLEVEL%).
pause
