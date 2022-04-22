Shader "Blinn_Phong"
{
    Properties
    {
        _MainColor ("MainColor", Color) = (1, 1, 1, 1)
        _SpecularPow ("高光次幂", range(1, 90)) = 30

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
            float _SpecularPow;
			CBUFFER_END


            struct VertexInput
            {
                float4 positionOS	: POSITION;    
                float3 normalOS     : NORMAL;      
            };

            struct VertexOutput
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;   
                float3 viewDirWS    : TEXCOORD2; 
            };

            

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = normalInputs.normalWS;
                o.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                return o;

            }

            half4 frag(VertexOutput i) : SV_Target
            {
               //准备向量
               float3 nDir = normalize(i.normalWS);                                         //获取法线方向

               //float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);
               Light  lightData = GetMainLight();
               float3 lDir = normalize(lightData.direction);                                //获取灯光方向
               //float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);    
               float3 vDir = normalize(i.viewDirWS);                                        //获取视角方向
               float3 hDir = normalize(vDir + lDir);                                        //获取半角方向
               
               //准备点积结果
               float ndotl = dot(nDir , lDir);
               float hdotn = dot(nDir , hDir);

               //光照模型
               float lambert = max(0.0 , ndotl);
               float blinnPhone = pow(max(0.0 , hdotn), _SpecularPow);                      //BlinnPhone ( n dot h)   hDir = vDir + lDir
              
               float3 finalColor = lambert * _MainColor.rgb + blinnPhone;

               return float4(finalColor , 1);
            }
            ENDHLSL
        }
    }
}
