#Requires -Version 5.1
<#
.SYNOPSIS
    PCMgr をビルドして起動するスクリプト。
    初回実行時はビルド済み ZIP を Debug\ に展開してサードパーティ DLL をセットアップします。
    2 回目以降は dotnet build で DLL を更新してそのまま起動します。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot
$DebugDir    = Join-Path $ProjectRoot "Debug"
$ZipPath     = Join-Path $ProjectRoot "Release\Release_x86_1.3.2.6.zip"
$ExePath     = Join-Path $DebugDir    "PCMgr32.exe"

# --- 1. C# 部分をビルド ---
Write-Host "Building PCMgrApp32.dll ..." -ForegroundColor Cyan
dotnet build "$ProjectRoot\TaskMgr\PCMgr32.csproj" `
    -c Debug /p:Platform=x86 `
    /p:FrameworkPathOverride="C:\Windows\Microsoft.NET\Framework\v4.0.30319"
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed (exit $LASTEXITCODE)" }

# --- 2. 初回セットアップ: ZIP 展開 + サードパーティ DLL ---
if (-not (Test-Path $ExePath)) {
    Write-Host "First run: extracting $ZipPath ..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipPath -DestinationPath $DebugDir -Force

    Write-Host "Copying third-party DLLs ..." -ForegroundColor Cyan
    Copy-Item "$ProjectRoot\ThirdPart\AeroWizard\AeroWizard32.dll" $DebugDir -Force
    Copy-Item "$ProjectRoot\ThirdPart\capstone\lib\x86\capstone.dll" $DebugDir -Force
}

# --- 3. 起動 ---
Write-Host "Launching $ExePath ..." -ForegroundColor Green
Start-Process $ExePath -WorkingDirectory $DebugDir -Verb RunAs
