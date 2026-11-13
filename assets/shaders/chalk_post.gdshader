shader_type canvas_item;
// Efecto "tiza" sobre todo lo dibujado: solo en los BORDES (granulado y huecos). El interior de los trazos gruesos,
// y por lo tanto el relleno de los números, queda sólido y sin ruido (legibilidad ante todo).
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform vec3 board_color = vec3(0.184, 0.290, 0.227);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float luma_at(vec2 uv) {
	return dot(texture(screen_tex, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = SCREEN_UV * res;
	vec2 px = SCREEN_PIXEL_SIZE;
	// borde granulado: desplazamiento chico y ruidoso
	vec2 off = (vec2(noise(p * 0.45), noise(p * 0.45 + 17.3)) - 0.5) * 1.6 * px * strength;
	vec3 c = texture(screen_tex, SCREEN_UV + off).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	float chalk = smoothstep(0.40, 0.62, luma);
	// ¿es un borde? (contraste con los vecinos a 2 px). En el interior de un trazo ancho no se toca nada.
	float l0 = luma_at(SCREEN_UV);
	float d = abs(l0 - luma_at(SCREEN_UV + vec2(2.0, 0.0) * px)) + abs(l0 - luma_at(SCREEN_UV - vec2(2.0, 0.0) * px))
		+ abs(l0 - luma_at(SCREEN_UV + vec2(0.0, 2.0) * px)) + abs(l0 - luma_at(SCREEN_UV - vec2(0.0, 2.0) * px));
	float edge = smoothstep(0.10, 0.45, d);
	float grain = noise(p * 1.35) * 0.55 + hash(floor(p)) * 0.45;
	float gap = smoothstep(0.62, 0.95, grain) * 0.45;
	c = mix(c, board_color * (0.9 + 0.2 * hash(floor(p * 0.5))), chalk * gap * edge * strength);
	COLOR = vec4(c, 1.0);
}
