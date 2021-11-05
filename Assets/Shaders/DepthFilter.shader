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
                   if(persistentCol.b < 0) persistentCol.r = 0;
                }

                newColors.r = max(persistentCol.r, newColors.r);
             
                return newColors;

            }
            ENDCG
        }
        Pass {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

             float4 _MainTex_ST;
             sampler2D _MainTex;

            float4 _MainTex_TexelSize;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            bool redPixelFound(float redColor, v2f i) {
                fixed2 texSize = _MainTex_TexelSize.xy;
                float _size = 4;
                float2 uv = i.uv;
                if(redColor == 0)  {
                    for (int i = -_size; i <= _size; ++i) {
                        for (int j = -_size; j <= _size; ++j) {
                            if(tex2Dlod(_MainTex, float4(uv.x + ((float)i * texSize.x), uv.y + ((float)j * texSize.y), 0, 0)).r > 0)
                                return true;      
                        }
                    }
                }
                return false;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed4 persistentCol = tex2D(_MainTex, i.uv);
                
               
                persistentCol.b = redPixelFound(persistentCol.r, i) ? 1 : 0;
              
                
                return persistentCol;
            }

         

            ENDCG

        }

        /*Pass
        {
            Cull Front
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            fixed4 _OutlineColor = (1,1,1,1);
            float _OutlineSize = 10;
            struct appdata

            {
                float4 vertex:POSITION;
            };
            struct v2f
            {
                float4 clipPos:SV_POSITION;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos=UnityObjectToClipPos(v.vertex*_OutlineSize);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }*/

    }
}
