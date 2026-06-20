Shader "Custom/Depth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [MainColor] _PrimaryColor("Base Color", Color) = (1, 1, 1, 1)
        _SecondaryColor("Secondary Color", Color) = (0, 0, 0, 1)

        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _Multiplier("Multiplier", Float) = 1
        _Ramp("Ramp", float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

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
                float4 screenSpace : TEXCOORD1;
                
                float3 normal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };
            
            CBUFFER_START(UnityPerMaterial)
                half4 _PrimaryColor;
                half4 _SecondaryColor;
                half4 _EdgeColor;
                float _Multiplier;
                float _Ramp;
                
                
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.uv += _Time.x;
                
                OUT.screenSpace = ComputeScreenPos(OUT.positionHCS);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDir = normalize(GetWorldSpaceViewDir(IN.positionOS.xyz));
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 col = tex2D(_MainTex, IN.uv);
                float2 screenSpaceUV = IN.screenSpace.xy / IN.screenSpace.w;
                
                float rawDepth = SampleSceneDepth(screenSpaceUV) ;
                float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture ,screenSpaceUV);
                float depth = Linear01Depth(depthSample, _ZBufferParams); //Linear01DepthFromNear?
                
                float3 mixedColor = lerp(_PrimaryColor, _SecondaryColor, depth);
                float frensel = pow(1 - dot(IN.viewDir, IN.normal), _Ramp) * _Multiplier;
                float3 finalColor = lerp(mixedColor, col, frensel * _EdgeColor);
                    
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
}
