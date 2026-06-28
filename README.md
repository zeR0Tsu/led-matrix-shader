# LED 点阵屏着色器 — 使用说明

## 文件位置
- `LEDMatrix.shader` — 主着色器文件
- 使用时将整个文件夹放入 Unity 项目的 `Assets/` 或 `Packages/` 目录即可

## 包目录结构

```
LED点阵材质/
├── LEDMatrix.shader        ← 核心着色器
├── package.json            ← UPM 包清单（VCC 兼容）
├── CHANGELOG.md            ← 版本历史
├── LICENSE                 ← MIT 许可证
├── .gitignore              ← Unity 专用 git 忽略规则
├── README.md               ← 本文件
├── AI_DEV_SPEC.md          ← 开发规范文档
├── Editor/                 ← 编辑器扩展（可选）
├── Materials/              ← 预设材质
├── Textures/               ← 示例贴图
└── Scenes/                 ← 演示场景
```

## 快速使用

1. 创建一个 **Quad**（或任意平面模型）
2. 新建材质，Shader 选择 **zeR0Tsu → LEDMatrix**
3. 把材质拖到模型上
4. 在材质 Inspector 中配置参数

## 材质面板结构

材质 Inspector 使用自定义 GUI，分为 **5 个可折叠面板**：

| 面板 | 包含参数 |
|------|----------|
| **📷 贴图 (Texture)** | Source Image、Tiling/Offset、图片缩放/偏移/旋转 |
| **🔲 点阵网格 (Grid)** | 分辨率、区域大小、占空比、LED 形状 |
| **🎨 颜色 (Colors)** | 背景色、灭灯色、灯点色、点亮阈值 |
| **✨ 辉光 (Glow)** | 启用辉光、强度、半径 |
| **✂️ Alpha Clip** | Alpha Clip 开关、裁剪阈值 |

## 参数说明

### 贴图
| 参数 | 说明 |
|---|---|
| **Source Image** | 要显示的图片纹理 |
| **Tiling / Offset** | Unity 内置，调整点阵在物体上的平铺（网格+图片同步） |
| **图片缩放 (Tiling)** | 仅对图片内容缩放，不影响网格位置 |
| **图片偏移 (Offset)** | 仅对图片内容平移 |
| **图片旋转 (Rotation)** | 以图片中心旋转（-180° ~ 180°） |

### 点阵网格
| 参数 | 说明 |
|---|---|
| **Grid Resolution** | LED 点阵分辨率，越大点越多（如 32、64） |
| **Matrix Scale** | 点阵在面板上的显示区域大小（0.1~2.0） |
| **LED Size (占空比)** | LED 灯点占网格单元的比例（0~1），越小点越细间距越大 |
| **LED 形状** | 下拉菜单切换圆形/方形 LED |

### 颜色
| 参数 | 说明 |
|---|---|
| **背景色** | 面板底色（灯点之间的间隙颜色） |
| **灭灯颜色** | LED 熄灭时的颜色 |
| **灯点颜色** | 点亮 LED 的色调叠加（与图片颜色相乘） |
| **点亮阈值** | 图片亮度超过此值则点亮，低于则熄灭 |

### 辉光
| 参数 | 说明 |
|---|---|
| **启用辉光** | 开启/关闭辉光效果 |
| **辉光强度** | 辉光亮度倍数 |
| **辉光半径** | 辉光扩散距离（0~2.0，可跨格子扩散） |

### Alpha
| 参数 | 说明 |
|---|---|
| **Alpha Clip** | 启用后裁剪半透明区域 |
| **Clip Threshold** | Alpha 裁剪阈值 |

## 建议参数

### 经典点阵屏风格
- Grid Resolution: 32
- LED Size: 0.6~0.7
- Glow Intensity: 1.0~1.5
- Glow Radius: 0.15~0.25

### 高密度像素屏风格
- Grid Resolution: 64~96
- LED Size: 0.8~0.9
- Glow Intensity: 0.5~1.0
- Glow Radius: 0.05~0.1

### 复古霓虹风格
- Grid Resolution: 16~24
- LED Size: 0.5~0.6
- Glow Intensity: 2.0~3.0
- Glow Radius: 0.3~0.4

## VRChat 注意事项

- **World 使用**：推荐开启辉光 + 场景中同时挂载 Post-Processing Bloom，效果叠加更华丽
- **Avatar 使用**：辉光在 Avatar 上也能正常工作，但 Bloom 需看世界是否开启
- 着色器为 **不透明队列**（Geometry），ZWrite 开启，面板完全不透明
- 辉光在背景色上做颜色混合，无透明度依赖
- 支持 **GPU Instancing**（SRP Batcher 不适用 Built-in，但内置合批不受影响）
