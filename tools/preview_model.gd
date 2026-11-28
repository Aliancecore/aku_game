extends SceneTree
## Montre un modèle animé sous plusieurs poses, de côté. Écrit une image avec tous les essais côte à côte.
##   godot-4 --path . --script res://tools/preview_model.gd -- res://assets/models/witch/Woman_Run.fbx /home/shabda/aku_game/.godot/shots/m.png "HumanArmature|Female_Run" "HumanArmature|Female_Sitting"
var frames := 0
var out_path := ""
var players: Array = []

func _build() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0]
	out_path = args[1]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.2, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.8)
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 40, 0); root.add_child(sun)
	var x := 0.0
	for i in range(2, args.size()):
		var node: Node3D = (load(path) as PackedScene).instantiate()
		node.position = Vector3(x, 0, 0)
		root.add_child(node)
		var player := Models.animation_player(node)
		if player != null and player.has_animation(args[i]):
			player.get_animation(args[i]).loop_mode = Animation.LOOP_LINEAR
			player.play(args[i])
			player.seek(0.35, true)
			player.pause()
		else:
			print("animation introuvable : ", args[i], " parmi ", player.get_animation_list() if player else [])
		var b := Models.bounds(node)
		print(args[i], " : hauteur %.2f largeur %.2f" % [b.size.y, b.size.x])
		x += 2.6
	var cam := Camera3D.new(); cam.position = Vector3((x - 2.6) / 2.0, 1.4, 9.5 + x * 0.3); cam.fov = 40; root.add_child(cam)
	cam.look_at(Vector3((x - 2.6) / 2.0, 1.0, 0), Vector3.UP)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 1: _build()
	elif frames == 14:
		root.get_texture().get_image().save_png(out_path)
		print("Capture : ", out_path)
		quit()
	return false
