class_name Witch
extends Node3D
## La sorcière sur son balai, vue de dos : déplacement, sorts (appui court)
## et sort chargé (maintenir). Elle vole vers le fond de l'avenue (-Z).
## Si elle descend près du sol, elle atterrit et court à pied ; deux appuis rapides
## sur la flèche du haut la font décoller.

signal fired(pos: Vector3, charged: bool)
signal landed
signal took_off

enum Mode { FLYING, LANDING, RUNNING, TAKING_OFF }

var mode := Mode.FLYING

var radius := GameConfig.PLAYER_RADIUS
var controls_enabled := false
var side_view := false      ## Vue 2D (touche P) : ←/→ la font avancer/reculer vers la droite/gauche de l'écran.
var invincible := 0.0
var charge := 0.0
## Niveaux des bonus cumulables (0 = aucun, jusqu'à GameConfig.MAX_POWER).
var power := {"force": 0, "boules": 0, "vitesse": 0, "cadence": 0}
var shield := 0.0           ## Secondes de bouclier restantes.

var _cooldown := 0.0
var _charging := false
var _time := 0.0
var _tilt: Node3D          ## Roulis et tangage quand elle se déplace.
var _body: Node3D          ## Le modèle en vol (sur son balai), tourné pour regarder vers -Z.
var _runner: Node3D        ## Le modèle debout, pour la course.
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _run_phase := 0.0
var _last_up_tap := -10.0  ## Moment du dernier appui sur la flèche du haut (double appui = décollage).
var _charge_orb: MeshInstance3D
var _shield_mesh: MeshInstance3D


func _ready() -> void:
	_tilt = Node3D.new()
	add_child(_tilt)
	_body = Node3D.new()
	_body.rotation.y = PI / 2.0   # le modèle est construit le long de +X : on le tourne vers -Z
	_tilt.add_child(_body)

	var wood := Fx.mat(Color(0.42, 0.26, 0.12))
	var straw := Fx.mat(Color(0.85, 0.68, 0.32))
	var skin := Fx.mat(Color(0.3, 0.18, 0.1))
	var wax_orange := Fx.mat(Color(0.95, 0.42, 0.05))   # pagne wax
	var wax_green := Fx.mat(Color(0.05, 0.6, 0.32))     # foulard

	# Le balai : manche vers l'avant, paille à l'arrière.
	Fx.mesh(_body, Fx.cylinder(0.06, 0.06, 3.4), wood, Vector3(0.2, 0, 0), Vector3(0, 0, PI / 2.0))
	Fx.mesh(_body, Fx.cylinder(0.12, 0.45, 1.0), straw, Vector3(-1.9, 0, 0), Vector3(0, 0, -PI / 2.0))
	Fx.mesh(_body, Fx.cylinder(0.13, 0.13, 0.12), wax_green, Vector3(-1.35, 0, 0), Vector3(0, 0, PI / 2.0))

	# La sorcière assise : robe en pagne, buste, tête et foulard noué (gèlè).
	Fx.mesh(_body, Fx.cylinder(0.22, 0.5, 0.9), wax_orange, Vector3(-0.1, 0.35, 0))
	Fx.mesh(_body, Fx.cylinder(0.2, 0.24, 0.55), wax_orange, Vector3(-0.05, 0.95, 0))
	Fx.mesh(_body, Fx.sphere(0.24), skin, Vector3(0.0, 1.42, 0))
	Fx.mesh(_body, Fx.sphere(0.3), wax_green, Vector3(-0.06, 1.6, 0), Vector3.ZERO, Vector3(1.1, 0.8, 1.0))
	Fx.mesh(_body, Fx.sphere(0.14), wax_green, Vector3(-0.32, 1.75, 0))
	# Les deux bras tendus vers le manche.
	for side in [-1.0, 1.0]:
		Fx.mesh(_body, Fx.cylinder(0.07, 0.07, 0.8), skin, Vector3(0.35, 0.75, side * 0.2), Vector3(0, 0, -1.0))
	# Écharpe qui flotte derrière elle.
	Fx.mesh(_body, Fx.box(Vector3(1.3, 0.05, 0.35)), wax_green, Vector3(-0.85, 1.2, 0), Vector3(0, 0, 0.3))

	_build_runner(wood, straw, skin, wax_orange, wax_green)

	# Halo magique : éclaire son dos, côté caméra.
	var aura := OmniLight3D.new()
	aura.light_color = Color(1.0, 0.6, 0.3)
	aura.light_energy = 1.6
	aura.omni_range = 5.0
	aura.position = Vector3(0, 1.4, 2.0)
	_tilt.add_child(aura)

	# Étincelles qui tombent de la paille.
	var sparks := GPUParticles3D.new()
	sparks.amount = 24
	sparks.lifetime = 0.5
	sparks.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(-1, 0, 0)
	pm.spread = 20.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3(0, -2.0, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	sparks.process_material = pm
	var spark_mesh := Fx.sphere(0.04, 6)
	spark_mesh.material = Fx.mat(Color(1.0, 0.75, 0.3), 3.0)
	sparks.draw_pass_1 = spark_mesh
	sparks.position = Vector3(-2.4, 0, 0)
	_body.add_child(sparks)

	# Boule d'énergie qui grossit devant elle pendant la charge (son point d'attache change à pied).
	_charge_orb = Fx.mesh(_tilt, Fx.sphere(0.6), Fx.mat(Color(1.0, 0.35, 0.9), 5.0), Vector3(0, 0, -2.3))
	_charge_orb.visible = false

	# Bulle du bouclier.
	_shield_mesh = Fx.mesh(self, Fx.sphere(1.9, 20), Fx.mat(Color(0.45, 0.6, 1.0, 0.25), 2.0, true),
			Vector3(0, 0.6, 0))
	_shield_mesh.visible = false


## Le modèle debout : jambes et bras qui balancent, le balai porté sur l'épaule.
## Construit comme celui en vol (le long de +X, puis tourné vers -Z), pieds à y = 0.
func _build_runner(wood: Material, straw: Material, skin: Material, wax_orange: Material, wax_green: Material) -> void:
	_runner = Node3D.new()
	_runner.rotation.y = PI / 2.0
	_runner.scale = Vector3.ONE * 0.85
	_runner.position.y = -GameConfig.RUN_HEIGHT
	_runner.visible = false
	_tilt.add_child(_runner)

	# Jambes : le pivot est à la hanche, la jambe pend dessous.
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0, 1.0, side * 0.14)
		_runner.add_child(leg)
		Fx.mesh(leg, Fx.cylinder(0.09, 0.07, 1.0), skin, Vector3(0, -0.5, 0))
		Fx.mesh(leg, Fx.box(Vector3(0.32, 0.1, 0.16)), wood, Vector3(0.08, -1.0, 0))
		_legs.append(leg)

	# Pagne, buste, tête et foulard noué.
	Fx.mesh(_runner, Fx.cylinder(0.25, 0.55, 0.8), wax_orange, Vector3(0, 1.1, 0))
	Fx.mesh(_runner, Fx.cylinder(0.2, 0.26, 0.6), wax_orange, Vector3(0, 1.7, 0))
	Fx.mesh(_runner, Fx.sphere(0.24), skin, Vector3(0, 2.15, 0))
	Fx.mesh(_runner, Fx.sphere(0.3), wax_green, Vector3(-0.05, 2.33, 0), Vector3.ZERO, Vector3(1.1, 0.8, 1.0))
	Fx.mesh(_runner, Fx.sphere(0.14), wax_green, Vector3(-0.3, 2.45, 0))

	# Bras : le pivot est à l'épaule, ils balancent à l'opposé des jambes.
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(0, 1.9, side * 0.28)
		_runner.add_child(arm)
		Fx.mesh(arm, Fx.cylinder(0.07, 0.06, 0.7), skin, Vector3(0, -0.35, 0))
		_arms.append(arm)

	# Le balai, penché sur l'épaule, la paille vers l'arrière.
	var broom := Node3D.new()
	broom.position = Vector3(-0.1, 1.5, 0.36)
	broom.rotation.z = 0.7
	_runner.add_child(broom)
	Fx.mesh(broom, Fx.cylinder(0.05, 0.05, 2.6), wood, Vector3(0, 0.3, 0))
	Fx.mesh(broom, Fx.cylinder(0.4, 0.1, 0.9), straw, Vector3(0, 1.75, 0))


func _physics_process(delta: float) -> void:
	_time += delta
	_tilt.position.y = 0.0 if on_ground() else sin(_time * 3.0) * 0.12
	_animate_run(delta)

	if shield > 0.0:
		shield -= delta
		# Clignote pendant la dernière seconde et demie pour prévenir que ça s'arrête.
		_shield_mesh.visible = shield > 1.5 or int(shield * 10.0) % 2 == 0
		_shield_mesh.scale = Vector3.ONE * (1.0 + 0.04 * sin(_time * 8.0))
	else:
		_shield_mesh.visible = false

	if invincible > 0.0:
		invincible -= delta
		visible = int(invincible * 12.0) % 2 == 0
	elif controls_enabled:
		visible = true

	if not controls_enabled:
		return

	var dir := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	var step := move_speed() * delta
	match mode:
		Mode.FLYING:
			position.y += dir.y * step
		Mode.LANDING:
			# Elle descend toute seule jusqu'au sol, puis se met à courir.
			position.y = move_toward(position.y, GameConfig.RUN_Y, GameConfig.LAND_SPEED * delta)
			if is_equal_approx(position.y, GameConfig.RUN_Y):
				_set_mode(Mode.RUNNING)
		Mode.RUNNING:
			position.y = GameConfig.RUN_Y
			step *= GameConfig.RUN_SPEED_FACTOR
			# Deux appuis rapides sur la flèche du haut : elle remonte sur son balai.
			if Input.is_action_just_pressed("move_up"):
				if _time - _last_up_tap <= GameConfig.DOUBLE_TAP_TIME:
					_set_mode(Mode.TAKING_OFF)
				_last_up_tap = _time
		Mode.TAKING_OFF:
			position.y = move_toward(position.y, GameConfig.TAKEOFF_Y, GameConfig.TAKEOFF_SPEED * delta)
			if is_equal_approx(position.y, GameConfig.TAKEOFF_Y):
				_set_mode(Mode.FLYING)

	if side_view:
		# Vue de côté : la droite de l'écran est le -Z du jeu ; on se recale sur x = 0.
		position.x = move_toward(position.x, 0.0, step * 1.5)
		position.z = clampf(position.z - dir.x * step, GameConfig.SIDE_Z_RANGE.x, GameConfig.SIDE_Z_RANGE.y)
	else:
		position.z = move_toward(position.z, 0.0, step * 1.5)
		position.x += dir.x * step
	position.x = clampf(position.x, GameConfig.PLAY_MIN.x, GameConfig.PLAY_MAX.x)
	if mode == Mode.FLYING:
		position.y = minf(position.y, GameConfig.PLAY_MAX.y)
		position.y = maxf(position.y, GameConfig.PLAY_MIN.y)
		# Assez près du sol : elle atterrit.
		if position.y <= GameConfig.LAND_TRIGGER_Y:
			_set_mode(Mode.LANDING)
	var k := 1.0 - exp(-8.0 * delta)
	var flying := not on_ground()
	var roll := 0.0 if side_view else -dir.x * (0.55 if flying else 0.2)
	_tilt.rotation.z = lerpf(_tilt.rotation.z, roll, k)                                  # roulis
	_tilt.rotation.x = lerpf(_tilt.rotation.x, dir.y * 0.25 if flying else 0.0, k)       # tangage

	_update_shooting(delta)


func _update_shooting(delta: float) -> void:
	_cooldown -= delta
	if Input.is_action_just_pressed("shoot"):
		_charging = true
		charge = 0.0
		if _cooldown <= 0.0:
			_cooldown = fire_cooldown()
			fired.emit(muzzle(), false)
	if _charging and Input.is_action_pressed("shoot"):
		charge = minf(charge + delta, GameConfig.CHARGE_TIME)
	if _charging and not Input.is_action_pressed("shoot"):
		if charge >= GameConfig.CHARGE_TIME:
			fired.emit(muzzle(), true)
		_charging = false
		charge = 0.0

	var ratio := charge / GameConfig.CHARGE_TIME
	_charge_orb.visible = ratio > 0.15
	_charge_orb.scale = Vector3.ONE * (0.3 + ratio) * (1.0 + 0.1 * sin(_time * 30.0) * ratio)


## Est-elle au sol (en train d'atterrir ou de courir) ?
func on_ground() -> bool:
	return mode == Mode.LANDING or mode == Mode.RUNNING


## Pose directement la sorcière en train de courir (mode test).
func start_running() -> void:
	position.y = GameConfig.RUN_Y
	_set_mode(Mode.RUNNING, false)


## Change d'état et montre le bon modèle : sur le balai en vol, debout au sol.
func _set_mode(new_mode: Mode, announce := true) -> void:
	var was_on_ground := on_ground()
	mode = new_mode
	var grounded := on_ground()
	_body.visible = not grounded
	_runner.visible = grounded
	# La boule de charge se tient au bout du balai en vol, dans la main à pied.
	_charge_orb.position = Vector3(0.0, 0.5, -1.3) if grounded else Vector3(0.0, 0.0, -2.3)
	_last_up_tap = -10.0
	if announce:
		if new_mode == Mode.RUNNING:
			landed.emit()
		elif new_mode == Mode.TAKING_OFF and was_on_ground:
			took_off.emit()


## Balancement des jambes et des bras pendant la course, léger rebond du corps.
func _animate_run(delta: float) -> void:
	if not _runner.visible:
		return
	_run_phase += delta * 13.0
	for i in _legs.size():
		_legs[i].rotation.z = sin(_run_phase + i * PI) * 0.9
		_arms[i].rotation.z = -sin(_run_phase + i * PI) * 0.7
	_runner.position.y = -GameConfig.RUN_HEIGHT + absf(sin(_run_phase)) * 0.06


## Point de départ des sorts : le bout du balai en vol, la main à pied.
func muzzle() -> Vector3:
	if on_ground():
		return position + Vector3(0.0, 0.5, -1.2)
	return position + Vector3(0.0, _tilt.position.y, -2.4)


## Dégâts d'un sort : 1, plus 1 par niveau de Force.
func damage() -> int:
	return 1 + power["force"]


## Nombre de boules de feu par tir : 1, plus 1 par niveau de Boules.
func shot_count() -> int:
	return 1 + power["boules"]


func move_speed() -> float:
	return GameConfig.PLAYER_SPEED * (1.0 + GameConfig.SPEED_PER_LEVEL * power["vitesse"])


func fire_cooldown() -> float:
	return GameConfig.PLAYER_FIRE_COOLDOWN / (1.0 + GameConfig.CADENCE_PER_LEVEL * power["cadence"])


## Somme des niveaux de bonus : sert à durcir le boss quand la sorcière est très puissante.
func total_power() -> int:
	var total := 0
	for k in power:
		total += power[k]
	return total


## Applique un bonus cumulable ou le bouclier. Renvoie false si le niveau est déjà au maximum.
func apply_bonus(kind: String) -> bool:
	if kind == "bouclier":
		shield = GameConfig.SHIELD_TIME
		return true
	if not power.has(kind) or power[kind] >= GameConfig.MAX_POWER:
		return false
	power[kind] += 1
	return true


## La sorcière peut-elle être touchée maintenant ?
func is_hittable() -> bool:
	return controls_enabled and invincible <= 0.0 and shield <= 0.0


func hurt() -> void:
	invincible = GameConfig.PLAYER_INVINCIBLE_TIME
	_charging = false
	charge = 0.0
