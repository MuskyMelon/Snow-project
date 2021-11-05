Shader "Custom/SnowTracks_edges"
{
    Properties
    {


        [Header(Tesselation)][Space(20)]
        _EdgeLength ("Edge length", Range(2,50)) = 15


        [Header(Textures)][Space(20)]

        _SnowTex ("Snow (RGB)", 2D) = "white" {}
        _SnowColor ("Snow Color", Color) = (1,1,1,1)

         _GroundTex ("Ground (RGB)", 2D) = "white" {}
        _GroundColor ("Ground Color", Color) = (1,1,1,1)


        [Header(Depth Textures)][Space(20)]
        _PerlinTex ("Perlin Texture (RGB)", 2D) = "white" {}
        _Splat ("SplatMap", 2D) = "black" {}
       

        [Header(Normals)][Space(20)]

        _SnowNormalMap ("Snow normals (RGB)", 2D) = "white" {}
        _DetailedSnowMap ("Detailed Snow normals (RGB)", 2D) = "white" {}
        _DirtNormalMap ("Dirt normals (RGB)", 2D) = "white" {}
        _edgesNormalMap ("Edge normals (RGB)", 2D) = "white" {}

        [Header(Displacement Texture)][Space(20)]

         _snowDisp ("Snow disp", 2D) = "white" {}
         _snowDispStrength  ("strength", Range(0, 1.0)) = 0.3

         _edgeDispStrength ("edge strength", Range(0, 1.0)) = 0.3

        [Header(Displacement)][Space(20)]

        _edgeDisplacement ("_edgeDisplacement", Range(0, 1.0)) = 0.3
        _PerlinDisplacement  ("Perlin Displacement", Range(0, 1.0)) = 0.3
        _Displacement  ("Displacement", Range(0, 1.0)) = 0.3

        [Header(Other)][Space(20)]
       
        _textureDepthOffset ("offsetFloorTexture", Range(0,1)) = 0.3

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessEdge nolightmap
        #pragma target 4.6
        #include "Tessellation.cginc"

        struct appdata {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input
        {
            float2 uv_GroundTex, uv_SnowTex, uv_Splat;
            float2 uv_SnowNormalMap, uv_DirtNormalMap, uv_DetailedSnowMap, uv_edgesNormalMap;
        };

        float2 uv_SnowNormalMap;

        sampler2D _Splat, _PerlinTex, _DispTex, _snowDisp;
        float4 _Splat_TexelSize;
        float _Displacement, _PerlinDisplacement;
        float _snowDispStrength, _edgeDispStrength;
        float _textureDepthOffset, _edgeDisplacement;
        
        sampler2D _GroundTex, _SnowTex;
        fixed4 _SnowColor, _GroundColor;
        float _EdgeLength;

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        sampler2D _DirtNormalMap, _SnowNormalMap, _DetailedSnowMap, _edgesNormalMap;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // tesselation
        float4 tessEdge (appdata v0, appdata v1, appdata v2)
        {
            return UnityEdgeLengthBasedTess (v0.vertex, v1.vertex, v2.vertex, _EdgeLength);
        }

        // vertex shader
        void disp (inout appdata v)
        {
            // apply the displacement texture and the perlin noise
            float4 perlinCoordinate = tex2Dlod(_PerlinTex, float4(v.texcoord.xy,0,0)); // get perlin map
            float4 depthCoordinate = tex2Dlod(_Splat, float4(v.texcoord.xy,0,0)); // get depth map

            float perlinDisplacement = perlinCoordinate.r * _PerlinDisplacement; // height of perlin map
            float imprintDisplacement = (perlinDisplacement + _Displacement) * depthCoordinate.r; // depth of tracks
            float edgeDisplacement = depthCoordinate.b * _edgeDisplacement;


            float3 normals = UnpackNormal( tex2D(_SnowNormalMap, v.texcoord.xy, 0, 0) );

            if(depthCoordinate.r < 0.2  && depthCoordinate.b == 0) {
                v.vertex.xyz += (1- depthCoordinate.r) * (v.normal * normals * tex2Dlod(_snowDisp, float4(v.texcoord.xy,0,0)).r * _snowDispStrength);
            } else if (depthCoordinate.b > 0) {
                v.vertex.xyz += (1- depthCoordinate.r) * (v.normal * normals * tex2Dlod(_snowDisp, float4(v.texcoord.xy,0,0)).r * _edgeDispStrength);
            }

            v.vertex.xyz -= v.normal * imprintDisplacement; // apply displacement to lower the footsteps
            v.vertex.xyz += v.normal * (_Displacement + perlinDisplacement + edgeDisplacement); // raise so you can walk inside the snow 
        }

        // surface shader
        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            float4 textureCoor = tex2Dlod(_Splat, float4(IN.uv_Splat.xy,0,0));
            float amount = textureCoor.r;
            fixed4 texC;

            if(amount > 1 - _textureDepthOffset) {
                // set color
                amount -= 1 - _textureDepthOffset;
                amount /= _textureDepthOffset;
                texC = lerp(tex2D (_SnowTex, IN.uv_SnowTex) * _SnowColor, tex2D (_GroundTex, IN.uv_GroundTex) * _GroundColor, amount);

                // blend all the normals
                float3 normals = UnpackNormal( tex2D(_SnowNormalMap, IN.uv_SnowNormalMap) );
                float3 detailedNormals = UnpackNormal( tex2D(_DetailedSnowMap, IN.uv_DetailedSnowMap) );
                float3 snowNormal = BlendNormals(normals, detailedNormals);
                float3 dirtNormal = UnpackNormal(tex2D(_DirtNormalMap, IN.uv_DirtNormalMap));
                o.Normal = normalize(lerp(snowNormal, dirtNormal, amount));
            } else if (textureCoor.b > 0) {
                float3 normals = UnpackNormal( tex2D(_SnowNormalMap, IN.uv_SnowNormalMap) );
                float3 detailedNormals = UnpackNormal( tex2D(_DetailedSnowMap, IN.uv_DetailedSnowMap) );

                float3 snowNormal = BlendNormals(normals, detailedNormals);

                float3 edgeNormals = UnpackNormal( tex2D(_edgesNormalMap, IN.uv_edgesNormalMap) );
                edgeNormals = BlendNormals(detailedNormals, edgeNormals);

          

               
                o.Normal = normalize(lerp(snowNormal, edgeNormals, textureCoor.b + 0.3));
                //o.Normal = edgeNormals;
                 texC = tex2D (_SnowTex, IN.uv_SnowTex) * _SnowColor;

            } else  {
                // set normals
                float3 normals = UnpackNormal( tex2D(_SnowNormalMap, IN.uv_SnowNormalMap) );
                float3 detailedNormals = UnpackNormal( tex2D(_DetailedSnowMap, IN.uv_DetailedSnowMap) );
                o.Normal = BlendNormals(normals, detailedNormals);

                // set color
                texC = tex2D (_SnowTex, IN.uv_SnowTex) * _SnowColor;

            }

    
            o.Albedo = texC.rgb;
            o.Alpha = texC.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}