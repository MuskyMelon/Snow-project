Shader "Custom/SnowTracksNew"
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

         _toggleEdgeBlur ("_toggleEdgeBlur", Range(0,1)) = 0
         _toggleBlur ("toggleAllBlur", Range(0,1)) = 0
         _textureDepthOffset ("offsetFloorTexture", Range(0,1)) = 0.3

         _offset ("offset", Range(0,1)) = 0.3
         _objectSize ("object size", float) = 0.3

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

        sampler2D _Splat, _PerlinTex;
        float4 _Splat_TexelSize;
        float _Displacement, _PerlinDisplacement;
        float _size;
        bool _toggleEdgeBlur, _toggleBlur;
        float _textureDepthOffset;

        sampler2D _GroundTex, _SnowTex;
        fixed4 _SnowColor, _GroundColor;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _NormalMap;

        float _Phong;
        float _EdgeLength;
        float _objectSize;

        float _offset;

        struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
            float3 worldNormal : TEXCOORD1;
        };

        struct Input
        {
            float2 uv_GroundTex, uv_SnowTex, uv_Splat;
            float2 uv_NormalMap;
            float3 worldNormal;
        };

        float4 tessEdge (appdata v0, appdata v1, appdata v2)
        {
            return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float boxBlur(fixed2 uv) {
            fixed2 texSize = _Splat_TexelSize.xy;
            float height = 0;
            for (int i = -_size; i <= _size; ++i) {
                for (int j = -_size; j <= _size; ++j) {
                    height += tex2Dlod(_Splat, float4(uv.x + ((float)i * texSize.x), uv.y + ((float)j * texSize.y), 0, 0)).r;
                }
            }

           return height /= pow(_size * 2 + 1, 2);
        }

        float getHeightColor(fixed2 uv) {
            float4 coordinate = tex2Dlod(_Splat, float4(uv.xy,0,0));
            if(_toggleEdgeBlur == 1)
                return coordinate.r != 0 ? boxBlur(uv) : coordinate.r;
            else if(_toggleBlur == 1)
                return boxBlur(uv);
            else 
                return coordinate.r;
        }

        float depthGenerate(fixed2 uv) {
            // get texture info of current uv
            float4 perlinCoordinate = tex2Dlod(_PerlinTex, float4(uv.xy,0,0));

            float height = getHeightColor(uv);

            // displacement = perlin displacement + normalDisplacement * the red value calculated above
            float d2 = perlinCoordinate.r * _PerlinDisplacement;

            height = (d2 + _Displacement) * height; 

            return height - (_Displacement + d2);
        }

        void disp (inout appdata v)
        {
            float3 displacement = v.vertex.xyz - v.normal * depthGenerate(v.texcoord.xy);
            v.vertex.xyz = displacement; // raise so you can walk inside the 
            // normals 

            float3 bitangent = normalize(cross(v.normal, v.tangent));

            float3 neighbour1 = v.vertex.xyz + v.tangent * _objectSize;
            float3 neighbour2 = v.vertex.xyz + bitangent * _objectSize;

            float2 neighbour1uv = v.texcoord.xy + float2(-_Splat_TexelSize.x, 0);
            float2 neighbour2uv = v.texcoord.xy + float2(0, -_Splat_TexelSize.x);

            float3 displacedNeighbour1 = neighbour1 - v.normal * depthGenerate(neighbour1uv);
            float3 displacedNeighbour2 = neighbour2 - v.normal * depthGenerate(neighbour2uv);

            float3 displacedTangent = displacedNeighbour1 - displacement;
            float3 displacedBitangent = displacedNeighbour2 - displacement;
            float3 displacedNormal = normalize(cross(displacedTangent, displacedBitangent));
            v.normal = displacedNormal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color

            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            float amount = getHeightColor(IN.uv_Splat.xy);
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

            //o.Normal *= amount;
            //o.Normal = UnpackNormal( tex2D(_NormalMap, IN.uv_NormalMap) );
            o.Albedo = 0.5 + o.Normal * 0.5;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
