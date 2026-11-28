class_name City
extends Node3D
## Cotonou la nuit, vue depuis le balai : une grande avenue bordée d'immeubles,
## de palmiers et de lampadaires, qui défile vers la caméra.
## Au loin : la ligne des toits, la lune et les étoiles. Sur la route : des voitures.
## Les immeubles, les voitures, les lampadaires et les palmiers sont des modèles CC0
## (voir assets/CREDITS.md) ; leurs fenêtres s'allument la nuit grâce à un masque d'émission.

const NEAR_Z := 30.0          ## Un élément qui dépasse la caméra repart au fond…
const FAR_Z := -300.0         ## …à cette profondeur.
const ROAD_HALF := 4.0        ## Demi-largeur de la chaussée.
const FRONT_ROW_X := 10.0     ## Façades de la première rangée d'immeubles.
const BACK_ROW_X := 26.0      ## Deuxième rangée, plus haute, derrière.

const CITY_DIR := "res://assets/models/city/"
const NATURE_DIR := "res://assets/models/nature/"
const BUILDINGS := ["A", "B", "C", "D", "E", "F", "G", "H"]
const CARS := ["car_taxi", "car_sedan", "car_hatchback", "car_stationwagon"]
const PALMS := ["ExoticPalmDefalt", "ExoticPalmOld", "ExoticPalmCurve", "ExoticPalmYoung"]
const PALM_HEIGHT := 9.0      ## Hauteur voulue d'un palmier, en mètres.
const CAR_HEIGHT := 1.6
const LAMP_HEIGHT := 7.5

var _scrolling: Node3D        ## Tout ce qui défile est enfant de ce nœud.
var _cars: Array[Node3D] = []
var _car_speeds: Array[float] = []
var _bounds := {}             ## Taille de chaque modèle, mesurée une seule fois.
var _window_mesh: QuadMesh
var _window_mats: Array[StandardMaterial3D] = []
var _wall_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_window_mesh = QuadMesh.new()
	_window_mesh.size = Vector2(0.6, 0.75)
	for c in [Color(1.0, 0.72, 0.35), Color(1.0, 0.85, 0.55), Color(0.7, 0.85, 1.0), Color(1.0, 0.55, 0.25)]:
		_window_mats.append(Fx.mat(c, 2.5))
	for c in [Color(0.16, 0.12, 0.1), Color(0.12, 0.12, 0.15), Color(0.2, 0.15, 0.1), Color(0.1, 0.1, 0.12)]:
		_wall_mats.append(Fx.mat(c))

	_scrolling = Node3D.new()
	add_child(_scrolling)

	_build_environment()
	_build_sky()
	_build_ground()
	_build_skyline()
	for side in [-1.0, 1.0]:
		_building_row(side, FRONT_ROW_X, Vector2(7, 13), true)
		_building_row(side, BACK_ROW_X, Vector2(14, 30), false)
		_street_furniture(side)
	_road_markings()
	_build_cars()


## Vue de côté : la caméra est du côté x > 0, on cache ce qui lui boucherait la vue.
func set_side_view(on: bool) -> void:
	for child in _scrolling.get_children():
		(child as Node3D).visible = not (on and (child as Node3D).position.x > 0.0)


func _process(delta: float) -> void:
	var span := NEAR_Z - FAR_Z
	var step := GameConfig.SCROLL_SPEED * delta
	for child in _scrolling.get_children():
		var n := child as Node3D
		n.position.z += step
		if n.position.z > NEAR_Z:
			n.position.z -= span
	for i in _cars.size():
		var m := _cars[i]
		m.position.z += (_car_speeds[i] + GameConfig.SCROLL_SPEED) * delta
		if m.position.z > NEAR_Z:
			m.position.z -= span
		elif m.position.z < FAR_Z:
			m.position.z += span


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.01, 0.015, 0.05)
	sky_mat.sky_horizon_color = Color(0.2, 0.09, 0.13)   # lueur orangée de la ville
	sky_mat.ground_horizon_color = Color(0.2, 0.09, 0.13)
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
	# Brume de nuit : les esprits sortent du fond de l'avenue.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.13, 0.08, 0.16)
	env.fog_density = 1.0
	env.fog_depth_begin = 35.0
	env.fog_depth_end = 290.0
	env.fog_depth_curve = 1.4
	env.fog_sky_affect = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var moonlight := DirectionalLight3D.new()
	moonlight.light_color = Color(0.6, 0.7, 1.0)
	moonlight.light_energy = 0.45
	moonlight.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
	moonlight.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(moonlight)


func _build_sky() -> void:
	Fx.mesh(self, Fx.sphere(20.0, 32), Fx.mat(Color(0.95, 0.92, 0.8), 2.0, false, true), Vector3(90, 110, -480))

	var stars := MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.mesh = Fx.sphere(0.5, 6)
	stars.instance_count = 400
	for i in stars.instance_count:
		var basis := Basis().scaled(Vector3.ONE * randf_range(0.5, 1.6))
		var pos := Vector3(randf_range(-700, 700), randf_range(40, 500), randf_range(-560, -500))
		stars.set_instance_transform(i, Transform3D(basis, pos))
	var stars_node := MultiMeshInstance3D.new()
	stars_node.multimesh = stars
	stars_node.material_override = Fx.mat(Color(0.9, 0.92, 1.0), 3.0, false, true)
	add_child(stars_node)


func _build_ground() -> void:
	var y := GameConfig.GROUND_Y
	var ground := PlaneMesh.new()
	ground.size = Vector2(900, 900)
	Fx.mesh(self, ground, Fx.mat(Color(0.05, 0.04, 0.045)), Vector3(0, y - 0.02, -300))
	var laterite := PlaneMesh.new()   # bas-côtés en terre rouge
	laterite.size = Vector2((FRONT_ROW_X) * 2.0, 900)
	Fx.mesh(self, laterite, Fx.mat(Color(0.32, 0.12, 0.05)), Vector3(0, y, -300))
	var road := PlaneMesh.new()
	road.size = Vector2(ROAD_HALF * 2.0, 900)
	Fx.mesh(self, road, Fx.mat(Color(0.09, 0.09, 0.1)), Vector3(0, y + 0.01, -300))


## Ligne des toits au loin, immobile : donne l'horizon de la ville.
func _build_skyline() -> void:
	var mat := Fx.mat(Color(0.06, 0.06, 0.1))
	for i in 70:
		var w := randf_range(12, 30)
		var h := randf_range(15, 60)
		var b := _building(w, h, 15.0, mat, 0.06, false)
		b.position = Vector3(randf_range(-320, 320), GameConfig.GROUND_Y, randf_range(-360, -330))
		add_child(b)


## Taille d'un modèle (mesurée une fois, puis gardée).
func _box_of(path: String) -> AABB:
	if not _bounds.has(path):
		var model := Models.load_scene(path)
		_bounds[path] = Models.bounds(model)
		model.free()
	return _bounds[path]


## Un modèle mis à l'échelle et posé dans un pivot, que l'appelant place ensuite.
##   "centre"  : centré en x et z, base au sol (voitures)
##   "facade"  : centré en x, façade (z max) à l'origine du pivot, base au sol (immeubles)
##   "origine" : l'origine du modèle sert de pied (palmiers, lampadaires)
func _place(path: String, scale: float, mode := "centre") -> Node3D:
	var pivot := Node3D.new()
	var model := Models.load_scene(path)
	model.scale = Vector3.ONE * scale
	var box := _box_of(path)
	var cx := box.position.x + box.size.x / 2.0
	var cz := box.position.z + box.size.z / 2.0
	match mode:
		"facade":
			model.position = Vector3(-cx, -box.position.y, -(box.position.z + box.size.z)) * scale
		"origine":
			model.position = Vector3.ZERO
		_:
			model.position = Vector3(-cx, -box.position.y, -cz) * scale
	pivot.add_child(model)
	return pivot


## Une rangée d'immeubles le long de l'avenue. side = -1 à gauche, +1 à droite.
## Chaque immeuble est un modèle choisi au hasard, agrandi jusqu'à une hauteur tirée dans `height`.
func _building_row(side: float, x_front: float, height: Vector2, with_monument: bool) -> void:
	var z := FAR_Z
	var index := 0
	while z < NEAR_Z:
		if with_monument and side < 0.0 and index == 6:
			# Place de l'Étoile Rouge : une trouée dans la rangée de gauche.
			var monument := _red_star_monument()
			monument.position = Vector3(side * (x_front + 6.0), GameConfig.GROUND_Y, z + 15.0)
			_scrolling.add_child(monument)
			z += 30.0
		else:
			var path: String = CITY_DIR + "building_%s_withoutBase.gltf" % BUILDINGS.pick_random()
			var box := _box_of(path)
			var scale := randf_range(height.x, height.y) / box.size.y
			var width := box.size.x * scale
			var b := _place(path, scale, "facade")
			# La façade regarde vers +Z dans le modèle : on la tourne vers la route.
			b.rotation.y = -side * PI / 2.0
			b.position = Vector3(side * x_front, GameConfig.GROUND_Y, z + width / 2.0)
			Models.light_windows(b)
			_scrolling.add_child(b)
			z += width + randf_range(0.3, 2.0)
		index += 1


## Un immeuble, façade vers +Z, posé au sol.
func _building(w: float, h: float, d: float, wall: Material, window_chance: float, shops: bool) -> Node3D:
	var b := Node3D.new()
	Fx.mesh(b, Fx.box(Vector3(w, h, d)), wall, Vector3(0, h / 2.0, 0))

	var cols := int(w / 1.6)
	var floors := int((h - 1.5) / 2.0)
	var margin := (w - cols * 1.6) / 2.0
	for f in floors:
		for c in cols:
			if randf() < window_chance:
				var pos := Vector3(-w / 2.0 + margin + 0.8 + c * 1.6, 2.6 + f * 2.0, d / 2.0 + 0.02)
				Fx.mesh(b, _window_mesh, _window_mats.pick_random(), pos)

	# Réservoir d'eau sur le toit, très courant à Cotonou.
	if randf() < 0.45:
		Fx.mesh(b, Fx.cylinder(0.6, 0.6, 1.2), Fx.mat(Color(0.12, 0.12, 0.14)),
				Vector3(randf_range(-w / 3.0, w / 3.0), h + 0.6, 0))

	# Enseigne lumineuse de boutique au rez-de-chaussée.
	if shops and randf() < 0.65:
		var colors := [Color(1.0, 0.85, 0.1), Color(0.1, 0.8, 0.3), Color(0.9, 0.15, 0.15), Color(0.2, 0.5, 1.0)]
		Fx.mesh(b, Fx.box(Vector3(w * 0.6, 0.7, 0.1)), Fx.mat(colors.pick_random(), 2.0),
				Vector3(0, 2.8, d / 2.0 + 0.1))
	return b


## La Place de l'Étoile Rouge : une colonne surmontée d'une étoile rouge.
func _red_star_monument() -> Node3D:
	var m := Node3D.new()
	var stone := Fx.mat(Color(0.55, 0.5, 0.45))
	Fx.mesh(m, Fx.box(Vector3(6, 1.2, 6)), stone, Vector3(0, 0.6, 0))
	Fx.mesh(m, Fx.cylinder(0.6, 0.9, 16, 16), stone, Vector3(0, 9.2, 0))
	var star := Node3D.new()
	star.position = Vector3(0, 19.5, 0)
	star.rotation.y = PI / 2.0   # face à l'avenue
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
	glow.light_energy = 5.0
	glow.omni_range = 22.0
	star.add_child(glow)
	return m


## Lampadaires et palmiers en alternance au bord de la route.
func _street_furniture(side: float) -> void:
	var z := FAR_Z + (0.0 if side < 0.0 else 10.0)
	var lamp := true
	while z < NEAR_Z:
		var item := Node3D.new()
		_scrolling.add_child(item)
		if lamp:
			item.position = Vector3(side * (ROAD_HALF + 1.5), GameConfig.GROUND_Y, z)
			var path := CITY_DIR + "streetlight.gltf"
			var post := _place(path, LAMP_HEIGHT / _box_of(path).size.y, "origine")
			# Le bras du lampadaire part vers -X dans le modèle : on le tourne vers la route.
			post.rotation.y = PI if side < 0.0 else 0.0
			item.add_child(post)
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.62, 0.3)
			light.light_energy = 3.0
			light.omni_range = 11.0
			light.position = Vector3(-side * 1.6, LAMP_HEIGHT * 0.9, 0)
			item.add_child(light)
			# Ampoule visible au bout du bras.
			Fx.mesh(item, Fx.sphere(0.3, 10), Fx.mat(Color(1.0, 0.7, 0.35), 5.0), Vector3(-side * 1.6, LAMP_HEIGHT * 0.93, 0))
		else:
			item.position = Vector3(side * (ROAD_HALF + 3.2), GameConfig.GROUND_Y, z)
			var path: String = NATURE_DIR + PALMS.pick_random() + ".fbx"
			var palm := _place(path, PALM_HEIGHT / _box_of(path).size.y, "origine")
			palm.rotation.y = randf() * TAU
			item.add_child(palm)
		lamp = not lamp
		z += 12.0


func _road_markings() -> void:
	var paint := Fx.mat(Color(0.75, 0.75, 0.65), 0.4)
	var z := FAR_Z
	while z < NEAR_Z:
		var dash := Fx.mesh(_scrolling, Fx.box(Vector3(0.18, 0.02, 2.5)), paint, Vector3(0, GameConfig.GROUND_Y + 0.03, z))
		dash.position.z = z
		z += 7.0


## Voitures sur la route, dans les deux sens : la moitié s'éloigne, l'autre vient vers nous.
func _build_cars() -> void:
	for i in 10:
		var away := i % 2 == 0
		var path: String = CITY_DIR + CARS.pick_random() + ".gltf"
		var car := _place(path, CAR_HEIGHT / _box_of(path).size.y, "centre")
		# Le devant de la voiture est à +Z dans le modèle : on la tourne dans le sens de la marche.
		car.rotation.y = PI if away else 0.0
		car.position = Vector3(1.8 if away else -1.8, GameConfig.GROUND_Y, randf_range(FAR_Z, 0.0))
		add_child(car)
		_cars.append(car)
		var speed := randf_range(8.0, 14.0)
		_car_speeds.append(-speed if away else speed)
