Shader "Unlit/NormalMap"
{
    Properties
    {
		_MainTex ("Albedo", 2D) = "white" {}
		[NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1

        _Tint ("Tint", Color) = (1, 1, 1, 1)
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.1
        
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
		        float4 tangent : TEXCOORD2;
                float3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex, _DetailTex;
            float4 _MainTex_ST, _DetailTex_ST;
            float4 _Tint;
            float4 _SpecularTint;
            float _Smoothness;
            float _Metallic;

            sampler2D _NormalMap, _DetailNormalMap;
            float _BumpScale, _DetailBumpScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); // get the worldposition of this object
                o.normal = UnityObjectToWorldNormal(v.normal); //set the normals in worldspace
 
                // get tangent and convert it to worldSpace
		        o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                // set uv with the textures
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	            o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
                return o;
            }

            void FragmentNormals(inout v2f i) {
                // get normal from normal map and merge them
                float3 mainNormal = UnpackNormal(tex2D(_NormalMap, i.uv.xy));
	            float3 detailNormal = UnpackNormal(tex2D(_DetailNormalMap, i.uv.zw));
	            float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

                // generate binormal from normal and tangent
		        float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);
	
                // apply new normals
    	        i.normal = normalize(
		            tangentSpaceNormal.x * i.tangent +
		            tangentSpaceNormal.y * binormal +
		            tangentSpaceNormal.z * i.normal
	            );
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // normalize the normals
                FragmentNormals(i);

                // get light and view direction
                float3 lightDir = _WorldSpaceLightPos0.xyz; // get light dir
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                // set light correct with the normals and lightdirection
                float3 dotLight = DotClamped(lightDir, i.normal);

                // difussion
                float3 lightColor = _LightColor0.rgb; // get light colors
                float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
                albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

                float3 diffuse = albedo * lightColor * dotLight; // check how much color is reflected

                // lower albedo and factor in the metallic Properties
                float3 specularTint;
                float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				); 

                // specular
                float3 halfVector = normalize(lightDir + viewDir); // get vector halfway between light and view direction (Blinn-Phong)
                float3 specular = specularTint * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);

                return float4(diffuse + specular, 1);
            }
            ENDCG
        }
    }
}
