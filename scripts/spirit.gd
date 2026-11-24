class_name Spirit
extends Enemy
## Un esprit de la nuit. Deux sortes pour l'instant :
##   "feu_follet"   : pâle et vert, 1 coup, tire rarement.
##   "esprit_rouge" : plus gros, 3 coups, tire plus souvent.
## Il arrive du fond de l'avenue et fonce vers la caméra.

var kind := "feu_follet"
var pattern := "linear"
var origin := Vector3.ZERO
var speed := GameConfig.SPIRIT_SPEED
var fire_cooldown := 3.0

var _elapsed := 0.0
var _fire_timer := 0.0
var _phase := 0.0
var _pulse := 0.0
var _core: MeshInstance3D


func setup(p_kind: String, p_pattern: String, p_origin: Vector3, p_game) -> void:
	kind = p_kind
	pattern = p_pattern
	origin = p_origin
	position = p_origin
	game = p_game
	add_to_group("enemies")
	radius = GameConfig.SPIRIT_RADIUS
	match kind:
		"esprit_rouge":
			color = Color(1.0, 0.22, 0.18)
			health = 3
			score = 300
			radius = 1.5
			speed = GameConfig.SPIRIT_SPEED * 0.8
			fire_cooldown = 1.4
		_:
			color = Color(0.45, 1.0, 0.75)
			health = 1
			score = 100
			fire_cooldown = 2.6
	max_health = health
	_fire_timer = randf_range(0.5, fire_cooldown)
	_phase = randf() * TAU
	_build()


func _build() -> void:
	_core = Fx.mesh(self, Fx.sphere(radius * 0.65), Fx.mat(color, 3.0))
	var veil := Fx.mat(Color(color, 0.22), 1.5, true)
	Fx.mesh(self, Fx.sphere(radius), veil)
	# Traîne de l'esprit, derrière lui (il fonce vers la caméra).
	Fx.mesh(self, Fx.cylinder(0.02, radius * 0.6, radius * 2.6), veil,
			Vector3(0.0, 0.0, -radius * 1.4), Vector3(-PI / 2.0, 0.0, 0.0))
	# Deux yeux sombres tournés vers la sorcière.
	var eye := Fx.mat(Color(0.02, 0.0, 0.05))
	for side in [-1.0, 1.0]:
		Fx.mesh(self, Fx.sphere(radius * 0.14, 8), eye, Vector3(side * radius * 0.28, radius * 0.15, radius * 0.6))


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position = Patterns.compute(pattern, origin, _elapsed, speed)
	_pulse = maxf(_pulse - delta * 4.0, 0.0)
	_core.scale = Vector3.ONE * (1.0 + 0.12 * sin(_elapsed * 6.0 + _phase) + _pulse * 0.5)

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_cooldown
		if position.z > GameConfig.FIRE_ZONE.x and position.z < GameConfig.FIRE_ZONE.y:
			game.enemy_fire(position)

	if position.z > GameConfig.DESPAWN_Z:
		queue_free()


func _on_damaged() -> void:
	_pulse = 1.0
