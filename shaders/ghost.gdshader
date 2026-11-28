shader_type spatial;
// Lueur d'esprit : la texture du modèle, teintée, et éclairée de l'intérieur.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.5, 1.0, 0.8, 1.0);
uniform float glow = 0.6;

void fragment() {
	vec3 t = texture(albedo_tex, UV).rgb;
	ALBEDO = mix(t, t * tint.rgb, 0.6);
	ROUGHNESS = 0.7;
	EMISSION = t * tint.rgb * glow;
}
