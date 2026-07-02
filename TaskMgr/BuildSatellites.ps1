param(
    [string]$ProjectRoot,
    [string]$IntermediateDir,
    [string]$OutDir,
    [string]$RootNamespace,
    [string]$AssemblyName,
    [string]$Cultures
)

# MSBuild Exec passes paths ending in \" which PowerShell parses as an escaped quote,
# leaving a trailing " in the string. Strip it along with any trailing slashes.
function Clean([string]$p) { return $p.TrimEnd('"').TrimEnd('\').TrimEnd('/') }
$ProjectRoot     = Clean $ProjectRoot
$IntermediateDir = Clean $IntermediateDir
$OutDir          = Clean $OutDir

Add-Type -Assembly "System.Drawing"
Add-Type -Assembly "System.Windows.Forms"

# Framework csc.exe can build resource-only satellite assemblies (the new SDK's AL task is
# incompatible with this project). The satellite only carries an AssemblyCulture attribute,
# so C# 5 era csc is sufficient.
$csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { Write-Warning "csc.exe not found: $csc"; exit 0 }

# Satellite assemblies must carry the SAME version as the main assembly, otherwise the
# resource loader silently ignores them. Read it back from the freshly built main assembly.
$mainDll = Join-Path $OutDir "$AssemblyName.dll"
$version = "1.3.2.6"
if (Test-Path $mainDll) {
    try { $version = [System.Reflection.AssemblyName]::GetAssemblyName($mainDll).Version.ToString() } catch { }
}

foreach ($culture in ($Cultures -split ',')) {
    $culture = $culture.Trim()
    if ($culture -eq '') { continue }

    $resxFiles = @(Get-ChildItem $ProjectRoot -Filter "*.$culture.resx" -Recurse)
    if ($resxFiles.Count -eq 0) { continue }

    $cultureTmp = Join-Path $IntermediateDir $culture
    if (-not (Test-Path $cultureTmp)) { New-Item -ItemType Directory -Path $cultureTmp -Force | Out-Null }

    $resourceArgs = @()
    foreach ($file in $resxFiles) {
        $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1)
        # Inside a satellite the resource stream keeps the culture in its name
        # (e.g. PCMgr.WorkWindow.FormVPrivileges.ja.resources); ResourceManager looks it up as
        # "<baseName>.<culture>.resources". The base part is filename-derived so it matches the
        # neutral resource's base name embedded in the main assembly.
        $manifestName = $RootNamespace + "." + (($relativePath -replace "\\", ".") -replace "\.resx$", ".resources")
        $outRes = Join-Path $cultureTmp $manifestName
        try {
            $reader = New-Object System.Resources.ResXResourceReader($file.FullName)
            $reader.BasePath = $file.Directory.FullName
            $reader.UseResXDataNodes = $false
            $outStream = [System.IO.File]::Create($outRes)
            $writer = New-Object System.Resources.ResourceWriter($outStream)
            foreach ($entry in $reader) { $writer.AddResource($entry.Key, $entry.Value) }
            $writer.Generate(); $writer.Close(); $outStream.Close(); $reader.Close()
            $resourceArgs += "/resource:$outRes,$manifestName"
        } catch {
            Write-Warning "RESX compile failed: $manifestName - $_"
        }
    }
    if ($resourceArgs.Count -eq 0) { continue }

    $stub = Join-Path $cultureTmp "_AssemblyCulture.cs"
    @(
        "using System.Reflection;",
        "[assembly: AssemblyCulture(""$culture"")]",
        "[assembly: AssemblyVersion(""$version"")]",
        "[assembly: AssemblyFileVersion(""$version"")]"
    ) | Set-Content -LiteralPath $stub -Encoding UTF8

    $satDir = Join-Path $OutDir $culture
    if (-not (Test-Path $satDir)) { New-Item -ItemType Directory -Path $satDir -Force | Out-Null }
    $outDll = Join-Path $satDir "$AssemblyName.resources.dll"

    $cscArgs = @("/nologo", "/target:library", "/out:$outDll") + $resourceArgs + @($stub)
    & $csc $cscArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "csc failed for culture '$culture' (exit $LASTEXITCODE)"
    } else {
        Write-Host "Built satellite: $culture\$AssemblyName.resources.dll ($($resourceArgs.Count) resources, v$version)"
    }
}
