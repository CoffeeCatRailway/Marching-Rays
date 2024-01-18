// Most of these are from:
// https://iquilezles.org/articles/distfunctions/

// Transformation
vec3 rotateX(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	mat3 m = mat3(
		vec3(1., 0., 0.),
		vec3(0., c, -s),
		vec3(0., s, c)
	);
	return m * p;
}

vec3 rotateY(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	mat3 m = mat3(
		vec3(c, 0., s),
		vec3(0., 1., 0.),
		vec3(-s, 0., c)
	);
	return m * p;
}

vec3 rotateZ(vec3 p, float a)
{
	float s = sin(a);
	float c = cos(a);
	mat3 m = mat3(
		vec3(c, -s, 0.),
		vec3(s, c, 0.),
		vec3(0., 0., 1.)
	);
	return m * p;
}

vec3 twistX(vec3 p, float k)
{
	float s = sin(k * p.x);
	float c = cos(k * p.x);
	mat2 m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m * p.yz, p.x);
}

vec3 twistY(vec3 p, float k)
{
	float s = sin(k * p.y);
	float c = cos(k * p.y);
	mat2 m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m * p.xz, p.y);
}

vec3 twistZ(vec3 p, float k)
{
	float s = sin(k * p.z);
	float c = cos(k * p.z);
	mat2 m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m * p.xy, p.z);
}

vec3 bendCheap(vec3 p, float k)
{
	float s = sin(k * p.x);
	float c = cos(k * p.x);
	mat2 m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m * p.xy, p.z);
}

// Smooth/boolean functions
float opUnion(float d1, float d2)
{
	return min(d1, d2);
}

float opSubtraction(float d1, float d2)
{
	return max(-d1, d2);
}

float opIntersection(float d1, float d2)
{
	return max(d1, d2);
}

float opXor(float d1, float d2)
{
	return max(min(d1, d2), -max(d1, d2));
}

float opSmoothUnion(float d1, float d2, float k)
{
	float h = clamp(.5 + .5 * (d2 - d1) / k, 0., 1.);
	return mix(d2, d1, h) - k * h * (1. - h);
}

float opSmoothSubtraction(float d1, float d2, float k)
{
	float h = clamp(.5 - .5 * (d2 + d1) / k, 0., 1.);
	return mix(d2, -d1, h) + k * h * (1. - h);
}

float opSmoothIntersection(float d1, float d2, float k)
{
	float h = clamp(.5 - .5 * (d2 - d1) / k, 0., 1.);
	return mix(d2, d1, h) + k * h * (1. - h);
}

float smoothMin(float da, float db, float bias) // Sebastion Lague ray marching video
{
	float h = max(bias - abs(da - db), 0.) / bias;
	return min(da, db) - h * h * h * bias * 1. / 6.;
}

// SDF
float sdPlane(vec3 p, vec3 n, float h) // n is the 'up' of the plane
{
	return dot(p, normalize(n)) + h;
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