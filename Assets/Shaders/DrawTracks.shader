Shader "Unlit/DrawTracks"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Coordinate ("Coordinate", vector) = (0,0,0,0)
        _Color("Draw Color", Color) = (1,0,0,0)
        _SecondColor("Draw Color", Color) = (0, 1, 0, 0)
        _Size("Size", Range(1, 500)) = 1
        _Strength("Strength", Range(0,1)) = 1
        _SecondStrength("Second Strength", Range(0,1)) = 1
        _HillOffset("HillOffset", Range(1, 500)) = 1
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
            float4 _MainTex_ST;
            fixed4 _Coordinate, _Color, _SecondColor;
            half _Size, _Strength, _SecondStrength, _HillOffset;

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
                float draw2 = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), (500 / (_Size + _HillOffset)));
                float draw = pow(saturate(1 - distance(i.uv, _Coordinate.xy)), (500 / _Size));
                fixed4 drawCol = _Color * (draw * _Strength);
                fixed4 drawCol2 =  _SecondColor * (draw2 * _SecondStrength);
                return saturate(col + drawCol2 + drawCol);
            }
            ENDCG
        }
    }
}
