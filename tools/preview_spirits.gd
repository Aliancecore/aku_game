extends SceneTree
## Les esprits vus de face, de près, pour régler leur apparence.
##   godot-4 --path . --script res://tools/preview_spirits.gd -- /home/shabda/aku_game/.godot/shots/esprits.png
var frames := 0
var out_path := "/home/shabda/aku_game/.godot/shots/esprits.png"

func _build() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.04, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.25, 0.4)
	env.glow_enabled = true
	env.glow_bloom = 0.08
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var moon := DirectionalLight3D.new(); moon.rotation_degrees = Vector3(-30, 160, 0); moon.light_energy = 0.5
	moon.light_color = Color(0.6, 0.7, 1.0); root.add_child(moon)
	var x := -6.0
	for kind in ["feu_follet", "esprit_rouge", "feu_follet", "esprit_rouge"]:
		var s := Spirit.new()
		root.add_child(s)
		s.setup(kind, "linear", Vector3(x, 0, 0), null)
		s.set_physics_process(false)
		x += 4.0
	var cam := Camera3D.new(); cam.position = Vector3(0, 0.5, 13); cam.fov = 40; root.add_child(cam)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 1: _build()
	elif frames == 14:
		root.get_texture().get_image().save_png(out_path)
		print("Capture : ", out_path)
		quit()
	return false
