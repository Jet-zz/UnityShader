Shader "Halftone"
{
    Properties
    {
            _BaseColor ("MainColor", Color) = (1, 1, 1, 1)
            _Distance ("Distance", Range(1, 200)) = 1
            _OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.24
            _OutlineColor ("OutLine Color", Color) = (1,1,1,1)
    }
    SubShader
    {
            HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _OutlineWidth;
            float4 _OutlineColor;

            float _Distance;

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
                float3 normalWS     : TEXCOORD2;  
                float4 screenPos    : TEXCOORD3;
            };

            ENDHLSL
        Pass 
        {
            Tags{"LightMode" = "UniversalForward"} 
            Cull off
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
                o.screenPos = ComputeScreenPos(o.positionCS);
                
                return o;
            }
            float4 Frag(VertexOutput i):SV_Target
            {  
               //????????????UV
               float2 screenUVs = (i.screenPos.xy / i.screenPos.w) * _Distance;                                                                     
                 
               float3 nDir = i.normalWS;
               //??????????????????                                                                                                
               Light  lightData = GetMainLight();

               //??????????????????
               float3 lDir = lightData.direction; 
               //?????????                                                                                      
               float nDotl = dot(nDir , lightData.direction);
               //float halflambert = nDotl * 0.5 + 0.5;

               float lattice = length((frac(screenUVs)*1.0+-0.5)); 
               float finalColor = round(pow(lattice, nDotl*-2.5+2.0));
               
               return float4(finalColor,finalColor,finalColor,1); 
            }
            ENDHLSL
        }
        Pass
        {
            Name "OutLine"
			Tags{ "LightMode" = "SRPDefaultUnlit" }
			Cull front
			HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			VertexOutput vert(VertexInput v)
            {
                float4 scaledScreenParams = GetScaledScreenParams();
                float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);        //??????X??????????????????????????????

				VertexOutput o = (VertexOutput)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                float3 normalCS = TransformWorldToHClipDir(normalInput.normalWS);       //???????????????????????????
                float2 extendDis = normalize(normalCS.xy) *(_OutlineWidth*0.01);        //????????????????????????????????????
                extendDis.x /=ScaleX ;                                                  //??????????????????????????????1:1????????????????????????????????????????????????????????????x????????????
                o.positionCS = vertexInput.positionCS;

                #if _OLWVWD_ON
                    //???????????????????????????
                    o.positionCS.xy +=extendDis;
                #else
                    //???????????????????????????????????????????????????????????????NDC?????????????????????
                    //????????????????????????NDC???????????????w?????????????????????????????????w???????????????????????????????????????NDC????????????
                    o.positionCS.xy += extendDis * o.positionCS.w ;
                #endif
                return o;
            }
			float4 frag(VertexOutput i) : SV_Target
            {
				return float4(_OutlineColor.rgb, 1);
			}
		    ENDHLSL
		}
    }
    Fallback "Universal Render Pipeline/Lit"
}