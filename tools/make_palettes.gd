extends SceneTree
## Fabrique le masque qui allume les vitres des bâtiments la nuit (citybits_emission.png), d'après la palette du pack.
## Les palettes sont des grilles de 8 colonnes x 4 lignes (cases de 128 x 256 pixels), chacune un dégradé vertical.
##   godot-4 --headless --path . --script res://tools/make_palettes.gd

const CELL_W := 128
const CELL_H := 256

# Cases de la palette de la ville qui sont des vitres (bleu clair et bleu vif) -> couleur de la lumière derrière.
const WINDOW_CELLS := {
	Vector2i(0, 1): Color(1.0, 0.78, 0.40),
	Vector2i(1, 1): Color(1.0, 0.62, 0.28),
}


func _initialize() -> void:
	_windows()
	quit()


func _path(res_path: String) -> String:
	return ProjectSettings.globalize_path(res_path)


func _windows() -> void:
	var src := Image.load_from_file(_path("res://assets/models/city/citybits_texture.png"))
	var mask := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	mask.fill(Color.BLACK)
	for cell in WINDOW_CELLS:
		var light: Color = WINDOW_CELLS[cell]
		for y in CELL_H:
			for x in CELL_W:
				mask.set_pixel(cell.x * CELL_W + x, cell.y * CELL_H + y, light)
	mask.save_png(_path("res://assets/models/city/citybits_emission.png"))
	print("citybits_emission.png écrit")
