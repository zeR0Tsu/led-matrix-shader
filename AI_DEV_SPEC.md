# LED Matrix Shader — AI Development Specification

> **Project**: Unity Built-in HLSL Shader for VRChat (Avatar + World)
> **Target Pipeline**: Built-in Render Pipeline
> **Shader Language**: HLSL (Unity CG)
> **Current Progress**: v1.1 — 核心功能 + 自定义 GUI 完成

---

## 1. Requirements Summary

A Unity shader that displays an imported image on an LED dot-matrix screen with the following features:

| # | Feature | Status |
|---|---------|--------|
| 1 | UV-based grid subdivision | ✅ Done |
| 2 | Configurable grid resolution | ✅ Done |
| 3 | Configurable LED shape (circle/square dropdown) | ✅ Done |
| 4 | Configurable LED size / duty cycle | ✅ Done |
| 5 | Sample image at cell center (nearest-neighbor) | ✅ Done |
| 6 | Configurable background color | ✅ Done |
| 7 | Configurable off-LED color | ✅ Done |
| 8 | On-threshold (luminance-based, post-tint) | ✅ Done |
| 9 | Cross-cell Gaussian glow with neighbor blending | ✅ Done |
| 10 | Configurable glow intensity & radius (0~2.0) | ✅ Done |
| 11 | One-minus-product glow blending (soft saturation) | ✅ Done |
| 12 | Custom Material Inspector GUI (foldable sections) | ✅ Done |
| 13 | Matrix scale (dot-matrix area on panel) | ✅ Done |
| 14 | Independent image transform (scale/offset/rotation) | ✅ Done |
| 15 | LED color tint | ✅ Done |
| 16 | TRANSFORM_TEX + Image Transform dual pipeline | ✅ Done |
| 17 | Demo scene | ❌ Not started |
| 18 | Pre-configured materials | ❌ Not started |
| 19 | Sample textures | ❌ Not started |
| 20 | Mobile performance optimization pass | ❌ Not started |

---

## 2. Architectural Decisions (from Design Review)

### 2.1 Core Approach
- **Type**: Hand-written HLSL (CGPROGRAM block in Unity)
- **Grid logic**: UV coordinate subdivision into virtual cells; each cell = one LED
- **No geometry dependency**: Works on any mesh (Quad, plane, etc.)

### 2.2 Per-Fragment Algorithm (v1.1)

```
For each fragment:
  0. Map UV to matrix area: matrixUV = (uv - 0.5) / MatrixScale + 0.5
  1. Compute cell index: floor(matrixUV * GridResolution)
  2. Compute cell center UV: (cellIndex + 0.5) / GridResolution
  3. Apply image-only transform to cellCenter → sampleUV
  4. Sample _MainTex at sampleUV → ledColor
  5. Compute distance from fragment to cell center (in cell-space)
     - If CIRCLE:   length(delta)
     - If SQUARE:   max(abs(delta.x), abs(delta.y))
  6. Apply LED tint: tintedColor = ledColor.rgb * _LEDColor.rgb
  7. Compute luminance of tintedColor
  8. Determine if LED is "on": luminance > _OnThreshold
  9. Determine region:
     - distance < ledHalfSize  → LED body (opaque)
     - else → Glow/Background zone
  10. LED body: on ? tintedColor : _OffColor
  11. Glow zone: search 3x3 neighbor cells, accumulate via one-minus-product, square-weighted color blend
  12. Background: _BgColor
```

### 2.3 Glow Model (v1.1)
- **Type**: Gaussian falloff `exp(-d² / 2σ²)` where `d = distance - ledHalfSize`
- **Sigma**: `glowRadius × 0.35`
- **Neighborhood**: Scans 3×3 neighbor cells for lit LEDs (cross-cell glow)
- **Intensity blending**: one-minus-product `combined = 1 - ∏(1 - g_i)` — soft saturation
- **Color blending**: Square-weighted `Σ(color_i × g_i²) / Σ(g_i²)` — closer LEDs dominate
- **Rendering**: Fully opaque, glow blends between `_BgColor` and LED color
- **Range**: `_GlowRadius` 0 ~ 2.0 cell units

### 2.4 On/Off Threshold (v1.1)
- Uses standard luminance: `0.299R + 0.587G + 0.114B`
- Luminance computed AFTER `_LEDColor` tint is applied
- If luminance > `_OnThreshold` → LED shows tinted image color
- If luminance ≤ `_OnThreshold` → LED shows `_OffColor`

### 2.5 UV Transform Pipeline (v1.1)
```
Original UV
    │
    ├─→ TRANSFORM_TEX (_MainTex_ST Tiling/Offset)  ← 网格+图片整体缩放
    │       │
    │       └─→ Matrix Scale remap                 ← 面板上点阵显示区域
    │               │
    │               └─→ Grid computation            ← 网格定位
    │
    └─→ TransformImageUV (Tiling→Rotate→Offset)    ← 仅图片采样坐标
            │
            └─→ tex2D(_MainTex, sampleUV)           ← 图片颜色
```

---

## 3. Shader Properties Reference (v1.1)

| Property Name | Type | Default | Range | Description |
|---|---|---|---|---|
| `_MainTex` | 2D | white | - | Source image (built-in Tiling/Offset via TRANSFORM_TEX) |
| `_ImageTiling` | Vector | (1,1,0,0) | - | Image-only scale (does not affect grid) |
| `_ImageOffset` | Vector | (0,0,0,0) | - | Image-only offset |
| `_ImageRotation` | Range | 0 | [-180, 180] | Image-only rotation (degrees) |
| `_GridResolution` | Float | 32 | [1, ∞) | LED grid density |
| `_MatrixScale` | Range | 1.0 | [0.1, 2.0] | Dot-matrix display area on panel |
| `_LEDSize` | Range | 0.7 | [0, 1] | LED duty cycle |
| `_CircleShape` | Toggle | 1 | 0/1 | Circle LED (managed by shape dropdown) |
| `_SquareShape` | Toggle | 0 | 0/1 | Square LED (managed by shape dropdown) |
| `_BgColor` | Color | (0.02,0.02,0.02,1) | - | Panel background color |
| `_OffColor` | Color | (0.12,0.12,0.12,1) | - | LED off-state color |
| `_LEDColor` | Color | (1,1,1,1) | - | LED on-state color tint (multiplied) |
| `_OnThreshold` | Range | 0.05 | [0, 1] | Luminance threshold (applied after tint) |
| `_GlowEnabled` | Toggle | 1 | 0/1 | Enable glow effect |
| `_GlowIntensity` | Range | 1.5 | [0, 5] | Glow brightness multiplier |
| `_GlowRadius` | Range | 0.25 | [0, 2.0] | Glow spread (can cross cell boundaries) |
| `_Clip` | Toggle | 0 | 0/1 | Enable alpha clip |
| `_ClipThreshold` | Range | 0.1 | [0, 1] | Alpha clip cutoff |

### Shader Variants (via `shader_feature_local`)
- `_CIRCLE_SHAPE` — Circle LED
- `_SQUARE_SHAPE` — Square LED
- `_GLOW_ON` — Glow enabled
- `UNITY_UI_ALPHACLIP` — Alpha clip enabled

**Note**: If both `_CIRCLE_SHAPE` and `_SQUARE_SHAPE` are enabled, circle takes priority (as defined in the `#if/#elif` chain).

---

## 4. Rendering State (v1.1)

```
Queue:    Geometry (Opaque)
ZWrite:   On
Cull:     Off
Lighting: Off
```

Panel is fully opaque. Glow via color blending on opaque surface — no alpha transparency.

---

## 5. Remaining Work

### 5.1 [✅ DONE] Custom Material Inspector GUI
**File**: `Editor/LEDMatrixShaderGUI.cs`

Implemented with 5 foldable sections, shape dropdown, and all v1.1 properties exposed.

### 5.2 [P1] Pre-configured Materials
**Directory**: `Materials/`

Create `.mat` files with common presets:

| File | Resolution | LED Size | Glow | Style |
|---|---|---|---|---|
| `LEDMatrix_Classic32.mat` | 32 | 0.7 | On | Classic dot-matrix |
| `LEDMatrix_HighDensity64.mat` | 64 | 0.85 | On | High-res display |
| `LEDMatrix_Retro16.mat` | 16 | 0.55 | On (high) | Retro neon |
| `LEDMatrix_NoGlow.mat` | 32 | 0.7 | Off | Clean dot-matrix |

### 5.3 [P1] Sample Textures
**Directory**: `Textures/`

Create or include sample textures for testing:
- Test pattern (color bars, gradients)
- Simple logo/graphic
- Grid test pattern

### 5.4 [P2] Demo Scene
**Directory**: `Scenes/`

Create a simple Unity scene showing:
- Multiple Quads with different preset materials
- A rotating display showing different images
- Comparison with/without glow

**Note**: Demo scene requires Unity to create properly (.unity files are binary-like YAML). This is lowest priority.

### 5.5 [P2] Mobile/VRChat Performance Optimization
Potential optimizations for VRChat:

- **LOD variant**: If grid resolution is very high (≥128), consider a simplified version
- **Reduce texture samples**: Currently 1 sample per fragment (cell center). Could use `tex2Dlod` with explicit LOD
- **Pre-compute cell centers** in vertex shader for very low-res grids (only if needed)
- **Test on Quest/Android**: Ensure transparent shader performs well

---

## 6. VRChat Compatibility Notes (v1.1)

- ✅ Built-in pipeline — fully compatible
- ✅ Opaque queue (Geometry) — works in both World and Avatar
- ✅ No post-processing dependency — glow is built-in via color blending
- ⚠️ Bloom: Scene Bloom PP will pick up bright LED colors naturally
- ⚠️ Quest/Android: 9 tex samples/fragment in glow zone (3×3 neighborhood) — test perf

---

## 7. File Structure

```
LED点阵材质/
├── AI_DEV_SPEC.md                  ← AI-readable dev spec
├── README.md                       ← User manual
├── LEDMatrix.shader                ← Core shader (v1.1)
├── package.json                    ← UPM package manifest
├── CHANGELOG.md                    ← Version history
├── LICENSE                         ← MIT License
├── Editor/
│   └── LEDMatrixShaderGUI.cs       ← Custom material inspector [✅ DONE]
├── Materials/                      ← [TODO] Pre-configured materials
├── Textures/                       ← [TODO] Sample textures
└── Scenes/                         ← [TODO] Demo scene
```

---

## 8. Development Progress Summary

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░  90%  Complete
                       
Core Shader Logic      ▓▓▓▓▓▓▓▓▓▓  100%
Glow Effect            ▓▓▓▓▓▓▓▓▓▓  100%
Shape Switching        ▓▓▓▓▓▓▓▓▓▓  100%
Color Customization    ▓▓▓▓▓▓▓▓▓▓  100%
Image Transform        ▓▓▓▓▓▓▓▓▓▓  100%
Material GUI           ▓▓▓▓▓▓▓▓▓▓  100%
───────────────        
Sample Materials       ░░░░░░░░░░░   0%
Sample Textures        ░░░░░░░░░░░   0%
Demo Scene             ░░░░░░░░░░░   0%
Performance Opt.       ░░░░░░░░░░░   0%
```

---

*Generated from design review — 2026-06-26*
*Last spec update: v1.1 — 2026-06-27*
