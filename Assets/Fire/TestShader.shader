Shader "Custom/TestShader"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        
        _ScrollSpeed ("speed", Float) = 1
        
        _Color1 ("Color 1", Color) = (0, 0, 0, 1)
		_Color2 ("Color 2", Color) = (0, 0, 0, 1)
		_Color3 ("Color 3", Color) = (0, 0, 0, 1)
		
		_Edge1 ("Edge 1-2", Range(0, 1)) = 0.25
		_Edge2 ("Edge 2-3", Range(0, 1)) = 0.5
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
            
            //texture and transforms of the texture
            sampler2D _BaseMap;
            float4 _BaseMap_ST;

            //tint of the texture
            float _ScrollSpeed;
            
            //tint of the texture
			half4 _Color1;
			half4 _Color2;
			half4 _Color3;
			
			float _Edge1;
			float _Edge2;
                
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
            
            float fwidth(float value){
                return abs(ddx(value)) + abs(ddy(value));
            }
            
            //smooth version of step
            float aaStep(float compValue, float gradient){
                float halfChange = fwidth(gradient) / 2;
                
                //base the range of the inverse lerp on the change over one pixel
                float lowerEdge = compValue - halfChange;
                float upperEdge = compValue + halfChange;
                
                //do the inverse interpolation
                float stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
                stepped = saturate(stepped);
                
                return stepped;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // They square this here to make the fire look a bit more "full"
                float fireGradient = 1 - IN.uv.y;
                fireGradient = fireGradient * fireGradient;
                
                //Calculate fire UVs and animate them
                float2 fireUV = TRANSFORM_TEX(IN.uv, _BaseMap);
                fireUV.y -= _Time.y * _ScrollSpeed;
                
                //Get the noise texture
                float fireNoise = tex2D(_BaseMap, fireUV).x;
                
                //calculate whether fire is visible at all and which colors should be shown
                float outline = aaStep(fireNoise, fireGradient);
                float edge1 = aaStep(fireNoise, fireGradient - _Edge1);
                float edge2 = aaStep(fireNoise, fireGradient - _Edge2);
                
                //define shape of fire
                half4 col = _Color1 * outline;
                //add other colors
                col = lerp(col, _Color2, edge1);
                col = lerp(col, _Color3, edge2);
                
                //UV to color
                return col;
            }
            ENDHLSL
        }
    }
}
