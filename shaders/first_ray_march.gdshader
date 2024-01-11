shader_type spatial;
render_mode unshaded;

varying vec3 worldCam;
varying vec3 worldPos;

const int MAX_STEPS = 100;
const float MAX_DST = 100.;
const float SURF_DST = 1e-3;

uniform float smoothness : hint_range(.01, 1., .01) = 1.;

float atan2Approx(float y, float x)
{
    //http://pubs.opengroup.org/onlinepubs/009695399/functions/atan2.html
    //Volkan SALMA

    float ONEQTR_PI = PI / 4.0;
	float THRQTR_PI = 3.0 * PI / 4.0;
	float r, angle;
	float abs_y = abs(y) + 1e-10f;      // kludge to prevent 0/0 condition
	if ( x < 0.0f )
	{
		r = (x + abs_y) / (abs_y - x);
		angle = THRQTR_PI;
	}
	else
	{
		r = (x - abs_y) / (x + abs_y);
		angle = ONEQTR_PI;
	}
	angle += (0.1963f * r * r - 0.9817f) * r;
	if ( y < 0.0f )
		return( -angle );     // negate if in quad III or IV
	else
		return( angle );
}

float mandelbulb(vec3 p)
{
	vec3 z = p;
	float dr = 1.;
	float r;
	
	for (int i = 0; i < 15; i++)
	{
		r = length(z);
		if (r > 2.)
			break;
		
		float theta = acos(z.z / r) * smoothness;
		float phi = atan2Approx(z.y, z.x) * smoothness;
		float zr = pow(r, smoothness);
		dr = pow(r, smoothness - 1.) * smoothness * dr + 1.;
		
		z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z += p;
	}
	return .5 * log(r) * r / dr;
}

float smoothMin(float da, float db, float bias)
{
	float h = max(bias - abs(da - db), 0.) / bias;
	return min(da, db) - h * h * h * bias * 1. / 6.;
}

float getDist(vec3 p)
{
	float sphere = length(p) - .5; // Sphere
	//p.y += sin(TIME * 2.) * 1.;
	float torus = length(vec2(length(p.xz) - .5, p.y)) - .1; // Torus
	//return max(sphere, -torus);
	return smoothMin(sphere, torus, smoothness);
	//return mandelbulb(p);
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

void vertex()
{
	worldCam = (inverse(MODELVIEW_MATRIX) * vec4(0., 0., 0., 1.)).xyz;
	worldPos = VERTEX;
}

void fragment()
{
	vec3 ro = worldCam;
	vec3 rd = normalize(worldPos - ro);
	vec3 col;
	
	float d = march(ro, rd);
	if (d >= MAX_DST)
		discard;
	else
	{
		vec3 p = ro + rd * d;
		vec3 n = getNormal(p);
		//col = vec3(1., 0., 0.) * n.rgb;
		col = n.rgb;
	}
	ALBEDO = col;
}
