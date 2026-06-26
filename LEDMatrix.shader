Shader "VRChat/LEDMatrix"
{
    Properties
    {
        _MainTex ("Source Image", 2D) = "white" {}
        [Space]
        _GridResolution ("Grid Resolution", Float) = 32
        _LEDSize ("LED Size (占空比)", Range(0.0, 1.0)) = 0.7
        [Space]
        [Toggle(_CIRCLE_SHAPE)] _CircleShape ("圆形 LED", Float) = 1
        [Toggle(_SQUARE_SHAPE)] _SquareShape ("方形 LED", Float) = 0
        [Space]
        _BgColor ("背景色 (Background)", Color) = (0.02, 0.02, 0.02, 1)
        _OffColor ("灭灯颜色 (Off LED)", Color) = (0.12, 0.12, 0.12, 1)
        _OnThreshold ("点亮阈值", Range(0.0, 1.0)) = 0.05
        [Space]
        [Toggle(_GLOW_ON)] _GlowEnabled ("启用辉光", Float) = 1
        _GlowIntensity ("辉光强度", Range(0.0, 5.0)) = 1.5
        _GlowRadius ("辉光半径", Range(0.0, 0.5)) = 0.25
        [Space]
        [Toggle(UNITY_UI_ALPHACLIP)] _Clip ("Alpha Clip", Float) = 0
        _ClipThreshold ("Alpha Clip Threshold", Range(0.0, 1.0)) = 0.1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        Lighting Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _CIRCLE_SHAPE
            #pragma shader_feature_local _SQUARE_SHAPE
            #pragma shader_feature_local _GLOW_ON
            #pragma shader_feature_local UNITY_UI_ALPHACLIP
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _GridResolution;
            float _LEDSize;
            float4 _BgColor;
            float4 _OffColor;
            float _OnThreshold;
            float _GlowIntensity;
            float _GlowRadius;
            float _ClipThreshold;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // Luminance helper
            float Luminance(float3 color)
            {
                return dot(color, float3(0.299, 0.587, 0.114));
            }

            // Gaussian falloff
            float GaussianFalloff(float dist, float sigma)
            {
                return exp(-(dist * dist) / (2.0 * sigma * sigma));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float res = max(_GridResolution, 1.0);

                // --- 1. 计算当前像素所在网格单元和单元中心 UV ---
                float2 cellIndex = floor(uv * res);
                float2 cellCenter = (cellIndex + 0.5) / res;

                // --- 2. 在单元中心采样图片（最近邻风格） ---
                fixed4 ledColor = tex2D(_MainTex, cellCenter);

                // --- 3. 计算到单元中心的距离（以网格单元为归一化单位, 0~0.5） ---
                float2 distToCenterVec = (uv - cellCenter) * res;

                float dist;
#if _CIRCLE_SHAPE
                dist = length(distToCenterVec);
#elif _SQUARE_SHAPE
                dist = max(abs(distToCenterVec.x), abs(distToCenterVec.y));
#else
                // 默认圆形（如果不小心两个都没开）
                dist = length(distToCenterVec);
#endif

                // LED 的半尺寸（0 ~ 0.5）
                float ledHalfSize = _LEDSize * 0.5;

                // --- 4. 判断 LED 是否"点亮" ---
                float luma = Luminance(ledColor.rgb);
                bool isOn = luma > _OnThreshold;

                // --- 5. 计算最终颜色 ---
                float4 finalColor;
                float alpha = 1.0;

                if (dist <= ledHalfSize)
                {
                    // ===== LED 灯体内部 =====
                    finalColor.rgb = isOn ? ledColor.rgb : _OffColor.rgb;
                    finalColor.a = 1.0;
                }
                else
                {
                    // ===== 灯体外部：辉光或背景 =====
#if _GLOW_ON
                    float glowDist = dist - ledHalfSize;
                    float maxGlow = _GlowRadius;

                    if (glowDist < maxGlow)
                    {
                        // 高斯衰减
                        float sigma = maxGlow * 0.35;
                        float glowFactor = GaussianFalloff(glowDist, sigma);
                        glowFactor *= _GlowIntensity;
                        glowFactor = saturate(glowFactor);

                        float3 glowColor = isOn ? ledColor.rgb : _OffColor.rgb;
                        finalColor.rgb = glowColor * glowFactor;
                        finalColor.a = glowFactor;
                    }
                    else
                    {
                        // 超出辉光范围 = 背景
                        finalColor = _BgColor;
                    }
#else
                    // 无辉光模式
                    finalColor = _BgColor;
#endif
                }

                // --- 6. Alpha Clip ---
#if UNITY_UI_ALPHACLIP
                clip(finalColor.a - _ClipThreshold);
#endif

                return finalColor;
            }
            ENDCG
        }
    }

    Fallback "Unlit/Texture"
}
