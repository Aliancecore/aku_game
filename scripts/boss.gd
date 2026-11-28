class_name Boss
extends Enemy
## L'Esprit du Lac Nokoué : un grand squelette-mage spectral. Il surgit du fond de l'avenue,
## flotte devant la sorcière, et tire alternativement des gerbes visées et des cercles de boules.
## Modèle CC0 (voir assets/CREDITS.md).

const MODEL := "res://assets/models/characters/Skeleton_Mage.glb"

var _elapsed := 0.0
var _fire_timer := 2.5
var _volley := 0
var _flash := 0.0
var _glow: Array[ShaderMaterial] = []   ## Matériaux du modèle, dont la lueur s'emballe quand il est touché
var _orbs: Node3D
var _ring: MeshInstance3D


func setup(p_game, y: float) -> void:
	game = p_game
	add_to_group("enemies")
	health = GameConfig.BOSS_HEALTH
	max_health = health
	radius = 2.6 * GameConfig.BOSS_SCALE
	score = GameConfig.BOSS_SCORE
	color = Color(0.3, 0.85, 1.0)
	position = Vector3(0.0, y, game.spawn_z() - 30.0)
	scale = Vector3.ONE * GameConfig.BOSS_SCALE
	_build()


func _build() -> void:
	var model := Models.load_scene(MODEL)
	model.scale = Vector3.ONE * 2.0
	_glow = Models.ghostify(model, Color(0.45, 0.7, 1.0), 0.22)
	Models.play(model, "Spellcasting", true, 0.8)
	var box := Models.bounds(model)
	model.position = -(box.position + box.size / 2.0) * model.scale
	add_child(model)

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
	# En vue 2D l'écran est bien plus petit : le boss y est réduit à 30 % (son corps et sa zone de touche).
	var k := 0.3 if game.side_view else 1.0
	scale = Vector3.ONE * GameConfig.BOSS_SCALE * k
	radius = 2.6 * GameConfig.BOSS_SCALE * k
	var hover_z: float = game.boss_hover_z()
	position.z = move_toward(position.z, hover_z, GameConfig.BOSS_ENTER_SPEED * delta)
	position.x = 6.0 * sin(_elapsed * 0.45)
	position.y = (-0.2 + 0.9 * sin(_elapsed * 0.7)) if game.side_view else (2.5 + 3.0 * sin(_elapsed * 0.7))
	_orbs.rotation.z += delta * 1.2
	_ring.rotation.y += delta * 0.8

	_flash = maxf(_flash - delta * 5.0, 0.0)
	for m in _glow:
		m.set_shader_parameter("glow", 0.22 + _flash * 2.5)

	_fire_timer -= delta
	if _fire_timer <= 0.0 and absf(position.z - hover_z) < 1.0:
		var enraged := health < max_health / 2
		_fire_timer = 0.8 if enraged else 1.3
		_volley += 1
		if _volley % 3 == 0:
			game.enemy_ring(position, 14 if enraged else 10)
		else:
			game.enemy_spread(position, 5 if enraged else 3, 0.12)


func _on_damaged() -> void:
	_flash = 1.0
