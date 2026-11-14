# NVFBC DLL patch script. See README.md in this folder.
#
# Renames the genuine NvFBC64.dll (System32) and NvFBC.dll (SysWOW64) to
# NvFBC64_.dll / NvFBC_.dll and puts the nvfbcwrp wrappers in their place.
# The wrappers load the renamed genuine DLLs, NvFBC64_.dll / NvFBC_.dll, so keep the backups.
#
# Exit codes: 0 = patched (or already patched); 1 = refused or failed.
# A failed run rolls back every change it made.

[CmdletBinding()]
param(
    [string]$System32Path = "$env:SystemRoot\System32",
    [string]$SysWOW64Path = "$env:SystemRoot\SysWOW64",
    # No UAC relaunch and no "press Enter" prompts. For tests and already-elevated callers.
    [switch]$Unattended,
    # Escape hatch (also used by tests): skips the check that the file at the original path is the
    # genuine NVIDIA DLL (CompanyName contains 'NVIDIA'). Use only if you are sure the file is genuine.
    [switch]$SkipGenuineCheck
)

$ErrorActionPreference = 'Stop'

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
    $ErrorActionPreference = 'Stop'
    try { if (Get-Command $Command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $OldPreference }
} #end function Test-CommandExist

Function Wait-BeforeExit {
    if (-not $Unattended) { $null = Read-Host 'Press Enter to exit' }
}

# Quotes one command-line argument. Windows PowerShell 5.1 joins -ArgumentList items
# with spaces and does not quote them, so paths must be quoted here.
Function Format-Argument {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    if ($Value -eq '' -or $Value -match '[\s"]') {
        $escaped = $Value -replace '(\\*)"', '$1$1\"'   # backslashes before a quote are doubled
        $escaped = $escaped -replace '(\\+)$', '$1$1'   # ...and before the closing quote
        return '"' + $escaped + '"'
    }
    return $Value
}

# Returns the argument list for the elevated copy of this script (no string building).
Function Get-ElevationArguments {
    param(
        [Parameter(Mandatory)][string]$ScriptPath,
        [Parameter(Mandatory)][string]$System32Dir,
        [Parameter(Mandatory)][string]$SysWOW64Dir
    )
    return @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', (Format-Argument $ScriptPath),
        '-System32Path', (Format-Argument $System32Dir),
        '-SysWOW64Path', (Format-Argument $SysWOW64Dir)
    )
}

# Relaunches this script elevated (one UAC prompt) and returns the child's exit code.
Function Start-ElevatedPatch {
    $psExe = if (Test-CommandExist 'pwsh.exe') { 'pwsh.exe' } else { 'powershell.exe' }
    $argList = Get-ElevationArguments -ScriptPath $PSCommandPath -System32Dir $System32Path -SysWOW64Dir $SysWOW64Path
    if ($SkipGenuineCheck) { $argList += '-SkipGenuineCheck' }   # the elevated copy must get the same switch
    Write-Host 'Administrator rights are required. Approve the UAC prompt to continue...'
    try {
        $proc = Start-Process -FilePath $psExe -ArgumentList ($argList -join ' ') -Verb RunAs -Wait -PassThru
        $code = $proc.ExitCode
        if ($null -eq $code) { return 1 }
        return [int]$code
    }
    catch {
        Write-Host "ERROR: could not start the elevated process: $($_.Exception.Message)" -ForegroundColor Red
        Wait-BeforeExit
        return 1
    }
}

# Runs a native tool (takeown.exe, icacls.exe) and returns ExitCode and the combined stdout+stderr
# text. $ErrorActionPreference is 'Continue' only for this call: on Windows PowerShell 5.1 a native
# stderr line under 'Stop' throws before $LASTEXITCODE can be read. Callers decide ONLY on ExitCode.
# 5.1 joins -ArgumentList style arrays without quotes, so each argument is quoted there.
Function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Arguments
    )
    $prevPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $passed = @($Arguments | ForEach-Object { Format-Argument $_ })
        }
        else {
            $passed = $Arguments
        }
        $out = & $FilePath @passed 2>&1
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prevPreference }
    $text = (@($out) | ForEach-Object { "$_" }) -join "`n"
    if ($null -eq $code) { $code = 1 }   # no exit code reported: treat as failure
    return [pscustomobject]@{ ExitCode = [int]$code; Output = $text.Trim() }
}

# True when the file at $Path looks like the genuine NVIDIA DLL: the version resource CompanyName
# contains 'NVIDIA' (case-insensitive). Read-only. This is NOT an Authenticode check: the real files
# are signed by Microsoft (Windows Hardware Compatibility Publisher), not by NVIDIA.
# Returns Genuine (bool) and Found (text naming what was found, for the refusal message).
# ReadError is set (and Genuine false) when the file cannot be read at all, for example because another
# program holds it open exclusively. That is NOT the same as "no version information": the caller
# must report the read error and must not suggest reinstalling the driver.
Function Test-GenuineNvidiaDll {
    param([Parameter(Mandatory)][string]$Path)
    $company = ''
    $product = ''
    try {
        # VersionInfo returns empty strings, without an error, for a file another program holds
        # exclusively, so the file is opened first to turn that case into a read error.
        $probe = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
        $probe.Close()
        $vi = (Get-Item -LiteralPath $Path -Force).VersionInfo
        $company = [string]$vi.CompanyName
        $product = [string]$vi.ProductName
    }
    catch {
        # Use the .NET message, not the "Exception calling Open ..." wrapper that PowerShell adds.
        $msg = $_.Exception.Message
        if ($_.Exception.InnerException) { $msg = $_.Exception.InnerException.Message }
        return [pscustomobject]@{ Genuine = $false; Found = ''; ReadError = $msg }
    }
    $found = if ($company -eq '' -and $product -eq '') { 'no version information' }
             else { "CompanyName '$company', ProductName '$product'" }
    return [pscustomobject]@{ Genuine = [bool]($company -match 'NVIDIA'); Found = $found; ReadError = $null }
}

Function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

Function New-Target {
    param([string]$Name, [string]$Dir, [string]$GenuineFile, [string]$BackupFile, [string]$Wrapper)
    [pscustomobject]@{
        Name         = $Name
        Dir          = $Dir
        Original     = (Join-Path $Dir $GenuineFile)
        Backup       = (Join-Path $Dir $BackupFile)
        Temp         = (Join-Path $Dir ((Split-Path -Leaf (Join-Path $Dir $GenuineFile)) + '.nvfbcwrp-tmp'))   # wrapper copy staging name
        Wrapper      = $Wrapper
        Action       = $null   # Install | ResumeInstall | AlreadyPatched
        OriginalHash = $null
    }
}

# Decides what to do for one architecture. Read-only; throws to refuse the whole run.
Function Set-PatchPlan {
    param($Target, [switch]$SkipGenuineCheck)
    $name = $Target.Name
    $wrapperHash = Get-Sha256 -Path $Target.Wrapper
    $hasOriginal = Test-Path -LiteralPath $Target.Original -PathType Leaf
    $hasBackup = Test-Path -LiteralPath $Target.Backup -PathType Leaf

    if (-not $hasOriginal -and -not $hasBackup) {
        throw "[$name] Neither $($Target.Original) nor $($Target.Backup) exists. Nothing was changed."
    }
    if ($hasBackup -and (Get-Sha256 -Path $Target.Backup) -eq $wrapperHash) {
        throw "[$name] The backup $($Target.Backup) is the wrapper, not the genuine DLL. The wrapper copy is the file to delete. If $($Target.Original) is the genuine NVIDIA DLL (File Properties > Details: Company 'NVIDIA Corporation', Product 'NVIDIA Frame Buffer Capture Library'), keep it and delete only the WRAPPER backup $($Target.Backup), then run again. If $($Target.Original) is missing or is also a wrapper, reinstall the NVIDIA driver, then run again. Nothing was changed."
    }

    $originalHash = $null
    if ($hasOriginal) {
        try { $originalHash = Get-Sha256 -Path $Target.Original }
        catch {
            # Typically a sharing lock held by another program. Refuse before any change.
            throw "[$name] could not read $($Target.Original): $($_.Exception.Message). Close programs that use NVIDIA components and run again. Nothing was changed."
        }
    }

    if ($hasOriginal -and $originalHash -eq $wrapperHash) {
        if (-not $hasBackup) {
            throw "[$name] $($Target.Original) is already the wrapper but $($Target.Backup) is missing, so the genuine DLL cannot be restored. Nothing was changed."
        }
        $Target.Action = 'AlreadyPatched'
    }
    elseif ($hasOriginal -and $hasBackup) {
        throw "[$name] Stale backup: $($Target.Backup) exists and $($Target.Original) is not the wrapper. Check which case you have. Case (a): after a driver update, $($Target.Original) may be a NEW genuine NVIDIA DLL. First verify it: only if the NVIDIA driver was just installed or updated and NvFBC works, or the size and SHA-256 of $($Target.Original) match the driver package, MOVE the OLD BACKUP $($Target.Backup) to another folder (do not delete it), then run again. Case (b): if $($Target.Original) is an old or partial copy of the wrapper, delete ONLY $($Target.Original) and KEEP the backup, then run again. Nothing was changed."
    }
    elseif ($hasBackup) {
        $Target.Action = 'ResumeInstall'
    }
    else {
        # The file at the original path is about to be taken as the genuine DLL. Refuse unless it
        # looks like one (an old wrapper build or a damaged file must not be moved and kept as genuine).
        if (-not $SkipGenuineCheck) {
            $genuine = Test-GenuineNvidiaDll -Path $Target.Original
            if ($genuine.ReadError) {
                throw "[$name] could not read version information of $($Target.Original): $($genuine.ReadError). Close programs that use NVIDIA components and run again. Nothing was changed."
            }
            if (-not $genuine.Genuine) {
                throw "[$name] $($Target.Original) does not look like the genuine NVIDIA DLL. Found: $($genuine.Found). It may be an old wrapper build or a damaged file. Reinstall the NVIDIA driver. If you are sure the file is genuine, run again with -SkipGenuineCheck. Nothing was changed."
            }
        }
        $Target.Action = 'Install'
        $Target.OriginalHash = $originalHash
    }
}

# Returns the owner SID text of $Path. Get-Acl read works for non-owners (READ_CONTROL).
Function Get-OwnerSid {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-Acl -LiteralPath $Path).GetOwner([System.Security.Principal.SecurityIdentifier]).Value
}

# True when $Path already has ANY explicit ACE for Administrators (well-known SID S-1-5-32-544,
# so it works on localized Windows). Such an ACE must never be removed by the restore, because
# it was there before this script touched the file. An existing ACE is widened to FullControl by
# Unlock-DLL and is not narrowed again on restore (real genuine DLLs have none).
Function Test-ExplicitAdminAce {
    param([Parameter(Mandatory)][string]$Path)
    $adminsSid = 'S-1-5-32-544'
    $rules = (Get-Acl -LiteralPath $Path).GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
    return [bool]@($rules | Where-Object { $_.IdentityReference.Value -eq $adminsSid }).Count
}

# Takes ownership for Administrators and grants it FullControl, using takeown.exe and
# icacls.exe. Both tools enable the privileges they need themselves, which Set-Acl does not
# (on a protected DACL such as the genuine TrustedInstaller-owned DLL, Set-Acl fails with
# "does not possess the 'SeSecurityPrivilege' privilege"). Only used after a Move-Item was
# refused with UnauthorizedAccess, and only on $Target.Original. The caller records the
# undo entry BEFORE calling this, so a half-done unlock is still rolled back.
Function Unlock-DLL {
    param([Parameter(Mandatory)][string]$Path)
    # An Administrators ACE that already existed is widened to FullControl here (icacls /grant) and is
    # not narrowed again by Restore-Owner (see Test-ExplicitAdminAce).
    $takeown = "$env:SystemRoot\System32\takeown.exe"
    $icacls = "$env:SystemRoot\System32\icacls.exe"

    $r = Invoke-Native -FilePath $takeown -Arguments @('/F', $Path, '/A')
    if ($r.ExitCode -ne 0) { throw "takeown failed on $Path (exit $($r.ExitCode)): $($r.Output)" }

    $r = Invoke-Native -FilePath $icacls -Arguments @($Path, '/grant', '*S-1-5-32-544:F')
    if ($r.ExitCode -ne 0) { throw "icacls /grant failed on $Path (exit $($r.ExitCode)): $($r.Output)" }

    Write-Host "OK: $Path is now owned by Administrators with FullControl"
}

# Undoes Unlock-DLL with icacls.exe (no Set-Acl, no SDDL, no privilege P/Invoke). Arguments:
#   OwnerSid          the owner SID saved before the unlock (SID text, e.g. S-1-5-18).
#   RemoveAdminGrant  $true when this run added the Administrators grant (the file had no
#                     explicit Administrators ACE before). $false keeps any existing ACE.
# Returns one of:
#   'full'     the grant was removed (if added) and the owner was set back.
#   'partial'  the grant was removed, but the owner could not be set back. Typical on a real
#              machine: the saved owner is NT SERVICE\TrustedInstaller, and an Administrator
#              token is not allowed to assign it. The file stays owned by Administrators; the
#              DACL is back to the original and the file contents are fine. A NOTE is printed.
#   'failed'   the grant could not be removed, so the DACL is still changed (a red WARNING is
#              printed). The caller treats this as a rollback failure.
Function Restore-Owner {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$OwnerSid,
        [bool]$RemoveAdminGrant = $true
    )
    $icacls = "$env:SystemRoot\System32\icacls.exe"
    $adminsSid = 'S-1-5-32-544'

    if ($RemoveAdminGrant) {
        $r = Invoke-Native -FilePath $icacls -Arguments @($Path, '/remove:g', "*$adminsSid")
        if ($r.ExitCode -ne 0) {
            $msg = "WARNING: could not remove the Administrators grant from $Path (exit $($r.ExitCode)): $($r.Output) Saved owner SID: $OwnerSid. Remove the Administrators entry by hand and restore the owner."
            Write-Host $msg -ForegroundColor Red
            if ($null -ne $script:AclNotes) { $script:AclNotes.Add($msg.Trim()) }
            return 'failed'
        }
    }

    $r = Invoke-Native -FilePath $icacls -Arguments @($Path, '/setowner', "*$OwnerSid")
    if ($r.ExitCode -ne 0) {
        $note = "NOTE: the owner of $Path could not be set back to SID $OwnerSid (exit $($r.ExitCode)). The original DACL is restored and the file is still owned by Administrators. The file contents are not affected. $($r.Output)"
        $note = $note.Trim()
        Write-Host $note -ForegroundColor Yellow
        if ($null -ne $script:AclNotes) { $script:AclNotes.Add($note) }
        return 'partial'
    }

    Write-Host "OK: restored original owner and DACL on $Path"
    return 'full'
}

# Reads only the PE headers of $Path (a few hundred bytes) and returns Machine and Magic.
# Magic 0x10B = PE32 (32-bit), 0x20B = PE32+ (64-bit). Throws if $Path is not a PE image.
Function Get-PeInfo {
    param([Parameter(Mandatory)][string]$Path)
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $dos = [byte[]]::new(64)
        if ($fs.Read($dos, 0, 64) -ne 64 -or $dos[0] -ne 0x4D -or $dos[1] -ne 0x5A) {
            throw "$Path is not a PE file (no MZ header)."
        }
        $lfanew = [BitConverter]::ToInt32($dos, 0x3C)   # e_lfanew: offset of 'PE\0\0'
        if ($lfanew -lt 64 -or $lfanew -gt 0x10000) { throw "$Path is not a PE file (bad e_lfanew)." }
        $null = $fs.Seek($lfanew, [System.IO.SeekOrigin]::Begin)
        # 'PE\0\0' (4 bytes) + COFF header (20 bytes) + Magic (2 bytes) = 26 bytes.
        $hdr = [byte[]]::new(26)
        if ($fs.Read($hdr, 0, 26) -ne 26 -or $hdr[0] -ne 0x50 -or $hdr[1] -ne 0x45 -or $hdr[2] -ne 0 -or $hdr[3] -ne 0) {
            throw "$Path is not a PE file (no PE signature)."
        }
        return [pscustomobject]@{
            Machine = [BitConverter]::ToUInt16($hdr, 4)    # IMAGE_FILE_HEADER.Machine
            Magic   = [BitConverter]::ToUInt16($hdr, 24)   # IMAGE_OPTIONAL_HEADER.Magic
        }
    }
    finally { $fs.Close() }
}

# Pre-flight check of one wrapper. Lenient on purpose so ARM64 hosts are not refused:
# 32-bit wrapper = x86 PE32 (0x014C, 0x10B); 64-bit wrapper = PE32+ (0x20B) that is not x86.
Function Test-WrapperPe {
    param($Target)
    $file = Split-Path -Leaf $Target.Wrapper
    try { $pe = Get-PeInfo -Path $Target.Wrapper }
    catch { throw "$file is not a usable wrapper: $($_.Exception.Message) Nothing was changed." }
    $found = 'Machine 0x{0:X4}, Magic 0x{1:X3}' -f $pe.Machine, $pe.Magic
    if ($Target.Name -eq '32-bit') {
        if ($pe.Machine -ne 0x014C -or $pe.Magic -ne 0x10B) {
            throw "$file must be a 32-bit x86 PE image (Machine 0x014C, Magic 0x10B) for the 32-bit DLL; it is $found. Nothing was changed."
        }
    }
    elseif ($pe.Magic -ne 0x20B -or $pe.Machine -eq 0x014C) {
        throw "$file must be a 64-bit PE32+ image (Magic 0x20B) that is not x86, for example x64 0x8664 or ARM64 0xAA64; it is $found. Nothing was changed."
    }
}

# Moves the genuine DLL to its backup name. Never overwrites an existing backup.
# Known limit (F-7): an interrupt (Ctrl+C) after taking ownership in Unlock-DLL and before
# Restore-Owner has finished (the window is between the unlock and the end of the restore) can
# leave NvFBC64_.dll / NvFBC_.dll owned by Administrators, possibly with an Administrators
# FullControl entry. The DLL contents are intact. A re-run does not restore owner/ACL, because the
# move then succeeds without UnauthorizedAccess. Fix by hand if desired (see README.md).
# Order: move, verify the move, restore owner/ACL on the moved backup, then verify the hash, so the
# unrestored window is as short as possible. Rollback records are kept correct at each step.
Function Move-Genuine {
    param($Target, $Undo)
    $from = $Target.Original
    $to = $Target.Backup
    $aclEntry = $null
    try {
        Move-Item -LiteralPath $from -Destination $to   # no -Force on purpose
    }
    catch [System.UnauthorizedAccessException] {
        Write-Host "[$($Target.Name)] Access denied; taking ownership of $from ..."
        # Everything needed to revert is recorded BEFORE the unlock. Rollback runs Restore-Owner on
        # the original path after the file has been moved back, so a half-done unlock is undone too.
        $ownerSid = Get-OwnerSid -Path $from
        $hadAdminAce = Test-ExplicitAdminAce -Path $from
        $aclEntry = [pscustomobject]@{
            Kind            = 'Acl'
            Path            = $from
            OwnerSid        = $ownerSid
            AddedAdminGrant = (-not $hadAdminAce)   # never remove an Administrators ACE that was already there
            Done            = $false
        }
        $Undo.Add($aclEntry)
        Unlock-DLL -Path $from
        Move-Item -LiteralPath $from -Destination $to
    }
    # Recorded right after the move, so rollback moves the backup back even if a later step fails.
    $Undo.Add([pscustomobject]@{ Kind = 'Move'; From = $from; To = $to })

    if ((Test-Path -LiteralPath $from) -or -not (Test-Path -LiteralPath $to -PathType Leaf)) {
        throw "Move verification failed: $from -> $to"
    }
    if ($aclEntry) {
        # Owner/ACL go back on the moved BACKUP, not on the original path. Runs before the hash check
        # so the window with the Administrators ownership is as short as possible.
        $r = Restore-Owner -Path $to -OwnerSid $aclEntry.OwnerSid -RemoveAdminGrant $aclEntry.AddedAdminGrant
        if ($r -eq 'failed') { throw "Could not remove the Administrators grant from the backup $to" }
        if ($r -eq 'full') { $aclEntry.Done = $true }
        else { $aclEntry.AddedAdminGrant = $false }   # partial: the grant is already gone; rollback retries only the owner
    }
    if ((Get-Sha256 -Path $to) -ne $Target.OriginalHash) {
        throw "Hash mismatch after moving the genuine DLL to $to"
    }
    Write-Host "[$($Target.Name)] OK: moved $from -> $to (SHA-256 verified)"
}

# Installs the wrapper without ever leaving a partial file under the final name:
#   1. copy to <name>.nvfbcwrp-tmp in the same folder (no -Force),
#   2. verify the SHA-256 of the temp copy,
#   3. Move-Item the temp copy to the final name (a rename, so it is all or nothing).
# An interrupted run leaves at most the temp file, which the next run removes. Target must not exist.
Function Install-Wrapper {
    param($Target, $Undo)
    $dest = $Target.Original
    $tmp = $Target.Temp
    if (Test-Path -LiteralPath $dest) { throw "$dest still exists; refusing to overwrite it." }
    if (Test-Path -LiteralPath $tmp) { throw "$tmp still exists; refusing to overwrite it." }
    # Recorded before the copy, so a partial temp file is removed on rollback.
    $Undo.Add([pscustomobject]@{ Kind = 'Copy'; Path = $tmp })
    Copy-Item -LiteralPath $Target.Wrapper -Destination $tmp
    if ((Get-Sha256 -Path $tmp) -ne (Get-Sha256 -Path $Target.Wrapper)) {
        throw "Hash mismatch after copying the wrapper to $tmp"
    }
    # Recorded before the rename, so a rollback removes the final copy if the rename did happen.
    $Undo.Add([pscustomobject]@{ Kind = 'Copy'; Path = $dest })
    Move-Item -LiteralPath $tmp -Destination $dest   # no -Force: must not overwrite
    if ((Get-Sha256 -Path $dest) -ne (Get-Sha256 -Path $Target.Wrapper)) {
        throw "Hash mismatch after installing the wrapper as $dest"
    }
    Write-Host "[$($Target.Name)] OK: installed $(Split-Path -Leaf $Target.Wrapper) as $dest (SHA-256 verified)"
}

# Removes leftover temp files of an interrupted earlier run. Only the exact temp name of this
# script next to the target is ever touched. Called after the plan is accepted.
Function Remove-LeftoverTemp {
    param($Target)
    if (Test-Path -LiteralPath $Target.Temp -PathType Leaf) {
        Remove-Item -LiteralPath $Target.Temp -Force
        Write-Host "[$($Target.Name)] Removed $($Target.Temp) left by an earlier interrupted run."
    }
}

# Reverts recorded steps in reverse order. Returns the number of steps that failed.
Function Undo-Changes {
    param($Undo)
    $failures = 0
    for ($i = $Undo.Count - 1; $i -ge 0; $i--) {
        $u = $Undo[$i]
        try {
            switch ($u.Kind) {
                'Copy' {
                    if (Test-Path -LiteralPath $u.Path) { Remove-Item -LiteralPath $u.Path -Force }
                    if (Test-Path -LiteralPath $u.Path) { throw "$($u.Path) still exists" }
                    Write-Host "ROLLBACK OK: removed wrapper copy $($u.Path)"
                }
                'Move' {
                    Move-Item -LiteralPath $u.To -Destination $u.From
                    if (-not (Test-Path -LiteralPath $u.From -PathType Leaf) -or (Test-Path -LiteralPath $u.To)) {
                        throw "could not move $($u.To) back to $($u.From)"
                    }
                    Write-Host "ROLLBACK OK: restored $($u.From)"
                }
                'Acl' {
                    # Runs after the 'Move' undo, so the file is back at its original path.
                    # 'partial' (owner not set back) is only a note: the contents were put back.
                    if (-not $u.Done -and (Test-Path -LiteralPath $u.Path)) {
                        if ((Restore-Owner -Path $u.Path -OwnerSid $u.OwnerSid -RemoveAdminGrant $u.AddedAdminGrant) -eq 'failed') {
                            throw "owner/DACL of $($u.Path) not restored"
                        }
                    }
                }
            }
        }
        catch {
            $failures++
            Write-Host "ROLLBACK FAILED ($($u.Kind)): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    return $failures
}

# Repeats the owner/ACL notes collected during the run, so they are not lost in the output.
Function Show-AclNotes {
    if ($null -eq $script:AclNotes -or $script:AclNotes.Count -eq 0) { return }
    Write-Host 'Owner/ACL summary:' -ForegroundColor Yellow
    foreach ($n in $script:AclNotes) { Write-Host "  $n" -ForegroundColor Yellow }
}

Function Invoke-Patch {
    $scriptDir = $PSScriptRoot
    Write-Host 'Starting NVFBC DLL patch...'
    $script:AclNotes = New-Object -TypeName System.Collections.Generic.List[string]

    $targets = @(
        (New-Target -Name '64-bit' -Dir $System32Path -GenuineFile 'NvFBC64.dll' -BackupFile 'NvFBC64_.dll' -Wrapper (Join-Path $scriptDir 'nvfbcwrp64.dll')),
        (New-Target -Name '32-bit' -Dir $SysWOW64Path -GenuineFile 'NvFBC.dll' -BackupFile 'NvFBC_.dll' -Wrapper (Join-Path $scriptDir 'nvfbcwrp32.dll'))
    )

    # Pre-flight: all checks run before anything is changed.
    foreach ($t in $targets) {
        if (-not (Test-Path -LiteralPath $t.Wrapper -PathType Leaf)) {
            throw "$(Split-Path -Leaf $t.Wrapper) was not found in $scriptDir. Put nvfbcwrp64.dll and nvfbcwrp32.dll next to Patch.ps1. Nothing was changed."
        }
        if (-not (Test-Path -LiteralPath $t.Dir -PathType Container)) {
            throw "Folder not found: $($t.Dir). Nothing was changed."
        }
        Test-WrapperPe -Target $t   # throws (Nothing was changed.) if the wrapper is not the right PE kind
    }
    foreach ($t in $targets) { Set-PatchPlan -Target $t -SkipGenuineCheck:$SkipGenuineCheck }
    # The plan was accepted. Leftover temp files of an interrupted run are removed now (not earlier,
    # so a refused run changes nothing).
    foreach ($t in $targets) { Remove-LeftoverTemp -Target $t }

    # Apply. Any failure rolls back everything done in this run, for both architectures.
    $undo = New-Object -TypeName System.Collections.Generic.List[object]
    try {
        foreach ($t in $targets) {
            switch ($t.Action) {
                'AlreadyPatched' {
                    Write-Host "[$($t.Name)] OK: already patched ($($t.Original) is the wrapper, $($t.Backup) kept). Skipped."
                }
                'Install' {
                    Move-Genuine -Target $t -Undo $undo
                    Install-Wrapper -Target $t -Undo $undo
                }
                'ResumeInstall' {
                    Write-Host "[$($t.Name)] Backup exists and $($t.Original) is missing; installing the wrapper only."
                    Install-Wrapper -Target $t -Undo $undo
                }
            }
        }
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Patch install failed. Rolling back this run''s changes...' -ForegroundColor Red
        $failed = Undo-Changes -Undo $undo
        if ($failed -gt 0) {
            Write-Host "ROLLBACK INCOMPLETE: $failed step(s) could not be reverted. Check the files named above and fix them by hand." -ForegroundColor Red
        }
        else {
            Write-Host 'Rollback complete. System32 and SysWOW64 are back to their previous state.'
        }
        Show-AclNotes
        return 1
    }

    Show-AclNotes
    Write-Host 'NVFBC patch complete.'
    return 0
}

# ---- main ----
if (-not $Unattended -and -not (Test-Administrator)) {
    exit (Start-ElevatedPatch)
}

try {
    $exitCode = Invoke-Patch
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $exitCode = 1
}

Wait-BeforeExit
exit $exitCode
# End of script
