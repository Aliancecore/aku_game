extends SceneTree
## Gros plan sur la sorcière sous plusieurs angles, pour régler le modèle, le balai et la pose.
##   godot-4 --path . --script res://tools/preview_witch.gd -- /home/shabda/aku_game/.godot/shots/sorciere
## Écrit <préfixe>_vol_arriere.png, <préfixe>_vol_cote.png et <préfixe>_course_cote.png.

var frames := 0
var prefix := "/home/shabda/aku_game/.godot/shots/sorciere"
var witch: Witch
var cam: Camera3D
var steps := [
	# [image, vol ?, position caméra, point visé]
	["vol_arriere", true, Vector3(0, 2.2, 7.0), Vector3(0, 0.6, 0)],
	["vol_cote", true, Vector3(7.0, 1.0, 0), Vector3(0, 0.6, 0)],
	["course_cote", false, Vector3(7.0, -3.0, 0), Vector3(0, -3.6, 0)],
]
var step := 0


func _build() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		prefix = args[0]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.85)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	root.add_child(sun)

	witch = Witch.new()
	root.add_child(witch)
	cam = Camera3D.new()
	cam.fov = 50
	root.add_child(cam)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		_build()
		return false
	if step >= steps.size():
		quit()
		return false
	var s: Array = steps[step]
	if frames % 20 == 2:
		# Nouvelle vue : on place la sorcière et la caméra.
		witch.position = Vector3.ZERO if s[1] else Vector3(0, GameConfig.RUN_Y + 6.0 - 6.0, 0)
		if not s[1]:
			witch.start_running()
		cam.position = s[2]
		cam.look_at(s[3], Vector3.UP)
	elif frames % 20 == 17:
		var path := "%s_%s.png" % [prefix, s[0]]
		root.get_texture().get_image().save_png(path)
		print("Capture : ", path)
		step += 1
	return false
