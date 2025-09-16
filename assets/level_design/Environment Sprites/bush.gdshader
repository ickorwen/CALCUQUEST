shader_type spatial;

void vertex() {
	vec3 dir = CAMERA_POSITION_WORLD - NODE_POSITION_WORLD;
	dir.y = 0.;
	dir = normalize(dir);
	mat3 bt = mat3(cross(vec3(0.,1.,0.),dir),vec3(0.,1.,0), dir);
	VERTEX = bt * VERTEX;
	NORMAL = dir;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
