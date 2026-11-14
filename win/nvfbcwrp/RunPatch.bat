@echo off
cd /d "%~dp0"
if not exist "%~dp0Patch.ps1" (
    echo "Patch.ps1" is not found next to this file.
    pause
    exit /b 1
)
REM -ExecutionPolicy Bypass applies to this process only. Scripts downloaded as a zip
REM carry the Mark-of-the-Web, so the default policy would refuse to run them.
REM The policy setting itself is not changed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch.ps1" %*
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo Patch failed with exit code %RC%. See the messages above.
    pause
)
exit /b %RC%
