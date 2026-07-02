param(
    [string]$ProjectRoot,
    [string]$OutputDir
)

# MSBuild Exec passes paths ending in \" which PowerShell parses as an escaped quote,
# leaving a trailing " in the string. Strip it along with any trailing slashes.
$OutputDir = $OutputDir.TrimEnd('"').TrimEnd('\').TrimEnd('/')
$ProjectRoot = $ProjectRoot.TrimEnd('"').TrimEnd('\').TrimEnd('/')

Add-Type -Assembly "System.Drawing"
Add-Type -Assembly "System.Windows.Forms"

$rootNamespace = "PCMgr"

$resxFiles = Get-ChildItem $ProjectRoot -Filter "*.resx" -Recurse |
    Where-Object { $_.Name -notmatch '\.[a-z]{2}(-[A-Z]{2})?\.resx$' }

foreach ($file in $resxFiles) {
    $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1)
    $resourceName = $rootNamespace + "." + ($relativePath -replace "\\", "." -replace "\.resx$", ".resources")
    $outputPath = Join-Path $OutputDir $resourceName

    try {
        $reader = New-Object System.Resources.ResXResourceReader($file.FullName)
        $reader.BasePath = $file.Directory.FullName
        $reader.UseResXDataNodes = $false

        $outStream = [System.IO.File]::Create($outputPath)
        $writer = New-Object System.Resources.ResourceWriter($outStream)

        foreach ($entry in $reader) {
            $writer.AddResource($entry.Key, $entry.Value)
        }
        $writer.Generate()
        $writer.Close()
        $outStream.Close()
        $reader.Close()
    } catch {
        # On failure, try to copy a pre-extracted fallback from the project
        $fallback = Join-Path $ProjectRoot "ResourcesFallback\$resourceName"
        if (Test-Path $fallback) {
            Copy-Item $fallback $outputPath -Force
        } else {
            Write-Warning "RESX compile failed (no fallback): $resourceName - $_"
        }
    }
}
