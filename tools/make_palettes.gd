extends SceneTree
## Fabrique deux textures à partir des palettes des packs d'origine :
##   - witch_palette.png : la palette du mage, avec une peau foncée et des couleurs de pagne wax
##   - citybits_emission.png : un masque qui allume les vitres des bâtiments la nuit
## Les palettes sont des grilles de 8 colonnes x 4 lignes (cases de 128 x 256 pixels), chacune un dégradé vertical.
##   godot-4 --headless --path . --script res://tools/make_palettes.gd
## Les valeurs ci-dessous se règlent à l'œil, en regardant le rendu avec tools/preview_witch.gd.

const CELL_W := 128
const CELL_H := 256

# Cases de la palette du mage (colonne, ligne) -> [teinte, saturation, luminosité mini, facteur de luminosité].
# Repérées en lisant les coordonnées de texture de chaque partie du modèle.
const WITCH_CELLS := {
	# Peau (visage, mains) : bruns profonds.
	Vector2i(0, 0): [0.065, 0.62, 0.10, 0.50],
	Vector2i(7, 2): [0.065, 0.62, 0.10, 0.50],
	Vector2i(6, 3): [0.065, 0.62, 0.10, 0.50],
	Vector2i(7, 3): [0.065, 0.62, 0.10, 0.50],
	# Chapeau : vert foulard.
	Vector2i(1, 1): [0.38, 0.85, 0.14, 0.85],
	# Robe : pagne wax orange.
	Vector2i(0, 1): [0.07, 0.92, 0.25, 0.95],
	# Cape : jaune doré.
	Vector2i(2, 1): [0.13, 0.88, 0.22, 0.95],
}

# Cases de la palette de la ville qui sont des vitres (bleu clair et bleu vif) -> couleur de la lumière derrière.
const WINDOW_CELLS := {
	Vector2i(0, 1): Color(1.0, 0.78, 0.40),
	Vector2i(1, 1): Color(1.0, 0.62, 0.28),
}


func _initialize() -> void:
	_witch()
	_windows()
	quit()


func _path(res_path: String) -> String:
	return ProjectSettings.globalize_path(res_path)


func _witch() -> void:
	var img := Image.load_from_file(_path("res://assets/models/characters/Mage_mage_texture.png"))
	if img == null:
		push_error("Mage_mage_texture.png introuvable : lance d'abord un import (godot-4 --headless --import).")
		return
	img.convert(Image.FORMAT_RGBA8)
	for cell in WITCH_CELLS:
		var p: Array = WITCH_CELLS[cell]
		for y in CELL_H:
			for x in CELL_W:
				var px := Vector2i(cell.x * CELL_W + x, cell.y * CELL_H + y)
				var c := img.get_pixelv(px)
				var v: float = c.v * p[3] + p[2]
				img.set_pixelv(px, Color.from_hsv(p[0], p[1], clampf(v, 0.0, 1.0), c.a))
	img.save_png(_path("res://assets/models/characters/witch_palette.png"))
	print("witch_palette.png écrit")


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
