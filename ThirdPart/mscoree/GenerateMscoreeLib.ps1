#Requires -Version 5.1
<#
.SYNOPSIS
    NETFXSDK が無い環境向けに、システムの mscoree.dll から x64 用 mscoree.lib
    （インポートライブラリ）を自動生成する。PCMgrLoader の x64 ビルドがリンク時に要求する。

.PARAMETER Force
    既存の mscoree.lib があっても再生成する。
#>
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$OutDir = Join-Path $PSScriptRoot "x64"
$OutLib = Join-Path $OutDir "mscoree.lib"

if ((Test-Path $OutLib) -and -not $Force) {
    Write-Host "mscoree.lib は既に存在します: $OutLib" -ForegroundColor DarkGray
    return
}

$VsWhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $VsWhere)) { throw "vswhere.exe が見つかりません。Visual Studio / Build Tools をインストールしてください。" }
$VcInstallPath = & $VsWhere -latest -products '*' -property installationPath
if (-not $VcInstallPath) { throw "Visual Studio / Build Tools のインストールが見つかりません。" }

$MsvcVersionDir = Get-ChildItem (Join-Path $VcInstallPath "VC\Tools\MSVC") -Directory | Sort-Object Name -Descending | Select-Object -First 1
if (-not $MsvcVersionDir) { throw "MSVC ツールセットが見つかりません。" }
$ToolBin = Join-Path $MsvcVersionDir.FullName "bin\Hostx64\x64"
$DumpbinExe = Join-Path $ToolBin "dumpbin.exe"
$LibExe = Join-Path $ToolBin "lib.exe"
if (-not (Test-Path $DumpbinExe) -or -not (Test-Path $LibExe)) { throw "dumpbin.exe / lib.exe が見つかりません: $ToolBin" }

$SysMscoree = Join-Path $env:WINDIR "System32\mscoree.dll"
if (-not (Test-Path $SysMscoree)) { throw "$SysMscoree が見つかりません。" }

Write-Host "Generating mscoree.lib from $SysMscoree ..." -ForegroundColor Cyan

$WorkDir = Join-Path $env:TEMP "pcmgr_mscoree_gen"
if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
$DumpOut = Join-Path $WorkDir "dumpbin_exports.txt"
$DefFile = Join-Path $WorkDir "mscoree.def"

& $DumpbinExe /exports $SysMscoree | Out-File -FilePath $DumpOut -Encoding ascii
if ($LASTEXITCODE -ne 0) { throw "dumpbin /exports failed (exit $LASTEXITCODE)" }

$lines = Get-Content $DumpOut
$names = foreach ($line in $lines) {
    if ($line -match '^\s*\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\S+)\s*$') {
        $Matches[1]
    }
}
if (-not $names -or $names.Count -eq 0) { throw "mscoree.dll からエクスポート関数を抽出できませんでした。" }

"LIBRARY mscoree.dll" | Set-Content -Path $DefFile -Encoding ascii
"EXPORTS" | Add-Content -Path $DefFile -Encoding ascii
foreach ($n in $names) { "    $n" | Add-Content -Path $DefFile -Encoding ascii }

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
& $LibExe "/def:$DefFile" "/out:$OutLib" /machine:x64 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "lib.exe failed (exit $LASTEXITCODE)" }

Write-Host "Generated: $OutLib ($($names.Count) exports)" -ForegroundColor Green
