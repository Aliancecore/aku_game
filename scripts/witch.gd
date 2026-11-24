class_name Witch
extends Node3D
## La sorcière sur son balai, vue de dos : déplacement, sorts (appui court)
## et sort chargé (maintenir). Elle vole vers le fond de l'avenue (-Z).

signal fired(pos: Vector3, charged: bool)

var radius := GameConfig.PLAYER_RADIUS
var controls_enabled := false
var invincible := 0.0
var charge := 0.0

var _cooldown := 0.0
var _charging := false
var _time := 0.0
var _tilt: Node3D          ## Roulis et tangage quand elle se déplace.
var _body: Node3D          ## Le modèle, tourné pour regarder vers -Z.
var _charge_orb: MeshInstance3D


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

	# Boule d'énergie qui grossit au bout du balai pendant la charge.
	_charge_orb = Fx.mesh(_body, Fx.sphere(0.6), Fx.mat(Color(1.0, 0.35, 0.9), 5.0), Vector3(2.3, 0, 0))
	_charge_orb.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	_tilt.position.y = sin(_time * 3.0) * 0.12

	if invincible > 0.0:
		invincible -= delta
		visible = int(invincible * 12.0) % 2 == 0
	elif controls_enabled:
		visible = true

	if not controls_enabled:
		return

	var dir := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	position += Vector3(dir.x, dir.y, 0.0) * GameConfig.PLAYER_SPEED * delta
	position.x = clampf(position.x, GameConfig.PLAY_MIN.x, GameConfig.PLAY_MAX.x)
	position.y = clampf(position.y, GameConfig.PLAY_MIN.y, GameConfig.PLAY_MAX.y)
	var k := 1.0 - exp(-8.0 * delta)
	_tilt.rotation.z = lerpf(_tilt.rotation.z, -dir.x * 0.55, k)   # roulis
	_tilt.rotation.x = lerpf(_tilt.rotation.x, dir.y * 0.25, k)    # tangage

	_update_shooting(delta)


func _update_shooting(delta: float) -> void:
	_cooldown -= delta
	if Input.is_action_just_pressed("shoot"):
		_charging = true
		charge = 0.0
		if _cooldown <= 0.0:
			_cooldown = GameConfig.PLAYER_FIRE_COOLDOWN
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


## Point de départ des sorts : le bout du balai.
func muzzle() -> Vector3:
	return position + Vector3(0.0, _tilt.position.y, -2.4)


## La sorcière peut-elle être touchée maintenant ?
func is_hittable() -> bool:
	return controls_enabled and invincible <= 0.0


func hurt() -> void:
	invincible = GameConfig.PLAYER_INVINCIBLE_TIME
	_charging = false
	charge = 0.0
