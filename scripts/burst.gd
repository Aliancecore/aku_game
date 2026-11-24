class_name Burst
extends Node3D
## Éclat lumineux quand un esprit disparaît ou que la sorcière est touchée.

var duration := 0.45
var size := 2.0
var _t := 0.0
var _mat: StandardMaterial3D
var _mi: MeshInstance3D


static func make(pos: Vector3, color: Color, p_size: float) -> Burst:
	var b := Burst.new()
	b.position = pos
	b.size = p_size
	b._mat = Fx.mat(color, 4.0, true)
	b._mi = Fx.mesh(b, Fx.sphere(0.5, 12), b._mat)
	return b


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / duration, 0.0, 1.0)
	_mi.scale = Vector3.ONE * lerpf(0.4, size, k)
	var c := _mat.albedo_color
	c.a = 1.0 - k
	_mat.albedo_color = c
	_mat.emission_energy_multiplier = 4.0 * (1.0 - k)
	if _t >= duration:
		queue_free()
