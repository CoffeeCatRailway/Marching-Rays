shader_type canvas_item;
// https://cgmathprog.home.blog/2019/08/31/raymarching-from-scratch-part-1/

uniform float fov = 45.;
uniform vec3 cameraPos = vec3(0., 0., 5.);
uniform vec3 front = vec3(0., 0., -1.);
uniform vec3 up = vec3(0., 1., 0.);

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
	vec3 adjustedRayDir = (rayDir + 1.) / 2.;
	// show direction on screen as a color
	COLOR = vec4(adjustedRayDir, 1.);
}
