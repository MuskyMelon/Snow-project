Shader "Unlit/ImagePersistence"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
            #pragma multi_compile_fog

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
       
                fixed4 persistentCol = tex2D(_ExistingTexture, i.uv);

                fixed4 mainCol = tex2D(_MainTex, i.uv);

                fixed4 col = fixed4(persistentCol.r + mainCol.r, 0, 0, 0);  
                
 
                return col;

            }
            ENDCG
        }
    }
}
