# File path and name: spikes/speech_trial/tool/download_models.ps1
# Modified On Timestamp: 2026-11-08 @ 06:23 EST (added Piper EN/FR voices)
# Created On Timestamp: 2026-11-08 @ 03:34 EST
# File Description: Downloads the speech models for the N1 speech trial into spikes/speech_trial/models/
#                   (git-ignored) and keeps only the files the app loads.
# Uses: curl.exe and tar.exe (both ship with Windows 10/11); sherpa-onnx GitHub release assets.
# Used By: the developer, before building the speech trial (see spikes/speech_trial/README.md).
# Purpose: Models are hundreds of MB, so they are never committed; this makes the download repeatable.
#
# Usage (PowerShell, from anywhere):  & .\spikes\speech_trial\tool\download_models.ps1
#   -Force  re-download models that are already present

param([switch]$Force)
$ErrorActionPreference = 'Stop'

$base   = 'https://github.com/k2-fsa/sherpa-onnx/releases/download'
$models = Join-Path (Split-Path $PSScriptRoot -Parent) 'models'
New-Item -ItemType Directory -Force $models | Out-Null

# name = folder created by the archive; url = release asset
$archives = @(
    @{ name = 'sherpa-onnx-streaming-zipformer-en-2023-06-26';           url = "$base/asr-models/sherpa-onnx-streaming-zipformer-en-2023-06-26.tar.bz2" },
    @{ name = 'sherpa-onnx-streaming-zipformer-fr-2023-04-14';           url = "$base/asr-models/sherpa-onnx-streaming-zipformer-fr-2023-04-14.tar.bz2" },
    @{ name = 'sherpa-onnx-nemo-canary-180m-flash-en-es-de-fr-int8';     url = "$base/asr-models/sherpa-onnx-nemo-canary-180m-flash-en-es-de-fr-int8.tar.bz2" },
    @{ name = 'sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01';    url = "$base/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2" },
    # Offline voices for the spoken prompts (VC-8)
    @{ name = 'vits-piper-en_US-amy-low';                                url = "$base/tts-models/vits-piper-en_US-amy-low.tar.bz2" },
    @{ name = 'vits-piper-fr_FR-siwis-medium';                           url = "$base/tts-models/vits-piper-fr_FR-siwis-medium.tar.bz2" }
)

foreach ($a in $archives) {
    $dir = Join-Path $models $a.name
    if ((Test-Path $dir) -and -not $Force) { Write-Host "skip  $($a.name) (present)"; continue }
    if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
    $file = Join-Path $models ($a.name + '.tar.bz2')
    Write-Host "get   $($a.name)"
    curl.exe -L --fail --progress-bar -o $file $a.url
    tar.exe -xjf $file -C $models
    Remove-Item $file

    # Keep the int8 version of each .onnx file when one exists; drop the full-size twin.
    Get-ChildItem $dir -Recurse -Filter *.onnx |
        Where-Object { $_.Name -notmatch '\.int8\.onnx$' } |
        Where-Object { Test-Path (Join-Path $_.DirectoryName ($_.BaseName + '.int8.onnx')) } |
        Remove-Item
}

# Voice activity detector (single file) - splits speech for the non-streaming Canary set-up.
$vad = Join-Path $models 'silero_vad.onnx'
if (-not (Test-Path $vad) -or $Force) {
    Write-Host 'get   silero_vad.onnx'
    curl.exe -L --fail --progress-bar -o $vad "$base/asr-models/silero_vad.onnx"
}

Write-Host "`nModels in $models"
Get-ChildItem $models -Directory | ForEach-Object {
    $mb = [math]::Round((Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 1)
    Write-Host ("  {0,8} MB  {1}" -f $mb, $_.Name)
}
