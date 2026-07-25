#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$Root,
    [string]$SdRoot,
    [switch]$Zip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }
$Core     = Get-Content (Join-Path $Root "core.json") -Raw | ConvertFrom-Json
$Author    = $Core.core.metadata.author
$ShortName = $Core.core.metadata.shortname
$Platform  = $Core.core.metadata.platform_ids[0]
$Version   = $Core.core.metadata.version
$Date      = $Core.core.metadata.date_release
$FpgaOut   = Join-Path $Root "src/fpga/output_files/ap_core.rbf"
$Dist      = Join-Path $Root "dist"
$Release   = Join-Path $Root "release"
$CoreName  = "$Author.$ShortName"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }

if (-not (Test-Path $FpgaOut)) { throw "Bitstream not found: $FpgaOut  (compile in Quartus first)" }

Write-Step "Reversing bitstream -> bitstream.rbf_r"
$rev = New-Object 'System.Byte[]' 256
for ($b = 0; $b -lt 256; $b++) {
    $r = 0
    for ($i = 0; $i -lt 8; $i++) { $r = ($r -shl 1) -bor (($b -shr $i) -band 1) }
    $rev[$b] = [byte]$r
}
$bytes = [System.IO.File]::ReadAllBytes($FpgaOut)
for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = $rev[$bytes[$i]] }

Write-Step "Building SD layout under release/"
if (Test-Path $Release) { Remove-Item $Release -Recurse -Force }
$CoreDir   = Join-Path $Release "Cores/$CoreName"
$PlatDir   = Join-Path $Release "Platforms"
$PlatImg   = Join-Path $PlatDir "_images"
$AssetDir  = Join-Path $Release "Assets/$Platform/common"
New-Item -ItemType Directory -Path $CoreDir, $PlatImg, $AssetDir | Out-Null

Get-ChildItem -Path $Root -Filter "*.json" -File | Copy-Item -Destination $CoreDir
Copy-Item (Join-Path $Root "info.txt") $CoreDir
Copy-Item (Join-Path $Dist "icon.bin") $CoreDir
[System.IO.File]::WriteAllBytes((Join-Path $CoreDir "bitstream.rbf_r"), $bytes)

Copy-Item (Join-Path $Dist "platforms/$Platform.json") $PlatDir
$PlatBin = Join-Path $Dist "platforms/_images/$Platform.bin"
if (Test-Path $PlatBin) { Copy-Item $PlatBin $PlatImg }

Write-Ok "Core folder: Cores/$CoreName"
Write-Ok "Bitstream:   $($bytes.Length) bytes"

if ($SdRoot) {
    Write-Step "Copying to SD card: $SdRoot"
    if (-not (Test-Path $SdRoot)) { throw "SD path not found: $SdRoot" }
    Copy-Item (Join-Path $Release "*") $SdRoot -Recurse -Force
    Write-Ok "Copied to $SdRoot"
}

if ($Zip) {
    $ZipPath = Join-Path $Root "${CoreName}_${Version}_${Date}.zip"
    Write-Step "Zipping release -> $(Split-Path $ZipPath -Leaf)"
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $Release "*") -DestinationPath $ZipPath
    Write-Ok "Wrote $(Split-Path $ZipPath -Leaf)"
}

Write-Step "Done."
