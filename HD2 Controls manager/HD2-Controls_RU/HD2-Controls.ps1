# HD2 Controls Manager — бэкап и перенос управления Helldivers 2
# Сохраняет раскладку клавиш (input_settings.config) и чувствительность мыши.

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

# Все места, где игра держит раскладку
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

# Строки вида "key = value" с чувствительностью/инверсией
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
    Write-Title 'Найденные файлы'
    $inputs = Find-InputFiles
    if ($inputs.Count -eq 0) {
        Write-Warn 'Файлы раскладки не найдены. Запусти игру хотя бы раз и зайди в настройки управления.'
    } else {
        foreach ($f in $inputs) { Write-Host "  Раскладка: $($f.FullName)  ($($f.LastWriteTime))" }
    }
    $us = Get-UserSettingsFile
    if ($us) {
        Write-Host "  Настройки: $($us.FullName)  ($($us.LastWriteTime))"
        $sens = Get-SensLines ([IO.File]::ReadAllText($us.FullName))
        if ($sens.Count -gt 0) {
            Write-Host '  Чувствительность/инверсия:' -ForegroundColor Gray
            foreach ($k in $sens.Keys) { Write-Host "    $k = $($sens[$k])" -ForegroundColor Gray }
        }
    } else {
        Write-Warn 'user_settings.config не найден.'
    }
}

function New-Backup([string]$label = '') {
    $inputs = Find-InputFiles
    $us = Get-UserSettingsFile
    if ($inputs.Count -eq 0 -and -not $us) {
        Write-Err 'Нечего сохранять — файлы настроек не найдены.'
        return $null
    }
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $name  = if ($label) { "HD2_${label}_$stamp" } else { "HD2_controls_$stamp" }
    $stage = Join-Path $env:TEMP $name
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Path $stage | Out-Null

    $manifest = @("HD2 Controls backup", "Создан: $(Get-Date)", "ПК: $env:COMPUTERNAME", "")
    if ($inputs.Count -gt 0) {
        # Берём самый свежий файл раскладки
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
    Write-Ok "Бэкап сохранён: $zip"
    return $zip
}

function Select-Backup {
    $list = @()
    if (Test-Path $BackupDir) {
        $list = @(Get-ChildItem $BackupDir -Filter '*.zip' | Sort-Object LastWriteTime -Descending)
    }
    Write-Title 'Выбор бэкапа'
    for ($i = 0; $i -lt $list.Count; $i++) {
        Write-Host ("  {0}) {1}  ({2})" -f ($i + 1), $list[$i].Name, $list[$i].LastWriteTime)
    }
    Write-Host '  Или вставь полный путь к .zip (например, с флешки / от друга)'
    $ans = (Read-Host 'Номер или путь').Trim('"', ' ')
    if ($ans -match '^\d+$' -and [int]$ans -ge 1 -and [int]$ans -le $list.Count) { return $list[[int]$ans - 1].FullName }
    if ($ans -and (Test-Path $ans)) { return (Resolve-Path $ans).Path }
    Write-Err 'Бэкап не найден.'
    return $null
}

function Restore-Backup {
    if (Test-GameRunning) { Write-Err 'Сначала закрой Helldivers 2 — игра перезапишет файлы при выходе.'; return }

    $zip = Select-Backup
    if (-not $zip) { return }

    Write-Title 'Что восстановить?'
    Write-Host '  1) Раскладку клавиш + чувствительность мыши (рекомендуется)'
    Write-Host '  2) Только раскладку клавиш'
    Write-Host '  3) Только чувствительность мыши'
    Write-Host '  4) Всё, включая графику (user_settings.config целиком)'
    $mode = Read-Host 'Выбор'
    if ($mode -notin '1','2','3','4') { Write-Err 'Неверный выбор.'; return }

    $tmp = Join-Path $env:TEMP ("HD2_restore_" + [guid]::NewGuid().ToString('N'))
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $srcInput = Join-Path $tmp 'input_settings.config'
    $srcUser  = Join-Path $tmp 'user_settings.config'

    try {
        # Страховочный бэкап текущего состояния
        Write-Host 'Сохраняю текущие настройки на всякий случай...' -ForegroundColor Gray
        New-Backup 'before-restore' | Out-Null

        # 1. Раскладка
        if ($mode -in '1','2','4') {
            if (-not (Test-Path $srcInput)) {
                Write-Warn 'В бэкапе нет раскладки клавиш.'
            } else {
                $targets = Find-InputFiles
                if ($targets.Count -eq 0) {
                    Write-Warn 'На этом ПК ещё нет файла раскладки. Запусти игру, зайди в настройки управления, закрой игру и повтори.'
                } else {
                    foreach ($t in $targets) {
                        Copy-Item $srcInput $t.FullName -Force
                        Write-Ok "Раскладка -> $($t.FullName)"
                    }
                }
            }
        }

        # 2. Настройки (чувствительность или целиком)
        if ($mode -in '1','3','4') {
            $dst = Join-Path $AppDataDir 'user_settings.config'
            if (-not (Test-Path $srcUser)) {
                Write-Warn 'В бэкапе нет user_settings.config.'
            } elseif ($mode -eq '4' -or -not (Test-Path $dst)) {
                New-Item -ItemType Directory -Force -Path $AppDataDir | Out-Null
                Copy-Item $srcUser $dst -Force
                Write-Ok "user_settings.config восстановлен целиком -> $dst"
            } else {
                # Переносим только строки с чувствительностью, графику не трогаем
                $src = Get-SensLines ([IO.File]::ReadAllText($srcUser))
                if ($src.Count -eq 0) {
                    Write-Warn 'В бэкапе не найдено параметров чувствительности (возможно, они в файле раскладки — он уже перенесён).'
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
                        else { Write-Warn "$k отсутствует в текущем файле — пропущен" }
                    }
                }
            }
        }

        Write-Host ''
        Write-Ok 'Готово! Запускай игру.'
        Write-Warn 'Если Steam покажет конфликт облачных сохранений — выбери ЛОКАЛЬНЫЕ файлы.'
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------- Главное меню ----------
while ($true) {
    Write-Host ''
    Write-Host '╔══════════════════════════════════════╗' -ForegroundColor Yellow
    Write-Host '║   HELLDIVERS 2 — менеджер управления ║' -ForegroundColor Yellow
    Write-Host '╚══════════════════════════════════════╝' -ForegroundColor Yellow
    Write-Host '  1) Сохранить текущие настройки (бэкап)'
    Write-Host '  2) Восстановить / перенести из бэкапа'
    Write-Host '  3) Показать найденные файлы и чувствительность'
    Write-Host '  4) Открыть папку с бэкапами'
    Write-Host '  0) Выход'
    $c = Read-Host 'Выбор'
    try {
        switch ($c) {
            '1' { New-Backup | Out-Null }
            '2' { Restore-Backup }
            '3' { Show-Status }
            '4' { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null; Start-Process explorer.exe $BackupDir }
            '0' { return }
            default { Write-Warn 'Нет такого пункта.' }
        }
    } catch {
        Write-Err $_.Exception.Message
    }
}
