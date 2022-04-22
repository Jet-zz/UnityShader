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
               //屏幕坐标UV
               float2 screenUVs = (i.screenPos.xy / i.screenPos.w) ;                                                                     

               /* float sceneRawDepth = SampleSceneDepth(IN.scrPos.xy / IN.scrPos.w);
               float sceneEyeDepth = LinearEyeDepth(sceneRawDepth, _ZBufferParams);
               float scene01Depth = Linear01Depth(sceneRawDepth, _ZBufferParams); */
              
               float3 nDir = i.normalWS;
               //获取法线方向                                                                                                
               Light  lightData = GetMainLight();

               //获取灯光方向
               float3 lDir = lightData.direction; 
               //漫反射                                                                                      
               float nDotl = dot(nDir , lightData.direction);
               //float halflambert = nDotl * 0.5 + 0.5;
               //纹理采样
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
                float ScaleX = abs(scaledScreenParams.x / scaledScreenParams.y);        //求得X因屏幕比例缩放的倍数

				VertexOutput o = (VertexOutput)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                float3 normalCS = TransformWorldToHClipDir(normalInput.normalWS);       //法线转换到裁剪空间
                float2 extendDis = normalize(normalCS.xy) *(_OutlineWidth*0.01);        //根据法线和线宽计算偏移量
                extendDis.x /=ScaleX ;                                                  //由于屏幕比例可能不是1:1，所以偏移量会被拉伸显示，根据屏幕比例把x进行修正
                o.positionCS = vertexInput.positionCS;

                #if _OLWVWD_ON
                    //屏幕下描边宽度会变
                    o.positionCS.xy +=extendDis;
                #else
                    //屏幕下描边宽度不变，则需要顶点偏移的距离在NDC坐标下为固定值
                    //因为后续会转换成NDC坐标，会除w进行缩放，所以先乘一个w，那么该偏移的距离就不会在NDC下有变换
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