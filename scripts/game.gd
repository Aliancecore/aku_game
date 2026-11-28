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
var _city: City
var _reticle: Node3D
var _clear_timer := 0.0

# Vue : 3D (caméra derrière la sorcière) ou 2D (de côté, façon R-Type), touche P.
var side_view := false
var _view_blend := 0.0          ## 0 = vue 3D, 1 = vue 2D, entre les deux pendant le changement.
var _cam_behind := Vector3(0, GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_Z)

# Mode test (ligne de commande), pour jouer tout seul et prendre une capture :
#   godot-4 --path . -- --screenshot=$HOME/capture.png --level=2 --time=38 --delay=6
var _autoplay := false
var _shot_path := ""
var _shot_delay := 6.0
var _start_level := 0
var _start_time := 0.0
var _start_side := false
var _start_power := 0
var _start_run := false
var _no_fire := false           ## Le pilote automatique ne tire pas (pour regarder les esprits).
var _drop_all := false          ## Chaque esprit vaincu lâche un bonus (pour tester).
var _auto_t := 0.0


func _ready() -> void:
	randomize()
	_setup_inputs()

	_camera = Camera3D.new()
	_camera.fov = GameConfig.CAMERA_FOV
	_camera.far = 1500.0
	_camera.position = Vector3(0, GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_Z)
	add_child(_camera)
	_city = City.new()
	add_child(_city)

	world = Node3D.new()
	add_child(world)
	witch = Witch.new()
	witch.position = GameConfig.PLAYER_START
	witch.fired.connect(_on_witch_fired)
	witch.landed.connect(func(): hud.toast("Elle court !  Flèche haut : sauter (voitures !)   Deux fois : s'envoler", Color(1.0, 0.8, 0.4)))
	witch.took_off.connect(func(): hud.toast("Envol !", Color(0.6, 0.85, 1.0)))
	world.add_child(witch)
	_reticle = _make_reticle()
	_reticle.visible = false
	world.add_child(_reticle)

	hud = Hud.new()
	add_child(hud)
	hud.show_message("AKU", "La sorcière de Cotonou\n\n"
			+ "Flèches : voler     Espace : lancer un sort\n"
			+ "Maintenir Espace : sort chargé     P : vue 3D / 2D\n"
			+ "Près du sol, elle atterrit et court : flèche haut pour sauter les voitures, deux fois pour s'envoler\n\nEntrée pour commencer")

	_read_cli()
	for kind in witch.power:
		witch.power[kind] = _start_power
	if _start_run:
		witch.start_running()
	if _start_side:
		_set_side_view(true, false)
		_view_blend = 1.0
	if _autoplay:
		_start_game()
		_take_screenshot()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_view"):
		_set_side_view(not side_view)
	match state:
		State.TITLE:
			if Input.is_action_just_pressed("start"):
				_start_game()
		State.GAME_OVER, State.VICTORY:
			if Input.is_action_just_pressed("start"):
				get_tree().reload_current_scene()
				return   # la scène est remplacée : on ne touche plus à la caméra ni au HUD
	if boss != null and not is_instance_valid(boss):
		boss = null
	_follow_camera(delta)
	_reticle.position = witch.muzzle() + Vector3(0, 0, -GameConfig.RETICLE_DISTANCE)
	_reticle.visible = witch.controls_enabled and not side_view
	hud.update_stats(score, lives, witch.charge / GameConfig.CHARGE_TIME, boss)
	hud.set_bonuses(_bonus_text())


func _physics_process(delta: float) -> void:
	if _autoplay:
		_autoplay_step(delta)
	match state:
		State.PLAYING:
			_run_level(delta)
			_check_collisions()
			_check_obstacles()
			_update_bonuses(delta)
		State.LEVEL_CLEAR:
			_check_collisions()
			_check_obstacles()
			_update_bonuses(delta)
			_clear_timer -= delta
			if _clear_timer <= 0.0:
				_load_level(level_index + 1)


# --- Caméra et viseur ----------------------------------------------------------

## Bascule entre la vue 3D (derrière la sorcière) et la vue 2D (de côté). Touche P.
func _set_side_view(on: bool, announce := true) -> void:
	side_view = on
	witch.side_view = on
	_city.set_side_view(on)
	Patterns.hover_z = GameConfig.SIDE_HOVER_Z if on else GameConfig.HOVER_Z
	if announce:
		hud.flash("Vue 2D" if on else "Vue 3D")


## Où apparaissent les esprits : tout au fond en 3D, juste hors écran en 2D.
func spawn_z() -> float:
	return GameConfig.SIDE_SPAWN_Z if side_view else GameConfig.SPAWN_Z


## Où le boss s'arrête pour combattre.
func boss_hover_z() -> float:
	return GameConfig.SIDE_BOSS_HOVER_Z if side_view else GameConfig.BOSS_HOVER_Z


## En vue 2D, la profondeur (x) n'existe plus à l'écran : on l'ignore pour les collisions et la visée.
func _flat(v: Vector3) -> Vector3:
	return Vector3(0.0, v.y, v.z) if side_view else v


## La caméra suit la sorcière à moitié en 3D ; en 2D elle regarde la scène de côté.
## Pendant le changement de vue, elle glisse de l'une à l'autre.
func _follow_camera(delta: float) -> void:
	_view_blend = move_toward(_view_blend, 1.0 if side_view else 0.0, GameConfig.VIEW_BLEND_SPEED * delta)
	var k := smoothstep(0.0, 1.0, _view_blend)

	var p := witch.position
	var follow := GameConfig.CAMERA_FOLLOW
	# La caméra suit presque toute la hauteur de la sorcière : à pied, au ras du sol, elle reste dans le cadre.
	var behind := Vector3(p.x * follow, p.y * 0.9 + GameConfig.CAMERA_HEIGHT, GameConfig.CAMERA_Z)
	_cam_behind = _cam_behind.lerp(behind, 1.0 - exp(-6.0 * delta))
	var look_behind := Vector3(p.x * 0.35, p.y * 0.6 + 1.5, -40.0)

	_camera.position = _cam_behind.lerp(GameConfig.SIDE_CAMERA, k)
	_camera.fov = lerpf(GameConfig.CAMERA_FOV, GameConfig.SIDE_FOV, k)
	_camera.look_at(look_behind.lerp(GameConfig.SIDE_LOOK, k), Vector3.UP)


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
	var z0 := spawn_z()
	var y := float(wave.get("y", 0.0))
	if kind == "boss":
		boss = Boss.new()
		boss.setup(self, y)
		# Plus la sorcière a de bonus, plus le boss est résistant : le combat reste un défi.
		boss.health = int(boss.health * (1.0 + GameConfig.BOSS_POWER_SCALE * witch.total_power()))
		boss.max_health = boss.health
		world.add_child(boss)
		hud.flash(GameConfig.BOSS_NAME)
		return
	var pattern := str(wave.get("pattern", "linear"))
	var count := int(wave.get("count", 1))
	var row := str(wave.get("formation", "column")) == "row"
	for i in count:
		var pos := Vector3(x, y, z0)
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
	_cancel_shots()

	for node in get_tree().get_nodes_in_group("player_shots"):
		var shot := node as Shot
		if shot.is_queued_for_deletion():
			continue
		for enemy_node in enemies:
			var enemy := enemy_node as Enemy
			var id := enemy.get_instance_id()
			if enemy.is_queued_for_deletion() or shot.hit.has(id):
				continue
			if _segment_hits(_flat(shot.previous), _flat(shot.position), _flat(enemy.position), shot.radius + enemy.radius):
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
		if _flat(witch.position).distance_to(_flat(enemy.position)) < witch.radius + enemy.radius:
			if not enemy is Boss:
				_kill_enemy(enemy)
			_hurt_player()
			return
	for node in get_tree().get_nodes_in_group("enemy_shots"):
		var shot := node as Shot
		if shot.is_queued_for_deletion():
			continue
		if _segment_hits(_flat(shot.previous), _flat(shot.position), _flat(witch.position), shot.radius + witch.radius):
			shot.queue_free()
			_hurt_player()
			return


## Obstacles du sol (voitures, bennes, bancs, buissons, poteaux, palmiers) : les heurter coûte une vie.
## Ils ne gênent que près du sol : en volant haut, ou en sautant, on passe par-dessus.
## En vue 2D la profondeur n'existe pas à l'écran, donc on ignore x comme pour les autres collisions.
func _check_obstacles() -> void:
	if _autoplay or not witch.is_hittable():
		return
	var feet := witch.feet_y() - GameConfig.GROUND_Y       # hauteur des pieds au-dessus du sol
	var body := GameConfig.PLAYER_BODY_RADIUS
	for c in _city.colliders_near(witch.position.z, body):
		if feet >= float(c["height"]):
			continue
		var node: Node3D = c["node"]
		var half: Vector2 = c["half"]
		var dx := 0.0 if side_view else absf(node.position.x - witch.position.x)
		if dx < half.x + body and absf(node.position.z - witch.position.z) < half.y + body:
			_hit_obstacle(str(c["kind"]))
			return


func _hit_obstacle(kind: String) -> void:
	_hurt_player("La circulation a eu raison de toi…" if kind == "voiture" else "Tu as foncé dans un obstacle…")
	witch.react_hit()
	if kind == "voiture":
		hud.toast("Renversée par une voiture !", Color(1.0, 0.4, 0.3))
	else:
		hud.toast("Aïe : %s !" % kind, Color(1.0, 0.6, 0.3))


## Quand un sort de la sorcière touche une boule d'esprit, les deux s'annulent.
## Un sort chargé détruit la boule mais continue sa route.
func _cancel_shots() -> void:
	var enemy_shots := get_tree().get_nodes_in_group("enemy_shots")
	for node in get_tree().get_nodes_in_group("player_shots"):
		var mine := node as Shot
		if mine.is_queued_for_deletion():
			continue
		for other_node in enemy_shots:
			var theirs := other_node as Shot
			if theirs.is_queued_for_deletion():
				continue
			# Les deux vont vite l'un vers l'autre : on teste le mouvement relatif pendant l'image.
			var before := _flat(mine.previous) - _flat(theirs.previous)
			var after := _flat(mine.position) - _flat(theirs.position)
			var reach := mine.radius + theirs.radius + GameConfig.SHOT_CANCEL_MARGIN
			if _segment_hits(before, after, Vector3.ZERO, reach):
				_burst(theirs.position, Color(1.0, 0.6, 0.9), 1.6)
				theirs.queue_free()
				if not mine.piercing:
					mine.queue_free()
					break


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
	elif _drop_all or randf() < enemy.drop_chance:
		var bonus := Bonus.new()
		bonus.setup(Bonus.random_kind(), enemy.position)
		world.add_child(bonus)
	enemy.queue_free()


# --- Bonus ------------------------------------------------------------------------

## Attire les bonus proches de la sorcière et les ramasse quand elle les touche.
func _update_bonuses(delta: float) -> void:
	if not witch.controls_enabled:
		return
	for node in get_tree().get_nodes_in_group("bonuses"):
		var bonus := node as Bonus
		if bonus.is_queued_for_deletion():
			continue
		var to := _flat(witch.position) - _flat(bonus.position)
		var dist := to.length()
		if dist < witch.radius + GameConfig.BONUS_PICKUP_RADIUS:
			_collect(bonus)
		elif dist < GameConfig.BONUS_MAGNET_RANGE:
			bonus.position += to.normalized() * GameConfig.BONUS_MAGNET_SPEED * delta


func _collect(bonus: Bonus) -> void:
	var info: Dictionary = Bonus.KINDS[bonus.kind]
	var text: String = info["label"]
	match bonus.kind:
		"vie":
			if lives < GameConfig.MAX_LIVES:
				lives += 1
				text = "+1 VIE"
			else:
				score += 500
				text = "VIE MAX  +500"
		"bouclier":
			witch.apply_bonus("bouclier")
			text = "BOUCLIER"
		_:
			if witch.apply_bonus(bonus.kind):
				text = "%s +%d" % [text, witch.power[bonus.kind]]
			else:
				score += 200
				text = "%s MAX  +200" % text
	_burst(bonus.position, info["color"], 2.5)
	hud.toast(text, info["color"])
	bonus.queue_free()


## Les bonus actifs, pour l'affichage sous les vies.
func _bonus_text() -> String:
	var parts: Array[String] = []
	for kind in witch.power:
		if witch.power[kind] > 0:
			parts.append("%s +%d" % [str(Bonus.KINDS[kind]["label"]).capitalize(), witch.power[kind]])
	if witch.shield > 0.0:
		parts.append("Bouclier %d s" % ceili(witch.shield))
	return "   ".join(parts)


func _hurt_player(cause := "Les esprits ont eu raison de toi…") -> void:
	if _autoplay:
		return
	lives -= 1
	_burst(witch.position, Color(1.0, 0.5, 0.2), 3.0)
	if lives <= 0:
		state = State.GAME_OVER
		witch.controls_enabled = false
		witch.visible = false
		hud.show_message("GAME OVER", "%s\nScore : %d\n\nEntrée pour rejouer" % [cause, score])
	else:
		witch.hurt()


func _burst(pos: Vector3, color: Color, size: float) -> void:
	world.add_child(Burst.make(pos, color, size))


# --- Tirs ---------------------------------------------------------------------

func _on_witch_fired(pos: Vector3, charged: bool) -> void:
	if charged:
		var big := Shot.make(pos, Vector3(0, 0, -GameConfig.CHARGED_SHOT_SPEED), Color(1.0, 0.35, 0.9),
				GameConfig.CHARGED_SHOT_RADIUS, "player_shots")
		big.damage = GameConfig.CHARGED_SHOT_DAMAGE + 2 * witch.power["force"]
		big.piercing = true
		world.add_child(big)
		return

	# Le bonus Boules ajoute des boules de feu en éventail. On l'ouvre dans le sens visible :
	# à l'horizontale en vue 3D (derrière la sorcière), à la verticale en vue 2D (de côté).
	var count := witch.shot_count()
	var fan_axis := Vector3.RIGHT if side_view else Vector3.UP
	var lateral := Vector3.UP if side_view else Vector3.RIGHT
	for i in count:
		var k := i - (count - 1) / 2.0
		var dir := Vector3(0, 0, -1).rotated(fan_axis, k * GameConfig.SHOT_SPREAD_ANGLE)
		var shot := Shot.make(pos + lateral * k * GameConfig.SHOT_SPREAD_OFFSET, dir * GameConfig.SHOT_SPEED,
				Color(1.0, 0.8, 0.3), GameConfig.SHOT_RADIUS, "player_shots")
		shot.damage = witch.damage()
		shot.basis = Basis.looking_at(dir, Vector3.UP).scaled_local(Vector3(1.0, 1.0, 3.0))
		world.add_child(shot)


## Un esprit tire une boule vers la sorcière.
func enemy_fire(from: Vector3) -> void:
	if _can_fire(from):
		_enemy_shot(from, (_flat(witch.position) - _flat(from)).normalized())


## Un esprit tire seulement pendant la partie, et en vue 2D seulement une fois entré à l'écran.
func _can_fire(from: Vector3) -> bool:
	if state != State.PLAYING:
		return false
	return not (side_view and from.z < GameConfig.SIDE_VIEW_FAR_Z)


## Gerbe horizontale de n boules visées, écartées de `step` radians.
func enemy_spread(from: Vector3, n: int, step: float) -> void:
	if not _can_fire(from):
		return
	var aim := (_flat(witch.position) - _flat(from)).normalized()
	for i in n:
		var angle := (i - (n - 1) / 2.0) * step
		_enemy_shot(from, aim.rotated(Vector3.UP, angle))


## Couronne de n boules qui s'ouvre en arrivant vers la sorcière.
func enemy_ring(from: Vector3, n: int) -> void:
	if not _can_fire(from):
		return
	for i in n:
		var a := TAU * i / n
		_enemy_shot(from, (Vector3.BACK + Vector3(cos(a), sin(a), 0.0) * 0.2).normalized())


func _enemy_shot(from: Vector3, dir: Vector3) -> void:
	world.add_child(Shot.make(from, dir * GameConfig.ENEMY_SHOT_SPEED, Color(0.75, 0.35, 1.0),
			GameConfig.ENEMY_SHOT_RADIUS, "enemy_shots"))


# --- Contrôles ----------------------------------------------------------------

func _setup_inputs() -> void:
	# Déplacement : flèches du clavier (ou stick gauche de la manette).
	_bind("move_up", [KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("move_down", [KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("move_left", [KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("shoot", [KEY_SPACE, KEY_J], -1, 0.0, JOY_BUTTON_A)
	_bind("start", [KEY_ENTER, KEY_KP_ENTER], -1, 0.0, JOY_BUTTON_START)
	_bind("quit", [KEY_ESCAPE])
	_bind("toggle_view", [KEY_P])


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
		elif arg == "--no-fire":
			_no_fire = true
		elif arg == "--run":
			_start_run = true
		elif arg == "--drop-all":
			_drop_all = true
		elif arg.begins_with("--power="):
			_start_power = clampi(int(value), 0, GameConfig.MAX_POWER)
		elif arg.begins_with("--view="):
			_start_side = value == "2d"
		elif arg.begins_with("--level="):
			_start_level = clampi(int(value) - 1, 0, GameConfig.LEVELS.size() - 1)
		elif arg.begins_with("--time="):
			_start_time = float(value)
		elif arg.begins_with("--delay="):
			_shot_delay = float(value)


func _autoplay_step(delta: float) -> void:
	_auto_t += delta
	if side_view:
		witch.position.z = -4.0 + sin(_auto_t * 0.6) * 5.0
	else:
		witch.position.x = sin(_auto_t * 0.6) * 5.0
	if not witch.on_ground():
		witch.position.y = 1.0 + sin(_auto_t * 0.9) * 3.0
	if int(_auto_t * 5.0) % 2 == 0 and not _no_fire:
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
