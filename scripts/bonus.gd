class_name Bonus
extends Node3D
## Un bonus lâché par un esprit vaincu. Il dérive vers la sorcière (groupe "bonuses") ;
## game.gd gère le ramassage et l'attraction (aimant).

const KINDS := {
	"force": {"label": "FORCE", "color": Color(1.0, 0.25, 0.2), "weight": 22},
	"boules": {"label": "BOULES", "color": Color(1.0, 0.65, 0.1), "weight": 22},
	"vitesse": {"label": "VITESSE", "color": Color(0.2, 0.85, 1.0), "weight": 18},
	"cadence": {"label": "CADENCE", "color": Color(0.8, 1.0, 0.2), "weight": 18},
	"vie": {"label": "VIE", "color": Color(1.0, 0.45, 0.75), "weight": 8},
	"bouclier": {"label": "BOUCLIER", "color": Color(0.5, 0.6, 1.0), "weight": 12},
}

var kind := "force"
var _t := 0.0
var _ring: MeshInstance3D
var _core: MeshInstance3D


## Tirage au sort pondéré : les bonus de puissance tombent plus souvent que la vie.
static func random_kind() -> String:
	var total := 0
	for k in KINDS:
		total += int(KINDS[k]["weight"])
	var roll := randi() % total
	for k in KINDS:
		roll -= int(KINDS[k]["weight"])
		if roll < 0:
			return k
	return "force"


func setup(p_kind: String, pos: Vector3) -> void:
	kind = p_kind
	position = pos
	add_to_group("bonuses")
	var color: Color = KINDS[kind]["color"]

	_core = Fx.mesh(self, Fx.sphere(0.5, 14), Fx.mat(color, 4.0))
	Fx.mesh(self, Fx.sphere(0.85, 14), Fx.mat(Color(color, 0.22), 2.0, true))
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.05
	_ring = Fx.mesh(self, torus, Fx.mat(color, 3.0), Vector3.ZERO, Vector3(PI / 3.0, 0.0, 0.0))

	var label := Label3D.new()
	label.text = KINDS[kind]["label"]
	label.font_size = 56
	label.pixel_size = 0.011
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color.lightened(0.4)
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.01, 0.08)
	label.position = Vector3(0.0, 1.6, 0.0)
	add_child(label)


func _physics_process(delta: float) -> void:
	_t += delta
	position.z += GameConfig.BONUS_DROP_SPEED * delta
	_core.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 7.0))
	_ring.rotation.y += delta * 3.0
	_ring.rotation.z += delta * 1.5
	if position.z > GameConfig.DESPAWN_Z:
		queue_free()
