Shader "zeR0Tsu/LEDMatrix"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Source Image", 2D) = "white" {}
        _ImageTiling ("Image Tiling", Vector) = (1, 1, 0, 0)
        _ImageOffset ("Image Offset", Vector) = (0, 0, 0, 0)
        _ImageRotation ("Image Rotation", Range(-180, 180)) = 0

        [Header(Grid)]
        _GridResolution ("Grid Resolution", Float) = 32
        _MatrixScale ("Matrix Scale", Range(0.1, 2.0)) = 1.0
        _LEDSize ("LED Size", Range(0.0, 1.0)) = 0.7
        [Toggle(_CIRCLE_SHAPE)] _CircleShape ("Circle LED", Float) = 1
        [Toggle(_SQUARE_SHAPE)] _SquareShape ("Square LED", Float) = 0

        [Header(Colors)]
        _BgColor ("Background Color", Color) = (0.02, 0.02, 0.02, 1)
        _OffColor ("Off LED Color", Color) = (0.12, 0.12, 0.12, 1)
        _LEDColor ("LED Color", Color) = (1, 1, 1, 1)
        _OnThreshold ("On Threshold", Range(0.0, 1.0)) = 0.05

        [Header(Glow)]
        [Toggle(_GLOW_ON)] _GlowEnabled ("Enable Glow", Float) = 1
        _GlowIntensity ("Glow Intensity", Range(0.0, 5.0)) = 1.5
        _GlowRadius ("Glow Radius", Range(0.0, 2.0)) = 0.25

        [Header(Alpha)]
        [Toggle(UNITY_UI_ALPHACLIP)] _Clip ("Alpha Clip", Float) = 0
        _ClipThreshold ("Clip Threshold", Range(0.0, 1.0)) = 0.1

        [Header(Marquee)]
        [Toggle(_MARQUEE_ON)] _MarqueeEnabled ("启用走马灯 (Enable Marquee)", Float) = 0
        _MarqueeDirection ("走马灯方向 (Direction)", Float) = 0
        _ScrollSpeed ("滚动速度 (Scroll Speed)", Float) = 1.0
        _ScrollDistance ("滚动距离 (Scroll Distance)", Range(0.1, 5.0)) = 1.0
        _PauseDuration ("暂停时长 (Pause Duration)", Range(0, 10)) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
        }

        ZWrite On
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
            #pragma shader_feature_local _MARQUEE_ON
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
            float2 _ImageTiling;
            float2 _ImageOffset;
            float _ImageRotation;
            float _GridResolution;
            float _MatrixScale;
            float _LEDSize;
            float4 _BgColor;
            float4 _OffColor;
            float4 _LEDColor;
            float _OnThreshold;
            float _GlowIntensity;
            float _GlowRadius;
            float _ClipThreshold;
            float _MarqueeDirection;
            float _ScrollSpeed;
            float _ScrollDistance;
            float _PauseDuration;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // 仅对图片采样坐标做变换：Tiling → Rotation → Offset
            float2 TransformImageUV(float2 uv)
            {
                uv *= _ImageTiling;
                float rad = radians(_ImageRotation);
                float s = sin(rad);
                float c = cos(rad);
                float2 centered = uv - 0.5;
                uv = float2(
                    centered.x * c - centered.y * s,
                    centered.x * s + centered.y * c
                );
                uv += 0.5;
                uv += _ImageOffset;
                return uv;
            }

            // 走马灯偏移：距离驱动间歇循环
            float2 GetMarqueeOffset()
            {
                float2 offset = 0;
#if _MARQUEE_ON
                float speed = abs(_ScrollSpeed);
                if (speed > 0.0001)
                {
                    float scrollTime = _ScrollDistance / speed;
                    float period = scrollTime + _PauseDuration;
                    float totalTime = _Time.y;
                    float cycleTime = fmod(totalTime, period);
                    float scrollOffset = (cycleTime < scrollTime)
                        ? cycleTime * speed          // 滚动阶段
                        : _ScrollDistance;           // 暂停阶段
                    scrollOffset *= (_ScrollSpeed > 0) ? 1.0 : -1.0;
                    if (_MarqueeDirection < 0.5)     // 0 = 水平
                        offset.x = scrollOffset;
                    else                              // 1 = 垂直
                        offset.y = scrollOffset;
                }
#endif
                return offset;
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
                float scale = max(_MatrixScale, 0.01);

                // --- 0. 将 UV 映射到点阵区域（以面板中心缩放） ---
                float2 matrixUV = (uv - 0.5) / scale + 0.5;

                float res = max(_GridResolution, 1.0);

                // --- 1. 计算当前像素所在网格单元和单元中心 UV ---
                float2 cellIndex = floor(matrixUV * res);
                float2 cellCenter = (cellIndex + 0.5) / res;

                // --- 2. 在单元中心采样图片（应用图片独立变换，最近邻风格） ---
                float2 sampleUV = TransformImageUV(cellCenter);
                sampleUV += GetMarqueeOffset();   // 走马灯滚动偏移
                fixed4 ledColor = tex2D(_MainTex, sampleUV);

                // --- 3. 计算到单元中心的距离（以网格单元为归一化单位, 0~0.5） ---
                float2 distToCenterVec = (matrixUV - cellCenter) * res;

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

                // --- 4. 判断 LED 是否"点亮"（先应用色调再判断亮度） ---
                float3 tintedColor = ledColor.rgb * _LEDColor.rgb;
                float luma = Luminance(tintedColor);
                bool isOn = luma > _OnThreshold;

                // --- 5. 计算最终颜色 ---
                float4 finalColor;

                if (dist <= ledHalfSize)
                {
                    // ===== LED 灯体内部 =====
                    finalColor.rgb = isOn ? tintedColor : _OffColor.rgb;
                    finalColor.a = 1.0;
                }
                else
                {
                    // ===== 灯体外部：辉光或背景 =====
#if _GLOW_ON
                    float maxGlow = _GlowRadius;

                    // 自然辉光混合：one-minus-product + 平方加权
                    float combinedGlow = 0.0;
                    float3 weightedColor = float3(0, 0, 0);
                    float weightSum = 0.0;

                    [unroll]
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        [unroll]
                        for (int dy = -1; dy <= 1; dy++)
                        {
                            float2 neighborIndex = cellIndex + float2(dx, dy);
                            float2 neighborCenter = (neighborIndex + 0.5) / res;
                            float2 nSampleUV = TransformImageUV(neighborCenter);
                            nSampleUV += GetMarqueeOffset();   // 走马灯偏移同步
                            fixed4 nColor = tex2D(_MainTex, nSampleUV);
                            float3 nTinted = nColor.rgb * _LEDColor.rgb;
                            if (Luminance(nTinted) > _OnThreshold)
                            {
                                float2 toN = (matrixUV - neighborCenter) * res;
                                float nDist;
#if _CIRCLE_SHAPE
                                nDist = length(toN);
#elif _SQUARE_SHAPE
                                nDist = max(abs(toN.x), abs(toN.y));
#else
                                nDist = length(toN);
#endif
                                float glowDist = nDist - ledHalfSize;
                                if (glowDist < maxGlow)
                                {
                                    float sigma = maxGlow * 0.35;
                                    float g = GaussianFalloff(glowDist, sigma);
                                    g = saturate(g * _GlowIntensity);
                                    // one-minus-product：能量守恒软饱和
                                    combinedGlow = combinedGlow + (1.0 - combinedGlow) * g;
                                    // 平方加权：近灯颜色主导
                                    float w = g * g;
                                    weightedColor += nTinted * w;
                                    weightSum += w;
                                }
                            }
                        }
                    }

                    if (combinedGlow > 0.0)
                    {
                        float3 glowColor = weightedColor / max(weightSum, 0.001);
                        finalColor.rgb = lerp(_BgColor.rgb, glowColor, combinedGlow);
                        finalColor.a = 1.0;
                    }
                    else
                    {
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
    CustomEditor "LEDMatrixShaderGUI"
}
