// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "sidefx/vertex_rigid_body_shader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_pivotMax("Pivot Max", Float) = 1.0
		_pivotMin("Pivot Min", Float) = 1.0
		_positionMax("Position Max", Float) = 1.0
		_positionMin("Position Min", Float) = 1.0
		_numOfFrames("Number Of Frames", int) = 240
		_speed("Speed", Float) = 0.33
		_timeoffset("Time Offset", Range(0,1)) = 0.0
		_posTex ("Position Map (RGB)", 2D) = "white" {}
		_rotTex ("Rotation Map (RGB)", 2D) = "grey" {}

		_CurrentTime("_CurrentTime", Range(0,1)) = 0
		_CrackFix_LerpPercent("_CrackFix_LerpPercent", Range(0,1)) = 0.1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#pragma fragmentoption ARB_precision_hint_nicest

		sampler2D _MainTex;
		sampler2D _posTex;
		sampler2D _rotTex;
		uniform float _pivotMax;
		uniform float _pivotMin;
		uniform float _positionMax;
		uniform float _positionMin;
		uniform int _numOfFrames;
		uniform float _speed;
		uniform float _timeoffset;
		uniform float _CurrentTime;
		uniform float _CrackFix_LerpPercent;

		struct Input {
			float2 uv_MainTex;
			float4 color: COLOR;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float2 VAT_uvPosition(float2 uvIndex, int numOfFrames, float speed, float time, float2 paddedRatio)
		{
			float2 uvPosition;
			float FPS = 24.0;
			float FPS_div_Frames = FPS / numOfFrames;
			float timeInFrames = frac(speed * time);

			timeInFrames = ceil(timeInFrames * numOfFrames);
			timeInFrames /= numOfFrames;
			timeInFrames += (1 / numOfFrames);

			uvPosition.x = uvIndex.x * paddedRatio.x;
			uvPosition.y = (1 - (timeInFrames * paddedRatio.y)) + (1 - ((1 - uvIndex.y) * paddedRatio.y));

			return uvPosition;
		}
		 
		//vertex function
		void vert(inout appdata_full v){
			//calculate uv coordinates
			//!!!
			float2 uvPosition = VAT_uvPosition(v.texcoord1, _numOfFrames, _speed, _CurrentTime, 1);

			//###float timeInFrames = ((ceil(frac(_CurrentTime * _speed) * _numOfFrames))/_numOfFrames);// + (1.0/_numOfFrames);
			
			//get position and rotation(quaternion) from textures
			float4 texturePos = tex2Dlod(_posTex, float4(uvPosition, 0, 0));
			float4 textureRot = tex2Dlod(_rotTex, float4(uvPosition, 0, 0));// rotationMap.SampleLevel(common_point_repeat_sampler, uvPosition, 0);
			//##float3 texturePos = tex2Dlod(_posTex,float4(v.texcoord1.x, (1 - timeInFrames) + v.texcoord1.y, 0, 0));
			//##float4 textureRot = tex2Dlod(_rotTex,float4(v.texcoord1.x, (1 - timeInFrames) + v.texcoord1.y, 0, 0));
			//comment out the 2 lines below if your colour space is set to linear
			//texturePos.xyz = pow(texturePos.xyz, 2.2);
			//textureRot.xyz = pow(textureRot.xyz, 2.2);

			//expand normalised position texture values to world space
			texturePos.xyz = lerp(_positionMin, _positionMax, texturePos.xyz);
			//##float expand1 = _positionMax - _positionMin;
			//##texturePos.xyz *= expand1;
			//##texturePos.xyz += _boundingMin1;
			//##// texturePos.x *= -1;  //flipped to account for right-handedness of unity
			//##texturePos = texturePos.xyz;  //swizzle y and z because textures are exported with z-up

			//expand normalised pivot vertex colour values to world space
			//##float expand = _pivotMax - _pivotMin;
			float3 pivot = lerp(_pivotMin, _pivotMax, v.color.rgb);
			//##float3 pivot = v.color.rgb;
			//##pivot.xyz *= expand;
			//##pivot.xyz += _boundingMin;
			// pivot.x *=  -1;
			// pivot = pivot.xzy;
			float3 atOrigin = v.vertex.xyz - pivot;

			//calculate rotation
			// textureRot = textureRot.gbra;
			textureRot *= 2.0;
			textureRot -= 1.0;
			// textureRot = floor(textureRot * 1000)/1000;
			float4 quat = 0;

			//swizzle and flip quaternion from ue4 to unity
			// quat.xyz = -textureRot.xzy;
			// quat.w = textureRot.w;
			// quat.yz = -quat.yz;
			// quat.x = -textureRot.x;
			// quat.y = textureRot.z;
			// quat.z = textureRot.y;
			// quat.w = textureRot.w;
			// quat = float4(0,0,0,1);
			quat = textureRot;

			float3 rotated = atOrigin + 2.0 * cross(quat.xyz, cross(quat.xyz, atOrigin) + quat.w * atOrigin);

			float3 restPos = v.vertex.xyz;
			v.vertex.xyz = rotated;
			//##v.vertex.xyz += pivot;
			v.vertex.xyz += texturePos.xyz;
			//!!! xc add
			v.vertex.xyz = lerp(restPos, v.vertex.xyz, saturate(1.0f/ (0.00001+_CrackFix_LerpPercent) *_CurrentTime));

			//calculate normal
			float3 rotatedNormal = v.normal + 2.0 * cross(quat.xyz, cross(quat.xyz, v.normal) + quat.w * v.normal);
			v.normal = rotatedNormal;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
