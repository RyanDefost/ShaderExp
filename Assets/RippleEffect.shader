Shader "Custom/RippleEffect"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _RippleIntensity("Ripple Intensity", Float) = 1
        
        _UpperFeather("Upper Feather", Float) = 0.1
        _BottomFeather("Bottom Feather", Float) = 0.1 
    }

    SubShader
    {
        Tags{ "RenderType"="Transparent" "Queue"="Transparent"}
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
            float4 _BaseMap_ST;
            float4 _BaseColor;
            
            float _UpperFeather;
            float _BottomFeather;
            float _RippleIntensity;
            
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
                
                float timer = frac(_Time.y);
                float len = length(newUV);

                float upperRing = smoothstep(len + _UpperFeather, len - _BottomFeather, timer);
                float inverseRing = 1 - upperRing;
                float finalRing = upperRing * inverseRing;
                
                half4 col = finalRing * _BaseColor * _RippleIntensity * (1- timer);
                return col;
            }
            ENDHLSL
        }
    }
}
