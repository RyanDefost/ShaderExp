Shader "Custom/Wind"
{
    Properties
    {
        [HideInInspector][MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _WindColor("Wind Color", Color) = (1,1,1,1)
        _AccentColor("Accent Color", Color) = (1, 1, 1, 1)
        
        [Header(Texture)]
        _WindTex("Wind Texture", 2D) = "White" {}
        _WindTexOffsetX("Wind Texture Offset", Range(0,2)) = 1
        _WindTexOffsetY("Wind Texture Offset", Range(0,2)) = 1
        _WindSpeed("Wind Speed", float) = 0.05
        
        [Header(Waves)]
        _WaveOffsetSize("Wave Offset Size", float) = 1
        _Zoom("Zoom Amount", Range(0.1,1)) = 0
        
        [Header(Edge)]
        _VisibleAreaTex("Visible Area Texture", 2D) = "White" {}
        _GapSize("Gap Suze", Range(0.1,1)) = 1
        _TaperSize("Taper size", Range(0.1,1)) = 1
        
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../WhiteNoise.cginc"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                
                float2 uv : TEXCOORD0;
                float2 wind_uv : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _AccentColor;
                float4 _BaseMap_ST;
            CBUFFER_END
            
            sampler2D _WindTex;
            half4 _WindTex_ST;
            
            float _WindTexOffsetX;
            float _WindTexOffsetY;
            float _WindSpeed;
            half4 _WindColor;

            float _WaveOffsetSize;
            float _Zoom;
            
            sampler2D _VisibleAreaTex;
            half4 _VisibleAreaTex_ST;
            
            float _GapSize;
            float _TaperSize;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                OUT.wind_uv = TRANSFORM_TEX(IN.uv, _WindTex);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //Get position in world
                vector windPosition = mul(unity_ObjectToWorld, IN.wind_uv);

                //Create random points across y
                float value = windPosition.y / _WaveOffsetSize; 
                float nextCellNoise = rand1dTo1d(ceil(value));
                float previousCellNoise = rand1dTo1d(floor(value));
                float noise = lerp(previousCellNoise, nextCellNoise, frac(value));
                
                float dist = abs(noise - IN.wind_uv.x - 0.5);
                
                //Create lines between points
                float pixelHeight = fwidth(IN.wind_uv.x / 0.1);
                float lineIntensity = smoothstep(0.3, pixelHeight, dist) ; 
                
                //use visibleTexture to mask part of the wind.
                half4 visibleColor = tex2D(_VisibleAreaTex, IN.uv);
                float stap = step(_GapSize, visibleColor);
                
                //Circle to tapper edges.
                float len = length(IN.uv * 2 - 1);
                float cirlce = (len + _TaperSize);
                cirlce = -clamp(cirlce, stap, 1);
                float disapearMask = cirlce;
                
                //Apply offsets
                windPosition.x += lineIntensity;
                
                windPosition.x *= _WindTexOffsetX;
                windPosition.y *= _WindTexOffsetY;
                
                //Move wind and set texture
                windPosition.y += _Time.y * _WindSpeed;
                half4 wind_tex = tex2D(_WindTex, windPosition.xy * _Zoom) * (_WindColor += disapearMask);
                
                //Apply texture without changing base alpha
                half4 color = half4(_AccentColor.rgb, 0);
                color.rgb = lerp(color.rgb, wind_tex.rgb, wind_tex.a);
                color.a = lerp(color.a, 1, wind_tex.a);
                
                return color;
            }
            ENDHLSL
        }
    }
}
