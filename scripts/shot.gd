class_name Shot
extends Node3D
## Un projectile : sort de la sorcière (groupe "player_shots") ou boule d'esprit ("enemy_shots").

var velocity := Vector3.ZERO
var radius := 0.3
var damage := 1
var piercing := false       ## Un sort chargé traverse les esprits.
var hit := {}               ## Ennemis déjà touchés (pour ne frapper qu'une fois en traversant).
var previous := Vector3.ZERO ## Position à l'image d'avant : les sorts vont vite, on teste le segment.


static func make(pos: Vector3, vel: Vector3, color: Color, size: float, group: String) -> Shot:
	var s := Shot.new()
	s.position = pos
	s.previous = pos
	s.velocity = vel
	s.radius = size
	s.add_to_group(group)
	Fx.mesh(s, Fx.sphere(size, 10), Fx.mat(color, 5.0))
	Fx.mesh(s, Fx.sphere(size * 1.8, 10), Fx.mat(Color(color, 0.3), 2.0, true))
	return s


func _physics_process(delta: float) -> void:
	previous = position
	position += velocity * delta
	var too_far := position.z < -GameConfig.SHOT_RANGE or position.z > GameConfig.DESPAWN_Z
	if too_far or absf(position.x) > 40.0 or absf(position.y) > 30.0:
		queue_free()
