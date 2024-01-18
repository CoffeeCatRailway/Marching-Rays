shader_type canvas_item;
// https://cgmathprog.home.blog/2019/08/31/raymarching-from-scratch-part-1/

#include "sdf_includes.gdshaderinc"

const int MAX_STEPS = 250;
const float MAX_DST = 20.;
const float SURF_DST = .00001;
const float DERIVATIVE_STEP = 0.0001;

uniform bool specularHighlights = false;
uniform bool showNormals = false;

uniform float fov = 45.;
uniform vec3 cameraPos = vec3(0., 0., 0.);
uniform vec3 front = vec3(1., 0., 0.);
uniform vec3 up = vec3(0., 1., 0.);

uniform float ambientCoeff = .1;
uniform float diffuseCoeff = 1.;
uniform float specularCoeff = 1.;
uniform float specularExponent = 64.;
uniform vec3 lightPos = vec3(-2., 5., 3.);

uniform vec3 ambientColor : source_color = vec3(1., 1., 1.);
uniform vec3 missColor : source_color = vec3(0., 0., 0.);

float sdf(vec3 p)
{
	float s1_5 = sin(TIME * 1.5);
	float c1_5 = cos(TIME * 1.5);
	float c1_75 = cos(TIME * 1.75);
	float rad45 = radians(90. * c1_5);
	
	float octahedron = sdOctahedron(twistY(p - vec3(0., 0., 1. + s1_5), c1_75 * 2.), 1.);
	vec3 sdfp = p - vec3(0., 0., -1. - s1_5);
	//sdfp = rotateY(rotateX(sdfp, rad45), rad45);
	float box = sdBox(sdfp, vec3(.5));
	float sphere = sdEllipsoid(sdfp, vec3(.5, .75, .5));
	box = mix(box, sphere, (c1_5 + 1.) / 2.);
	
	float op = opSmoothUnion(octahedron, box, .75);
	//op = opIntersection(-octahedron, box);
	
	//float box1 = sdBox(bendCheap(p + vec3(0., 1.5, 0.), rad45), vec3(.5, .25, 2.));
	//op = opUnion(op, box1);
	
	return opUnion(op, sdPlane(p, vec3(0., 1., 0.), 2.));
}

vec3 estimateNormal(vec3 p)
{
	return normalize(vec3(
		sdf(vec3(p.x + DERIVATIVE_STEP, p.y, p.z)) - sdf(vec3(p.x - DERIVATIVE_STEP, p.y, p.z)),
		sdf(vec3(p.x, p.y + DERIVATIVE_STEP, p.z)) - sdf(vec3(p.x, p.y - DERIVATIVE_STEP, p.z)),
		sdf(vec3(p.x, p.y, p.z + DERIVATIVE_STEP)) - sdf(vec3(p.x, p.y, p.z - DERIVATIVE_STEP))
	));
}

vec3 blinnPhong(vec3 p, vec3 lp, vec3 ambient, vec3 diffuse)
{
	vec3 normal = estimateNormal(p);
	vec3 toEye = normalize(cameraPos - p);
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

vec3 rayMarch(vec3 rd)
{
	//vec3 ambientColor = vec3(1., 1., 1.);
	vec3 hitColor = vec3(1., 1., 1.);
	//vec3 missColor = vec3(0., 0., 0.);
	
	float depth = 0.;
	for (int i = 0; depth < MAX_DST && i < MAX_STEPS; i++)
	{
		vec3 p = cameraPos + rd * depth;
		float dst = sdf(p);
		depth += dst;
		
		if (abs(dst) <= SURF_DST)
		{
			if (showNormals)
				return estimateNormal(p);
			else
				return blinnPhong(p, lightPos, ambientColor, hitColor);
		}
	}
	
	return missColor;
	//return vec3(depth / MAX_DST);
}

vec3 getRayDirection(vec2 resolution, vec2 uv)
{
	float aspect = resolution.x / resolution.y;
	float fov2 = radians(fov) / 2.;
	
	// convert coordinates from [0, 1] to [-1, 1] and invert y axis to flow from bottom to top
	vec2 screenCoord = (uv - .5) * 2.;
	screenCoord.x *= aspect;
	screenCoord.y = -screenCoord.y;
	
	// contibutions of the up and right vectors
	vec2 offsets = screenCoord * tan(fov2);
	
	// compute 3 orthogonal unit vectors
	vec3 rayFront = normalize(front);
	vec3 rayRight = cross(rayFront, normalize(up));
	vec3 rayUp = cross(rayRight, rayFront);
	vec3 rayDir = rayFront + rayRight * offsets.x + rayUp * offsets.y;
	return normalize(rayDir);
}

void fragment() {
	vec2 resolution = 1. / SCREEN_PIXEL_SIZE;
	
	vec3 rayDir = getRayDirection(resolution, UV);
	
	// convert ray coordinates from [-1, 1] range to the [0, 1]
	//vec3 adjustedRayDir = (rayDir + 1.) / 2.;
	// show direction on screen as a color
	//COLOR = vec4(adjustedRayDir, 1.);
	
	vec3 rayMarchColor = rayMarch(rayDir);
	COLOR = vec4(rayMarchColor, 1.);
}











