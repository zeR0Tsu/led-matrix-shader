# LED Matrix Shader - VPM 打包脚本
$version = "1.0.0"
$name = "com.vrchat.led-matrix-shader"
$zipName = "$name-$version.zip"
$distDir = ".\dist"

# 创建 dist 目录
if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# 复制必要文件（不含 .meta）
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
    $dst = "$distDir\$item"
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

# 压缩
$compressPath = ".\$zipName"
if (Test-Path $compressPath) { Remove-Item $compressPath -Force }
Compress-Archive -Path "$distDir\*" -DestinationPath $compressPath

# 清理
Remove-Item $distDir -Recurse -Force

Write-Host "✅ 打包完成: $zipName"
Write-Host "请将此 ZIP 上传到 GitHub Release"
