Shader "Custom/TransparentToon"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _LineColor ("Line Color", Color) = (0, 1, 1, 1)
        _FresnelColor ("Fresnel Color", Color) = (0, 0.8, 1, 1)
        _RimIntensity ("Rim Intensity", Float) = 1.5
        _FresnelPower ("Fresnel Power", Range (1, 5)) = 2.0
        _LineSpeed ("Line Speed", Float) = 1.0
        _LineFrequency ("Line Frequency", Float) = 10.0
        _Transparency ("Transparency", Range (0, 1)) = 0.5
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0.1, 8.0)) = 1.5
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangentOS : TANGENT; // Tangent space for rim light calculations
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _LineColor;
            float4 _FresnelColor;
            float _RimIntensity;
            float _FresnelPower;
            float _LineSpeed;
            float _LineFrequency;
            float _Transparency;
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);
            float4 _BaseColor;
            float4 _RimColor;
            float _RimPower;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); 
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                half3 normalWS = normalize(IN.normalWS);
                half3 viewDirWS = normalize(IN.viewDirWS);

                half fresnel = pow(1.0 - saturate(dot(viewDirWS, normalWS)), _FresnelPower);
                half3 fresnelColor = _FresnelColor.rgb * fresnel * _RimIntensity;

                float lineValue = sin(IN.uv.y * _LineFrequency + _Time.y * _LineSpeed);
                half3 lineColor = _LineColor.rgb * step(0.5, lineValue);

                half3 finalColor = texColor.rgb * _BaseColor.rgb + fresnelColor + lineColor;

                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);
                float3 lightColor = mainLight.color.rgb;
                
                half NdotL = saturate(dot(normalWS, lightDirWS));
                half rampValue = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(NdotL, 0)).r;
                finalColor *= lightColor * rampValue;

                half rimFactor = 1.0 - saturate(dot(viewDirWS, normalWS));
                half rimLighting = pow(rimFactor, _RimPower);
                finalColor += _RimColor.rgb * rimLighting;

                return half4(finalColor, texColor.a * _Transparency);
            }

            ENDHLSL
        }
    }
}
