shader_type spatial;
render_mode unshaded;

#include "sdf_includes.gdshaderinc"

varying vec3 worldCam;
varying vec3 worldPos;

const int MAX_STEPS = 100;
const float MAX_DST = 100.;
const float SURF_DST = 1e-3;
const float SHADOW_BIAS = SURF_DST * 50.;

uniform vec3 light = vec3(10., 5., 10.);
uniform bool directionalLight = false;
uniform bool useLighting = true;

uniform float smoothness : hint_range(.001, 1., .01) = 1.;

// Uniforms passed in through scirpt
uniform float isoLevel : hint_range(0., 1., .01) = .5;
uniform vec3 unitBox = vec3(.25);
uniform vec4 cubesIn[512];

float sdf(vec3 p)
{
	float o = sdSphere(p - cubesIn[0].xyz, cubesIn[0].w * unitBox.x);
	if (cubesIn.length() == 1)
		return o;
	else
	{
		float sdfNew;
		for (int i = 1; i < cubesIn.length(); i++)
		{
			if (cubesIn[i].w <= isoLevel) // Values meeting this condition are removed before passing to shader
				continue;
			sdfNew = sdSphere(p - cubesIn[i].xyz, cubesIn[i].w * unitBox.x);
			o = opSmoothUnion(o, sdfNew, smoothness);
		}
		return o;
	}
	
	//float unit = unitBox.x * 2.;
	//float[] cubes = {
	//	sdBox(p, unitBox),
	//	sdBox(p - vec3(unit, 0., 0.), unitBox),
	//	sdBox(p - vec3(0., 0., unit), unitBox),
	//	sdBox(p - vec3(0., unit, 0.), unitBox)
	//};
	
	//float o = cubes[0];
	//if (cubes.length() == 1)
	//	return o;
	//for (int i = 1; i < cubes.length(); i++)
	//	o = smoothMin(o, cubes[i], smoothness);
	//return o;
}

vec3 estimateNormal(vec3 p)
{
	vec2 e = vec2(SURF_DST, 0.);
	vec3 n = sdf(p) - vec3(
		sdf(p - e.xyy),
		sdf(p - e.yxy),
		sdf(p - e.yyx)
	);
	return normalize(n);
}

float calculateShadow(in vec3 ro, vec3 rd, float dstToLight)
{
	float rayDst = 0.;
	float shadowIntensity = .2;
	float brightness = 1.;
	while (rayDst < dstToLight)
	{
		float dst = 1.;//march(ro, rd);
		if (dst < SURF_DST)
			return shadowIntensity;
		brightness = min(brightness, dst * 200.);
		ro += rd * dst;
		rayDst += dst;
	}
	return shadowIntensity + (1. - shadowIntensity) * brightness;
}

// Shadow - Based on: https://github.com/SebLague/Ray-Marching/blob/master/Assets/Scripts/SDF/Raymarching.compute
vec3 calculateLightingLague(vec3 p, vec3 ro, vec3 baseColor)
{
	vec3 normal = estimateNormal(p);
	vec3 lightDir = normalize(light + ro);
	float lighting = (dot(normal, lightDir) + 1.) / 2.;
	
	//vec3 offset = p + normal * SHADOW_BIAS;
	//vec3 toLight = normalize(light - offset);
	
	//float dstToLight = distance(offset, light);
	//float shadow = calculateShadow(offset, toLight, dstToLight);
	return baseColor * lighting;// * shadow;
}

vec3 blinnPhong(vec3 p, vec3 ro, vec3 lp, vec3 ambient, vec3 diffuse)
{
	const float ambientCoeff = .1;
	const float diffuseCoeff = 1.;
	const float specularCoeff = 1.;
	const float specularExponent = 64.;
	const bool specularHighlights = false;
	
	vec3 normal = estimateNormal(p);
	vec3 toEye = normalize(ro - p);
	vec3 toLight = normalize(lp - p);
	vec3 halfwayDir = normalize(toLight + toEye);
	
	vec3 ambientFactor = ambient * ambientCoeff;
	vec3 diffuseFactor = diffuse * max(0., dot(normal, toLight)) * diffuseCoeff;
	vec3 specularFactor = diffuse * pow(max(0., dot(normal, halfwayDir)), specularExponent) * specularCoeff;
	
	vec3 res = ambientFactor + diffuseFactor;
	if (specularHighlights)
		res += specularFactor;
	return res;
}

vec4 rayMarch(vec3 ro, vec3 rd)
{
	vec3 hitColor = vec3(1.);
	vec3 missColor = vec3(0.);
	
	float depth = 0.;
	for (int i = 0; depth < MAX_DST && i < MAX_STEPS; i++)
	{
		vec3 p = ro + rd * depth;
		float dst = sdf(p);
		depth += dst;
		
		if (abs(dst) <= SURF_DST)
		{
			if (useLighting)
			{
				return vec4(calculateLightingLague(p, ro, estimateNormal(p)), 1.);
				//return vec4(blinnPhong(p, ro, light, vec3(1.), estimateNormal(p)), 1.);
			} else
				return vec4(hitColor, 1.);
			//return vec4(hitColor, depth / MAX_DST);
		}
	}
	return vec4(missColor, 0.);
	//return vec4(missColor, depth / MAX_DST);
}

void vertex()
{
	worldCam = (inverse(MODELVIEW_MATRIX) * vec4(0., 0., 0., 1.)).xyz;
	worldPos = VERTEX;
}

void fragment()
{
	vec3 ro = worldCam;
	vec3 rd = normalize(worldPos - ro);
	
	vec4 marchColor = rayMarch(ro, rd);
	ALBEDO = marchColor.xyz;
	ALPHA = marchColor.w;
	//DEPTH = marchColor.w;
}
