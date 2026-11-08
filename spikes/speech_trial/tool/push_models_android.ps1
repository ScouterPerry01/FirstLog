# File path and name: spikes/speech_trial/tool/push_models_android.ps1
# Modified On Timestamp: 2026-11-08 @ 06:23 EST
# Created On Timestamp: 2026-11-08 @ 06:23 EST
# File Description: Copies the downloaded models to the trial app's own folder on a USB-connected Android phone,
#                   and pulls trial logs back.
# Uses: adb.exe from the Android SDK (%LOCALAPPDATA%\Android\Sdk\platform-tools); spikes/speech_trial/models/.
# Used By: the developer, after tool/download_models.ps1 and after installing the app once.
# Purpose: Keep ~500 MB of models out of the APK; the app reads them from its external files folder.
#
# Usage:  & .\spikes\speech_trial\tool\push_models_android.ps1              # push models
#         & .\spikes\speech_trial\tool\push_models_android.ps1 -PullLogs    # copy trial-logs to the PC
#         add -Device <serial> when more than one phone is connected

param([switch]$PullLogs, [string]$Device)
$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$pkg = 'io.github.scouterperry01.speech_trial'
$remote = "/sdcard/Android/data/$pkg/files"
$root = Split-Path $PSScriptRoot -Parent
$dev = if ($Device) { @('-s', $Device) } else { @() }

if ($PullLogs) {
    $dest = Join-Path $root 'trial-logs'
    New-Item -ItemType Directory -Force $dest | Out-Null
    & $adb @dev pull "$remote/trial-logs/." $dest
    Write-Host "Logs copied to $dest (git-ignored; they contain recorded speech)"
    return
}

$models = Join-Path $root 'models'
if (-not (Test-Path $models)) { throw "No models folder - run tool/download_models.ps1 first" }

& $adb @dev shell mkdir -p "$remote/models"
foreach ($item in Get-ChildItem $models) {
    if ($item.Name -like '*kws*') { continue }   # keyword spotter not used yet
    Write-Host "push  $($item.Name)"
    if ($item.PSIsContainer) {
        # Skip sample audio and export scripts to save phone space.
        & $adb @dev shell mkdir -p "$remote/models/$($item.Name)"
        foreach ($f in Get-ChildItem $item.FullName | Where-Object { $_.Name -notin @('test_wavs', 'README.md', 'MODEL_CARD') -and $_.Extension -ne '.sh' }) {
            & $adb @dev push $f.FullName "$remote/models/$($item.Name)/" | Out-Null
        }
    } else {
        & $adb @dev push $item.FullName "$remote/models/" | Out-Null
    }
}
Write-Host "Models pushed to $remote/models"
