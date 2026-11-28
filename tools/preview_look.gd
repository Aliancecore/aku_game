extends SceneTree
## L'apparence de la sorcière sous plusieurs angles : assise sur son balai (de côté, de dos), et à pied.
##   godot-4 --path . --script res://tools/preview_look.gd -- /home/shabda/aku_game/.godot/shots/look
var frames := 0
var prefix := "/home/shabda/aku_game/.godot/shots/look"
var cam: Camera3D
var steps := [
	["vol_cote", true, Vector3(5.0, 0.8, 0), Vector3(0, 0.7, 0.4)],
	["vol_arriere", true, Vector3(0, 1.6, 4.5), Vector3(0, 0.6, 0)],
	["vol_trois_quarts", true, Vector3(-3.6, 1.4, 3.2), Vector3(0, 0.6, 0.2)],
	["course_cote", false, Vector3(5.0, 0.9, 0), Vector3(0, 0.9, 0)],
	["course_arriere", false, Vector3(0, 1.4, 4.5), Vector3(0, 0.9, 0)],
]
var step := 0
var rider: Node3D
var runner: Node3D

func _build() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: prefix = args[0]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.10, 0.11, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.6, 0.6, 0.75)
	env.glow_enabled = true; env.glow_bloom = 0.06
	var we := WorldEnvironment.new(); we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 30, 0); root.add_child(sun)
	rider = WitchLook.riding(); root.add_child(rider)
	runner = WitchLook.running(); runner.position = Vector3(20, 0, 0); root.add_child(runner)
	cam = Camera3D.new(); cam.fov = 45; root.add_child(cam)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		_build(); return false
	if step >= steps.size():
		quit(); return false
	var s: Array = steps[step]
	var base := Vector3.ZERO if s[1] else Vector3(20, 0, 0)
	if frames % 20 == 2:
		cam.position = base + s[2]
		cam.look_at(base + s[3], Vector3.UP)
	elif frames % 20 == 17:
		var path := "%s_%s.png" % [prefix, s[0]]
		root.get_texture().get_image().save_png(path)
		print("Capture : ", path)
		step += 1
	return false
