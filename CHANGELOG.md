# Changelog

## [1.2.0] - 2026-06-29

### Added
- LED 走马灯 (Marquee) scrolling — auto-scrolls image content on LED screen
- Distance-driven intermittent scrolling with configurable pause between cycles
- Marquee direction dropdown (Horizontal / Vertical) in Material Inspector
- Unified scroll speed parameter (sign controls direction)
- New foldable section "走马灯 (Marquee)" in Material Inspector (6th panel)
- `_MARQUEE_ON` shader keyword for conditional compilation

## [1.1.0] - 2026-06-29

### Added
- Custom Material Inspector GUI with 5 foldable sections
- Shape dropdown (Circle/Square) with keyword switching
- Image-only transform (Tiling/Offset/Rotation independent of grid)
- Matrix Scale control for dot-matrix display area
- LED color tint (_LEDColor)
- VPM repository support (docs/index.json for VCC installation)
- Build script (build_package.ps1) for VPM ZIP packaging

### Changed
- Package renamed from com.vrchat.led-matrix-shader to com.zer0tsu.led-matrix-shader
- Shader path changed from "VRChat/LEDMatrix" to "zeR0Tsu/LEDMatrix"
- Gaussian glow now uses cross-cell 3x3 neighborhood blending
- Glow model improved with one-minus-product + square-weighted color blend

## [1.0.0] - 2026-06-26

### Added
- Initial release
- UV-based LED grid subdivision with configurable resolution
- Circle / Square LED shape toggle
- Configurable LED duty cycle (size/spacing)
- Gaussian glow effect spilling into gaps between LEDs
- Glow intensity and radius controls
- On/Off threshold based on image luminance
- Background color and off-LED color customization
- Alpha clip support
- VRChat compatible (Built-in pipeline, Transparent queue)
