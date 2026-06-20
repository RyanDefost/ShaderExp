Shader "Custom/ColorInterpolation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} //the base texture
        _SecondaryTex ("Secondary Texture", 2D) = "black" {} //the texture to blend to
		//_Blend ("Blend Value", Range(0,1)) = 0 //0 is the first color, 1 the second
    
        _BlendTex ("Blend Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            //float _Blend;
            sampler2D _BlendTex;
            float4 _BlendTex_ST;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _SecondaryTex;
            float4 _SecondaryTex_ST;
            
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
            

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 main_uv = TRANSFORM_TEX(IN.uv, _MainTex);
                float2 secondary_uv = TRANSFORM_TEX(IN.uv, _SecondaryTex);
                float2 blend_uv = TRANSFORM_TEX(IN.uv, _BlendTex);
                
                half4 main_color = tex2D(_MainTex, main_uv);
                half4 secondary_color = tex2D(_SecondaryTex, secondary_uv);
                half4 blend_color = tex2D(_BlendTex, blend_uv);
                
                half blend = blend_color.r;
                
                half4 color = lerp(main_color, secondary_color, blend);
                return color;
            }
            ENDHLSL
        }
    }
}
