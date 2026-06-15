@echo off
%~d0
cd "%~dp0"
if not exist Patch.ps1 (
    echo "Patch.ps1" is not found.
    echo Press any key to exit
    pause>nul
    exit 1
) else (
    start powershell.exe -ExecutionPolicy Bypass -File .\Patch.ps1
    exit
)
