Shader "Custom/PerlinNoise"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        
        _CellSize ("Cell Size", Range(0,5)) = 1
        _ScrollSpeed ("Scroll Speed", Range(0, 1)) = 1
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
            #include "WhiteNoise.cginc"
            
            sampler2D _BaseMap;
            float4 _BaseMap_TS;
            
            half4 _Color;
            
            float _CellSize;
            float _ScrollSpeed;
            
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
            
            inline float easeIn(float interpolator)
            {
                return interpolator * interpolator;
            }
            
            float easeOut(float interpolator){
                return 1 - easeIn(1 - interpolator);
            }
            
            float easeInOut(float interpolator)
            {
                float easInValue = easeIn(interpolator); 
                float easOutValue = easeOut(interpolator); 
                return lerp(easInValue, easOutValue, interpolator);
            }
            
            float gradienNoise(float value)
            {
                float fraction = frac(value);
                float interpolator = easeInOut(fraction);

                float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
                float previousCellLinePoint = previousCellInclination * fraction;
                
                float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
                float nextCellLinePoint = nextCellInclination * (fraction - 1);
                
                
                return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
            }
            
            float perlinNoise2D(float2 value)
            {
                float2 lowerLeftDirection = rand2dTo2d(float2(floor(value.x), floor(value.y))) * 2 - 1;
                float2 lowerRightDirection = rand2dTo2d(float2(ceil(value.x), floor(value.y))) * 2 - 1;
                float2 upperLeftDirection = rand2dTo2d(float2(floor(value.x), ceil(value.y))) * 2 - 1;
                float2 upperRightDirection = rand2dTo2d(float2(ceil(value.x), ceil(value.y))) * 2 - 1;
                
                float2 fraction = frac(value);
                
                float lowerLeftFuntionValue = dot(lowerLeftDirection, fraction - float2(0,0));
                float lowerRightFunctionValue = dot(lowerRightDirection, fraction - float2(1,0));
                float upperLeftFuntionValue = dot(upperLeftDirection, fraction - float2(0,1));
                float upperRightFuntionValue = dot(upperRightDirection, fraction - float2(1,1));
                
                float interpolatorX = easeInOut(fraction.x);
                float interpolatorY = easeInOut(fraction.y);
                
                float lowerCells = lerp(lowerLeftFuntionValue, lowerRightFunctionValue, interpolatorX);
                float upperCells = lerp(upperLeftFuntionValue, upperRightFuntionValue, interpolatorX);
                
                float noise = lerp(lowerCells, upperCells, interpolatorY);
                return noise;
            }
            
            float perlinNoise3D(float3 value)
            {
                float3 fraction = frac(value);
                float interpolatorX = easeInOut(fraction.x);
                float interpolatorY = easeInOut(fraction.y);
                float interpolatorZ = easeInOut(fraction.z);

                float cellNoiseZ[2];
                for (int z = 0; z <= 1; ++z)
                {
                    float cellNoiseY[2];
                    for (int y = 0; y <= 1; ++y)
                    {
                        float cellNoiseX[2];
                        for (int x = 0; x <= 1; ++x)
                        {
                            float3 cell = floor(value) + float3(x,y,z);
                            float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                            float3 compareVector = fraction - float3(x, y, z);
                            cellNoiseX[x] = dot(cellDirection, compareVector);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                
                float noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 newUV = IN.uv * 2 - 1;
                
                //float3 worldToObject = mul(unity_ObjectToWorld, float2(newUV.x + _Time.y, newUV.y));
                float3 worldToObject = mul(unity_ObjectToWorld, newUV);
                
                float3 value = worldToObject.xyz / _CellSize;
                value.y += _Time.y * _ScrollSpeed;
                /*float noise = gradienNoise(value);
                
                float dist = abs(noise - worldToObject.y);
                float pixelHeight = fwidth(worldToObject.y);
                float lineIntensity = smoothstep(2*pixelHeight, pixelHeight, dist);*/
                
                //float4 color = lerp(1,0, lineIntensity);
                float4 color = perlinNoise3D(value) + 0.5;
                
                color = frac(color * 6);
                
                float pixelNoiseChange = fwidth(color);
                float heightLine = smoothstep(1 - pixelNoiseChange, 0.1, color);
                heightLine += smoothstep(pixelNoiseChange, 0, color);
                
                half4 baseUV = tex2D(_BaseMap, IN.uv);
                
                return (heightLine * _Color) + baseUV;
            }
            ENDHLSL
        }
    }
}
