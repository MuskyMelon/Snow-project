Shader "Unlit/CreateTracks"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Draw Color", Color) = (1,0,0,0)
    }
    SubShader
    {
        // No culling or depth
		Cull Off ZWrite Off ZTest Always
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _MainTex_ST;
            sampler2D _CameraDepthNormalsTexture;
 

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv); // get existing values

                float4 NormalDepth;
 
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), NormalDepth.w, NormalDepth.xyz); // get depth from the camera
                col.rgb = 1 - NormalDepth.w; // set color according to the depth width

                return (col * _Color);
            }
            ENDCG
        }
    }
}
