Shader "Assignment1/ToonRim"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        //_BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)     // Rim color
        _RimPower ("Rim Power", Range(0.1, 8.0)) = 1.5    // Rim width
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }

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
                float4 tangentOS : TANGENT; // Tangent space for rim light calculations
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _RimColor;   // Rim lighting color
                float _RimPower;    // Rim lighting width/intensity
            CBUFFER_END

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
                
                // Fetch main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                // Calculate Lambertian diffuse lighting (NdotL)
                half NdotL = saturate(dot(IN.normalWS, lightDirWS));

                // Sample the ramp texture using NdotL to get the correct shade
                half rampValue = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(NdotL, 0)).r;

                // Rim lighting calculation
                half rimFactor = 1.0 - saturate(dot(viewDirWS, normalWS)); // View angle-based rim lighting
                half rimLighting = pow(rimFactor, _RimPower);   // Use _RimPower to control rim width/intensity

                // Multiply the base color by the ramp value and light color
                //half3 finalColor = _BaseColor.rgb * lightColor * rampValue + _RimColor.rgb * rimLighting;
                half3 finalColor = texColor.rgb * lightColor * rampValue + _RimColor.rgb * rimLighting;

                // Return the final color with alpha
                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}
