Shader "Unlit/CelRenderOfBumpFinal"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1,1,1)
        _BumpMap("Normal Map",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
            [Space(20)]
        _ShadowColor("Shadow Color", Color) = (0.7, 0.7, 0.8)
        _ShadowRange("Shadow Range", Range(0, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.2
         
         [Space(20)]
        _SpecularColor("Specular Color", Color) = (1,1,1)
        _SpecularRange("Specular Range",  Range(0, 1)) = 0.9
        _SpecularMulti("Specular Multi", Range(0, 1)) = 0.4
        _SpecularGloss("Sprecular Gloss", Range(0.001, 255)) = 4

        [Space(20)]
        _OutlineWidth("Outline Width", Range(0.01, 2)) = 0.24
        _OutLineColor("OutLine Color", Color) = (0.5,0.5,0.5,1)
         [Space(20)]
        _RimColor("Rim Color",Color) = (255,255,255,0)
        _RimRange("Rim Range",Range(0,1)) = 0.5
        _RimBloomMulti("RimBloomMulti",Range(0,100))=0.5
        _RimBloomExp("RimBloomExp",Range(0,100)) = 0.5
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        pass
        {
           Tags {"LightMode" = "ForwardBase"}

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            half3 _MainColor;
            half3 _ShadowColor;
            half _ShadowRange;
            half _ShadowSmooth;
            half3 _SpecularColor;
            half _SpecularRange;
            half _SpecularMulti;
            half _SpecularGloss;
            float4 _RimColor;
            half _RimRange;
            half _RimBloomMulti;
            half _RimBloomExp;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;//存放主纹理贴图和法线贴图的uv坐标
                //因为贴图是一样的，只是颜色不同
                //所以只用一个float2就可以存储完，即可以共用
                float4 tangent:TANGENT;//模型的切线信息
            };

            struct v2f
            { 
                float4 pos : SV_POSITION;//裁剪空间下的顶点坐标
                float4 uv : TEXCOORD1;//xy分量存储纹理贴图坐标,zw贴图存储法线贴图坐标
                float4 T2W0:TEXCOORD2;
                float4 T2W1:TEXCOORD3;
                float4 T2W2:TEXCOORD4;
            };


            v2f vert(a2v v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);//转换到裁剪空间
                o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
               
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//将模型顶点坐标转换到世界坐标系
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.T2W0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.T2W0 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.T2W0 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
               
                return o;
            }
        

            half4 frag(v2f i) : SV_TARGET
            { 
                float3 worldPos = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);
                half4 col = 1;
                half4 mainTex = tex2D(_MainTex, i.uv);//解uv贴纹理
                half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));//视野方向，因为只取方向，所以要归一化
               // half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                //float3 worldNormal =normalize( float3(i.T2W0.z, i.T2W1.z, i.T2W2.z));
                half3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                float3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//解开uv，bump就是经过加上法线贴图运算后重新得到的法线
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                bump = normalize(float3 (dot(i.T2W0.xyz, bump), dot(i.T2W1.xyz, bump), dot(i.T2W2.xyz, bump)));
               
              



     
                half halfLambert = dot(bump, worldLightDir) * 0.5 + 0.5;
               // half3 diffuse = halfLambert > _ShadowRange ? _MainColor : _ShadowColor; 
                //上面的用来计算漫反射的是一个二分判断，如果说大于我们设定的一个值，那么就当作受光面渲染，反之则是阴影面
                half ramp = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowRange);
                //smootstep函数用于生成在定义域[0,_ShadowSmooth]上的一个值域为[0,1]的单调的连续函数，halfLambert - _ShadowRange为自变量
                half3 diffuse = lerp(_ShadowColor, _MainColor, ramp);
                //lerp函数用于将_ShadowColor, _MainColor进行插值，其比重为ramp
                diffuse *= mainTex.rgb;
                //颜色=环境光+漫反射

                //高光计算
                
                //获得反射的光源方向
                fixed3 refDir = normalize(reflect(-_WorldSpaceLightPos0.xyz, bump));
                half3 specular = _SpecularColor.rgb * pow(max(0, dot(viewDir, refDir)), _SpecularGloss);

                //边缘光计算
                half f = 1.0 - saturate(dot(viewDir, bump));
                //saturate函数可以将dot的结果规范到[0,1];
                fixed3 rimColor = f* _RimColor.rgb*_RimColor.a;

                //后处理Bloom效果
                half NdotL = max(0, dot(bump, worldLightDir));
                half rimBloom = pow(f, _RimBloomExp) * _RimBloomMulti * NdotL;

                col.rgb = (diffuse + specular+rimColor*_RimRange+rimBloom) * _LightColor0.rgb;


             
                //光源颜色*漫反射
                return col;
            }
            ENDCG
        }

        Pass
    {
           Tags {"LightMode" = "ForwardBase"}

            Cull Front//剔除前面

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            half _OutlineWidth;
            half4 _OutLineColor;

             struct a2v
             {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 vertColor : COLOR;//顶点颜色
                float4 tangent : TANGENT;
             };

            struct v2f
       {
                float4 pos : SV_POSITION;
                float3 vertColor:COLOR;
            };


            v2f vert(a2v v)
          {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * _OutlineWidth * 0.1 ,1));   //顶点沿着法线方向外扩
                o.vertColor = v.vertColor.rgb;//访问顶点的rgb
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                return fixed4(_OutLineColor * i.vertColor,0);//返回

            //return _OutLineColor;
            }
          ENDCG
        }
    }
}