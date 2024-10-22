Shader "Assignment1/ToonBump"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _myDiffuse ("Diffuse Texture", 2D) = "white" {}
        _myBump ("Bump Texture", 2D) = "bump" {}
        _mySlider ("Bump Amount", Range(0,10)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Ramp"
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Vertex input structure
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangentOS : TANGENT;
            };

            // Variables passed from vertex to fragment shader
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Homogeneous clip-space position
                float3 normalWS : TEXCOORD0; // World space normal
                float3 tangetWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float3 viewDirWS : TEXCOORD4;
            };

            // Declare the base texture and sampler
            TEXTURE2D(_RampTex);
            SAMPLER(sampler_RampTex);

            TEXTURE2D(_myDiffuse);
            SAMPLER(sampler_myDiffuse);
            
            TEXTURE2D(_myBump);
            SAMPLER(sampler_myBump);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _mySlider;
            CBUFFER_END

            // Vertex Shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // Transform object space position to homogeneous clip space
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // Transform the object space normal to world space
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.tangetWS = normalize(TransformObjectToWorldNormal(IN.tangentOS.xyz));
                OUT.bitangentWS = cross(OUT.normalWS, OUT.tangetWS) * IN.tangentOS.w;

                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);

                OUT.uv = IN.uv;
                return OUT;
            }

            // Fragment Shader
            half4 frag(Varyings IN) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_myDiffuse, sampler_myDiffuse, IN.uv);

                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_myBump, sampler_myBump, IN.uv));

                normalTS.xy *= _mySlider;

                half3x3 TBN = half3x3(IN.tangetWS, IN.bitangentWS, IN.normalWS);
                half3 normalWS = normalize(mul(normalTS, TBN));
                
                // Fetch main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;
                // Calculate Lambertian diffuse lighting (NdotL)
                //half NdotL = saturate(dot(IN.normalWS, lightDirWS));
                half NdotL = saturate(dot(normalWS, lightDirWS));
                // Sample the ramp texture using NdotL to get the correct shade
                half rampValue = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(NdotL, 0)).r;
                // Multiply the base color by the ramp value and light color
                half3 finalColor = _BaseColor * albedo.rgb * lightColor * rampValue;
                // Return the final color with alpha
                return half4(finalColor, albedo.a);
            }
            ENDHLSL
        }
    }
}