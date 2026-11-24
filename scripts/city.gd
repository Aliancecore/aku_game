class_name City
extends Node3D
## Cotonou la nuit : ciel, lune, étoiles, et plusieurs couches de décor qui défilent
## à des vitesses différentes (parallaxe) — immeubles, Place de l'Étoile Rouge,
## palmiers, lampadaires, route en terre rouge et zémidjans.

class Layer:
	var root: Node3D
	var speed: float
	var start: float
	var span: float

var _layers: Array[Layer] = []
var _motos: Array[Node3D] = []
var _moto_speeds: Array[float] = []
var _window_mesh: QuadMesh
var _window_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_window_mesh = QuadMesh.new()
	_window_mesh.size = Vector2(0.55, 0.7)
	for c in [Color(1.0, 0.72, 0.35), Color(1.0, 0.85, 0.55), Color(0.7, 0.85, 1.0), Color(1.0, 0.55, 0.25)]:
		_window_mats.append(Fx.mat(c, 2.5))

	_build_environment()
	_build_sky()
	_build_ground()
	_buildings_layer(-75.0, Vector2(5, 10), Vector2(6, 26), Color(0.05, 0.06, 0.1), 0.12, false)
	_buildings_layer(-40.0, Vector2(5, 9), Vector2(4, 16), Color(0.08, 0.08, 0.12), 0.2, true)
	_buildings_layer(-18.0, Vector2(6, 10), Vector2(3, 10), Color(0.16, 0.11, 0.08), 0.28, false)
	_street_layer(-6.0)
	_road_markings(-2.5)
	_build_motos()


func _process(delta: float) -> void:
	for layer in _layers:
		for child in layer.root.get_children():
			var n := child as Node3D
			n.position.x -= layer.speed * delta
			if n.position.x < layer.start:
				n.position.x += layer.span
	var half := _half_width(-1.0) + 6.0
	for i in _motos.size():
		var m := _motos[i]
		m.position.x += _moto_speeds[i] * delta
		if m.position.x < -half:
			m.position.x += half * 2.0
		elif m.position.x > half:
			m.position.x -= half * 2.0


## Demi-largeur visible par la caméra à la profondeur z.
func _half_width(z: float) -> float:
	return (GameConfig.CAMERA_Z - z) * tan(deg_to_rad(GameConfig.CAMERA_FOV / 2.0)) * 16.0 / 9.0


## Vitesse de défilement d'une couche : plus elle est loin, plus elle est lente.
func _new_layer(z: float) -> Layer:
	var layer := Layer.new()
	layer.root = Node3D.new()
	layer.root.position.z = z
	add_child(layer.root)
	layer.speed = GameConfig.SCROLL_SPEED * GameConfig.CAMERA_Z / (GameConfig.CAMERA_Z - z)
	layer.start = -_half_width(z) - 12.0
	_layers.append(layer)
	return layer


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.01, 0.015, 0.05)
	sky_mat.sky_horizon_color = Color(0.18, 0.08, 0.12)   # lueur orangée de la ville
	sky_mat.ground_horizon_color = Color(0.18, 0.08, 0.12)
	sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.02)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.18, 0.32)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.07, 0.14)
	env.fog_density = 0.006
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var moonlight := DirectionalLight3D.new()
	moonlight.light_color = Color(0.6, 0.7, 1.0)
	moonlight.light_energy = 0.45
	moonlight.rotation_degrees = Vector3(-35.0, 30.0, 0.0)
	moonlight.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(moonlight)


func _build_sky() -> void:
	Fx.mesh(self, Fx.sphere(7.0, 32), Fx.mat(Color(0.95, 0.92, 0.8), 2.0, false, true), Vector3(40, 34, -130))

	var stars := MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.mesh = Fx.sphere(0.18, 6)
	stars.instance_count = 260
	for i in stars.instance_count:
		var basis := Basis().scaled(Vector3.ONE * randf_range(0.5, 1.6))
		var pos := Vector3(randf_range(-230, 230), randf_range(8, 130), -190)
		stars.set_instance_transform(i, Transform3D(basis, pos))
	var stars_node := MultiMeshInstance3D.new()
	stars_node.multimesh = stars
	stars_node.material_override = Fx.mat(Color(0.9, 0.92, 1.0), 3.0, false, true)
	add_child(stars_node)


func _build_ground() -> void:
	var y := GameConfig.GROUND_Y
	var ground := PlaneMesh.new()
	ground.size = Vector2(700, 220)
	Fx.mesh(self, ground, Fx.mat(Color(0.05, 0.04, 0.045)), Vector3(0, y, -100))
	var laterite := PlaneMesh.new()   # bas-côtés en terre rouge
	laterite.size = Vector2(700, 10)
	Fx.mesh(self, laterite, Fx.mat(Color(0.3, 0.11, 0.05)), Vector3(0, y + 0.01, -4))
	var road := PlaneMesh.new()
	road.size = Vector2(700, 4)
	Fx.mesh(self, road, Fx.mat(Color(0.09, 0.09, 0.1)), Vector3(0, y + 0.02, -2.5))


func _buildings_layer(z: float, width: Vector2, height: Vector2, base: Color,
		window_chance: float, with_monument: bool) -> void:
	var layer := _new_layer(z)
	var wall_mats: Array[StandardMaterial3D] = []
	for k in 3:
		wall_mats.append(Fx.mat(base.lightened(0.08 * k)))
	var x := layer.start
	var end := -layer.start
	var index := 0
	while x < end:
		var w := randf_range(width.x, width.y)
		if with_monument and index == 4:
			var monument := _red_star_monument()
			monument.position = Vector3(x + 5.0, GameConfig.GROUND_Y, 0)
			layer.root.add_child(monument)
			x += 12.0
		else:
			var h := randf_range(height.x, height.y)
			var b := _building(w, h, randf_range(4, 8), wall_mats.pick_random(), window_chance, z > -25.0)
			b.position = Vector3(x + w / 2.0, GameConfig.GROUND_Y, 0)
			layer.root.add_child(b)
			x += w + randf_range(0.3, 2.0)
		index += 1
	layer.span = x - layer.start


func _building(w: float, h: float, d: float, wall: Material, window_chance: float, shops: bool) -> Node3D:
	var b := Node3D.new()
	Fx.mesh(b, Fx.box(Vector3(w, h, d)), wall, Vector3(0, h / 2.0, 0))

	var cols := int(w / 1.5)
	var floors := int((h - 1.0) / 1.8)
	var margin := (w - cols * 1.5) / 2.0
	for f in floors:
		for c in cols:
			if randf() < window_chance:
				var pos := Vector3(-w / 2.0 + margin + 0.75 + c * 1.5, 2.2 + f * 1.8, d / 2.0 + 0.02)
				Fx.mesh(b, _window_mesh, _window_mats.pick_random(), pos)

	# Réservoir d'eau sur le toit, très courant à Cotonou.
	if randf() < 0.45:
		Fx.mesh(b, Fx.cylinder(0.5, 0.5, 1.0), Fx.mat(Color(0.12, 0.12, 0.14)),
				Vector3(randf_range(-w / 3.0, w / 3.0), h + 0.5, 0))

	# Enseigne lumineuse de boutique au rez-de-chaussée.
	if shops and randf() < 0.6:
		var colors := [Color(1.0, 0.85, 0.1), Color(0.1, 0.8, 0.3), Color(0.9, 0.15, 0.15), Color(0.2, 0.5, 1.0)]
		var sign_mat := Fx.mat(colors.pick_random(), 2.0)
		Fx.mesh(b, Fx.box(Vector3(w * 0.6, 0.6, 0.1)), sign_mat, Vector3(0, 2.6, d / 2.0 + 0.1))
	return b


## La Place de l'Étoile Rouge : une colonne surmontée d'une étoile rouge.
func _red_star_monument() -> Node3D:
	var m := Node3D.new()
	var stone := Fx.mat(Color(0.55, 0.5, 0.45))
	Fx.mesh(m, Fx.box(Vector3(5, 1.2, 5)), stone, Vector3(0, 0.6, 0))
	Fx.mesh(m, Fx.cylinder(0.6, 0.9, 16, 16), stone, Vector3(0, 9.2, 0))
	var star := Node3D.new()
	star.position = Vector3(0, 19.5, 0)
	m.add_child(star)
	var red := Fx.mat(Color(1.0, 0.08, 0.05), 3.5)
	var spike := PrismMesh.new()
	spike.size = Vector3(1.4, 2.4, 0.5)
	for i in 5:
		var a := TAU * i / 5.0
		Fx.mesh(star, spike, red, Vector3(-sin(a), cos(a), 0) * 1.6, Vector3(0, 0, a))
	Fx.mesh(star, Fx.sphere(1.0, 12), red)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.15, 0.1)
	glow.light_energy = 4.0
	glow.omni_range = 18.0
	star.add_child(glow)
	return m


func _street_layer(z: float) -> void:
	var layer := _new_layer(z)
	var trunk_mat := Fx.mat(Color(0.12, 0.08, 0.05))
	var leaf_mat := Fx.mat(Color(0.03, 0.12, 0.06))
	var pole_mat := Fx.mat(Color(0.1, 0.1, 0.11))
	var lamp_mat := Fx.mat(Color(1.0, 0.7, 0.35), 5.0)
	var x := layer.start
	var lamp := true
	while x < -layer.start:
		var item := Node3D.new()
		item.position = Vector3(x, GameConfig.GROUND_Y, 0)
		layer.root.add_child(item)
		if lamp:
			Fx.mesh(item, Fx.cylinder(0.1, 0.14, 6.5), pole_mat, Vector3(0, 3.25, 0))
			Fx.mesh(item, Fx.box(Vector3(1.4, 0.12, 0.12)), pole_mat, Vector3(0.6, 6.4, 0))
			Fx.mesh(item, Fx.sphere(0.25, 10), lamp_mat, Vector3(1.2, 6.2, 0))
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.62, 0.3)
			light.light_energy = 2.5
			light.omni_range = 10.0
			light.position = Vector3(1.2, 5.8, 1.0)
			item.add_child(light)
		else:
			var h := randf_range(6.0, 9.0)
			var lean := randf_range(-0.12, 0.12)
			Fx.mesh(item, Fx.cylinder(0.14, 0.24, h), trunk_mat, Vector3(-lean * h / 2.0, h / 2.0, 0), Vector3(0, 0, lean))
			var crown := Node3D.new()
			crown.position = Vector3(-lean * h, h, 0)
			item.add_child(crown)
			for i in 7:
				var pivot := Node3D.new()
				pivot.rotation.y = TAU * i / 7.0
				crown.add_child(pivot)
				Fx.mesh(pivot, Fx.box(Vector3(2.6, 0.06, 0.55)), leaf_mat, Vector3(1.2, -0.35, 0), Vector3(0, 0, -0.35))
		lamp = not lamp
		x += randf_range(5.0, 8.0)
	layer.span = x - layer.start


func _road_markings(z: float) -> void:
	var layer := _new_layer(z)
	var paint := Fx.mat(Color(0.7, 0.7, 0.6), 0.3)
	var x := layer.start
	while x < -layer.start:
		var dash := Fx.mesh(layer.root, Fx.box(Vector3(1.6, 0.02, 0.15)), paint, Vector3(x, GameConfig.GROUND_Y + 0.03, 0))
		dash.position.x = x
		x += 4.0
	layer.span = x - layer.start


## Zémidjans (motos-taxis) : un phare devant, un feu rouge derrière, dans les deux sens.
func _build_motos() -> void:
	var body_mat := Fx.mat(Color(0.08, 0.08, 0.08))
	var shirt := Fx.mat(Color(0.95, 0.8, 0.1))   # chemise jaune des zémidjans
	var head := Fx.mat(Color(1.0, 0.95, 0.8), 6.0)
	var tail := Fx.mat(Color(1.0, 0.1, 0.05), 4.0)
	for i in 5:
		var m := Node3D.new()
		var forward := 1.0 if i % 2 == 0 else -1.0
		var lane_z := -1.6 if forward > 0.0 else -3.4
		m.position = Vector3(randf_range(-25, 25), GameConfig.GROUND_Y, lane_z)
		m.scale.x = forward
		add_child(m)
		Fx.mesh(m, Fx.box(Vector3(1.4, 0.35, 0.25)), body_mat, Vector3(0, 0.55, 0))
		Fx.mesh(m, Fx.cylinder(0.25, 0.25, 0.1), body_mat, Vector3(0.6, 0.25, 0), Vector3(PI / 2.0, 0, 0))
		Fx.mesh(m, Fx.cylinder(0.25, 0.25, 0.1), body_mat, Vector3(-0.6, 0.25, 0), Vector3(PI / 2.0, 0, 0))
		Fx.mesh(m, Fx.box(Vector3(0.35, 0.7, 0.3)), shirt, Vector3(-0.1, 1.05, 0))
		Fx.mesh(m, Fx.sphere(0.17, 8), Fx.mat(Color(0.2, 0.12, 0.08)), Vector3(-0.05, 1.55, 0))
		Fx.mesh(m, Fx.sphere(0.12, 8), head, Vector3(0.75, 0.75, 0))
		Fx.mesh(m, Fx.sphere(0.08, 8), tail, Vector3(-0.75, 0.65, 0))
		_motos.append(m)
		_moto_speeds.append(forward * randf_range(5.0, 9.0) - GameConfig.SCROLL_SPEED)
