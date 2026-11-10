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

rem Locate Godot, preferring the *_console build so engine output stays visible.
rem Any Godot 4.x build is accepted; the version in the file name is not hardcoded.
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

rem Switch to the console twin when it exists (same folder, _console suffix).
if defined GODOT call :prefer_console "%GODOT%"

if not defined GODOT (
    echo Godot executable not found.
    echo Put any Godot 4.x Godot*win64.exe into %PROJECT_DIR%\.tools\godot\
    pause
    exit /b 1
)

echo Running with console output (close the game window to return)...
echo Godot: %GODOT%
echo User data: %APPDATA%\Godot
rem Set GMWB_NO_LAUNCH=1 to only test the Godot detection, without starting the game.
if defined GMWB_NO_LAUNCH exit /b 0
if not exist "%PROJECT_DIR%\.godot\imported" (
    echo First run: importing assets...
    "%GODOT%" --headless --path "%PROJECT_DIR%" --import
)
"%GODOT%" --path "%PROJECT_DIR%"
echo.
echo Exit code: %ERRORLEVEL%
pause
exit /b 0

rem ---------------------------------------------------------------------------
rem :scan_godot <dir>  -  set GODOT to the first Godot*win64*.exe found under <dir>
rem ---------------------------------------------------------------------------
:scan_godot
if defined GODOT goto :eof
if not exist "%~1" goto :eof
for /f "delims=" %%f in ('dir /b /a-d /s "%~1\Godot*win64*.exe" 2^>nul') do (
    if not defined GODOT set "GODOT=%%f"
)
goto :eof

rem ---------------------------------------------------------------------------
rem :prefer_console <exe>  -  switch to the *_console.exe twin when present
rem ---------------------------------------------------------------------------
:prefer_console
if not exist "%~dpn1_console.exe" goto :eof
set "GODOT=%~dpn1_console.exe"
goto :eof
