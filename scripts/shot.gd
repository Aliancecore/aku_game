class_name Shot
extends Node3D
## Un projectile : sort de la sorcière (groupe "player_shots") ou boule d'esprit ("enemy_shots").

var velocity := Vector3.ZERO
var radius := 0.3
var damage := 1
var piercing := false       ## Un sort chargé traverse les esprits.
var hit := {}               ## Ennemis déjà touchés (pour ne frapper qu'une fois en traversant).


static func make(pos: Vector3, vel: Vector3, color: Color, size: float, group: String) -> Shot:
	var s := Shot.new()
	s.position = pos
	s.velocity = vel
	s.radius = size
	s.add_to_group(group)
	Fx.mesh(s, Fx.sphere(size, 10), Fx.mat(color, 5.0))
	var halo := Fx.mat(Color(color, 0.3), 2.0, true)
	Fx.mesh(s, Fx.sphere(size * 1.8, 10), halo)
	return s


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation.x += delta * 6.0
	var limit_x := GameConfig.PLAY_MAX.x + GameConfig.OFFSCREEN_MARGIN + 4.0
	if absf(position.x) > limit_x or absf(position.y) > 16.0:
		queue_free()
