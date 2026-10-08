# HD2 Controls Manager

Back up and transfer your **Helldivers 2** key bindings and mouse sensitivity between PCs. The tool finds the config files automatically and leaves your graphics settings alone. Nothing to install: run the `.bat` and pick an option from the menu.

## Features

- **Backup**: saves your key bindings (`input_settings.config`) and settings (`user_settings.config`) to a timestamped zip in `Documents\HD2_Controls_Backups`.
- **Restore / transfer**: pick a backup from the list or paste the path to any zip (from another PC, a USB stick, a friend). Choose what to restore:
  1. Key bindings + mouse sensitivity (recommended)
  2. Key bindings only
  3. Mouse sensitivity only
  4. Everything, including graphics
- **Safety backup**: your current settings are saved automatically (`before-restore`) before anything is overwritten.
- **Game check**: refuses to restore while Helldivers 2 is running, since the game rewrites its config on exit.
- **Status view**: shows which config files were found and your current sensitivity values.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1).
- Windows 7 / 8.1: install [Windows Management Framework 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) first.
- No admin rights needed.

## Installation

1. Download `HD2-Controls.bat` and `HD2-Controls.ps1`.
2. Put **both files in the same folder** (anywhere you like).
3. Double-click `HD2-Controls.bat`.

## Transferring settings to another PC

1. On the old PC: run the tool and choose **1 (Back up)**.
2. Copy the zip from `Documents\HD2_Controls_Backu# HD2 Controls Manager

Back up and transfer your **Helldivers 2** key bindings and mouse sensitivity between PCs. The tool finds the config files automatically and leaves your graphics settings alone. Nothing to install: run the `.bat` and pick an option from the menu.

## Features

- **Backup**: saves your key bindings (`input_settings.config`) and settings (`user_settings.config`) to a timestamped zip in `Documents\HD2_Controls_Backups`.
- **Restore / transfer**: pick a backup from the list or paste the path to any zip (from another PC, a USB stick, a friend). Choose what to restore:
  1. Key bindings + mouse sensitivity (recommended)
  2. Key bindings only
  3. Mouse sensitivity only
  4. Everything, including graphics
- **Safety backup**: your current settings are saved automatically (`before-restore`) before anything is overwritten.
- **Game check**: refuses to restore while Helldivers 2 is running, since the game rewrites its config on exit.
- **Status view**: shows which config files were found and your current sensitivity values.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1).
- Windows 7 / 8.1: install [Windows Management Framework 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) first.
- No admin rights needed.

## Installation

1. Download `HD2-Controls.bat` and `HD2-Controls.ps1`.
2. Put **both files in the same folder** (anywhere you like).
3. Double-click `HD2-Controls.bat`.

## Transferring settings to another PC

1. On the old PC: run the tool and choose **1 (Back up)**.
2. Copy the zip from `Documents\HD2_Controls_Backups` to the new PC.
3. On the new PC: launch Helldivers 2 once, open the controls settings so the config files get created, then **close the game**.
4. Run the tool, choose **2 (Restore)** and select the zip.

If Steam reports a cloud save conflict on the next launch, choose the **local** files.

## Where the game keeps its settings

The tool checks all known locations:

- `[Steam]\userdata\[user id]\553850\remote\input_settings.config`
- `[Steam]\userdata\[user id]\553850\input_settings.config`
- `%APPDATA%\Arrowhead\Helldivers2\saves\*input_settings.config`
- `%APPDATA%\Arrowhead\Helldivers2\user_settings.config`

## Why does my antivirus / SmartScreen complain?

The `.bat` launcher starts PowerShell with `-ExecutionPolicy Bypass`, because Windows blocks unsigned local scripts by default. That pattern triggers heuristic scanners even for harmless scripts.

The tool is plain text and fully readable: open `HD2-Controls.ps1` in Notepad to see exactly what it does. It only reads and writes the Helldivers 2 config files listed above and its own backup folder, and it makes no network connections.

If SmartScreen blocks the launcher, click **More info → Run anyway**.

## Troubleshooting

- **"No key binding files found"**: launch the game once, open the controls settings, close the game, then try again.
- **Settings didn't apply**: make sure the game was fully closed during restore, and pick the local files if Steam shows a cloud conflict.
- **Something broke**: restore the automatic `before-restore` backup, or delete `input_settings.config` to reset bindings to the game defaults.

## Disclaimer

Not affiliated with Arrowhead Game Studios or Sony Interactive Entertainment. Use at your own risk; backups are made before every restore, but keep your own copy of anything important.
ps` to the new PC.
3. On the new PC: launch Helldivers 2 once, open the controls settings so the config files get created, then **close the game**.
4. Run the tool, choose **2 (Restore)** and select the zip.

If Steam reports a cloud save conflict on the next launch, choose the **local** files.

## Where the game keeps its settings

The tool checks all known locations:

- `[Steam]\userdata\[user id]\553850\remote\input_settings.config`
- `[Steam]\userdata\[user id]\553850\input_settings.config`
- `%APPDATA%\Arrowhead\Helldivers2\saves\*input_settings.config`
- `%APPDATA%\Arrowhead\Helldivers2\user_settings.config`

## Why does my antivirus / SmartScreen complain?

The `.bat` launcher starts PowerShell with `-ExecutionPolicy Bypass`, because Windows blocks unsigned local scripts by default. That pattern triggers heuristic scanners even for harmless scripts.

The tool is plain text and fully readable: open `HD2-Controls.ps1` in Notepad to see exactly what it does. It only reads and writes the Helldivers 2 config files listed above and its own backup folder, and it makes no network connections.

If SmartScreen blocks the launcher, click **More info → Run anyway**.

## Troubleshooting

- **"No key binding files found"**: launch the game once, open the controls settings, close the game, then try again.
- **Settings didn't apply**: make sure the game was fully closed during restore, and pick the local files if Steam shows a cloud conflict.
- **Something broke**: restore the automatic `before-restore` backup, or delete `input_settings.config` to reset bindings to the game defaults.

## Disclaimer

Not affiliated with Arrowhead Game Studios or Sony Interactive Entertainment. Use at your own risk; backups are made before every restore, but keep your own copy of anything important.
