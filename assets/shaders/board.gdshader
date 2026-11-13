shader_type canvas_item;
// Pizarrón: fondo verde oscuro con ruido, polvo de tiza y borrones viejos semitransparentes.
uniform vec4 board_color : source_color = vec4(0.184, 0.290, 0.227, 1.0);
uniform float smudge : hint_range(0.0, 1.0) = 0.0;   // 0 = limpio, 1 = hiperinflación (casi todo manchado)
uniform float seed_v = 3.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = UV * res / 220.0;
	float h = res.y / 220.0;
	vec3 col = board_color.rgb * (0.86 + 0.28 * fbm(p * 2.2 + seed_v));
	// borrones viejos: pasadas anchas de trapo, más claras que el fondo
	float band = fbm(vec2(p.x * 0.55 + p.y * 0.25, p.y * 3.6 + seed_v));
	float old = smoothstep(0.52, 0.78, band) * 0.11;
	float band2 = fbm(vec2(p.x * 1.1 - p.y * 0.4 + 7.0, p.y * 5.5 + 2.0));
	old += smoothstep(0.58, 0.82, band2) * 0.07;
	// con inflación alta la pizarra se ensucia casi toda
	float heavy = smoothstep(0.35, 0.7, fbm(p * vec2(0.9, 2.4) + 11.0)) * 0.38 * smudge;
	heavy += smoothstep(0.45, 0.8, fbm(p * vec2(2.2, 1.0) + 31.0)) * 0.22 * smudge;
	col += vec3(0.86, 0.9, 0.85) * (old + heavy);
	// polvo de tiza fino
	float speck = step(0.9965, hash(floor(UV * res * 0.8)));
	col += vec3(0.85) * speck * 0.22;
	float haze = smoothstep(0.55, 1.0, UV.y) * fbm(p * 3.0 + 5.0) * 0.07;   // polvo cerca de la repisa
	col += vec3(0.9) * haze;
	// viñeta
	vec2 q = UV - 0.5;
	col *= 1.0 - dot(q, q) * 0.55;
	COLOR = vec4(col, 1.0);
}
