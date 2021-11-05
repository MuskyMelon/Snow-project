  Shader "Phong Tessellation" {
        Properties {
            _EdgeLength ("Edge length", Range(2,50)) = 5
            _Phong ("Phong Strengh", Range(0,1)) = 0.5
             _DispTex ("Disp Texture", 2D) = "gray" {}
            _Displacement ("Displacement", Range(0, 1.0)) = 0.3
            _MainTex ("Base (RGB)", 2D) = "white" {}
            _NormalMap ("normalMap", 2D) = "white" {}
            _Color ("Color", color) = (1,1,1,0)
        }
        SubShader {
            Tags { "RenderType"="Opaque" }
            LOD 300
            
            CGPROGRAM
            #pragma surface surf Lambert addshadow  vertex:disp tessellate:tessEdge tessphong:_Phong nolightmap
            #pragma debug
            #include "Tessellation.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                float4 tangent: TANGENT;
            };

             struct Input {
                float2 uv_MainTex;
                float2 uv : TEXCOORD0;
                half3 normal: TEXCOORD1;
                half3 tspace0 : TEXCOORD2; // tangent.x, bitangent.x, normal.x
                half3 tspace1 : TEXCOORD3; // tangent.y, bitangent.y, normal.y
                half3 tspace2 : TEXCOORD4; // tangent.z, bitangent.z, normal.z
            };

            float _Phong;
            
            sampler2D _DispTex;
            float _Displacement;
            float _EdgeLength;

            float4 tessEdge (appdata v0, appdata v1, appdata v2)
            {
                return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
            }

            Input disp (inout appdata v)
            {

                Input i;
                float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
                v.vertex.xyz -= v.normal * d;

                half3 wNormal       = UnityObjectToWorldNormal(v.normal);
                i.normal            = wNormal;

                i.uv = v.texcoord;

                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(wNormal, wTangent) * tangentSign;

                //output the tangent space matrix
                i.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                i.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                i.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

                return i;

            }

            fixed4 _Color;
            sampler2D _NormalMap;
            sampler2D _MainTex;
            half _BumpAmount;

            void surf (Input IN, inout SurfaceOutput o) {
                half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                o.Alpha = c.a;

                half3 snormal = normalize(IN.normal);

                half3 tnormal = UnpackNormal(tex2D(_NormalMap, IN.uv)); 
                half3 worldNormal;
                worldNormal.x = dot(IN.tspace0, tnormal);
                worldNormal.y = dot(IN.tspace1, tnormal);
                worldNormal.z = dot(IN.tspace2, tnormal);
                half3 normal = normalize(lerp(snormal, worldNormal, _BumpAmount));
                o.Normal = snormal;

            }

            ENDCG
        }
        FallBack "Diffuse"
    }