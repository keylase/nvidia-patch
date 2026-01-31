# NVFBC DLL patch script
# Requires administrator privileges to run
Function Test-Administrator {
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
} #end function Test-Administrator
Function Test-CommandExist {
    Param ($Command)
    $OldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try { if (Get-Command $Command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $OldPreference }
} #end function Test-CommandExist
If (Test-CommandExist pwsh.exe) {
    $pwsh = "pwsh.exe"
}
Else {
    $pwsh = "powershell.exe"
}
If (-Not (Test-Administrator)) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
    $Proc = Start-Process -PassThru -Verb RunAs $pwsh -Args "-ExecutionPolicy Bypass -Command Set-Location '$PSScriptRoot'; &'$PSCommandPath' EVAL"
    If ($null -Ne $Proc) {
        $Proc.WaitForExit()
    }
    If ($null -Eq $Proc -Or $Proc.ExitCode -Ne 0) {
        Write-Warning "Failed to launch start as Administrator`r`nPress any key to exit"
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
    exit
}
ElseIf (($args.Count -Eq 1) -And ($args[0] -Eq "EVAL")) {
    Start-Process $pwsh -NoNewWindow -Args "-ExecutionPolicy Bypass -Command Set-Location '$PSScriptRoot'; &'$PSCommandPath'"
    exit
}
Function Unlock-DLL {
    param (
        [string]$filePath
    )

    # Check if the file exists
    if (-Not (Test-Path -Path $filePath)) {
        Write-Error "The specified file does not exist."
        exit
    }

    Write-Information "Unlocking file: $filePath"

    # Get the file security object
    $fileSecurity = Get-Acl -Path $filePath

    # Set the owner to "Administrators"
    $administrators = [System.Security.Principal.NTAccount]"Administrators"
    $fileSecurity.SetOwner($administrators)

    # Apply the new owner to the file
    Set-Acl -Path $filePath -AclObject $fileSecurity

    # Define a new access rule for "Administrators" with full control
    $administratorsRights = [System.Security.AccessControl.FileSystemRights]::FullControl
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($administrators, $administratorsRights, [System.Security.AccessControl.InheritanceFlags]::None, [System.Security.AccessControl.PropagationFlags]::None, [System.Security.AccessControl.AccessControlType]::Allow)

    # Add the new access rule to the file security object
    $fileSecurity.AddAccessRule($accessRule)

    # Apply the updated security settings to the file
    Set-Acl -Path $filePath -AclObject $fileSecurity

    Write-Information "Owner changed to 'Administrators' and full control permissions granted to 'Administrators' for file: $filePath"
} #end function Unlock-DLL
Write-Information "Staring NVFBC DLL patch..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$system32Path = "$env:WINDIR\system32"
$sysWOW64Path = "$env:WINDIR\SysWOW64"

$originalNvFBC64 = "$system32Path\NvFBC64.dll"
$originalNvFBC32 = "$sysWOW64Path\NvFBC.dll"

$backupNvFBC64 = "$system32Path\NvFBC64_.dll"
$backupNvFBC32 = "$sysWOW64Path\NvFBC_.dll"

$wrapperNvFBC64 = "$scriptDir\nvfbcwrp64.dll"
$wrapperNvFBC32 = "$scriptDir\nvfbcwrp32.dll"

try {
    # Step 1: Backup NvFBC64.dll
    if (Test-Path $originalNvFBC64) {
        Write-Information "Rename $originalNvFBC64 to $backupNvFBC64"
        Unlock-DLL $originalNvFBC64
        Move-Item -Path $originalNvFBC64 -Destination $backupNvFBC64 -Force
        Write-Information "✓ NvFBC64.dll backup completed"
    }
    else {
        Write-Warning "NvFBC64.dll not found"
    }

    # Step 2: Backup NvFBC.dll
    if (Test-Path $originalNvFBC32) {
        Write-Information "Rename $originalNvFBC32 to $backupNvFBC32"
        Unlock-DLL $originalNvFBC32
        Move-Item -Path $originalNvFBC32 -Destination $backupNvFBC32 -Force
        Write-Information "✓ NvFBC.dll backup completed"
    }
    else {
        Write-Warning "NvFBC.dll not found"
    }

    # Step 3: Copy 64-bit wrapper to system32
    if (Test-Path $wrapperNvFBC64) {
        Write-Information "Copy $wrapperNvFBC64 to $originalNvFBC64"
        Copy-Item -Path $wrapperNvFBC64 -Destination $originalNvFBC64 -Force
        Write-Information "✓ 64-bit warpper copied"
    }
    else {
        throw "nvfbcwrp64.dll not found"
    }

    # Step 4: Copy 32-bit wrapper SysWOW64
    if (Test-Path $wrapperNvFBC32) {
        Write-Information "Copy $wrapperNvFBC32 to $originalNvFBC32"
        Copy-Item -Path $wrapperNvFBC32 -Destination $originalNvFBC32 -Force
        Write-Information "✓ 32-bit wrapper copied"
    }
    else {
        throw "nvfbcwrp32.dll not found"
    }
}
catch {
    Write-Error "$($_.Exception.Message)" -ErrorAction Continue
    Write-Error "Patch install failed!" -ErrorAction Continue
    Write-Information "Rolling back changes..."
    if ((Test-Path $backupNvFBC64) -and (-not (Test-Path $originalNvFBC64))) {
        Move-Item -Path $backupNvFBC64 -Destination $originalNvFBC64 -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path $backupNvFBC32) -and (-not (Test-Path $originalNvFBC32))) {
        Move-Item -Path $backupNvFBC32 -Destination $originalNvFBC32 -Force -ErrorAction SilentlyContinue
    }
    Read-Host "Press to stop."
    exit 1
}

Write-Information "Press to stop."
pause
# End of script
