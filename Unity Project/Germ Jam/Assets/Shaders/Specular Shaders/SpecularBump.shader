Shader "Assignment1/SpecularBump"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(0.1,100)) = 16
        _myDiffuse ("Diffuse Texture", 2D) = "white" {}
        _myBump ("Bump Texture", 2D) = "bump" {}
        _mySlider ("Bump Amount", Range(0,10)) = 1
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
                float2 uv : TEXCOORD0;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_myDiffuse);
            SAMPLER(sampler_myDiffuse);

            TEXTURE2D(_myBump);
            SAMPLER(sampler_myBump);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _SpecColor;
                float _Shininess;
                float _mySlider;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.tangentWS = normalize(TransformObjectToWorldNormal(IN.tangentOS.xyz));
                OUT.bitangentWS = cross(OUT.normalWS, OUT.tangentWS) * IN.tangentOS.w;
                
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);
                
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_myDiffuse, sampler_myDiffuse, IN.uv);

                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_myBump, sampler_myBump, IN.uv));

                normalTS.xy *= _mySlider;

                half3x3 TBN = half3x3(IN.tangentWS, IN.bitangentWS, IN.normalWS);
                half3 normalWS = normalize(mul(normalTS, TBN));
                half3 normal = normalize(IN.normalWS);
                
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                half NdotL = saturate(dot(normalWS, lightDir));
                half3 diffuse = albedo.rgb * _BaseColor.rgb * NdotL;

                half3 ambientSH = SampleSH(normal);

                half3 reflectDir = reflect(-lightDir, normal);

                half3 viewDir = normalize(IN.viewDirWS);
                half specFactor = pow(saturate(dot(reflectDir, viewDir)), _Shininess);
                half3 specular = _SpecColor.rgb * specFactor;

                half3 finalColor = diffuse + ambientSH * albedo.rgb * _BaseColor.rgb + specular;

                return half4(finalColor, albedo.a);
            }
            ENDHLSL
        }
    }
}
