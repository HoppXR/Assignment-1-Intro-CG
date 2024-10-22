Shader "Assignment1/HologramSpecular"
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
        
        _BaseColor ("Base Color", Color) = (1,1,1,1)  
        _SpecColor ("Specular Color", Color) = (1,1,1,1)  
        _Shininess ("Shininess", Range(0.1,100)) = 16  
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

            float4 _BaseColor;
            float4 _SpecColor;
            float _Shininess;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionOS));
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

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                half NdotL = saturate(dot(normalWS, lightDir));

                half3 ambientSH = SampleSH(normalWS);

                half3 diffuse = texColor.rgb * _BaseColor.rgb * NdotL;

                half3 reflectDir = reflect(-lightDir, normalWS);
                half specFactor = pow(saturate(dot(reflectDir, viewDirWS)), _Shininess);
                half3 specular = _SpecColor.rgb * specFactor;

                half3 finalColor = diffuse + ambientSH * texColor.rgb * _BaseColor.rgb + fresnelColor + lineColor + specular;

                return half4(finalColor, texColor.a * _Transparency);
            }

            ENDHLSL
        }
    }
}
