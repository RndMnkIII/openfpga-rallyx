#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$Zip = "$HOME/Downloads/nrallyx.zip",
    [string]$Out
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $Out) { $Out = Join-Path (Split-Path -Parent $PSScriptRoot) "build/nrallyx.rom" }

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }

# Assembly order taken verbatim from the MiSTer "New Rally-X.mra" (rom index 0).
# Off/Len are byte offset + length within each source file (2048-byte halves of
# the 4096-byte program ROMs are interleaved).
$Parts = @(
    @{ File = "nrx_prg1.1d"; Off = 0;    Len = 2048 }
    @{ File = "nrx_prg2.1e"; Off = 0;    Len = 2048 }
    @{ File = "nrx_prg1.1d"; Off = 2048; Len = 2048 }
    @{ File = "nrx_prg2.1e"; Off = 2048; Len = 2048 }
    @{ File = "nrx_prg3.1k"; Off = 0;    Len = 2048 }
    @{ File = "nrx_prg4.1l"; Off = 0;    Len = 2048 }
    @{ File = "nrx_prg3.1k"; Off = 2048; Len = 2048 }
    @{ File = "nrx_prg4.1l"; Off = 2048; Len = 2048 }
    @{ File = "nrx_chg1.8e"; Off = 0;    Len = 2048 }
    @{ File = "nrx_chg2.8d"; Off = 0;    Len = 2048 }
    @{ File = "rx1-6.8m";    Off = 0;    Len = 256 }
    @{ File = "rx1-5.3p";    Off = 0;    Len = 256 }
    @{ File = "nrx1-7.8p";   Off = 0;    Len = 256 }
    @{ File = "nrx1-1.11n";  Off = 0;    Len = 32 }
)
$ExpectedTotal = 21280

if (-not (Test-Path $Zip)) { throw "ROM zip not found: $Zip" }

Write-Step "Extracting $Zip"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("nrx_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Expand-Archive -Path $Zip -DestinationPath $tmp -Force

    Write-Step "Assembling ROM blob per MRA layout"
    $blob = New-Object System.Collections.Generic.List[byte]
    foreach ($p in $Parts) {
        $src = Join-Path $tmp $p.File
        if (-not (Test-Path $src)) { throw "Missing ROM file in zip: $($p.File)" }
        $bytes = [System.IO.File]::ReadAllBytes($src)
        $end = $p.Off + $p.Len
        if ($bytes.Length -lt $end) {
            throw "$($p.File) is $($bytes.Length) bytes, need $end (off $($p.Off) len $($p.Len))"
        }
        for ($i = $p.Off; $i -lt $end; $i++) { $blob.Add($bytes[$i]) }
        Write-Ok ("0x{0:X4}  {1,-13} off {2,4} len {3,4}" -f ($blob.Count - $p.Len), $p.File, $p.Off, $p.Len)
    }

    if ($blob.Count -ne $ExpectedTotal) {
        throw "Assembled $($blob.Count) bytes, expected $ExpectedTotal"
    }

    $outDir = Split-Path -Parent $Out
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    [System.IO.File]::WriteAllBytes($Out, $blob.ToArray())
    Write-Step "Wrote $Out ($($blob.Count) bytes)"
}
finally {
    Remove-Item $tmp -Recurse -Force
}
