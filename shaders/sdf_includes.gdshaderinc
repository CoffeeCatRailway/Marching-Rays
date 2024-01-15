// Smooth/boolean functions
float smoothMin(float da, float db, float bias)
{
	float h = max(bias - abs(da - db), 0.) / bias;
	return min(da, db) - h * h * h * bias * 1. / 6.;
}

// SDF
float sdPlane(vec3 p, vec3 n, float h)
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