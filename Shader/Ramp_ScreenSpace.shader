Shader "Ramp_ScreenSpace"
{
    Properties
    {
            _BaseColor ("MainColor", Color) = (1, 1, 1, 1)
            _RampMap ("RampMap", 2D) = "white" {}

            _BrightColor ("BrightColor", Color) = (1,1,1,1)
            _DarkColor ("DarkColor", Color) = (1,1,1,1)

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
            float4 _RampMap_ST;

            float4 _BrightColor;
            float4 _DarkColor;
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

            //TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            //SAMPLER(sampler_CameraDepthTexture);

            TEXTURE2D(_RampMap);
            SAMPLER(sampler_RampMap);
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
               float2 screenUVs = (i.screenPos.xy / i.screenPos.w) ;                                                                     

               /* float sceneRawDepth = SampleSceneDepth(IN.scrPos.xy / IN.scrPos.w);
               float sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
               float scene01Depth = Linear01Depth(sceneRawDepth, _ZBufferParams); */
              
               float3 nDir = i.normalWS;
               //??????????????????                                                                                                
               Light  lightData = GetMainLight();

               //??????????????????
               float3 lDir = lightData.direction; 
               //?????????                                                                                      
               float nDotl = dot(nDir , lightData.direction);
               //float halflambert = nDotl * 0.5 + 0.5;
               //????????????
               float4 maintex = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, TRANSFORM_TEX((screenUVs * 2 - 1).rg , _RampMap));
               float4 stepcolor = lerp(_DarkColor , _BrightColor, step(maintex , nDotl)) + nDotl * _BaseColor; 


               //float3 finalColor = nDotl * _BaseColor.rgb * maintex.rgb;
               return stepcolor; 
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