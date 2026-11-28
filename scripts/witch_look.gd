class_name WitchLook
extends RefCounted
## L'apparence de la sorcière : une femme animée (Quaternius, CC0) à la peau foncée, en robe wax,
## avec chapeau pointu, foulard qui flotte, balai et chat noir. Voir assets/CREDITS.md.
## Tout est en mètres ; les modèles FBX sont mis à l'échelle ici.

const WOMAN := "res://assets/models/witch/Woman_Run.fbx"
const CAT := "res://assets/models/witch/Cat.fbx"
const WAX_SHADER := "res://shaders/wax.gdshader"
const SCALE := 0.376           ## Le modèle fait 4,57 unités : à cette échelle, 1,72 m sans chapeau.
const SKIN := Color(0.27, 0.15, 0.09)
const HAIR := Color(0.04, 0.03, 0.03)
const SEAT := 0.41             ## Hauteur du balai quand elle est assise dessus.
const BROOM_Z := 0.2           ## Où le balai passe sous elle (assise, ses hanches sont 0,2 m derrière ses pieds).


## Un matériau wax. Le motif change avec les couleurs : robe bleu-vert à cercles orange, foulard orange...
static func wax(base: Color, a: Color, b: Color, c: Color, as_ribbon := false, wave := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(WAX_SHADER)
	m.set_shader_parameter("base", base)
	m.set_shader_parameter("ring_a", a)
	m.set_shader_parameter("ring_b", b)
	m.set_shader_parameter("ring_c", c)
	m.set_shader_parameter("use_uv", as_ribbon)
	m.set_shader_parameter("wave", wave)
	return m


## La femme, face à -Z (elle avance vers le fond de l'avenue), avec son animation.
## Renvoie un nœud dont les métadonnées donnent "model", "skeleton" et "player".
static func woman(animation: String, freeze_at := -1.0) -> Node3D:
	var holder := Node3D.new()
	var model := Models.load_scene(WOMAN)
	model.scale = Vector3.ONE * SCALE
	model.rotation.y = PI
	holder.add_child(model)
	Models.paint(model, {
		"Skin": SKIN,
		"Hair": HAIR,
		"Shoes": Color(0.10, 0.07, 0.05),
		"Dress": wax(Color(0.04, 0.28, 0.38), Color(0.97, 0.55, 0.08), Color(0.99, 0.85, 0.25), Color(0.84, 0.10, 0.14)),
	})
	var player := Models.play(model, animation)
	if freeze_at >= 0.0 and player != null:
		player.seek(freeze_at, true)   # une pose fixe : l'animation d'assise bouge ensuite de façon imprévisible
		player.pause()
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	holder.set_meta("model", model)
	holder.set_meta("skeleton", skeleton)
	holder.set_meta("player", Models.animation_player(model))
	# Chapeau sur la tête, foulard au cou.
	var head := BoneFollower.new().setup(skeleton, "Head")
	holder.add_child(head)
	head.add_child(hat())
	var neck := BoneFollower.new().setup(skeleton, "Neck")
	holder.add_child(neck)
	neck.add_child(scarf())
	return holder


## Le chapeau pointu, noir et or, un peu penché. Repère : l'origine est à la base de la tête, Y vers le haut.
static func hat() -> Node3D:
	var hat_root := Node3D.new()
	hat_root.rotation_degrees = Vector3(-8, 0, 0)    # légèrement en arrière
	var felt := Fx.mat(Color(0.07, 0.05, 0.14))
	var gold := Fx.mat(Color(0.95, 0.74, 0.18), 0.6)
	Fx.mesh(hat_root, Fx.cylinder(0.32, 0.32, 0.018, 12), felt, Vector3(0, 0.11, 0.02))        # le large bord
	Fx.mesh(hat_root, Fx.cylinder(0.075, 0.19, 0.36, 10), felt, Vector3(0, 0.30, 0.0))         # le cône
	var tip := Node3D.new()                                                                      # la pointe, recourbée
	tip.position = Vector3(0, 0.46, 0)
	tip.rotation_degrees = Vector3(-24, 0, 0)
	hat_root.add_child(tip)
	Fx.mesh(tip, Fx.cylinder(0.0, 0.078, 0.22, 10), felt, Vector3(0, 0.1, 0))
	Fx.mesh(hat_root, Fx.cylinder(0.205, 0.205, 0.05, 12), gold, Vector3(0, 0.15, 0.0))       # le ruban doré
	return hat_root


## Le foulard wax qui flotte derrière elle : il part du cou vers l'arrière, monte à peine et dérive sur le côté.
## Le ruban est tordu à 45° pour se voir aussi bien de dos (caméra 3D) que de côté (vue 2D).
static func scarf() -> Node3D:
	var anchor := Node3D.new()
	anchor.rotation_degrees = Vector3(-80, 28, 0)
	var ribbon := PlaneMesh.new()
	ribbon.size = Vector2(0.2, 0.95)
	ribbon.subdivide_depth = 14
	ribbon.orientation = PlaneMesh.FACE_Z
	var mi := Fx.mesh(anchor, ribbon, wax(Color(0.85, 0.30, 0.05), Color(0.99, 0.85, 0.25), Color(0.05, 0.40, 0.35), Color(0.1, 0.05, 0.2), true, 0.12),
			Vector3(0, 0.47, 0), Vector3(0, deg_to_rad(45), 0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return anchor


## Le balai : manche en bois, brins de paille, ruban doré et une petite lueur magique. Axe le long de Z.
## L'avant (la poignée) est du côté -Z, les brins du côté +Z.
static func broom() -> Node3D:
	var b := Node3D.new()
	var wood := Fx.mat(Color(0.45, 0.27, 0.12))
	var straw := Fx.mat(Color(0.86, 0.66, 0.30))
	var dark := Fx.mat(Color(0.55, 0.38, 0.16))
	var gold := Fx.mat(Color(0.95, 0.74, 0.18), 0.6)
	Fx.mesh(b, Fx.cylinder(0.028, 0.028, 1.9, 6), wood, Vector3(0, 0, -0.1), Vector3(PI / 2.0, 0, 0))     # le manche
	Fx.mesh(b, Fx.sphere(0.045, 6), wood, Vector3(0, 0, -1.05))                                           # le bout du manche
	Fx.mesh(b, Fx.cylinder(0.035, 0.15, 0.55, 8), straw, Vector3(0, 0, 1.12), Vector3(-PI / 2.0, 0, 0))   # les brins
	Fx.mesh(b, Fx.cylinder(0.05, 0.16, 0.12, 8), dark, Vector3(0, 0, 1.42), Vector3(-PI / 2.0, 0, 0))     # le bout des brins
	Fx.mesh(b, Fx.cylinder(0.04, 0.04, 0.09, 8), gold, Vector3(0, 0, 0.86), Vector3(PI / 2.0, 0, 0))      # le ruban doré
	Fx.mesh(b, Fx.sphere(0.07, 8), Fx.mat(Color(0.6, 0.35, 1.0), 4.0), Vector3(0, 0, -1.0))              # lueur violette à l'avant
	return b


## Le chat noir, avec ses yeux verts lumineux. Il regarde vers -Z, debout sur ses quatre pattes (pieds à l'origine).
static func cat() -> Node3D:
	var holder := Node3D.new()
	var model := Models.load_scene(CAT)
	model.scale = Vector3.ONE * 0.125          # 4 unités de long -> 50 cm
	model.rotation.y = PI / 2.0                # le chat regarde vers +X dans le modèle : on le tourne vers -Z
	holder.add_child(model)
	Models.paint(model, {
		"Grey": Color(0.03, 0.03, 0.04),
		"White": Color(0.07, 0.07, 0.09),
		"Pink": Color(0.50, 0.18, 0.42),
	})
	Models.play(model, "CatArmature|Idle")
	# Les yeux : deux petites billes vertes qui brillent, placées sur la tête (en unités du modèle).
	var eye := Fx.mat(Color(0.35, 1.0, 0.45), 5.0)
	for side in [-1.0, 1.0]:
		Fx.mesh(model, Fx.sphere(0.12, 6), eye, Vector3(3.05, 2.95, side * 0.2))
	return holder


## Elle assise sur son balai, avec le chat derrière elle : l'apparence en vol. Origine : à ses pieds.
static func riding() -> Node3D:
	var rider := woman("HumanArmature|Female_Sitting", 0.35)
	var b := broom()
	b.position = Vector3(0, SEAT, BROOM_Z)
	rider.add_child(b)
	var c := cat()
	c.position = Vector3(0, SEAT + 0.03, BROOM_Z + 0.55)
	rider.add_child(c)
	return rider


## Elle qui court, le balai en bandoulière dans le dos. Origine : à ses pieds.
static func running() -> Node3D:
	var runner := woman("HumanArmature|Female_Run")
	var skeleton := runner.get_meta("skeleton") as Skeleton3D
	var back := BoneFollower.new().setup(skeleton, "Torso")
	runner.add_child(back)
	var b := broom()
	b.scale = Vector3.ONE * 0.8
	b.position = Vector3(0.0, 0.0, -0.1)
	# Le balai passe en diagonale dans le dos : manche vers le haut et le côté, brins en bas de l'autre côté.
	# Un nœud pour l'inclinaison, un autre pour mettre le balai en travers : manche vers le haut et le côté.
	var tilt := Node3D.new()
	tilt.rotation_degrees = Vector3(0, 0, 38)
	var across := Node3D.new()
	across.rotation_degrees = Vector3(0, 90, 0)
	across.add_child(b)
	tilt.add_child(across)
	back.add_child(tilt)
	return runner
