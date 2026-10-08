# HD2 Controls Manager - back up and transfer Helldivers 2 controls
# Saves key bindings (input_settings.config) and mouse sensitivity.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$AppId      = '553850'
$AppDataDir = Join-Path $env:APPDATA 'Arrowhead\Helldivers2'
$BackupDir  = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'HD2_Controls_Backups'
$SensPattern = 'sensitiv|invert|aim_assist|deadzone'
$Utf8NoBom  = New-Object Text.UTF8Encoding($false)

function Write-Title($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)    { Write-Host "[OK] $t" -ForegroundColor Green }
function Write-Warn($t)  { Write-Host "[!]  $t" -ForegroundColor Yellow }
function Write-Err($t)   { Write-Host "[X]  $t" -ForegroundColor Red }

function Get-SteamPath {
    foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        try {
            $p = Get-ItemProperty -Path $k -ErrorAction Stop
            foreach ($n in 'SteamPath', 'InstallPath') {
                if ($p.$n -and (Test-Path $p.$n)) { return ($p.$n -replace '/', '\') }
            }
        } catch {}
    }
    $def = Join-Path ${env:ProgramFiles(x86)} 'Steam'
    if (Test-Path $def) { return $def }
    return $null
}

# Every location where the game keeps key bindings
function Find-InputFiles {
    $found = @()
    $steam = Get-SteamPath
    if ($steam) {
        $ud = Join-Path $steam 'userdata'
        if (Test-Path $ud) {
            Get-ChildItem $ud -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                foreach ($sub in "$AppId\remote", $AppId) {
                    $f = Join-Path $_.FullName "$sub\input_settings.config"
                    if (Test-Path $f) { $found += Get-Item $f }
                }
            }
        }
    }
    $saves = Join-Path $AppDataDir 'saves'
    if (Test-Path $saves) {
        $found += Get-ChildItem $saves -Filter '*input_settings.config' -File -ErrorAction SilentlyContinue
    }
    $direct = Join-Path $AppDataDir 'input_settings.config'
    if (Test-Path $direct) { $found += Get-Item $direct }
    return $found | Sort-Object FullName -Unique
}

function Get-UserSettingsFile {
    $f = Join-Path $AppDataDir 'user_settings.config'
    if (Test-Path $f) { return Get-Item $f }
    return $null
}

function Test-GameRunning {
    return [bool](Get-Process -Name 'helldivers2' -ErrorAction SilentlyContinue)
}

# "key = value" lines for sensitivity / inversion
function Get-SensLines([string]$text) {
    $map = [ordered]@{}
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$' -and $Matches[1] -match $SensPattern) {
            $map[$Matches[1]] = $Matches[2]
        }
    }
    return $map
}

function Show-Status {
    Write-Title 'Files found'
    $inputs = Find-InputFiles
    if ($inputs.Count -eq 0) {
        Write-Warn 'No key binding files found. Launch the game at least once and open the controls settings.'
    } else {
        foreach ($f in $inputs) { Write-Host "  Bindings: $($f.FullName)  ($($f.LastWriteTime))" }
    }
    $us = Get-UserSettingsFile
    if ($us) {
        Write-Host "  Settings: $($us.FullName)  ($($us.LastWriteTime))"
        $sens = Get-SensLines ([IO.File]::ReadAllText($us.FullName))
        if ($sens.Count -gt 0) {
            Write-Host '  Sensitivity / inversion:' -ForegroundColor Gray
            foreach ($k in $sens.Keys) { Write-Host "    $k = $($sens[$k])" -ForegroundColor Gray }
        }
    } else {
        Write-Warn 'user_settings.config not found.'
    }
}

function New-Backup([string]$label = '') {
    $inputs = Find-InputFiles
    $us = Get-UserSettingsFile
    if ($inputs.Count -eq 0 -and -not $us) {
        Write-Err 'Nothing to back up - no settings files found.'
        return $null
    }
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $name  = if ($label) { "HD2_${label}_$stamp" } else { "HD2_controls_$stamp" }
    $stage = Join-Path $env:TEMP $name
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Path $stage | Out-Null

    $manifest = @("HD2 Controls backup", "Created: $(Get-Date)", "PC: $env:COMPUTERNAME", "")
    if ($inputs.Count -gt 0) {
        # Use the most recent bindings file
        $newest = $inputs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Copy-Item $newest.FullName (Join-Path $stage 'input_settings.config')
        $manifest += "input_settings.config <- $($newest.FullName)"
    }
    if ($us) {
        Copy-Item $us.FullName (Join-Path $stage 'user_settings.config')
        $manifest += "user_settings.config  <- $($us.FullName)"
    }
    [IO.File]::WriteAllLines((Join-Path $stage 'manifest.txt'), $manifest, $Utf8NoBom)

    $zip = Join-Path $BackupDir "$name.zip"
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
    Remove-Item $stage -Recurse -Force
    Write-Ok "Backup saved: $zip"
    return $zip
}

function Select-Backup {
    $list = @()
    if (Test-Path $BackupDir) {
        $list = @(Get-ChildItem $BackupDir -Filter '*.zip' | Sort-Object LastWriteTime -Descending)
    }
    Write-Title 'Choose a backup'
    for ($i = 0; $i -lt $list.Count; $i++) {
        Write-Host ("  {0}) {1}  ({2})" -f ($i + 1), $list[$i].Name, $list[$i].LastWriteTime)
    }
    Write-Host '  Or paste the full path to a .zip (e.g. from a USB stick / a friend)'
    $ans = (Read-Host 'Number or path').Trim('"', ' ')
    if ($ans -match '^\d+$' -and [int]$ans -ge 1 -and [int]$ans -le $list.Count) { return $list[[int]$ans - 1].FullName }
    if ($ans -and (Test-Path $ans)) { return (Resolve-Path $ans).Path }
    Write-Err 'Backup not found.'
    return $null
}

function Restore-Backup {
    if (Test-GameRunning) { Write-Err 'Close Helldivers 2 first - the game overwrites these files on exit.'; return }

    $zip = Select-Backup
    if (-not $zip) { return }

    Write-Title 'What to restore?'
    Write-Host '  1) Key bindings + mouse sensitivity (recommended)'
    Write-Host '  2) Key bindings only'
    Write-Host '  3) Mouse sensitivity only'
    Write-Host '  4) Everything, including graphics (whole user_settings.config)'
    $mode = Read-Host 'Choice'
    if ($mode -notin '1','2','3','4') { Write-Err 'Invalid choice.'; return }

    $tmp = Join-Path $env:TEMP ("HD2_restore_" + [guid]::NewGuid().ToString('N'))
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $srcInput = Join-Path $tmp 'input_settings.config'
    $srcUser  = Join-Path $tmp 'user_settings.config'

    try {
        # Safety backup of the current state
        Write-Host 'Backing up current settings just in case...' -ForegroundColor Gray
        New-Backup 'before-restore' | Out-Null

        # 1. Key bindings
        if ($mode -in '1','2','4') {
            if (-not (Test-Path $srcInput)) {
                Write-Warn 'This backup has no key bindings.'
            } else {
                $targets = Find-InputFiles
                if ($targets.Count -eq 0) {
                    Write-Warn 'No bindings file on this PC yet. Launch the game, open the controls settings, close the game and try again.'
                } else {
                    foreach ($t in $targets) {
                        Copy-Item $srcInput $t.FullName -Force
                        Write-Ok "Bindings -> $($t.FullName)"
                    }
                }
            }
        }

        # 2. Settings (sensitivity only, or the whole file)
        if ($mode -in '1','3','4') {
            $dst = Join-Path $AppDataDir 'user_settings.config'
            if (-not (Test-Path $srcUser)) {
                Write-Warn 'This backup has no user_settings.config.'
            } elseif ($mode -eq '4' -or -not (Test-Path $dst)) {
                New-Item -ItemType Directory -Force -Path $AppDataDir | Out-Null
                Copy-Item $srcUser $dst -Force
                Write-Ok "user_settings.config fully restored -> $dst"
            } else {
                # Copy only the sensitivity lines, leave graphics alone
                $src = Get-SensLines ([IO.File]::ReadAllText($srcUser))
                if ($src.Count -eq 0) {
                    Write-Warn 'No sensitivity settings found in the backup (they may live in the bindings file, which was already copied).'
                } else {
                    $lines = [IO.File]::ReadAllText($dst) -split "`r?`n"
                    $done = @{}
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match '^(\s*)([A-Za-z0-9_]+)(\s*=\s*)(.+?)\s*$' -and $src.Contains($Matches[2])) {
                            $key = $Matches[2]
                            $lines[$i] = $Matches[1] + $key + $Matches[3] + $src[$key]
                            $done[$key] = $true
                        }
                    }
                    [IO.File]::WriteAllText($dst, ($lines -join "`r`n"), $Utf8NoBom)
                    foreach ($k in $src.Keys) {
                        if ($done[$k]) { Write-Ok "$k = $($src[$k])" }
                        else { Write-Warn "$k is missing from the current file - skipped" }
                    }
                }
            }
        }

        Write-Host ''
        Write-Ok 'Done! You can launch the game now.'
        Write-Warn 'If Steam reports a cloud save conflict, choose the LOCAL files.'
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------- Main menu ----------
while ($true) {
    Write-Host ''
    Write-Host '+--------------------------------------+' -ForegroundColor Yellow
    Write-Host '|   HELLDIVERS 2 - Controls Manager    |' -ForegroundColor Yellow
    Write-Host '+--------------------------------------+' -ForegroundColor Yellow
    Write-Host '  1) Back up current settings'
    Write-Host '  2) Restore / transfer from a backup'
    Write-Host '  3) Show found files and sensitivity'
    Write-Host '  4) Open the backups folder'
    Write-Host '  0) Exit'
    $c = Read-Host 'Choice'
    try {
        switch ($c) {
            '1' { New-Backup | Out-Null }
            '2' { Restore-Backup }
            '3' { Show-Status }
            '4' { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null; Start-Process explorer.exe $BackupDir }
            '0' { return }
            default { Write-Warn 'No such option.' }
        }
    } catch {
        Write-Err $_.Exception.Message
    }
}
