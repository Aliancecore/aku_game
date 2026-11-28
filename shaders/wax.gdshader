shader_type spatial;
render_mode cull_disabled;   // visible des deux côtés (foulard)
// Tissu wax (pagne) : cercles concentriques et rayures, comme les imprimés ankara d'Afrique de l'Ouest.
// Posé sur le corps (use_uv = false) : le motif suit le tour du corps et la hauteur.
// Posé sur un ruban (use_uv = true) : le motif suit la longueur du ruban ; wave le fait onduler.

uniform vec3 base : source_color = vec3(0.04, 0.30, 0.40);
uniform vec3 ring_a : source_color = vec3(0.95, 0.55, 0.08);
uniform vec3 ring_b : source_color = vec3(0.98, 0.84, 0.25);
uniform vec3 ring_c : source_color = vec3(0.82, 0.10, 0.14);
uniform float columns = 7.0;          // motifs autour du corps (un nombre entier : pas de couture visible)
uniform float rows_per_unit = 3.0;    // motifs en hauteur, par unité de modèle (la femme mesure 4,57 unités)
uniform bool use_uv = false;
uniform float raw_scale = 100.0;     // les coordonnées brutes du modèle FBX sont ~100 fois trop petites ; son axe vertical est Z
uniform float wave = 0.0;             // amplitude d'ondulation (foulard)
uniform float wave_speed = 7.0;

varying vec3 lp;
varying vec2 uv_v;

void vertex() {
	lp = VERTEX * raw_scale;
	uv_v = UV;
	if (wave > 0.0) {
		float t = UV.y;
		VERTEX.x += sin(TIME * wave_speed + t * 7.0) * wave * t;
		VERTEX.y += sin(TIME * wave_speed * 0.8 + t * 5.0 + 1.3) * wave * 0.6 * t;
	}
}

void fragment() {
	vec2 p;
	if (use_uv) {
		p = vec2(uv_v.x * 2.0, uv_v.y * 7.0);
	} else {
		p = vec2(atan(lp.y, lp.x) / 6.2831853 * columns, lp.z * rows_per_unit);
	}
	float row = floor(p.y);
	vec2 q = vec2(fract(p.x + mod(row, 2.0) * 0.5), fract(p.y)) - 0.5;
	float d = length(q);
	vec3 col = base;
	col = mix(col, ring_c, step(d, 0.44));
	col = mix(col, ring_b, step(d, 0.35));
	col = mix(col, ring_a, step(d, 0.25));
	col = mix(col, base, step(d, 0.12));
	col = mix(col, ring_b, step(0.93, fract(p.y + 0.5)) * 0.9);   // fines rayures entre les rangées
	ALBEDO = col;
	ROUGHNESS = 0.85;
}
