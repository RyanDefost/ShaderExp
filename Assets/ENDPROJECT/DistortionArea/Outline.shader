Shader "Custom/Outline"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0,.1)) = 0.03
        
        [Header(Warping)]
        _Amplitude ("Wave Size", Range(0,1)) = 0.4
        _Frequency ("Wave Freqency", Range(1, 8)) = 2
        
        [Enum(UnityEngine.Rendering.CullMode)] _Culltype ("Cull", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            Name "Outline"
            Cull front
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };
            
            SAMPLER(_CameraOpaqueTexture);
            half4 _CameraOpaqueTexture_ST;
            
            half4 _OutlineColor;
            float _OutlineThickness;

            float _Amplitude;
            float _Frequency;
            
            Varyings vert(Attributes IN)
            {
                //Warping
                float4 modifiedPos = IN.positionOS;
                modifiedPos.y += sin(IN.positionOS.x * _Frequency + _Time.y) * _Amplitude;
                IN.positionOS = modifiedPos;
                
                //Outline
                float3 normal = normalize(IN.normal);
                float3 outlineOffset = normal * _OutlineThickness;
                float3 position = IN.positionOS + outlineOffset;
                
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(position);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 screen_uv = (IN.positionHCS.xy / _ScreenParams.xy);
                half4 color = tex2D(_CameraOpaqueTexture, screen_uv);
                
                return color * _OutlineColor;
            }
            ENDHLSL
        }
    }
    
    FallBack "Standard"
}
