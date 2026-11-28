shader_type spatial;
// Bâtiment de nuit : la texture d'origine, plus des fenêtres qui brillent là où le masque est clair.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D window_mask : source_color, filter_linear_mipmap;
uniform float window_energy = 1.6;

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = 0.6;
	EMISSION = texture(window_mask, UV).rgb * window_energy;
}
