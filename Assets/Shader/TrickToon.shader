Shader "ToonShader/TrickToon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        
        _LightMapTex ("LightMapTex", 2D) = "white" { }
        _R ("R", 2D) = "white" { }
        _G ("G", 2D) = "white" { }
        _B ("B", 2D) = "white" { }
        [Toggle(ENABLE_SPLITMAP)] _SplitMap ("Use SplitMap", Float) = 0

		
        [Toggle(ENABLE_CAST_SHADOWS)] _CastShadow ("_CastShadow", Float) = 0
        _ShadowColor ("Shadow Color", Color) = (0.8, 0.8, 1, 1)
        
        _MainColor ("MainColor", color) = (1, 1, 1, 1)
        _FirstShadowArea ("FirstShadowArea", range(0, 1)) = 0.5
        _FirstShadowColor ("FirstShadowColor", color) = (0.5, 0.5, 0.5, 1)
        _SecondShadow ("SecondShadow", range(0, 1)) = 0.2
        _SecondShadowColor ("SecondShadowColor", color) = (0.5, 0.5, 0.5, 1)
        _Shininess ("Shininess", range(0, 10)) = 0.2
        _SpecIntensity ("SpecIntensity", range(0, 1)) = 0.7
        _LightSpecColor ("LightSpecColor", color) = (0.5, 0.5, 0.5, 1)
        
        [Toggle(ENABLE_OUTLINECOLOR)] _UseOutColor ("Use OutLineColor", Float) = 1
        _Outline ("Thick of Outline", range(0, 0.1)) = 0.03
        _Factor ("Factor", range(0, 1)) = 0.5
        _OutColor ("OutColor", color) = (0, 0, 0, 0)
        _OutGray ("OutGray", range(0, 1)) = 0.7
    }
    
    SubShader
    {
        //outline
        pass
        {
            Tags { "LightMode" = "Always" }
            Cull Front
            ZWrite On
            CGPROGRAM
            
            #pragma shader_feature ENABLE_OUTLINECOLOR
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            float _Outline;
            float _Factor;
            fixed _OutGray;
            fixed4 _OutColor;
            
            float4 _MainTex_ST;
            sampler2D _MainTex;
            
            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
            };
            
            
            v2f vert(appdata v)
            {
                v2f o;
                float3 dir = normalize(v.vertex.xyz);
                float3 dir2 = v.normal;
                float D = dot(dir, dir2);
                dir = dir * sign(D);
                dir = dir * _Factor + dir2 * (1 - _Factor);
                v.vertex.xyz += dir * _Outline;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv.xy, _MainTex);
                return o;
            }
            float4 frag(v2f i): COLOR
            {
                float4 c = _OutColor;
                
                #ifdef ENABLE_OUTLINECOLOR
                    return c;
                #else
                    
                    float4 diffuseMapColor = tex2D(_MainTex, i.uv);
                    float maxChan = max(max(diffuseMapColor.r, diffuseMapColor.g), diffuseMapColor.b);
                    float4 newMapColor = diffuseMapColor;
                    
                    maxChan -= (1.0 / 255.0);
                    float3 lerpVals = saturate((newMapColor.rgb - float3(maxChan, maxChan, maxChan)) * 255.0);
                    newMapColor.rgb = lerp(0.6 * newMapColor.rgb, newMapColor.rgb, lerpVals);
                    return float4(_OutGray * newMapColor.rgb * diffuseMapColor.rgb, diffuseMapColor.a);
                    
                #endif
            }
            ENDCG
            
        }
        
        
        Pass
        {
            Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile COLOR_DIFFUSE COLOR_R COLOR_G COLOR_B
			
            #pragma shader_feature ENABLE_CAST_SHADOWS
            #pragma shader_feature ENABLE_SPLITMAP
            
            #include "lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _R;
            sampler2D _G;
            sampler2D _B;
            
            sampler2D _LightMapTex;
            float _UsingDitherAlpha;
            float _SecondShadow;
            fixed4 _SecondShadowColor;
            fixed4 _FirstShadowColor;
            half _FirstShadowArea;
            float _Shininess;
            float _SpecIntensity;
            fixed4 _LightSpecColor;
            fixed4 _MainColor;
          
            float4 _ShadowColor;

            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float4 uv: TEXCOORD0;
                float4 color: COLOR0;
            };
            
            
            struct v2f
            {
                float4 pos: POSITION;
                float4 color: COLOR0;
                float2 uv: TEXCOORD0;
                float halfLambert: COLOR1;
                float3 normal: TEXCOORD1;
                float3 viewDir: TEXCOORD2;

				
                #ifdef ENABLE_CAST_SHADOWS
                    LIGHTING_COORDS(3, 4)
                #endif
            };
            
            
            v2f vert(appdata v)
            {
                v2f o;
                half4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv = TRANSFORM_TEX(v.uv.xy, _MainTex);
                
                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                o.normal = worldNormal;
                
                //half lambert
                float lambert = dot(worldNormal, normalize(/*fixed3(-0.52,0.77,0.38)*/_WorldSpaceLightPos0));
                lambert = lambert * 0.5 + 0.5;
                o.halfLambert = lambert;

				
                #ifdef ENABLE_CAST_SHADOWS
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                #endif
                
                
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed3 lightMapColor = tex2D(_LightMapTex, i.uv.xy).xyz;
                fixed R;
                fixed G;
                fixed B;
                #ifdef ENABLE_SPLITMAP
                    R = tex2D(_R, i.uv.xy).xyz;
                    G = tex2D(_G, i.uv.xy).xyz;
                    B = tex2D(_B, i.uv.xy).xyz;
                #else
                    R = lightMapColor.r;
                    G = lightMapColor.g;
                    B = lightMapColor.b;
                #endif
                
                float4 mainColor = tex2D(_MainTex, i.uv.xy);
                
                float vrCr = lightMapColor.g/* * i.color.r*/;
                
                //閾值，關於第二層暗面的顏色，如果lColorG = 0,就是用第二層暗面顏色，否則使用第一層暗面顏色
                float lColorG = floor((vrCr + i.halfLambert) * 0.5 + (-_SecondShadow) + 1.0);
                half3 secondShadowColor = mainColor.xyz * _SecondShadowColor.rgb;
                fixed3 firstShadowColor = mainColor.xyz * _FirstShadowColor.rgb;
                secondShadowColor.rgb = (lColorG > 0) ? firstShadowColor.rgb: secondShadowColor.rgb;
                
                //閾值，關於普通顏色與第一層暗面的閾值，如果lColorGx = 0 就是用第一層暗面，隨光的方向進行移動
                float lColorGx = floor(/*(-i.color.r) * */G + 1.5);
                float2 tempXY = vrCr.rr /** float2(1.20, 1.25) + float2(-0.10, -0.125)*/;
                vrCr = (lColorGx > 0) ? tempXY.y: tempXY.x;
                vrCr = floor((vrCr + i.halfLambert) * 0.5 + (-_FirstShadowArea) + 1.0);
                firstShadowColor.rgb = (vrCr > 0) ? mainColor.rgb: firstShadowColor.rgb;
                
                
                //閾值，關於第一層暗面與第二層暗面的閾值，如果lColorGz = 0 就使用第二層暗面，固定暗面
                float lColorGz = floor(G /** i.color.r*/ + 0.9);
                half3 color = (lColorGz > 0) ? firstShadowColor.rgb: secondShadowColor.rgb;
                
                //Specular
                float3 normal = normalize(i.normal.xyz);
                float3 viewDirection = i.viewDir;
                float3 lightDirection = normalize(/*fixed3(-0.52,0.77,0.38)*/ - _WorldSpaceLightPos0.xyz);
                float3 H = normalize(viewDirection + lightDirection);
                half spec = pow(saturate(dot(normal, H)), _Shininess);
                
                //閾值，關於高光顏色選擇，如果lColorGy = 0, 使用高光顏色，否則，無高光
                float lColorGy = floor(2 - spec - B);
                float3 specColor = R * _LightSpecColor * _SpecIntensity * spec;
                specColor = (lColorGy > 0) ? float3(0.0, 0.0, 0.0): specColor.rgb;
                color.rgb = color.rgb + specColor;
                color.rgb = color.rgb * _MainColor.rgb;

				#ifdef ENABLE_CAST_SHADOWS
                    // Cast shadows
                    half3 shadowColor = _ShadowColor.rgb * color;
                    half3 sss = color;
                    half attenuation = saturate(2.0 * LIGHT_ATTENUATION(i) - 1.0);
                    color = lerp(shadowColor, sss, attenuation);
                #endif
                
                #ifdef COLOR_DIFFUSE
                    fixed4 col;
                    col.rgb = color.rgb;
                    col.a = 1;
                    return col;
                #endif
                
                #ifdef COLOR_R
                    return fixed4(R, R, R, 1);
                #elif COLOR_G
                    return fixed4(G, G, G, 1);
                #elif COLOR_B
                    return fixed4(B, B, B, 1);
                #endif
            }
            ENDCG
            
        }

    }
	FallBack "Diffuse"
}