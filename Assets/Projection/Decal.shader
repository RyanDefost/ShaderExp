Shader "Custom/Decal"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
    }

    SubShader
    {
        Tags{ "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "UnityCG.cginc"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };
            
            sampler2D _BaseMap;
            sampler sampler_BaseMap;

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            sampler2D_float _CameraDepthTexture;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                float3 worldPos = mul(unity_ObjectToWorld, IN.uv);
                OUT.positionHCS = UnityWorldToClipPos(worldPos);
                
                
                OUT.ray = worldPos - _WorldSpaceCameraPos;
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                
                return OUT;
            }

            float3 getProjectedObjectPos(float2 screenPos, float3 worldRay){
	            //get depth from depth texture
	            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
	            depth = Linear01Depth (depth) * _ProjectionParams.z;
	            //get a ray thats 1 long on the axis from the camera away (because thats how depth is defined)
	            worldRay = normalize(worldRay);
	            //the 3rd row of the view matrix has the camera forward vector encoded, so a dot product with that will give the inverse distance in that direction
	            worldRay /= dot(worldRay, -UNITY_MATRIX_V[2].xyz);
	            //with that reconstruct world and object space positions
	            float3 worldPos = _WorldSpaceCameraPos + worldRay * depth;
	            float3 objectPos =  mul (unity_WorldToObject, float4(worldPos,1)).xyz;
	            //discard pixels where any component is beyond +-0.5
	            clip(0.5 - abs(objectPos));

                return objectPos;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float3 uv = getProjectedObjectPos(screenUV, IN.ray);
                
                return half4(uv, 1);
                //return half4(uv.xy,0,1);
            }
            ENDHLSL
        }
    }
}
