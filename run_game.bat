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

rem Locate the Godot binary. Any Godot 4.x build works, so the version in the
rem file name is NOT hardcoded. Order:
rem   1. .tools\godot\godot_path.txt (optional, one full path per line)
rem   2. %PROJECT_DIR%\.tools\godot\Godot*win64.exe
rem   3. Program Files / LocalAppData install dirs
rem   4. "godot" on PATH
set "GODOT="
set "PF86=%ProgramFiles(x86)%"

if exist "%PROJECT_DIR%\.tools\godot\godot_path.txt" (
    for /f "usebackq delims=" %%p in ("%PROJECT_DIR%\.tools\godot\godot_path.txt") do (
        if not defined GODOT if exist "%%~p" set "GODOT=%%~p"
    )
)

call :scan_godot "%PROJECT_DIR%\.tools\godot"
call :scan_godot "%ProgramFiles%\Godot"
call :scan_godot "%PF86%\Godot"
call :scan_godot "%LOCALAPPDATA%\Programs\Godot"

if not defined GODOT (
    for /f "delims=" %%i in ('where godot 2^>nul') do (
        if not defined GODOT set "GODOT=%%i"
    )
)
:found

if not defined GODOT (
    echo Godot executable not found.
    echo Install Godot 4.x, or drop the .exe into:
    echo   %PROJECT_DIR%\.tools\godot\
    echo Any file named Godot*win64.exe in that folder is picked up automatically.
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

rem Set GMWB_NO_LAUNCH=1 to only test the Godot detection, without starting the game.
if defined GMWB_NO_LAUNCH exit /b 0

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
exit /b 0

rem ---------------------------------------------------------------------------
rem :scan_godot <dir>  -  set GODOT to the first Godot*win64.exe found under <dir>
rem Skips *_console.exe (the console build is only used by the debug launcher).
rem ---------------------------------------------------------------------------
:scan_godot
if defined GODOT goto :eof
if not exist "%~1" goto :eof
for /f "delims=" %%f in ('dir /b /a-d /s "%~1\Godot*win64.exe" 2^>nul') do (
    if not defined GODOT (
        echo %%~nxf | findstr /i /c:"console" >nul || set "GODOT=%%f"
    )
)
goto :eof
