extends Node3D
## Aku — la boucle de jeu : état de la partie, niveaux (vagues lues dans un JSON),
## collisions, santé et score. Même découpage que le R-Type :
## config.gd = GameConfig, patterns.gd = patterns, levels/*.json = niveaux,
## _check_collisions = CollisionSystem, Enemy.take_damage = HealthSystem.
## La caméra est derrière la sorcière ; les esprits arrivent du fond de l'avenue.

enum State { TITLE, PLAYING, LEVEL_CLEAR, GAME_OVER, VICTORY }

var state := State.TITLE
var score := 0
var lives := GameConfig.PLAYER_LIVES
var level_index := 0
var level_time := 0.0
var waves: Array = []
var next_wave := 0
var boss: Boss = null

var witch: Witch
var world: Node3D
var hud: Hud
var _camera: Camera3D
var _reticle: Node3D
var _clear_timer := 0.0

# Mode test (ligne de commande), pour jouer tout seul et prendre une capture :
#   godot-4 --path . -- --screenshot=$HOME/capture.png --level=2 --time=38 --delay=6
var _autoplay := false
var _shot_path := ""
var _shot_delay := 6.0
var _start_level := 0
var _start_time := 0.0
var _auto_t := 0.0


func _ready() -> void:
	randomize()
	_setup_inputs()

	_camera = Camera3D.new()
	_camera.fov = GameConfig.CAMERA_FOV
	_camera.far = 1500.0
	_camera.position = Vector3(0, GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_Z)
	add_child(_camera)
	add_child(City.new())

	world = Node3D.new()
	add_child(world)
	witch = Witch.new()
	witch.position = GameConfig.PLAYER_START
	witch.fired.connect(_on_witch_fired)
	world.add_child(witch)
	_reticle = _make_reticle()
	_reticle.visible = false
	world.add_child(_reticle)

	hud = Hud.new()
	add_child(hud)
	hud.show_message("AKU", "La sorcière de Cotonou\n\n"
			+ "Flèches ou ZQSD : voler     Espace : lancer un sort\n"
			+ "Maintenir Espace : sort chargé\n\nEntrée pour commencer")

	_read_cli()
	if _autoplay:
		_start_game()
		_take_screenshot()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	match state:
		State.TITLE:
			if Input.is_action_just_pressed("start"):
				_start_game()
		State.GAME_OVER, State.VICTORY:
			if Input.is_action_just_pressed("start"):
				get_tree().reload_current_scene()
	if boss != null and not is_instance_valid(boss):
		boss = null
	_follow_camera(delta)
	_reticle.position = witch.muzzle() + Vector3(0, 0, -GameConfig.RETICLE_DISTANCE)
	_reticle.visible = witch.controls_enabled
	hud.update_stats(score, lives, witch.charge / GameConfig.CHARGE_TIME, boss)


func _physics_process(delta: float) -> void:
	if _autoplay:
		_autoplay_step(delta)
	match state:
		State.PLAYING:
			_run_level(delta)
			_check_collisions()
		State.LEVEL_CLEAR:
			_check_collisions()
			_clear_timer -= delta
			if _clear_timer <= 0.0:
				_load_level(level_index + 1)


# --- Caméra et viseur ----------------------------------------------------------

## La caméra suit la sorcière à moitié : elle reste visible et on sent ses virages.
func _follow_camera(delta: float) -> void:
	var p := witch.position
	var follow := GameConfig.CAMERA_FOLLOW
	var target := Vector3(p.x * follow, p.y * follow * 0.8 + GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_Z)
	_camera.position = _camera.position.lerp(target, 1.0 - exp(-6.0 * delta))
	_camera.look_at(Vector3(p.x * 0.35, p.y * 0.35 + 1.8, -40.0), Vector3.UP)


## Le viseur : deux anneaux devant la sorcière, toujours visibles.
func _make_reticle() -> Node3D:
	var r := Node3D.new()
	var m := Fx.mat(Color(1.0, 0.7, 0.3, 0.8), 2.0, true)
	m.no_depth_test = true
	for size in [0.9, 0.5]:
		var ring := TorusMesh.new()
		ring.inner_radius = size
		ring.outer_radius = size + 0.08
		Fx.mesh(r, ring, m, Vector3.ZERO, Vector3(PI / 2.0, 0, 0))
	return r


# --- Niveaux (comme LevelSystem / LevelLoader) -------------------------------

func _start_game() -> void:
	witch.controls_enabled = true
	hud.hide_message()
	_load_level(_start_level)
	level_time = _start_time
	while next_wave < waves.size() and float(waves[next_wave]["time"]) < _start_time:
		next_wave += 1


func _load_level(index: int) -> void:
	level_index = index
	var file := FileAccess.open(GameConfig.LEVELS[index], FileAccess.READ)
	if file == null:
		push_error("Niveau introuvable : %s" % GameConfig.LEVELS[index])
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	waves = data.get("waves", [])
	waves.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
	next_wave = 0
	level_time = 0.0
	state = State.PLAYING
	hud.flash(str(data.get("name", "Niveau %d" % (index + 1))))


func _run_level(delta: float) -> void:
	level_time += delta
	while next_wave < waves.size() and level_time >= float(waves[next_wave]["time"]):
		_spawn_wave(waves[next_wave])
		next_wave += 1

	if next_wave >= waves.size() and get_tree().get_nodes_in_group("enemies").is_empty():
		if level_index + 1 < GameConfig.LEVELS.size():
			state = State.LEVEL_CLEAR
			_clear_timer = 3.0
			hud.flash("Niveau terminé !")
		else:
			state = State.VICTORY
			witch.controls_enabled = false
			hud.show_message("VICTOIRE", "Les esprits ont quitté Cotonou.\nScore : %d\n\nEntrée pour rejouer" % score)


## Une vague : "column" = les esprits arrivent l'un derrière l'autre,
## "row" = côte à côte.
func _spawn_wave(wave: Dictionary) -> void:
	var kind := str(wave.get("type", "feu_follet"))
	var x := float(wave.get("x", 0.0))
	var y := float(wave.get("y", 0.0))
	if kind == "boss":
		boss = Boss.new()
		boss.setup(self, y)
		world.add_child(boss)
		hud.flash(GameConfig.BOSS_NAME)
		return
	var pattern := str(wave.get("pattern", "linear"))
	var count := int(wave.get("count", 1))
	var row := str(wave.get("formation", "column")) == "row"
	for i in count:
		var pos := Vector3(x, y, GameConfig.SPAWN_Z)
		if row:
			pos.x += (i - (count - 1) / 2.0) * GameConfig.ROW_SPACING
		else:
			pos.z -= i * GameConfig.WAVE_SPACING
		var spirit := Spirit.new()
		spirit.setup(kind, pattern, pos, self)
		world.add_child(spirit)


# --- Collisions et santé (comme CollisionSystem / HealthSystem) ---------------

func _check_collisions() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")

	for node in get_tree().get_nodes_in_group("player_shots"):
		var shot := node as Shot
		if shot.is_queued_for_deletion():
			continue
		for enemy_node in enemies:
			var enemy := enemy_node as Enemy
			var id := enemy.get_instance_id()
			if enemy.is_queued_for_deletion() or shot.hit.has(id):
				continue
			if _segment_hits(shot.previous, shot.position, enemy.position, shot.radius + enemy.radius):
				shot.hit[id] = true
				if enemy.take_damage(shot.damage):
					_kill_enemy(enemy)
				if not shot.piercing:
					shot.queue_free()
					break

	if not witch.is_hittable():
		return
	for enemy_node in enemies:
		var enemy := enemy_node as Enemy
		if enemy.is_queued_for_deletion():
			continue
		if witch.position.distance_to(enemy.position) < witch.radius + enemy.radius:
			if not enemy is Boss:
				_kill_enemy(enemy)
			_hurt_player()
			return
	for node in get_tree().get_nodes_in_group("enemy_shots"):
		var shot := node as Shot
		if shot.is_queued_for_deletion():
			continue
		if _segment_hits(shot.previous, shot.position, witch.position, shot.radius + witch.radius):
			shot.queue_free()
			_hurt_player()
			return


## Le segment [a, b] (trajet d'un projectile pendant une image) passe-t-il à moins de r du point c ?
func _segment_hits(a: Vector3, b: Vector3, c: Vector3, r: float) -> bool:
	var ab := b - a
	var len2 := ab.length_squared()
	var t := 0.0 if len2 == 0.0 else clampf((c - a).dot(ab) / len2, 0.0, 1.0)
	return (a + ab * t).distance_to(c) < r


func _kill_enemy(enemy: Enemy) -> void:
	score += enemy.score
	_burst(enemy.position, enemy.color, enemy.radius * 2.5)
	if enemy == boss:
		boss = null
		for i in 8:
			var offset := Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-3, 3))
			_burst(enemy.position + offset, enemy.color, 10.0)
		for shot in get_tree().get_nodes_in_group("enemy_shots"):
			shot.queue_free()
	enemy.queue_free()


func _hurt_player() -> void:
	if _autoplay:
		return
	lives -= 1
	_burst(witch.position, Color(1.0, 0.5, 0.2), 3.0)
	if lives <= 0:
		state = State.GAME_OVER
		witch.controls_enabled = false
		witch.visible = false
		hud.show_message("GAME OVER", "Les esprits ont eu raison de toi…\nScore : %d\n\nEntrée pour rejouer" % score)
	else:
		witch.hurt()


func _burst(pos: Vector3, color: Color, size: float) -> void:
	world.add_child(Burst.make(pos, color, size))


# --- Tirs ---------------------------------------------------------------------

func _on_witch_fired(pos: Vector3, charged: bool) -> void:
	var shot: Shot
	if charged:
		shot = Shot.make(pos, Vector3(0, 0, -GameConfig.CHARGED_SHOT_SPEED), Color(1.0, 0.35, 0.9),
				GameConfig.CHARGED_SHOT_RADIUS, "player_shots")
		shot.damage = GameConfig.CHARGED_SHOT_DAMAGE
		shot.piercing = true
	else:
		shot = Shot.make(pos, Vector3(0, 0, -GameConfig.SHOT_SPEED), Color(1.0, 0.8, 0.3),
				GameConfig.SHOT_RADIUS, "player_shots")
		shot.scale = Vector3(1.0, 1.0, 3.0)
	world.add_child(shot)


## Un esprit tire une boule vers la sorcière.
func enemy_fire(from: Vector3) -> void:
	if state == State.PLAYING:
		_enemy_shot(from, (witch.position - from).normalized())


## Gerbe horizontale de n boules visées, écartées de `step` radians.
func enemy_spread(from: Vector3, n: int, step: float) -> void:
	if state != State.PLAYING:
		return
	var aim := (witch.position - from).normalized()
	for i in n:
		var angle := (i - (n - 1) / 2.0) * step
		_enemy_shot(from, aim.rotated(Vector3.UP, angle))


## Couronne de n boules qui s'ouvre en arrivant vers la sorcière.
func enemy_ring(from: Vector3, n: int) -> void:
	if state != State.PLAYING:
		return
	for i in n:
		var a := TAU * i / n
		_enemy_shot(from, (Vector3.BACK + Vector3(cos(a), sin(a), 0.0) * 0.2).normalized())


func _enemy_shot(from: Vector3, dir: Vector3) -> void:
	world.add_child(Shot.make(from, dir * GameConfig.ENEMY_SHOT_SPEED, Color(0.75, 0.35, 1.0),
			GameConfig.ENEMY_SHOT_RADIUS, "enemy_shots"))


# --- Contrôles ----------------------------------------------------------------

func _setup_inputs() -> void:
	# Touches physiques : W/A/S/D correspondent à Z/Q/S/D sur un clavier AZERTY.
	_bind("move_up", [KEY_UP, KEY_W], JOY_AXIS_LEFT_Y, -1.0)
	_bind("move_down", [KEY_DOWN, KEY_S], JOY_AXIS_LEFT_Y, 1.0)
	_bind("move_left", [KEY_LEFT, KEY_A], JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_RIGHT, KEY_D], JOY_AXIS_LEFT_X, 1.0)
	_bind("shoot", [KEY_SPACE, KEY_J], -1, 0.0, JOY_BUTTON_A)
	_bind("start", [KEY_ENTER, KEY_KP_ENTER], -1, 0.0, JOY_BUTTON_START)
	_bind("quit", [KEY_ESCAPE])


func _bind(action: String, keys: Array, axis := -1, axis_value := 0.0, button := -1) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.3)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis
		motion.axis_value = axis_value
		InputMap.action_add_event(action, motion)
	if button >= 0:
		var pad := InputEventJoypadButton.new()
		pad.button_index = button
		InputMap.action_add_event(action, pad)


# --- Mode test ------------------------------------------------------------------

func _read_cli() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg == "--autoplay":
			_autoplay = true
		elif arg.begins_with("--screenshot="):
			_shot_path = value
			_autoplay = true
		elif arg.begins_with("--level="):
			_start_level = clampi(int(value) - 1, 0, GameConfig.LEVELS.size() - 1)
		elif arg.begins_with("--time="):
			_start_time = float(value)
		elif arg.begins_with("--delay="):
			_shot_delay = float(value)


func _autoplay_step(delta: float) -> void:
	_auto_t += delta
	witch.position.x = sin(_auto_t * 0.6) * 5.0
	witch.position.y = 1.0 + sin(_auto_t * 0.9) * 3.0
	if int(_auto_t * 5.0) % 2 == 0:
		Input.action_press("shoot")
	else:
		Input.action_release("shoot")


func _take_screenshot() -> void:
	if _shot_path == "":
		return
	await get_tree().create_timer(_shot_delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shot_path)
	print("Capture enregistrée : ", _shot_path)
	get_tree().quit()
