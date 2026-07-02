#Requires -Version 5.1
<#
.SYNOPSIS
    PCMgr をビルドして起動するスクリプト。
    dotnet build で PCMgrApp32.dll をビルドし、ThirdPart の DLL を Debug\ にコピーしてから起動します。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot
$DebugDir    = Join-Path $ProjectRoot "Debug"
$ExePath     = Join-Path $DebugDir    "PCMgr32.exe"

# --- 1. C# 部分をビルド ---
Write-Host "Building PCMgrApp32.dll ..." -ForegroundColor Cyan
$DotnetExe = if (Get-Command dotnet -ErrorAction SilentlyContinue) { "dotnet" } else { "C:\Program Files\dotnet\dotnet.exe" }
& $DotnetExe build "$ProjectRoot\TaskMgr\PCMgr32.csproj" `
    -c Debug /p:Platform=x86 `
    /p:FrameworkPathOverride="C:\Windows\Microsoft.NET\Framework\v4.0.30319"
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed (exit $LASTEXITCODE)" }

# --- 2. ThirdPart DLL を Debug\ にコピー ---
Write-Host "Copying third-party DLLs ..." -ForegroundColor Cyan
if (-not (Test-Path $DebugDir)) { New-Item -ItemType Directory -Path $DebugDir | Out-Null }
Copy-Item "$ProjectRoot\ThirdPart\AeroWizard\AeroWizard32.dll" $DebugDir -Force
Copy-Item "$ProjectRoot\ThirdPart\capstone\lib\x86\capstone.dll" $DebugDir -Force

# --- 3. 起動 ---
if (-not (Test-Path $ExePath)) {
    throw "PCMgr32.exe が見つかりません: $ExePath`nC++ ビルド済みバイナリを Debug\ フォルダに配置してください。"
}

Write-Host "Launching $ExePath ..." -ForegroundColor Green
Start-Process $ExePath -WorkingDirectory $DebugDir -Verb RunAs
