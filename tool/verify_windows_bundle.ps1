param(
    [string]$Bundle = "build/windows/x64/runner/Release"
)

$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "ripme.exe",
    "flutter_windows.dll",
    "data/icudtl.dat",
    "data/flutter_assets/AssetManifest.bin",
    "data/app.so",
    "LICENSE.txt"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $Bundle $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Windows bundle is missing $relativePath"
    }
}

$version = (Get-Item -LiteralPath (Join-Path $Bundle "ripme.exe")).VersionInfo
if ($version.FileDescription -ne "RipMe") {
    throw "ripme.exe FileDescription is not RipMe"
}
if ($version.ProductName -ne "RipMe") {
    throw "ripme.exe ProductName is not RipMe"
}
if ($version.OriginalFilename -ne "ripme.exe") {
    throw "ripme.exe OriginalFilename is incorrect"
}
if ([string]::IsNullOrWhiteSpace($version.FileVersion) -or
    [string]::IsNullOrWhiteSpace($version.ProductVersion)) {
    throw "ripme.exe is missing version resources"
}

Write-Output "Windows release bundle verified: $Bundle"
