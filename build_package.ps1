# LED Matrix Shader - VPM package builder
# Usage:
#   .\build_package.ps1              # build with version from package.json
#   .\build_package.ps1 -Version "1.1.0"  # build with specific version
# Output: Builds\com.zer0tsu.led-matrix-shader-<version>.zip

param(
    [string]$Version
)

$name = "com.zer0tsu.led-matrix-shader"

# Read version from package.json if not specified
if (-not $Version) {
    $pkg = Get-Content ".\package.json" | ConvertFrom-Json
    $Version = $pkg.version
}

$zipName = "$name-$Version.zip"
$buildDir = ".\Builds"
$stageDir = "$buildDir\_stage_$Version"

# Ensure Builds directory exists
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir -Force | Out-Null }

# Clean staging directory
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

# Copy necessary files (no .meta files)
$items = @(
    "package.json",
    "LEDMatrix.shader",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "AI_DEV_SPEC.md",
    "Editor\LEDMatrixShaderGUI.cs",
    "Materials\",
    "Textures\",
    "Scenes\"
)

foreach ($item in $items) {
    $src = ".\$item"
    $dst = "$stageDir\$item"
    if (Test-Path $src) {
        $parent = Split-Path $dst -Parent
        if (!(Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        if ((Get-Item $src) -is [System.IO.DirectoryInfo]) {
            Copy-Item "$src\*" "$dst\" -Recurse -Force
        } else {
            Copy-Item $src $dst -Force
        }
    }
}

# Compress to Builds directory
$compressPath = "$buildDir\$zipName"
if (Test-Path $compressPath) { Remove-Item $compressPath -Force }
Compress-Archive -Path "$stageDir\*" -DestinationPath $compressPath

# Clean staging directory
Remove-Item $stageDir -Recurse -Force

Write-Host "=============================="
Write-Host " Build complete: $zipName"
Write-Host " Output: $compressPath"
Write-Host "=============================="
Write-Host ""
Write-Host "Publish steps:"
Write-Host "  1. Create GitHub Release (tag: v$Version)"
Write-Host "  2. Upload $zipName as release asset"
Write-Host "  3. Update docs/index.json with new version entry"
Write-Host "=============================="
