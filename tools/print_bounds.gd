extends SceneTree
## Affiche la boîte englobante (origine, taille) de quelques modèles : utile pour les placer.
##   godot-4 --headless --path . --script res://tools/print_bounds.gd
func _initialize() -> void:
	for path in [
		"res://assets/models/city/streetlight.gltf",
		"res://assets/models/city/car_taxi.gltf",
		"res://assets/models/city/building_C_withoutBase.gltf",
		"res://assets/models/nature/ExoticPalmDefalt.fbx",
		"res://assets/models/nature/ExoticPalmCurve.fbx",
		"res://assets/models/halloween/skull.gltf",
	]:
		var m: Node3D = (load(path) as PackedScene).instantiate()
		var b := Models.bounds(m)
		m.free()
		print("%-52s origine (%.2f %.2f %.2f)  taille (%.2f %.2f %.2f)" % [path.get_file(), b.position.x, b.position.y, b.position.z, b.size.x, b.size.y, b.size.z])
	quit()
