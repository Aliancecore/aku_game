extends SceneTree
## Affiche la boîte englobante (origine, taille) de quelques modèles : utile pour les placer et les mettre à l'échelle.
##   godot-4 --headless --path . --script res://tools/print_bounds.gd
func _initialize() -> void:
	for path in [
		"res://assets/models/characters/Mage.glb",
		"res://assets/models/city/car_taxi.gltf",
		"res://assets/models/city/car_sedan.gltf",
		"res://assets/models/city/dumpster.gltf",
		"res://assets/models/city/trash_A.gltf",
		"res://assets/models/city/bench.gltf",
		"res://assets/models/city/bush.gltf",
	]:
		var m: Node3D = (load(path) as PackedScene).instantiate()
		var b := Models.bounds(m)
		m.free()
		print("%-22s origine (%.2f %.2f %.2f)  taille (%.2f %.2f %.2f)" % [path.get_file(), b.position.x, b.position.y, b.position.z, b.size.x, b.size.y, b.size.z])
	quit()
