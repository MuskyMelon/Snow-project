Shader "Tessellation 2" {
        Properties {
            _EdgeLength ("Edge length", Range(2,50)) = 15
            _MainTex ("Base (RGB)", 2D) = "white" {}
             _Phong ("Phong Strengh", Range(0,1)) = 0.5
            _DispTex ("Disp Texture", 2D) = "gray" {}
            _NormalMap ("Normalmap", 2D) = "bump" {}
            _Displacement ("Displacement", Range(0, 1.0)) = 0.3
            _Color ("Color", color) = (1,1,1,0)
            _SpecColor ("Spec color", color) = (0.5,0.5,0.5,0.5)

        	_Col1 ("Color 1", Color) = (1,1,1,1)
		    _Col2 ("Color 2", Color) = (0,0,0,1)
        }
        SubShader {
            Tags { "RenderType"="Opaque" }
            LOD 300
            
            CGPROGRAM
            #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessEdge nolightmap tessphong:_Phong
            #pragma target 4.6
            #include "Tessellation.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            
            float _Phong;

            float _EdgeLength;

            float4 tessEdge (appdata v0, appdata v1, appdata v2)
            {
                return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
            }

            sampler2D _DispTex;
            float _Displacement;
        
            struct Input {
                float2 uv_MainTex;
                float3 normal;
                float3 worldNormal;
            };

            float3 filterNormal(float2 uv, float texelSize, float texelAspect) 
            { 
                float4 h; 

                h[0] = tex2Dlod(_DispTex, float4(uv + texelSize * float2( 0,-1),0,0)).r * texelAspect; 
                h[1] = tex2Dlod(_DispTex, float4(uv + texelSize * float2(-1, 0),0,0)).r * texelAspect; 
                h[2] = tex2Dlod(_DispTex, float4(uv + texelSize * float2( 1, 0),0,0)).r * texelAspect; 
                h[3] = tex2Dlod(_DispTex, float4(uv + texelSize * float2( 0, 1),0,0)).r * texelAspect;
                 
                float3 n; 
                n.z = h[0] - h[3]; 
                n.x = h[1] - h[2]; 
                n.y = 2; 
 
                return normalize(n); 
            } 


            Input disp (inout appdata v)
            {
                Input o;
                float d = tex2Dlod(_DispTex, float4(v.texcoord.xy,0,0)).r * _Displacement;
                v.vertex.xyz -= v.normal * d;

                v.normal = filterNormal(v.texcoord.xy, (float)((float)1/(float)512), 512);

                return o;

            }

            sampler2D _MainTex;
            sampler2D _NormalMap;
            fixed4 _Color;

             float3 _Col1;
	 float3 _Col2;

            void surf (Input IN, inout SurfaceOutput o) {
                half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                o.Specular = 1;
                o.Gloss = 1;
                //float3 normal = IN.worldNormal;
		        //float normalMask = normal.x + normal.y + normal.z;
		        //o.Emission = _Col1 * normalMask + _Col2 * (1-normalMask);
                o.Albedo = o.Normal +0.5 * 0.5;
            }
            ENDCG
        }
        FallBack "Diffuse"
    }