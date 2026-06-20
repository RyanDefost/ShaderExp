Shader "Custom/River"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        
        [Header(Spec Layer 1)]
        _Specs1("Specs", 2D) = "white" {}
        _SpecColor1("Spec Color", Color) = (1,1,1,1)
        _SpecDirection1("Spec Direction", Vector) = (0,1,0,0)
        
        [Header(Spec Layer 2)]
        _Specs2 ("Specs", 2D) = "white" {}
        _SpecColor2 ("Spec Color", Color) = (1,1,1,1)
        _SpecDirection2 ("Spec Direction", Vector) = (0, 1, 0, 0)
        
        [Header(Foam)]
        _FoamNoise("Foam Noise", 2D) = "white" {}
        _FoamDirection("Foam Direction", Vector) = (0,1,0,0)
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamAmount("Foam Amount", Range(0,2)) = 1 
    }

    SubShader
    {
        Tags{ "RenderType"="Transparent" "Queue"="Transparent"}
		Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _Specs1;
                float4 _Specs1_ST;
            half4 _SpecColor1;
            float2 _SpecDirection1;
            
            sampler2D _Specs2;
                float4 _Specs2_ST;
            half4 _SpecColor2;
            float2 _SpecDirection2;
            
            sampler2D _FoamNoise;
                float4 _FoamNoise_ST;
            half4 _FoamColor;
            float _FoamAmount;
            float2 _FoamDirection;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionVS : TEXCOORD5;
                
                float2 uv : TEXCOORD0;
                float4 screenSpace : TEXCOORD1;
                
                float2 uv_Specs1 : TEXCOORD2;
                float2 uv_Specs2 : TEXCOORD3;
                float2 uv_FoamNoise : TEXCOORD4;
            };
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 positionVS = TransformWorldToView(positionWS);
                float4 positionCS = TransformWorldToHClip(positionWS);
                OUT.positionVS = positionVS; // (TEXCOORD1 or whatever, any unused will do)
                OUT.positionCS = positionCS; // (SV_POSITION)
                
                OUT.uv_Specs1 = TRANSFORM_TEX(IN.uv, _Specs1);
                OUT.uv_Specs2 = TRANSFORM_TEX(IN.uv, _Specs2);
                OUT.uv_FoamNoise = TRANSFORM_TEX(IN.uv, _FoamNoise);
                
                OUT.screenSpace = ComputeScreenPos(positionCS);
                
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = _BaseColor;
                
                float2 specCoordinates1 = IN.uv_Specs1 + _SpecDirection1 * _Time.y;
                half4 specLayer1 = tex2D(_Specs1, specCoordinates1) * _SpecColor1;
                
                color.rgb = lerp(color.rgb, specLayer1.rgb, specLayer1.a);
                color.a = lerp(color.a, 1, specLayer1.a);
                
                float2 specCoordinates2 = IN.uv_Specs2 + _SpecDirection2 * _Time.y;
                half4 specLayer2 = tex2D(_Specs2, specCoordinates2) * _SpecColor2;
                
                color.rgb = lerp(color.rgb, specLayer2.rgb, specLayer2.a);
                color.a = lerp(color.a, 1, specLayer2.a);
                
                float2 screenSpaceUV = IN.screenSpace.xy / IN.screenSpace.w;
                
                float rawDepth = SampleSceneDepth(screenSpaceUV);
                
                float fragmentEyeDepth = -IN.positionVS.z;
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                
                float2 foamCoords = IN.uv_FoamNoise + _FoamDirection * _Time.y;
                float foamNoise = tex2D(_FoamNoise, foamCoords).r;
                float foam = ((sceneEyeDepth - fragmentEyeDepth ) / _FoamAmount) * 1;
                foam = 1- saturate(foam - foamNoise);
                
                color.rgb = lerp(color.rgb, _FoamColor.rgb, foam);
                color.a = lerp(color.a, 1, foam * _FoamColor.a);
                
                
                return color;

            }
            ENDHLSL
        }
    }
}
