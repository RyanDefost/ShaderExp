Shader "Custom/ValueNoise"
{
    Properties
    {
        _CellSize ("Cell Size", Range(0,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            float _CellSize;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "WhiteNoise.cginc"
            
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
            
            float ValueNoise2d(float2 value)
            {
                float upperLeftCell = rand2dTo1d(float2(floor(value.x), ceil(value.y)));
                float upperRightCell = rand2dTo1d(float2(ceil(value.x), ceil(value.y)));
                float lowerLeftCell = rand2dTo1d(float2(floor(value.x), floor(value.y)));
                float lowerRightCell = rand2dTo1d(float2(ceil(value.x), floor(value.y)));
                
                float interpolatorX = easeInOut(frac(value.x));
                float interpolatorY = easeInOut(frac(value.y));
                
                float upperCells = lerp(upperLeftCell, upperRightCell, interpolatorX);
                float lowerCells = lerp(lowerLeftCell, lowerRightCell, interpolatorX);
                
                float noise = lerp(lowerCells, upperCells, interpolatorY);
                return noise;
            }
            
            float3 ValueNoise3d(float3 value)
            {
                float interpolatorX = easeOut(frac(value.x));
                float interpolatorY = easeOut(frac(value.y));
                float interpolatorZ = easeOut(frac(value.z));
                
                float3 cellNoiseZ[2];
                for (int z = 0; z <= 1; ++z)
                {
                    float3 cellNoiseY[2];
                    [unroll]
                    for (int y = 0; y <= 1; ++y)
                    {
                        float3 cellNoiseX[2];
                        [unroll]
                        for (int x = 0; x <= 1; ++x) {
                            float3 cell = floor(value) + float3(x, y, z);
                            cellNoiseX[x] = rand3dTo3d(cell);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                
                float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }
            
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

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //float3 worldToObject = mul(unity_ObjectToWorld, float2(IN.uv.x + _Time.y, IN.uv.y));
                float3 worldToObject = mul(unity_ObjectToWorld, IN.uv);
                float3 value = (worldToObject.xyz  / _CellSize); //for xy use FLOAT2

                /*float previousCellNoise = rand1dTo1d(floor(value));
                float nextCellNoise = rand1dTo1d(ceil(value));
                
                float interpolator = frac(value);
                interpolator = easeInOut(interpolator);*/
                
                float3 noise = ValueNoise3d(value);
                return float4(noise.rgb, 1);
                
                /*float noise = lerp(previousCellNoise, nextCellNoise, interpolator);
                float dis = abs(noise - worldToObject.y);
                
                float pixelHeight = fwidth(worldToObject);
                float lineIntensity = smoothstep(0, pixelHeight, dis);
                
                return lineIntensity;*/
                
                //==================
                
                
            }
            ENDHLSL
        }
    }
}
