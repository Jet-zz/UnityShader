Shader "Ramp_Jade"
{
    Properties
    {
            _RampMap ("RampMap", 2D) = "white" {}

            _HighLightOffset01("highlightoffset01" , vector) = (1 ,1 , 1 ,0)
            _HighLightOffset02("highlightoffset02" , vector) = (1 ,1 , 1 ,0)
            _HighLightOffRange01("HighLightOffRange01" , range(0.9 , 1.0)) = 0.1
            _HighLightOffRange02("HighLightOffRange02" , range(0.9 , 1.0)) = 0.1

            _HighLightColor("HighLightColor" , color) = (1, 1, 1, 1)

            _FresnelColor("FresnelColor", color) =(1, 1, 1, 1)
            _FresnelPow("FresnelPow" , range(1,5)) = 1

    }
    SubShader
    {   
            Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
            LOD 100
            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float4 _RampMap_ST;

            float3 _HighLightOffset01;
            float3 _HighLightOffset02;
            float _HighLightOffRange01;
            float _HighLightOffRange02;

            float4 _HighLightColor;

            float4 _FresnelColor;
            float  _FresnelPow;

            TEXTURE2D(_RampMap);
            SAMPLER(sampler_RampMap);
            
            CBUFFER_END
            

            struct VertexInput
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 uv           : TEXCOORD;
            };
            struct VertexOutput
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;    
                float3 positionWS   : TEXCOORD1;
                half3  normalWS     : TEXCOORD2;  
                float3 viewDirWS    : TEXCOORD3; 
            };

            ENDHLSL
        Pass 
        {
            Tags{"LightMode" = "UniversalForward"} 
			HLSLPROGRAM
			#pragma target 3.0
            #pragma vertex Vertex
            #pragma fragment Frag
            VertexOutput Vertex(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = normalInputs.normalWS;
                o.uv = v.uv;
                o.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                return o;
            }
            float4 Frag(VertexOutput i):SV_Target
            {
               //获取法线方向
               float3 nDir = i.normalWS;  
               //获取灯光方向                    
               Light  lightData = GetMainLight();
               float3 lDir = normalize(lightData.direction);  
               //获取视角方向
               float3 vDir = normalize(i.viewDirWS);                                        
               //向量计算
               float nDotl = dot(nDir , lDir); 
               //漫反射                
               float halflambert = nDotl * 0.5 + 0.5;
               float4 maintex = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, real2(halflambert, 0.5));
               
               //漫反射高光
               float3 nDirOffset01 = normalize(nDir + _HighLightOffset01);
               float3 highlight01 = step(_HighLightOffRange01 , dot(nDirOffset01, lDir)); 

               float3 nDirOffset02 = normalize(nDir + _HighLightOffset02);
               float3 highlight02 =step(_HighLightOffRange02 , dot(nDirOffset02, lDir)); 

               float3 max_highlight = clamp(max(highlight01 , highlight02), 0 , 1) *_HighLightColor; 

               //菲尼尔反射
               float3 Fresnel = pow((1.0 - saturate(dot(normalize(nDir) , normalize(vDir)))) , _FresnelPow) * _FresnelColor;
               float3 finalColor = maintex.rgb + max_highlight ; 
               float3 BlendColor =  saturate((1.0-(1.0-Fresnel.rgb)*(1.0-finalColor.rgb)));      //Blend  Screen

               return float4(BlendColor , 1);
            }
            ENDHLSL
        }
      
    }
    Fallback "Universal Render Pipeline/Lit"
}