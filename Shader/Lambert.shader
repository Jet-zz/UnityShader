Shader "Lambert"
{
    Properties
    {
        _BaseColor ("_MainColor", Color) = (1, 1, 1, 1)
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

            CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			CBUFFER_END


            struct VertexInput
            {
                float4 positionOS	  : POSITION;    
                float3 normalOS       : NORMAL;      
            };

            struct VertexOutput
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                half3  normalWS     : TEXCOORD1;       
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz);
                o.normalWS = normalInputs.normalWS;
                return o;

            }

            half4 frag(VertexOutput i) : SV_Target
            {
               float3 nDir = i.normalWS;            //获取法线方向

               float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);
               Light  lightData = GetMainLight(SHADOW_COORDS);
               
               float3 lDir = lightData.direction;   //获取灯光方向
               float nDotl =  dot(nDir , lDir);
               float3 lambert = max(0.0, nDotl) * _BaseColor.rgb;

               return float4(lambert,1);
            }
            ENDHLSL
        }
    }
}
