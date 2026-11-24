class_name Boss
extends Enemy
## L'Esprit du Lac Nokoué : surgit du fond de l'avenue, flotte devant la sorcière,
## et tire alternativement des gerbes visées et des cercles de boules.

var _elapsed := 0.0
var _fire_timer := 2.5
var _volley := 0
var _flash := 0.0
var _core_mat: StandardMaterial3D
var _orbs: Node3D
var _ring: MeshInstance3D


func setup(p_game, y: float) -> void:
	game = p_game
	add_to_group("enemies")
	health = GameConfig.BOSS_HEALTH
	max_health = health
	radius = 3.0 * GameConfig.BOSS_SCALE
	score = GameConfig.BOSS_SCORE
	color = Color(0.3, 0.85, 1.0)
	position = Vector3(0.0, y, GameConfig.SPAWN_Z - 30.0)
	scale = Vector3.ONE * GameConfig.BOSS_SCALE
	_build()


func _build() -> void:
	_core_mat = Fx.mat(Color(0.12, 0.1, 0.35), 1.5)
	_core_mat.emission = Color(0.2, 0.35, 0.9)
	Fx.mesh(self, Fx.sphere(2.4, 24), _core_mat)
	Fx.mesh(self, Fx.sphere(3.2, 24), Fx.mat(Color(0.3, 0.7, 1.0, 0.18), 1.0, true))

	var eye := Fx.mat(Color(1.0, 0.15, 0.1), 6.0)
	for side in [-1.0, 1.0]:
		Fx.mesh(self, Fx.sphere(0.32, 10), eye, Vector3(side * 0.75, 0.45, 2.2))

	var ring := TorusMesh.new()
	ring.inner_radius = 3.6
	ring.outer_radius = 3.85
	_ring = Fx.mesh(self, ring, Fx.mat(color, 3.0), Vector3.ZERO, Vector3(PI / 2.6, 0.0, 0.0))

	_orbs = Node3D.new()
	add_child(_orbs)
	var orb_mat := Fx.mat(Color(0.5, 1.0, 0.9), 4.0)
	for i in 8:
		var a := TAU * i / 8.0
		Fx.mesh(_orbs, Fx.sphere(0.35, 10), orb_mat, Vector3(cos(a), sin(a), 0.0) * 4.6)

	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 0.7, 1.0)
	light.light_energy = 4.0
	light.omni_range = 16.0
	add_child(light)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if position.z < GameConfig.BOSS_HOVER_Z:
		position.z = minf(position.z + GameConfig.BOSS_ENTER_SPEED * delta, GameConfig.BOSS_HOVER_Z)
	position.x = 6.0 * sin(_elapsed * 0.45)
	position.y = 2.5 + 3.0 * sin(_elapsed * 0.7)
	_orbs.rotation.z += delta * 1.2
	_ring.rotation.y += delta * 0.8

	_flash = maxf(_flash - delta * 5.0, 0.0)
	_core_mat.emission_energy_multiplier = 1.5 + _flash * 6.0

	_fire_timer -= delta
	if _fire_timer <= 0.0 and position.z >= GameConfig.BOSS_HOVER_Z - 1.0:
		var enraged := health < max_health / 2
		_fire_timer = 0.8 if enraged else 1.3
		_volley += 1
		if _volley % 3 == 0:
			game.enemy_ring(position, 14 if enraged else 10)
		else:
			game.enemy_spread(position, 5 if enraged else 3, 0.12)


func _on_damaged() -> void:
	_flash = 1.0
