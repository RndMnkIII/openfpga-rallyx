#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$Repo,
    [switch]$DryRun,
    [string]$Root
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ReferenceRepos = @(
    @{ Name = "arcade-rallyx_mister"; Url = "https://github.com/MiSTer-devel/Arcade-RallyX_MiSTer.git"; Ref = $null }
    @{ Name = "mister-arcade-rallyx"; Url = "https://github.com/MrX-8B/MiSTer-Arcade-RallyX.git"; Ref = $null }
    @{ Name = "openfpga-atarisystem1"; Url = "https://github.com/obsidian-dot-dev/openFPGA-AtariSystem1.git"; Ref = $null }
    @{ Name = "openfpga-snes-analogizer"; Url = "https://github.com/RndMnkIII/openfpga-SNES-Analogizer.git"; Ref = $null }
)

if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }
$ReposDir = Join-Path $Root ".repos"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "    $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }

function Get-DefaultBranch($path) {
    $head = git -C $path symbolic-ref --quiet refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $head) { return ($head -replace "^refs/remotes/origin/", "") }
    return "HEAD"
}

function Invoke-Git {
    param([string[]]$GitArgs)
    if ($DryRun) { Write-Skip "git $($GitArgs -join " ")"; return }
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join " ") failed (exit $LASTEXITCODE)" }
}

$targets = $ReferenceRepos
if ($Repo) {
    $targets = $ReferenceRepos | Where-Object { $_.Name -eq $Repo }
    if (-not $targets) {
        $names = ($ReferenceRepos | ForEach-Object { $_.Name }) -join ", "
        throw "Unknown repo '$Repo'. Known: $names"
    }
}

if ($DryRun) { Write-Host "(dry run -- no changes will be made)" -ForegroundColor Yellow }
Write-Step "Reference dir: $ReposDir"

if (-not $DryRun -and -not (Test-Path $ReposDir)) {
    New-Item -ItemType Directory -Path $ReposDir | Out-Null
}

$synced = 0
foreach ($r in $targets) {
    $dest = Join-Path $ReposDir $r.Name
    if (Test-Path (Join-Path $dest ".git")) {
        $ref = if ($r.Ref) { $r.Ref } else { Get-DefaultBranch $dest }
        Write-Step "$($r.Name): update -> $ref"
        Invoke-Git @("-C", $dest, "fetch", "--depth", "1", "origin", $ref)
        Invoke-Git @("-C", $dest, "reset", "--hard", "FETCH_HEAD")
        Invoke-Git @("-C", $dest, "clean", "-fdx")
    }
    else {
        $refLabel = if ($r.Ref) { $r.Ref } else { "default branch" }
        Write-Step "$($r.Name): clone -> $refLabel"
        $cloneArgs = @("clone", "--depth", "1")
        if ($r.Ref) { $cloneArgs += @("--branch", $r.Ref) }
        $cloneArgs += @("--single-branch", $r.Url, $dest)
        Invoke-Git $cloneArgs
    }
    Write-Ok "$($r.Name) ok"
    $synced++
}

Write-Step "Done ($synced repo(s))."
