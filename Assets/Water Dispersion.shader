	Shader "Unlit/Water Dispersion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D iChannel0;
			int iFrame;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

			float4 getTexture(sampler2D sam, float2 g, float2 p, float2 s)
			{
				float2 gp = g + p;

				if (gp.x >= s.x) gp.x = gp.x - s.x;
				if (gp.y >= s.y) gp.y = gp.y - s.y;
				if (gp.x < 0.0) gp.x = s.x + gp.x;
				if (gp.y < 0.0) gp.y = s.y + gp.y;

				return tex2D(sam, gp / s);
			}

			float4 getState(sampler2D sam, float2 g, float2 s, float n)
			{
				float4 p = float4(0, 0, 0, 0);
				for (float i = 0.; i < n; i++)
				{
					p = getTexture(sam, g, -p.xy, s);
				}
				return p;
			}

			#define tex(p) getTexture(iChannel0, g, p, s)
			#define emit(v,k) if (length(g-(s * (0.5 + v))) < 5.) f.x = k, f.w = 1.

			#define frameStep 10000.

            fixed4 frag (v2f i) : SV_Target
            {
				/*
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
				*/
				//float frame = float(iFrame);
				//frame = mod(frame, frameStep);
				float2 g = i.uv * _ScreenParams.xy;

				float2 s = _ScreenParams.xy;

				float4 r = tex(float2(1, 0));
				float4 t = tex(float2(0, 1));
				float4 l = tex(float2(-1, 0));
				float4 b = tex(float2(0, -1));

				float2 v = g / s;

				// pifometre :)
				float2 c = sin(v * 6.28318)*.5 + .5;
				float cc = c.x + c.y;

				float4 f = getState(iChannel0, g, s, cc * 2. + 1.);

				f.xy += float2(r.z - l.z, t.z - b.z);

				float4 dp = (r + t + l + b) / 4.;
				float div = ((l - r).x + (b - t).y) / 20.;

				f.z = dp.z - div;

				emit(float2(-0.45, 0.), 50.0);
				emit(float2(0.45, 0.), -50.0);

				return f;
            }
            ENDCG
        }
		GrabPass{"iChannel0"}
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
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D iChannel0;
			int iFrame;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 q = i.uv;
				float3 e = float3(float2(1., 1.) / _ScreenParams.xy, 0.);
				float f = 10.0;
				float p10 = tex2D(iChannel0, q - e.zy).z;
				float p01 = tex2D(iChannel0, q - e.xz).z;
				float p21 = tex2D(iChannel0, q + e.xz).z;
				float p12 = tex2D(iChannel0, q + e.zy).z;

				float4 w = tex2D(iChannel0, q);
				

				float3 grad = normalize(float3(p21 - p01, p12 - p10, 0.5));
				//float2 uv = fragCoord.xy*2. / iChannelResolution[1].xy + grad.xy*.35;
				float2 uv = ((i.uv *_ScreenParams.xy)*1.) / (_ScreenParams.xy + grad.xy*.35);
				//uv = uv * 0.5;
				float4 c = tex2D(_MainTex, uv);
				//float2 white = (0.7, 0.7);
				//float4 c = (white.x, white.y, white.x, white.y);
				c *= 1.1;
				c += c * 0.5;
				c += c * w * (0.5 - distance(q, float2(0.5, 0.5)));
				//float3 lightDir = float3(0.2, -0.5, 0.7);
				float3 lightDir = float3(1.0, 1.0, 1.0);
				float3 light = normalize(lightDir);

				float diffuse = dot(grad, light);
				float spec = pow(max(0., -reflect(light, grad).z), 32.);
				//return lerp(c, float4(.7, .8, 1., 1.), .25)*max(diffuse, 0.) + spec;
				return c*max(diffuse, 0.) + spec;

				//return f;
			}
		ENDCG
		}
    }
}
