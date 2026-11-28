extends SceneTree
## Planche de présentation des modèles 3D : les aligne, affiche leur taille et enregistre une capture.
##   godot-4 --path . --script res://tools/preview_assets.gd -- /home/shabda/aku_game/.godot/shots/planche.png
## (Le Godot installé par snap ne peut écrire que dans le dossier personnel.)

const MODELS := [
	["Cat", "res://assets/models/witch/Cat.fbx"],
	["Woman", "res://assets/models/witch/Woman_Run.fbx"],
	["Skeleton_Minion", "res://assets/models/characters/Skeleton_Minion.glb"],
	["Skeleton_Warrior", "res://assets/models/characters/Skeleton_Warrior.glb"],
	["Skeleton_Mage", "res://assets/models/characters/Skeleton_Mage.glb"],
	["skull", "res://assets/models/halloween/skull.gltf"],
	["jackolantern", "res://assets/models/halloween/pumpkin_orange_jackolantern.gltf"],
	["palm", "res://assets/models/nature/ExoticPalmDefalt.fbx"],
	["palm_old", "res://assets/models/nature/ExoticPalmOld.fbx"],
	["building_A", "res://assets/models/city/building_A_withoutBase.gltf"],
	["building_C", "res://assets/models/city/building_C_withoutBase.gltf"],
	["building_F", "res://assets/models/city/building_F_withoutBase.gltf"],
	["taxi", "res://assets/models/city/car_taxi.gltf"],
	["streetlight", "res://assets/models/city/streetlight.gltf"],
]

var frames := 0
var out_path := "/home/shabda/aku_game/.godot/shots/planche.png"


func _build() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.7)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	root.add_child(sun)

	var x := 0.0
	for entry in MODELS:
		var scene: PackedScene = load(entry[1])
		if scene == null:
			print("ECHEC chargement ", entry[0])
			continue
		var node: Node3D = scene.instantiate()
		# Les bâtiments de la ville sont montrés avec leurs fenêtres allumées, comme dans le jeu.
		if String(entry[0]).begins_with("building"):
			Models.light_windows(node)
		root.add_child(node)
		var box := _aabb(node)
		var h := box.size.y
		var w := maxf(box.size.x, box.size.z)
		print("%-18s hauteur %.2f  largeur %.2f  animations: %s" % [entry[0], h, w, _anims(node)])
		# Rapetisse ce qui est énorme pour que tout tienne sur la planche.
		var k := 3.0 / maxf(h, 0.001) if h > 6.0 else 1.0
		node.scale = Vector3.ONE * k
		x += (w * k) / 2.0 + 0.6
		node.position = Vector3(x - box.position.x * k - box.size.x * k / 2.0, -box.position.y * k, 0)
		x += (w * k) / 2.0 + 0.6

	var cam := Camera3D.new()
	cam.position = Vector3(x / 2.0, 2.5, 13.0 + x * 0.22)
	cam.fov = 55
	root.add_child(cam)
	cam.look_at(Vector3(x / 2.0, 1.4, 0), Vector3.UP)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		_build()   # les nœuds ne sont dans l'arbre qu'à partir de la première image
	elif frames == 14:
		root.get_texture().get_image().save_png(out_path)
		print("Capture : ", out_path)
		quit()
	return false


func _aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var local := (node as Node3D).global_transform.affine_inverse() * m.global_transform
		var a := local * m.get_aabb()
		if first:
			result = a
			first = false
		else:
			result = result.merge(a)
	return result


func _anims(node: Node) -> String:
	var players := node.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return "-"
	return str((players[0] as AnimationPlayer).get_animation_list().size())
