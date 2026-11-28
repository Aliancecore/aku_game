extends SceneTree
## Décrit un modèle : taille, maillages, matériaux, squelette et animations.
##   godot-4 --headless --path . --script res://tools/inspect_model.gd -- res://assets/models/witch/Cat.fbx
func _initialize() -> void:
	for path in OS.get_cmdline_user_args():
		var node: Node3D = (load(path) as PackedScene).instantiate()
		var b := Models.bounds(node)
		print("== ", path.get_file(), " taille (%.2f %.2f %.2f) origine (%.2f %.2f %.2f)" % [b.size.x, b.size.y, b.size.z, b.position.x, b.position.y, b.position.z])
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var mats := []
			for s in m.mesh.get_surface_count():
				var mat := m.get_active_material(s)
				if mat is StandardMaterial3D:
					mats.append("%s %s" % [mat.resource_name, (mat as StandardMaterial3D).albedo_color.to_html(false)])
				else:
					mats.append(str(mat))
			print("  maillage ", m.name, " : ", mats)
		for sk in node.find_children("*", "Skeleton3D", true, false):
			var names := []
			for i in (sk as Skeleton3D).get_bone_count():
				names.append((sk as Skeleton3D).get_bone_name(i))
			print("  squelette ", (sk as Skeleton3D).get_bone_count(), " os : ", names)
		for ap in node.find_children("*", "AnimationPlayer", true, false):
			print("  animations : ", (ap as AnimationPlayer).get_animation_list())
		node.free()
	quit()
