Shader "Custom/URP_RimLighting_Specular"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)   
        _MainTex ("Base Texture", 2D) = "white" {}        
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1) 
        _RimColor ("Rim Color", Color) = (0, 0.5, 0.5, 1)  
        _Shininess ("Shininess", Range(0.1, 100)) = 16   
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.0   
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

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor; 
                float4 _RimColor;   
                float _RimPower;    
                float4 _SpecColor; 
                float _Shininess;  
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

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                half NdotL = saturate(dot(normalWS, lightDir));
                half3 diffuse = texColor.rgb * _BaseColor.rgb * NdotL;

                half3 reflectDir = reflect(-lightDir, normalWS);
                half specFactor = pow(saturate(dot(reflectDir, viewDirWS)), _Shininess);
                half3 specular = _SpecColor.rgb * specFactor;

                half rimFactor = 1.0 - saturate(dot(viewDirWS, normalWS));
                half rimLighting = pow(rimFactor, _RimPower);
                half3 rimColor = _RimColor.rgb * rimLighting;

                half3 finalColor = diffuse + specular + rimColor;

                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}
