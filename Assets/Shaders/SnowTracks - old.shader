Shader "Custom/SnowTracksOld"
{
    Properties
    {
        _SnowTex ("Snow (RGB)", 2D) = "white" {}
        _SnowColor ("Snow Color", Color) = (1,1,1,1)

         _GroundTex ("Ground (RGB)", 2D) = "white" {}
        _GroundColor ("Ground Color", Color) = (1,1,1,1)

        _PerlinTex ("Perlin Texture (RGB)", 2D) = "white" {}
        _PerlinDisplacement  ("Perlin Displacement", Range(0, 1.0)) = 0.3

        _EdgeLength ("Edge length", Range(2,50)) = 5
        _Phong ("Phong Strengh", Range(0,1)) = 0.5

        _Splat ("SplatMap", 2D) = "black" {}
        _Displacement  ("Displacement", Range(0, 1.0)) = 0.3
   
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _size ("size", int) = 1

         _toggleSnow ("toggleOld", Range(0,1)) = 0
         _toggleBlur ("toggleAllBlur", Range(0,1)) = 0
         _textureDepthOffset ("offsetFloorTexture", Range(0,1)) = 0.3

          _NormalMap ("Normal Map (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:disp tessellate:tessEdge tessphong:_Phong 
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

        sampler2D _Splat, _PerlinTex;
        float4 _Splat_TexelSize;
        float _Displacement, _PerlinDisplacement;
        float _size;
        bool _toggleSnow, _toggleBlur;
        float _textureDepthOffset;

        float3 filterNormal(float2 uv, float texelSize, int terrainSize, float displacement)
        {
            
            float x = tex2D(_Splat, uv + texelSize*float2(0,-1)).r * displacement;
            float y = tex2D(_Splat, uv + texelSize*float2(-1,0)).r * displacement;
            float z = tex2D(_Splat, uv + texelSize*float2(1,0)).r * displacement;
            float w = tex2D(_Splat, uv + texelSize*float2(0,1)).r * displacement;
            float4 h = (x, y, z, w);
 
            float3 n;
            n.z = -(h[0] - h[3]);
            n.x = (h[1] - h[2]);
            n.y = 2 * texelSize * terrainSize; // pixel space -> uv space -> world space
 
            return normalize(n);
        }

        float getSmoothDepth(fixed2 uv) {
            float4 coordinate = tex2Dlod(_Splat, float4(uv.xy,0,0));
            fixed2 texSize =  _Splat_TexelSize.xy;
            float redness = 0;
            if(coordinate.r != 0) {
                for (int i = -_size; i <= _size; ++i) {
                    for (int j = -_size; j <= _size; ++j) {
                       redness += tex2Dlod(_Splat, float4(uv.x + ((float)i * texSize.x), uv.y + ((float)j * texSize.y), 0, 0)).r;
                    }
                }
                redness /= pow(_size * 2 + 1, 2);
            } else {
                redness = coordinate.r;
            }

            if(_toggleBlur == 1) {
                for (int i = -_size; i <= _size; ++i) {
                    for (int j = -_size; j <= _size; ++j) {
                       redness += tex2Dlod(_Splat, float4(uv.x + ((float)i * texSize.x), uv.y + ((float)j * texSize.y), 0, 0)).r;
                    }
                }
                redness /= pow(_size * 2 + 1, 2);
            }

            if(_toggleSnow == 1) {
                 redness = coordinate.r;
            }

            return redness;
        }

        void disp (inout appdata v)
        {
            // apply the displacement texture and the perlin noise
            float4 perlinCoordinate = tex2Dlod(_PerlinTex, float4(v.texcoord.xy,0,0)); // get perlin map

            float d2 = perlinCoordinate.r * _PerlinDisplacement; // height of perlin map

            float d = (d2 + _Displacement) * getSmoothDepth(v.texcoord.xy); // depth of tracks

            v.vertex.xyz -= v.normal * d; // apply displacement to lower the footsteps
            v.vertex.xyz += v.normal * (_Displacement + d2); // raise so you can walk inside the snow
            

            // normals 
            
        }

        sampler2D _GroundTex, _SnowTex;
        fixed4 _SnowColor, _GroundColor;

        struct Input
        {
            float2 uv_GroundTex, uv_SnowTex, uv_Splat;
            float2 uv_NormalMap;

        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _NormalMap;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color

            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            float amount = getSmoothDepth(IN.uv_Splat.xy);
            fixed4 texC;
            if(amount > 1 - _textureDepthOffset) {
                amount -= 1 - _textureDepthOffset;
                amount /= _textureDepthOffset;
                texC = lerp(tex2D (_SnowTex, IN.uv_SnowTex) * _SnowColor, tex2D (_GroundTex, IN.uv_GroundTex) * _GroundColor, amount);
            } else 
                texC = tex2D (_SnowTex, IN.uv_SnowTex) * _SnowColor;

            o.Albedo = texC.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = texC.a;

            o.Normal += amount;
            o.Normal = UnpackNormal( tex2D(_NormalMap, IN.uv_NormalMap) );
             o.Albedo = (0, 0, 0, amount);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
