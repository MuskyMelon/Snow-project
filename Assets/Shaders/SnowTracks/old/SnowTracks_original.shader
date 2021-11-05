Shader "Custom/SnowTracks"
{
    Properties
    {
        // snow
        _SnowTex ("Snow (RGB)", 2D) = "white" {}
        _SnowColor ("Snow Color", Color) = (1,1,1,1)

        // ground
        _GroundTex ("Ground (RGB)", 2D) = "white" {}
        _GroundColor ("Ground Color", Color) = (1,1,1,1)

        // perlin
        _PerlinTex ("Perlin Texture (RGB)", 2D) = "white" {}
        _PerlinDisplacement  ("Perlin Displacement", Range(0, 1.0)) = 0.3

        // tess
        _Tess ("Tesselation", Range(1,32)) = 4
        
        // splat and displacement
        _Splat ("SplatMap", 2D) = "black" {}
        _Displacement  ("Displacement", Range(0, 1.0)) = 0.3

        // normal textures
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1

        // second textures
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1

        // params
        _Tint ("Tint", Color) = (1, 1, 1, 1)
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        pass {
            CGPROGRAM
            #pragma require tessellation 
            #pragma tesselation tessDistance
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.6
            #include "Tessellation.cginc"
            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
		        float4 tangent : TEXCOORD2;
                float3 worldPos : TEXCOORD4;
            };
            // textures
            sampler2D _GroundTex, _SnowTex, _DetailTex;
            fixed4 _SnowColor, _GroundColor, _DetailTex_ST;

            // normal maps
            sampler2D _NormalMap, _DetailNormalMap;
            float _BumpScale, _DetailBumpScale;

            // height textures
            sampler2D _Splat, _PerlinTex;
            float _Displacement, _PerlinDisplacement;

            // tesselation
            float _Tess;
    
            // extra params
            float4 _Tint, _SpecularTint;
            half _Metallic, _Smoothness;

            float4 tessDistance (appdata v0, appdata v1, appdata v2) {
                float minDist = 10.0;
                float maxDist = 25.0;
                return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
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


            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); // get the worldposition of this object
                o.normal = UnityObjectToWorldNormal(v.normal); //set the normals in worldspace

                // apply the displacement texture and the perlin noise
                float4 coordinate = tex2Dlod(_Splat, float4(v.texcoord.xy,0,0)); // get splatmap
                float4 perlinCoordinate = tex2Dlod(_PerlinTex, float4(v.texcoord.xy,0,0)); // get perlin map

                float d2 = perlinCoordinate.r * _PerlinDisplacement; // height of perlin map

                float d = (d2 + _Displacement) * coordinate.r; // depth of tracks

                o.vertex.xyz -= v.normal * d; // apply displacement to lower the footsteps
                o.vertex.xyz += v.normal * (_Displacement + d2); // raise so you can walk inside the snow

                return o;

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
                float3 albedo = tex2D(_SnowTex, i.uv.xy).rgb * _Tint.rgb;
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
