Shader "Phone"
{
    Properties
    {
        _MainColor ("_MainColor", Color) = (1, 1, 1, 1)
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
               float3 nDir = i.normalWS;                                             //获取法线方向

               float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.positionWS);
               Light  lightData = GetMainLight(SHADOW_COORDS);
               
               float3 lDir = lightData.direction;                                   //获取灯光方向
               float3 rDir = reflect(-lDir , nDir);                                 //获取反射方向
               //float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS);    //获取视角方向
               half3 vDir = normalize(GetCameraPositionWS() - i.positionWS);

               
               float Phone = pow(max(0.0 , dot(rDir , vDir)), _SpecularPow);           //Phone ( r dot v)   rDir = Refect(-lDir , nDir)
               float lambert = max(0.0 , dot(nDir , lDir));
               float3 finalColor = lambert * _MainColor.rgb + Phone;

               return float4(finalColor , 1);
            }
            ENDHLSL
        }
    }
}
