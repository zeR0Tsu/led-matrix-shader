# LED Matrix Shader — AI Development Specification

> **Project**: Unity Built-in HLSL Shader for VRChat (Avatar + World)
> **Target Pipeline**: Built-in Render Pipeline
> **Shader Language**: HLSL (Unity CG)
> **Current Progress**: 核心着色器 v1 已完成

---

## 1. Requirements Summary

A Unity shader that displays an imported image on an LED dot-matrix screen with the following features:

| # | Feature | Status |
|---|---------|--------|
| 1 | UV-based grid subdivision | ✅ Done |
| 2 | Configurable grid resolution | ✅ Done |
| 3 | Configurable LED shape (circle/square) | ✅ Done |
| 4 | Configurable LED size / duty cycle | ✅ Done |
| 5 | Sample image at cell center (nearest-neighbor style) | ✅ Done |
| 6 | Configurable background color | ✅ Done |
| 7 | Configurable off-LED color | ✅ Done |
| 8 | On-threshold (luminance-based) | ✅ Done |
| 9 | Gaussian glow spilling into gaps (not inside LED) | ✅ Done |
| 10 | Configurable glow intensity & radius | ✅ Done |
| 11 | Hybrid glow (built-in + Bloom compatible output) | ✅ Done |
| 12 | Custom Material Inspector GUI | ❌ Not started |
| 13 | Demo scene | ❌ Not started |
| 14 | Pre-configured materials | ❌ Not started |
| 15 | Sample textures | ❌ Not started |
| 16 | Mobile performance optimization pass | ❌ Not started |

---

## 2. Architectural Decisions (from Design Review)

### 2.1 Core Approach
- **Type**: Hand-written HLSL (CGPROGRAM block in Unity)
- **Grid logic**: UV coordinate subdivision into virtual cells; each cell = one LED
- **No geometry dependency**: Works on any mesh (Quad, plane, etc.)

### 2.2 Per-Fragment Algorithm

```
For each fragment:
  1. Compute cell index: floor(uv * GridResolution)
  2. Compute cell center UV: (cellIndex + 0.5) / GridResolution
  3. Sample _MainTex at cell center → ledColor
  4. Compute distance from fragment to cell center (in cell-space)
     - If CIRCLE:   length(delta)
     - If SQUARE:   max(abs(delta.x), abs(delta.y))
  5. Compute luminance of ledColor
  6. Determine if LED is "on": luminance > _OnThreshold
  7. Determine region:
     - distance < ledHalfSize  → LED body (opaque)
     - distance < ledHalfSize + glowRadius → Glow zone (Gaussian falloff)
     - else → Background
  8. Assign color per region:
     - LED body:     on ? ledColor : _OffColor
     - Glow zone:    on ? ledColor*gaussian : _OffColor*gaussian, alpha = gaussian
     - Background:   _BgColor
```

### 2.3 Glow Model
- **Type**: Gaussian falloff `exp(-d² / 2σ²)` where `d = distance - ledHalfSize`
- **Sigma**: `glowRadius × 0.35`
- **Modulation**: glowFactor = saturate(gaussian × glowIntensity)
- **Alpha**: glowFactor in glow zone, 1.0 in LED body, 1.0 for background
- **Bloom compatibility**: Bright color output naturally works with scene Bloom post-processing

### 2.4 On/Off Threshold
- Uses standard luminance: `0.299R + 0.587G + 0.114B`
- If luminance > `_OnThreshold` → LED shows image color
- If luminance ≤ `_OnThreshold` → LED shows `_OffColor`

---

## 3. Shader Properties Reference

| Property Name | Type | Default | Range | Description |
|---|---|---|---|---|
| `_MainTex` | 2D | white | - | Source image |
| `_GridResolution` | Float | 32 | [1, ∞) | LED grid density |
| `_LEDSize` | Range | 0.7 | [0, 1] | LED duty cycle (0=point, 1=full cell) |
| `_CircleShape` | Toggle | 1 | 0/1 | Use circle LED shape |
| `_SquareShape` | Toggle | 0 | 0/1 | Use square LED shape |
| `_BgColor` | Color | (0.02,0.02,0.02,1) | - | Panel background color |
| `_OffColor` | Color | (0.12,0.12,0.12,1) | - | LED off-state color |
| `_OnThreshold` | Range | 0.05 | [0, 1] | Luminance threshold for on/off |
| `_GlowEnabled` | Toggle | 1 | 0/1 | Enable glow effect |
| `_GlowIntensity` | Range | 1.5 | [0, 5] | Glow brightness multiplier |
| `_GlowRadius` | Range | 0.25 | [0, 0.5] | Glow spread distance in cell-space |
| `_Clip` | Toggle | 0 | 0/1 | Enable alpha clip |
| `_ClipThreshold` | Range | 0.1 | [0, 1] | Alpha clip cutoff |

### Shader Variants (via `shader_feature_local`)
- `_CIRCLE_SHAPE` — Circle LED
- `_SQUARE_SHAPE` — Square LED
- `_GLOW_ON` — Glow enabled
- `UNITY_UI_ALPHACLIP` — Alpha clip enabled

**Note**: If both `_CIRCLE_SHAPE` and `_SQUARE_SHAPE` are enabled, circle takes priority (as defined in the `#if/#elif` chain).

---

## 4. Rendering State

```
Queue:    Transparent
Blend:    SrcAlpha OneMinusSrcAlpha
ZWrite:   Off
Cull:     Off
Lighting: Off
```

---

## 5. Remaining Work

### 5.1 [P0] Custom Material Inspector GUI
**File**: `Editor/LEDMatrixShaderGUI.cs`

Create a custom `ShaderGUI` that provides a more user-friendly material inspector:

- **Shape selector**: Dropdown (Circle / Square) instead of two separate toggles
- **Section headers**: Group parameters visually
- **Live preview**: Show a small preview of current LED pattern
- **Preset buttons**: Quick buttons for "Classic Dot", "High Density", "Retro Neon"

```csharp
// Expected structure:
using UnityEditor;
using UnityEngine;

public class LEDMatrixShaderGUI : ShaderGUI
{
    MaterialProperty gridResolution;
    MaterialProperty ledSize;
    // ... etc
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // Layout optimized for LED matrix controls
    }
}
```

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

## 6. VRChat Compatibility Notes

- ✅ Built-in pipeline — fully compatible
- ✅ Transparent queue — works in both World and Avatar
- ✅ No post-processing dependency — glow is built-in
- ✅ Bloom compatible — bright alpha output enhances scene Bloom if present
- ⚠️ Avatar usage: Glow works via alpha blending; Bloom depends on world settings
- ⚠️ Quest/Android: Test glow performance; consider reducing `_GlowRadius` default

---

## 7. File Structure

```
f:\dev\shader\LED点阵材质\
├── AI_DEV_SPEC.md                  ← This file — AI-readable dev spec
├── README.md                       ← User manual
├── LEDMatrix.shader                ← Core shader (v1 complete)
├── package.json                    ← UPM package manifest (VCC compatible)
├── CHANGELOG.md                    ← Version history
├── LICENSE                         ← MIT License
├── .gitignore                      ← Unity gitignore
├── Editor\
│   └── LEDMatrixShaderGUI.cs       ← Custom material inspector [TODO]
├── Materials\
│   ├── LEDMatrix_Classic32.mat     ← [TODO]
│   ├── LEDMatrix_HighDensity64.mat ← [TODO]
│   ├── LEDMatrix_Retro16.mat       ← [TODO]
│   └── LEDMatrix_NoGlow.mat        ← [TODO]
├── Textures\
│   ├── TestPattern.png             ← [TODO]
│   └── SampleLogo.png              ← [TODO]
└── Scenes\
    └── LEDMatrix_Demo.unity        ← [TODO]
```

---

## 8. Development Progress Summary

```
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░  78%  Complete
                       
Core Shader Logic      ▓▓▓▓▓▓▓▓▓▓  100%
Glow Effect            ▓▓▓▓▓▓▓▓▓▓  100%
Shape Switching        ▓▓▓▓▓▓▓▓▓▓  100%
Color Customization    ▓▓▓▓▓▓▓▓▓▓  100%
───────────────        
Material GUI           ░░░░░░░░░░░   0%
Sample Materials       ░░░░░░░░░░░   0%
Sample Textures        ░░░░░░░░░░░   0%
Demo Scene             ░░░░░░░░░░░   0%
Performance Opt.       ░░░░░░░░░░░   0%
```

---

*Generated from design review (grillme session) — 2026-06-26*
*Last spec update: v1.0*
