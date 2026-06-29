using UnityEditor;
using UnityEngine;

/// <summary>
/// Custom material inspector for VRChat/LEDMatrix shader.
/// Provides foldable grouped layout, shape dropdown, and quick presets.
/// </summary>
public class LEDMatrixShaderGUI : ShaderGUI
{
    // ── Cached material properties ────────────────────────────
    private MaterialProperty _mainTex;
    private MaterialProperty _imageTiling;
    private MaterialProperty _imageOffset;
    private MaterialProperty _imageRotation;
    private MaterialProperty _gridResolution;
    private MaterialProperty _matrixScale;
    private MaterialProperty _ledSize;
    private MaterialProperty _circleShape;
    private MaterialProperty _squareShape;
    private MaterialProperty _bgColor;
    private MaterialProperty _offColor;
    private MaterialProperty _ledColor;
    private MaterialProperty _onThreshold;
    private MaterialProperty _glowEnabled;
    private MaterialProperty _glowIntensity;
    private MaterialProperty _glowRadius;
    private MaterialProperty _clip;
    private MaterialProperty _clipThreshold;
    private MaterialProperty _marqueeEnabled;
    private MaterialProperty _marqueeDirection;
    private MaterialProperty _scrollSpeed;
    private MaterialProperty _scrollDistance;
    private MaterialProperty _pauseDuration;

    private MaterialEditor _editor;

    // ── Foldout states (persisted via EditorPrefs) ────────────
    private static bool FoldoutTexture = true;
    private static bool FoldoutGrid    = true;
    private static bool FoldoutColor   = true;
    private static bool FoldoutGlow    = true;
    private static bool FoldoutAlpha   = false;
    private static bool FoldoutMarquee = false;

    // ── Entry point ───────────────────────────────────────────
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _editor = materialEditor;
        CacheProperties(properties);

        // ── Foldout sections ──────────────────────────────────
        // ═══════════════════════════════════════════════════════
        //  Section: Texture
        // ═══════════════════════════════════════════════════════
        FoldoutTexture = DrawFoldoutHeader("📷 贴图 (Texture)", FoldoutTexture);
        if (FoldoutTexture)
        {
            EditorGUI.indentLevel++;
            _editor.TexturePropertySingleLine(new GUIContent("Source Image"), _mainTex);
            _editor.TextureScaleOffsetProperty(_mainTex);
            EditorGUILayout.Space(2);
            EditorGUILayout.LabelField("图片变换 (Image Transform)", EditorStyles.miniBoldLabel);
            _editor.ShaderProperty(_imageTiling,  "缩放 (Tiling)");
            _editor.ShaderProperty(_imageOffset,  "偏移 (Offset)");
            _editor.ShaderProperty(_imageRotation,"旋转 (Rotation)");
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.Space(4);

        // ═══════════════════════════════════════════════════════
        //  Section: 点阵网格
        // ═══════════════════════════════════════════════════════
        FoldoutGrid = DrawFoldoutHeader("🔲 点阵网格 (Grid)", FoldoutGrid);
        if (FoldoutGrid)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_gridResolution, "分辨率 (Resolution)");
            _editor.ShaderProperty(_matrixScale,    "区域大小 (Matrix Scale)");
            _editor.ShaderProperty(_ledSize,        "占空比 (LED Size)");
            DrawShapeDropdown();
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.Space(4);

        // ═══════════════════════════════════════════════════════
        //  Section: 颜色
        // ═══════════════════════════════════════════════════════
        FoldoutColor = DrawFoldoutHeader("🎨 颜色 (Colors)", FoldoutColor);
        if (FoldoutColor)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_bgColor,     "背景色 (Background)");
            _editor.ShaderProperty(_offColor,    "灭灯颜色 (Off LED)");
            _editor.ShaderProperty(_ledColor,    "灯点颜色 (LED Color)");
            _editor.ShaderProperty(_onThreshold, "点亮阈值 (Threshold)");
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.Space(4);

        // ═══════════════════════════════════════════════════════
        //  Section: 辉光
        // ═══════════════════════════════════════════════════════
        FoldoutGlow = DrawFoldoutHeader("✨ 辉光 (Glow)", FoldoutGlow);
        if (FoldoutGlow)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_glowEnabled, "启用辉光");
            if (_glowEnabled.floatValue > 0.5f)
            {
                _editor.ShaderProperty(_glowIntensity, "强度 (Intensity)");
                _editor.ShaderProperty(_glowRadius,    "半径 (Radius)");
            }
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.Space(4);

        // ═══════════════════════════════════════════════════════
        //  Section: Alpha
        // ═══════════════════════════════════════════════════════
        FoldoutAlpha = DrawFoldoutHeader("✂️ Alpha Clip", FoldoutAlpha);
        if (FoldoutAlpha)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_clip, "启用 Alpha Clip");
            if (_clip.floatValue > 0.5f)
            {
                _editor.ShaderProperty(_clipThreshold, "裁剪阈值 (Threshold)");
            }
            EditorGUI.indentLevel--;
        }

        // ═══════════════════════════════════════════════════════
        //  Section: 走马灯 (Marquee)
        // ═══════════════════════════════════════════════════════
        FoldoutMarquee = DrawFoldoutHeader("📜 走马灯 (Marquee)", FoldoutMarquee);
        if (FoldoutMarquee)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_marqueeEnabled, "启用走马灯");
            if (_marqueeEnabled.floatValue > 0.5f)
            {
                DrawMarqueeDirectionDropdown();
                _editor.ShaderProperty(_scrollSpeed,    "滚动速度 (Speed)");
                _editor.ShaderProperty(_scrollDistance, "滚动距离 (Distance)");
                _editor.ShaderProperty(_pauseDuration,  "暂停时长 (Pause)");
            }
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.Space(4);
    }

    // ── Foldout header with horizontal rule ───────────────────
    private static bool DrawFoldoutHeader(string label, bool folded)
    {
        EditorGUILayout.Space(2);
        var style = new GUIStyle(EditorStyles.foldout)
        {
            fontStyle = FontStyle.Bold,
            fontSize  = 12,
        };
        folded = EditorGUILayout.Foldout(folded, label, true, style);
        Rect r = EditorGUILayout.GetControlRect(false, 1);
        EditorGUI.DrawRect(r, new Color(0.3f, 0.3f, 0.3f));
        EditorGUILayout.Space(2);
        return folded;
    }

    // ── Helpers ───────────────────────────────────────────────

    private void CacheProperties(MaterialProperty[] props)
    {
        _mainTex        = FindProperty("_MainTex",        props);
        _imageTiling    = FindProperty("_ImageTiling",    props);
        _imageOffset    = FindProperty("_ImageOffset",    props);
        _imageRotation  = FindProperty("_ImageRotation",  props);
        _gridResolution = FindProperty("_GridResolution", props);
        _matrixScale    = FindProperty("_MatrixScale",    props);
        _ledSize        = FindProperty("_LEDSize",        props);
        _circleShape    = FindProperty("_CircleShape",    props);
        _squareShape    = FindProperty("_SquareShape",    props);
        _bgColor        = FindProperty("_BgColor",        props);
        _offColor       = FindProperty("_OffColor",       props);
        _ledColor       = FindProperty("_LEDColor",       props);
        _onThreshold    = FindProperty("_OnThreshold",    props);
        _glowEnabled    = FindProperty("_GlowEnabled",    props);
        _glowIntensity  = FindProperty("_GlowIntensity",  props);
        _glowRadius     = FindProperty("_GlowRadius",     props);
        _clip           = FindProperty("_Clip",           props);
        _clipThreshold  = FindProperty("_ClipThreshold",  props);
        _marqueeEnabled = FindProperty("_MarqueeEnabled", props);
        _marqueeDirection = FindProperty("_MarqueeDirection", props);
        _scrollSpeed    = FindProperty("_ScrollSpeed",    props);
        _scrollDistance = FindProperty("_ScrollDistance", props);
        _pauseDuration  = FindProperty("_PauseDuration",  props);
    }

    private void DrawShapeDropdown()
    {
        int currentShape = _circleShape.floatValue > 0.5f ? 0 :
                           _squareShape.floatValue > 0.5f ? 1 : 0;

        EditorGUI.BeginChangeCheck();
        int newShape = EditorGUILayout.Popup("LED 形状", currentShape,
            new[] { "⚫ 圆形 (Circle)", "⬜ 方形 (Square)" });
        if (EditorGUI.EndChangeCheck())
        {
            _circleShape.floatValue = (newShape == 0) ? 1f : 0f;
            _squareShape.floatValue = (newShape == 1) ? 1f : 0f;

            foreach (var obj in _editor.targets)
            {
                var mat = obj as Material;
                if (mat == null) continue;
                if (newShape == 0)
                {
                    mat.EnableKeyword("_CIRCLE_SHAPE");
                    mat.DisableKeyword("_SQUARE_SHAPE");
                }
                else
                {
                    mat.DisableKeyword("_CIRCLE_SHAPE");
                    mat.EnableKeyword("_SQUARE_SHAPE");
                }
            }
        }
    }

    private void DrawMarqueeDirectionDropdown()
    {
        int currentDir = _marqueeDirection.floatValue < 0.5f ? 0 : 1;

        EditorGUI.BeginChangeCheck();
        int newDir = EditorGUILayout.Popup("滚动方向 (Direction)", currentDir,
            new[] { "↔ 水平 (Horizontal)", "↕ 垂直 (Vertical)" });
        if (EditorGUI.EndChangeCheck())
        {
            _marqueeDirection.floatValue = newDir;
        }
    }

}

