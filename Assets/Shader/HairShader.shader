Shader "Unlit/HairRender"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1,1,1)
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
            half3 _MainColor;
            half3 _ShadowColor;
            half _ShadowRange;
            half _ShadowSmooth;
            half3 _SpecularColor;
            half _SpecularRange;
            half _SpecularMulti;
            half _SpecularGloss;
            float4 _RimColor;
            half  _RimRange;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            { 
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };


            v2f vert(a2v v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);//将顶点就行缩放和平移确保和材质里的uv坐标对应
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//法线一起转换到世界坐标系
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;//将模型顶点坐标转换到世界坐标系
                o.pos = UnityObjectToClipPos(v.vertex);//转换到裁剪空间
                return o;
            }
        

            half4 frag(v2f i) : SV_TARGET
       {
                half4 col = 1;
                half4 mainTex = tex2D(_MainTex, i.uv);//解uv贴纹理
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);//视野方向，因为只取方向，所以要归一化
                half3 worldNormal = normalize(i.worldNormal);
                half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);


     
                half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
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
                fixed3 refDir = normalize(reflect(-_WorldSpaceLightPos0.xyz, worldNormal));
                half3 specular = _SpecularColor.rgb * pow(max(0, dot(viewDir, refDir)), _SpecularGloss);

                //边缘光计算
                half f = 1.0 - saturate(dot(viewDir, worldNormal));
                fixed3 rimColor = f* _RimColor.rgb*_RimColor.a;
                col.rgb = (diffuse + rimColor* _RimRange) * _LightColor0.rgb;


             
                //光源颜色*漫反射
                return col;
            }
            ENDCG
        }

       /* Pass
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
        }*/
    }
}