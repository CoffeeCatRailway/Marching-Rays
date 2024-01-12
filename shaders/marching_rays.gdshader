shader_type spatial;
render_mode unshaded;

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
uniform vec4 cubesIn[250];

float smoothMin(float da, float db, float bias)
{
	float h = max(bias - abs(da - db), 0.) / bias;
	return min(da, db) - h * h * h * bias * 1. / 6.;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 q = abs(p) - b;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float sdSphere(vec3 p, float r)
{
	return length(p) - r;
}

float sdEllipsoid(vec3 p, vec3 r)
{
	float k0 = length(p / r);
	float k1 = length(p / (r * r));
	return k0 * (k0 - 1.) / k1;
}

float sdOctahedron(vec3 p, float s)
{
	p = abs(p);
	return (p.x + p.y + p.z - s) * .57735027;
}

float getDist(vec3 p)
{
	float sdf = sdSphere(p - cubesIn[0].xyz, cubesIn[0].w * unitBox.x);
	if (cubesIn.length() == 1)
		return sdf;
	else
	{
		float sdfNew;
		for (int i = 1; i < cubesIn.length(); i++)
		{
			if (cubesIn[i].w <= isoLevel) // Values meeting this condition are removed before passing to shader
				continue;
			sdfNew = sdSphere(p - cubesIn[i].xyz, cubesIn[i].w * unitBox.x);
			sdf = smoothMin(sdf, sdfNew, smoothness);
		}
		return sdf;
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

float march(vec3 ro, vec3 rd)
{
	float dO = 0.;
	float dS;
	
	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 p = ro + dO * rd;
		dS = getDist(p);
		dO += dS;
		
		if (dS < SURF_DST || dO > MAX_DST)
		break;
	}
	return dO;
}

vec3 getNormal(vec3 p)
{
	vec2 e = vec2(1e-2, 0.);
	vec3 n = getDist(p) - vec3(
		getDist(p - e.xyy),
		getDist(p - e.yxy),
		getDist(p - e.yyx)
	);
	return normalize(n);
}

float saturate(float x)
{
	return max(0., min(1., x));
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

void vertex()
{
	worldCam = (inverse(MODELVIEW_MATRIX) * vec4(0., 0., 0., 1.)).xyz;
	worldPos = VERTEX;
}

void fragment()
{
	vec3 ro = worldCam;
	vec3 rd = normalize(worldPos - ro);
	vec3 col = vec3(1.);
	
	float d = march(ro, rd);
	if (d >= MAX_DST)
		discard;
	else
	{
		vec3 pointOnSurface = ro + rd * d;
		vec3 normal = getNormal(pointOnSurface);
		col = normal;
		
		if (useLighting)
		{
			vec3 lightDir = !directionalLight ? normalize(light + ro) : -light;
			float lighting = saturate(dot(normal, lightDir));
			
			// Shadow - Based on: https://github.com/SebLague/Ray-Marching/blob/master/Assets/Scripts/SDF/Raymarching.compute
			vec3 offsetPos = pointOnSurface + normal * SHADOW_BIAS;
			vec3 dirToLight = !directionalLight ? normalize(light - offsetPos) : -light;
			
			float dstToLight = !directionalLight ? distance(offsetPos, light) : MAX_DST;
			float shadow = calculateShadow(offsetPos, dirToLight, dstToLight);
			
			col *= lighting * shadow;
		}
	}
	ALBEDO = col;
}
