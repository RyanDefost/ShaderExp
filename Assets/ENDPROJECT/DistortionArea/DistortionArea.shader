Shader "Custom/DistortionArea"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Texture("Texture", 2D) = "White" {}
    
        [Header(Frensel)]
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _Multiplier("Multiplier", Float) = 1
        _Ramp("Ramp", float) = 1
    
        [Header(Warping)]
        _Amplitude ("Wave Size", Range(0,1)) = 0.4
        _Frequency ("Wave Freqency", Range(1, 8)) = 2
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        Cull Front
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            SAMPLER(_CameraOpaqueTexture);
            half4 _CameraOpaqueTexture_ST;
            
            float _Amplitude;
            float _Frequency;
            
            half4 _Color;
            
            sampler2D _Texture;
            float4 _Texture_ST;
            
            half4 _EdgeColor;
            float _Multiplier;
            float _Ramp;
            
            float2 toPolar(float2 cartesian)
            {
                float distance = length(cartesian);
                float angle = atan2(cartesian.y, cartesian.x);
                return float2(angle / (2 * PI), distance);
            }
            
            float2 toCartesian(float2 polar)
            {
                float2 cartesian;
                sincos(polar.x * (2 * PI), cartesian.y, cartesian.x);
                return cartesian * polar.y;
            }
            
            Varyings vert(Attributes IN)
            {
                float4 modifiedPos = IN.positionOS;
                modifiedPos.y += sin(IN.positionOS.x * _Frequency + _Time.y) * _Amplitude;
                IN.positionOS = modifiedPos;
                
                
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDir = TransformViewToWorldDir(IN.positionOS.xyz);
                
                
                OUT.uv = TRANSFORM_TEX(IN.uv, _Texture);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 screen_uv = (IN.positionHCS.xy / _ScreenParams.xy) - 0.5;
                
                screen_uv = toPolar(screen_uv);
                screen_uv.x += sin(_Time.x) * screen_uv.y * 1;

                screen_uv = toCartesian(screen_uv);
                screen_uv += 0.5;
                
                half4 color = tex2D(_CameraOpaqueTexture, screen_uv);
                
                float frensel = pow(1 + dot(IN.viewDir, IN.normal), _Ramp) * _Multiplier;
                color -= frensel;
                
                return color * _Color;
            }
            ENDHLSL
        }
    }
}
