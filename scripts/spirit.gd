class_name Spirit
extends Enemy
## Un esprit de la nuit. Deux sortes pour l'instant :
##   "feu_follet"   : un crâne flottant à la lueur verte, 1 coup, tire rarement.
##   "esprit_rouge" : un squelette spectral à la lueur rouge, plus gros, 3 coups, tire plus souvent.
## Il arrive du fond de l'avenue et fonce vers la caméra. Modèles CC0 (voir assets/CREDITS.md).

const SKULL := "res://assets/models/halloween/skull.gltf"
const WARRIOR := "res://assets/models/characters/Skeleton_Warrior.glb"

var kind := "feu_follet"
var pattern := "linear"
var origin := Vector3.ZERO
var speed := GameConfig.SPIRIT_SPEED
var fire_cooldown := 3.0

var _elapsed := 0.0
var _fire_timer := 0.0
var _phase := 0.0
var _pulse := 0.0
var _core: Node3D          ## Le modèle, qui pulse un peu


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
			drop_chance = 0.55
			radius = 1.9
			speed = GameConfig.SPIRIT_SPEED * 0.8
			fire_cooldown = 1.4
		_:
			color = Color(0.45, 1.0, 0.75)
			health = 1
			score = 100
			drop_chance = 0.2
			fire_cooldown = 2.6
	max_health = health
	_fire_timer = randf_range(0.5, fire_cooldown)
	_phase = randf() * TAU
	_build()


func _build() -> void:
	_core = Node3D.new()
	add_child(_core)
	var model: Node3D
	if kind == "esprit_rouge":
		model = Models.load_scene(WARRIOR)
		model.scale = Vector3.ONE * 1.2
		Models.ghostify(model, color, 0.6)
		Models.play(model, "Idle_Combat" if pattern == "hover" else "Running_A", true, randf_range(0.9, 1.15))
	else:
		model = Models.load_scene(SKULL)
		model.scale = Vector3.ONE * 2.2
		Models.ghostify(model, color, 0.9)
	# Les modèles ont leurs pieds à l'origine : on les centre sur la position de l'esprit.
	var box := Models.bounds(model)
	model.position = -(box.position + box.size / 2.0) * model.scale
	_core.add_child(model)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position = Patterns.compute(pattern, origin, _elapsed, speed)
	_pulse = maxf(_pulse - delta * 4.0, 0.0)
	_core.scale = Vector3.ONE * (1.0 + 0.05 * sin(_elapsed * 6.0 + _phase) + _pulse * 0.25)

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_cooldown
		if position.z > GameConfig.FIRE_ZONE.x and position.z < GameConfig.FIRE_ZONE.y:
			game.enemy_fire(position)

	if position.z > GameConfig.DESPAWN_Z:
		queue_free()


func _on_damaged() -> void:
	_pulse = 1.0
