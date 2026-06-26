using UnityEditor;
using UnityEngine;

/// <summary>
/// Custom material inspector for VRChat/LEDMatrix shader.
/// Provides grouped layout, shape dropdown, and quick presets.
/// </summary>
public class LEDMatrixShaderGUI : ShaderGUI
{
    // ── Cached material properties ────────────────────────────
    private MaterialProperty _mainTex;
    private MaterialProperty _gridResolution;
    private MaterialProperty _ledSize;
    private MaterialProperty _circleShape;
    private MaterialProperty _squareShape;
    private MaterialProperty _bgColor;
    private MaterialProperty _offColor;
    private MaterialProperty _onThreshold;
    private MaterialProperty _glowEnabled;
    private MaterialProperty _glowIntensity;
    private MaterialProperty _glowRadius;
    private MaterialProperty _clip;
    private MaterialProperty _clipThreshold;

    private MaterialEditor _editor;
    private Material _material;

    // ── Preset definitions ────────────────────────────────────
    private static readonly Preset[] Presets = new[]
    {
        new Preset("经典点阵", 32,  0.7f,  true, 1.5f, 0.25f),
        new Preset("高密度屏", 64,  0.85f, true, 1.0f, 0.10f),
        new Preset("复古霓虹", 16,  0.55f, true, 2.5f, 0.35f),
        new Preset("无辉光",   32,  0.7f,  false,0f,   0f),
    };

    private struct Preset
    {
        public string name;
        public float resolution;
        public float ledSize;
        public bool glowOn;
        public float glowIntensity;
        public float glowRadius;

        public Preset(string name, float res, float size, bool glow, float intensity, float radius)
        {
            this.name = name;
            this.resolution = res;
            this.ledSize = size;
            this.glowOn = glow;
            this.glowIntensity = intensity;
            this.glowRadius = radius;
        }
    }

    // ── Entry point ───────────────────────────────────────────
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _editor = materialEditor;
        _material = materialEditor.target as Material;

        CacheProperties(properties);

        // ── Preset buttons ────────────────────────────────────
        EditorGUILayout.Space(4);
        EditorGUILayout.LabelField("快速预设", EditorStyles.boldLabel);
        EditorGUILayout.BeginHorizontal();
        foreach (var preset in Presets)
        {
            if (GUILayout.Button(preset.name, GUILayout.Height(28)))
            {
                ApplyPreset(preset);
            }
        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space(8);

        // ── Section: 贴图 ─────────────────────────────────────
        DrawSectionHeader("📷 源贴图");
        _editor.TexturePropertySingleLine(new GUIContent("Source Image"), _mainTex);
        EditorGUILayout.Space(6);

        // ── Section: 网格 / LED 形状 ──────────────────────────
        DrawSectionHeader("🔲 LED 网格");
        _editor.ShaderProperty(_gridResolution, "分辨率 (Grid Resolution)");
        _editor.ShaderProperty(_ledSize, "LED 占空比 (Size)");
        DrawShapeDropdown();
        EditorGUILayout.Space(6);

        // ── Section: 颜色 ─────────────────────────────────────
        DrawSectionHeader("🎨 颜色");
        _editor.ShaderProperty(_bgColor, "背景色 (Background)");
        _editor.ShaderProperty(_offColor, "灭灯颜色 (Off LED)");
        _editor.ShaderProperty(_onThreshold, "点亮阈值 (On Threshold)");
        EditorGUILayout.Space(6);

        // ── Section: 辉光 ─────────────────────────────────────
        DrawSectionHeader("✨ 辉光 (Glow)");
        _editor.ShaderProperty(_glowEnabled, "启用辉光");
        if (_glowEnabled.floatValue > 0.5f)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_glowIntensity, "辉光强度 (Intensity)");
            _editor.ShaderProperty(_glowRadius, "辉光半径 (Radius)");
            EditorGUI.indentLevel--;
        }
        EditorGUILayout.Space(6);

        // ── Section: Alpha Clip ───────────────────────────────
        DrawSectionHeader("✂️ Alpha Clip");
        _editor.ShaderProperty(_clip, "启用 Alpha Clip");
        if (_clip.floatValue > 0.5f)
        {
            EditorGUI.indentLevel++;
            _editor.ShaderProperty(_clipThreshold, "裁剪阈值 (Threshold)");
            EditorGUI.indentLevel--;
        }

        EditorGUILayout.Space(4);
    }

    // ── Helpers ───────────────────────────────────────────────

    private void CacheProperties(MaterialProperty[] props)
    {
        _mainTex        = FindProperty("_MainTex",        props);
        _gridResolution = FindProperty("_GridResolution", props);
        _ledSize        = FindProperty("_LEDSize",        props);
        _circleShape    = FindProperty("_CircleShape",    props);
        _squareShape    = FindProperty("_SquareShape",    props);
        _bgColor        = FindProperty("_BgColor",        props);
        _offColor       = FindProperty("_OffColor",       props);
        _onThreshold    = FindProperty("_OnThreshold",    props);
        _glowEnabled    = FindProperty("_GlowEnabled",    props);
        _glowIntensity  = FindProperty("_GlowIntensity",  props);
        _glowRadius     = FindProperty("_GlowRadius",     props);
        _clip           = FindProperty("_Clip",           props);
        _clipThreshold  = FindProperty("_ClipThreshold",  props);
    }

    private void DrawSectionHeader(string label)
    {
        EditorGUILayout.LabelField(label, EditorStyles.boldLabel);
        Rect r = EditorGUILayout.GetControlRect(false, 1);
        EditorGUI.DrawRect(r, new Color(0.35f, 0.35f, 0.35f));
        EditorGUILayout.Space(3);
    }

    private void DrawShapeDropdown()
    {
        // Determine current shape (circle takes priority if both on)
        int currentShape = _circleShape.floatValue > 0.5f ? 0 :
                           _squareShape.floatValue > 0.5f ? 1 : 0;

        EditorGUI.BeginChangeCheck();
        int newShape = EditorGUILayout.Popup("LED 形状 (Shape)", currentShape, new[] { "⚫ 圆形 (Circle)", "⬜ 方形 (Square)" });
        if (EditorGUI.EndChangeCheck())
        {
            _circleShape.floatValue = (newShape == 0) ? 1f : 0f;
            _squareShape.floatValue = (newShape == 1) ? 1f : 0f;

            // Sync keywords
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

    private void ApplyPreset(Preset preset)
    {
        Undo.RecordObjects(_editor.targets, "Apply LED Matrix Preset");

        _gridResolution.floatValue = preset.resolution;
        _ledSize.floatValue        = preset.ledSize;
        _glowEnabled.floatValue    = preset.glowOn ? 1f : 0f;
        _glowIntensity.floatValue  = preset.glowIntensity;
        _glowRadius.floatValue     = preset.glowRadius;

        foreach (var obj in _editor.targets)
        {
            var mat = obj as Material;
            if (mat == null) continue;
            mat.SetFloat("_GridResolution", preset.resolution);
            mat.SetFloat("_LEDSize",        preset.ledSize);
            mat.SetFloat("_GlowEnabled",    preset.glowOn ? 1f : 0f);
            mat.SetFloat("_GlowIntensity",  preset.glowIntensity);
            mat.SetFloat("_GlowRadius",     preset.glowRadius);

            if (preset.glowOn)
                mat.EnableKeyword("_GLOW_ON");
            else
                mat.DisableKeyword("_GLOW_ON");
        }
    }
}
