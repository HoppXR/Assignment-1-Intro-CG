Shader "ToonShaderURP_Rim"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
            };

            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

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
                OUT.viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionOS.xyz));
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Fetch main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                // Calculate Lambertian diffuse lighting (NdotL)
                half NdotL = saturate(dot(IN.normalWS, lightDirWS));

                // Sample the ramp texture using NdotL to get the correct shade
                half rampValue = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(NdotL, 0)).r;

                // Multiply the base color by the ramp value and light color
                half3 finalColor = _BaseColor.rgb * lightColor * rampValue;

                // Rim lighting calculation
                half rimDot = 1.0 - saturate(dot(IN.viewDirWS, IN.normalWS)); // View angle-based rim lighting
                half rimFactor = pow(rimDot, _RimPower);   // Use _RimPower to control rim width/intensity
                finalColor += _RimColor.rgb * rimFactor;   // Add rim lighting to the final color

                // Return the final color with alpha
                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}
