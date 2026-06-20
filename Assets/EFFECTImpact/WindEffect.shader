Shader "Custom/WindEffect"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _WindDirection("Wind Direction", Vector) = (0,1,0,0)
        _Intensity("Intensity", float) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../Noise/WhiteNoise.cginc"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionVS : TEXCOORD0;
                
                float4 screenSpace : TEXCOORD2;
                float2 uv : TEXCOORD1;
            };

            sampler2D _BaseMap;
            float4 _BaseMap_ST;
            float4 _BaseColor;
            
            vector _WindDirection;
            float _Intensity;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 positionVS = TransformWorldToView(positionWS);
                float4 positionCS = TransformWorldToHClip(positionWS);
                OUT.positionVS = positionVS; // (TEXCOORD1 or whatever, any unused will do)
                OUT.positionCS = positionCS; // (SV_POSITION)
                
                OUT.positionCS.y += frac(_Time.y * -1) * 50;
                
                OUT.screenSpace = ComputeScreenPos(OUT.positionCS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = _BaseColor;
                float2 new_uv = IN.uv * 2 - 1;
                
                float len = length(new_uv);
                //Depth
                /*float2 screenSpaceUV = IN.screenSpace.xy / IN.screenSpace.w;
                float rawDepth = SampleSceneDepth(screenSpaceUV);
                
                float fragmentEyeDepth = -IN.positionVS.z;
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                
                float edge = ((sceneEyeDepth - fragmentEyeDepth ) / _Intensity) * 1;
                edge = 1 - saturate(edge);*/
                
                //float upperRing = smoothstep(new_uv.x, new_uv.y, _Time.y);
                //new_uv += (_WindDirection * frac(_Time.x)) * _Intensity;
                
                half4 windTex = tex2D(_BaseMap, IN.uv);;
                color.rgba = windTex;
                
                //color.rgb = lerp(color, edge, edge);
                //color.a = lerp(color.a, 1, edge * half4(1,1,1,1));
                
                return color;
            }
            ENDHLSL
        }
    }
}
