# Intro CG Assignment 1 Explanation

### How was the item implemented?

The shaders and lighting models used in the assignment were provided in the lecture slides.

The base shader and base lighting model were combined to create a completely new shader and used to create both a cartoony and realistic look for our game. 
The way we created our shaders was by taking segments of code from other shaders and lighting models and then experimenting with them to achieve our desired look.

#### To give an example:

### Base Lambert lighting model
``` HLSL
Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
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
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                half3 finalColor = texColor.rgb * _BaseColor.rgb;

                half3 normal = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half NdotL = saturate(dot(normal, lightDir));

                return half4(finalColor * NdotL, 1.0);
            }
            ENDHLSL
        }
    }
```
### Base Rim lighting shader
``` HLSL
Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1) // Base color of the object
        _RimColor ("Rim Color", Color) = (0, 0.5, 0.5, 1) // Color for the rim light
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.0 // Controls sharpness of rim lighting
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
                float4 positionOS : POSITION; // Object space position
                float3 normalOS : NORMAL; // Object space normal
                float4 tangentOS : TANGENT; // Tangent space for rim light calculations
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Homogeneous clip-space position
                float3 viewDirWS : TEXCOORD0; // View direction in world space
                float3 normalWS : TEXCOORD1; // World space normal
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor; // Base color property
                float4 _RimColor; // Rim color property
                float _RimPower; // Rim power property
            CBUFFER_END

            // Vertex Shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Transform object space position to homogeneous clip-space position
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // Transform object space normal to world space
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                // Calculate the view direction in world space (from the camera to the surface)
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);

                return OUT;
            }

            // Fragment Shader
            half4 frag(Varyings IN) : SV_Target
            {
                // Normalize the world space normal and view direction
                half3 normalWS = normalize(IN.normalWS);
                half3 viewDirWS = normalize(IN.viewDirWS);

                // Rim lighting calculation (using dot product between normal and view direction)
                half rimFactor = 1.0 - saturate(dot(viewDirWS, normalWS));
                half rimLighting = pow(rimFactor, _RimPower);

                // Combine rim lighting color with the base color
                half3 finalColor = _BaseColor.rgb + _RimColor.rgb * rimLighting;

                return half4(finalColor, _BaseColor.a);
            }
            ENDHLSL
        }
    }
```
### Lambert and Rim lighting shader
``` HLSL
Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _RimColor ("Rim Color", Color) = (0, 0.5, 0.5, 1)
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
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _RimColor;
                float _RimPower;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.uv = IN.uv;
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                half3 normal = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half NdotL = saturate(dot(normal, lightDir));

                half3 viewDirWS = normalize(IN.viewDirWS);

                half rimFactor = 1.0 - saturate(dot(viewDirWS, normal));
                half rimLighting = pow(rimFactor, _RimPower);

                half3 finalColor = texColor.rgb + _RimColor.rgb * rimLighting;

                return half4(finalColor * NdotL, 1.0);
            }
            ENDHLSL
        }
    }
```
The resulting shader has the Lambert lighting model, with a rim lighting shader.

The shaders created enhanced the visuals of our game. Rim lighting was used for the players to make them stand out from the rest of the objects in the game scene, 
while Bump mapping was used to create a textured and bumpy look for the environment, and finally the transparent shader was used for the falling objects to give them a glass-like look.

## Screenshots

### Default Unity Lighting
![](<default scene.png>)

### Lambert Lighting
![](<lambert scene.png>)

### Specular Lighting
![](<specular scene.png>)

### Toon Lighting
![](<toon scene.png>)

## DEMO
![](ShaderDemo.gif)