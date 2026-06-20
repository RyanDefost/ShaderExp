Shader "Custom/ScreenDistortion"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _CircleSIze("Circle Size", Range(0,1)) = 0.6
        _CutOff("Cutoff", Range(1,2)) = 1.4
        
        _TaperDistance("Taper Distance", Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }
        Blend SrcAlpha OneMinusSrcAlpha
        
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _BaseMap;
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END
            
            SAMPLER(_CameraOpaqueTexture);
            half4 _CameraOpaqueTexture_ST;
            
            float _CircleSIze;
            float _CutOff;
            
            float _TaperDistance;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 newUV = IN.uv * 2 - 1;
                
                float len = length(newUV);
                float cirlce = (len + _CircleSIze - 1);
                float inverseCircle = 1 - cirlce;
                float fullCircle = cirlce * inverseCircle;
                
                
                float2 noiseUV = IN.uv * 2 - 1;
                noiseUV += _Time.y * 0.1 + (len - IN.uv);
                
                half4 noise = tex2D(_BaseMap, noiseUV * _CutOff);
                float filterdNoise = step(-fullCircle, noise);
                half4 color = _BaseColor - filterdNoise;
                
                color.a = clamp((color.a), 0, _BaseColor.a * len * _TaperDistance);
                return color * noise;
            }
            ENDHLSL
        }
    }
}
