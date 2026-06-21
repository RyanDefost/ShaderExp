Shader "Custom/Liquid"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _SecondColor("Color", Color) = (1,1,1,1)
        _ThirdColor("Color", Color) = (1,1,1,1)
        
        _Height("Height", Range(0,2)) = 1
        
        _Size ("Size", Range(0,1)) = 1
        _ScrollSpeed ("Scroll Speed", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags{ "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        Cull off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            float4 _Color;
            float4 _SecondColor;
            float4 _ThirdColor;
            
            float _Height;
            
            float _Size;
            float _ScrollSpeed;
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../WhiteNoise.cginc"
            
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
            
            float perlinNoise(float value)
            {
                float fraction = frac(value);
                float interpolator = easeInOut(fraction);
                
                float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
                float previouseCellLinePoint = previousCellInclination * fraction;
                
                float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
                float nextCellLinePoint = nextCellInclination * (fraction - 1);
                
                return lerp(previouseCellLinePoint, nextCellLinePoint, interpolator);
                
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
                float2 new_uv = IN.uv * 2 - _Height;
                vector world_to_object = mul(unity_ObjectToWorld, new_uv);

                float3 value = world_to_object.x / _Size;
                float4 noise = perlinNoise(value);
                
                value.x += _Time.y * _ScrollSpeed;
                float4 offsetnoise = perlinNoise(value / 3);
                
                float world_pos = world_to_object.y + offsetnoise.x;
                
                float dist = floor(noise + world_pos) * 0.5;
                float bg_dist = floor(offsetnoise + world_pos) * 0.5;
                
                float Line = abs(noise + world_pos) * 0.9;
                float bg_line = abs(offsetnoise + world_pos) * 1;
                
                float pixel_height = fwidth(world_to_object.y);
                float line_intensity = smoothstep(2*pixel_height, pixel_height, Line * bg_line);
                
                float4 color = line_intensity * _Color;
                color -= (_SecondColor * clamp(dist, bg_dist, dist) / 2);
                color -= (_SecondColor * clamp(bg_dist, dist, bg_dist) / 8);
                color.a = step(0.1, color.a);
                
                return float4(color.rgba);
            }
            ENDHLSL
        }
    }
}
