#Requires -Version 5.1
<#
.SYNOPSIS
    PCMgr を 64bit 版としてビルドして起動するスクリプト。
    ネイティブ側（TaskMgrCore 等）を MSBuild で、C# 側（PCMgr64.csproj）を dotnet build で
    ビルドし、ThirdPart の x64 DLL を Debug_64\ にコピーしてから起動します。

    ネイティブ側のビルドには Visual Studio Build Tools（C++ によるデスクトップ開発ワークロード）
    が必要です。カーネルドライバ（PCMgrKernel32.sys）は WDK が無いためビルド対象外です。
    ドライバ機能が未ロードの場合はアプリ側が既定でグレースフルに無効化表示します。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot
$DebugDir    = Join-Path $ProjectRoot "Debug_64"
$ExePath     = Join-Path $DebugDir    "PCMgr64.exe"

# --- 1. ネイティブ側を x64/Debug でビルド ---
Write-Host "Locating MSBuild ..." -ForegroundColor Cyan
$VsWhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
$MSBuildExe = $null
if (Test-Path $VsWhere) {
    $MSBuildExe = & $VsWhere -latest -products '*' -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
}
if (-not $MSBuildExe) {
    throw "MSBuild.exe が見つかりません。Visual Studio Build Tools（C++ によるデスクトップ開発ワークロード）をインストールしてください。"
}

# NETFXSDK が無い環境では mscoree.lib が存在しないため、無ければ自動生成する
& "$ProjectRoot\ThirdPart\mscoree\GenerateMscoreeLib.ps1"

Write-Host "Building native x64 projects ..." -ForegroundColor Cyan
$SolutionDirArg = "$ProjectRoot\"
$NativeProjects = @(
    "PCMgrCmdRunner\PCMgrCmdRunner.vcxproj",
    "PCMgrKrnlMgr\PCMgrKrnlMgr.vcxproj",
    "TaskMgrCore\TaskMgrCore.vcxproj",
    "PCMgrLoader\PCMgrLoader.vcxproj",
    "PCMgrCmd\PCMgrCmd.vcxproj"
)
foreach ($proj in $NativeProjects) {
    $projPath = Join-Path $ProjectRoot $proj
    Write-Host "  -> $proj" -ForegroundColor DarkCyan
    & $MSBuildExe $projPath /p:Configuration=Debug /p:Platform=x64 "/p:SolutionDir=$SolutionDirArg" /v:minimal /nologo
    if ($LASTEXITCODE -ne 0) { throw "MSBuild failed for $proj (exit $LASTEXITCODE)" }
}

# --- 2. C# 部分をビルド ---
Write-Host "Building PCMgrApp64.dll ..." -ForegroundColor Cyan
$DotnetExe = if (Get-Command dotnet -ErrorAction SilentlyContinue) { "dotnet" } else { "C:\Program Files\dotnet\dotnet.exe" }
& $DotnetExe build "$ProjectRoot\TaskMgr\PCMgr64.csproj" `
    -c Debug `
    /p:FrameworkPathOverride="C:\Windows\Microsoft.NET\Framework\v4.0.30319"
if ($LASTEXITCODE -ne 0) { throw "dotnet build failed (exit $LASTEXITCODE)" }

# --- 3. ThirdPart DLL を Debug_64\ にコピー ---
Write-Host "Copying third-party DLLs ..." -ForegroundColor Cyan
if (-not (Test-Path $DebugDir)) { New-Item -ItemType Directory -Path $DebugDir | Out-Null }
Copy-Item "$ProjectRoot\ThirdPart\AeroWizard\AeroWizard64.dll" $DebugDir -Force
Copy-Item "$ProjectRoot\ThirdPart\capstone\lib\x64\capstone.dll" $DebugDir -Force

# --- 4. 起動 ---
if (-not (Test-Path $ExePath)) {
    throw "PCMgr64.exe が見つかりません: $ExePath"
}

Write-Host "Launching $ExePath ..." -ForegroundColor Green
Start-Process $ExePath -WorkingDirectory $DebugDir -Verb RunAs
