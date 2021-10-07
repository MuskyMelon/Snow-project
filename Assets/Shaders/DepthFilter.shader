Shader "Unlit/DepthFilter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Draw Color", Color) = (1,0,0,0)
        _ExistingTexture ("Texture", 2D) = "white" {}
    }
    SubShader
    {
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
            sampler2D _ExistingTexture;
            float4 _MainTex_ST;
            float4 _ExistingTexture_ST;
            fixed4 _Color;
            sampler2D _CameraDepthNormalsTexture;
            float snowIncrease;
            int isRegening = 0;
            float colorRed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 persistentCol = tex2D(_ExistingTexture, i.uv);

                fixed4 NormalDepth;
 
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), NormalDepth.w, NormalDepth.xyz);
                col.rgb = 1 - NormalDepth.w;

                fixed4 newColors = (col * _Color);
                if(persistentCol.r > 0 && isRegening) {
                   persistentCol.r -= snowIncrease;
                   if(persistentCol.r < 0) persistentCol.r = 0;
                }

                colorRed = persistentCol.r;

                newColors.r = max(persistentCol, newColors.r);
             
                return newColors;

            }
            ENDCG
        }
    }
}
