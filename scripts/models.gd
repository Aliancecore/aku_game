class_name Models
extends RefCounted
## Chargement des modèles 3D (glTF / FBX) du dossier assets/models, de leurs animations,
## et petites retouches de matériau (texture de remplacement, lueur d'esprit).
## Les modèles viennent de packs libres CC0 : voir assets/CREDITS.md.

const MAGE := "res://assets/models/characters/Mage.glb"
const WITCH_TEXTURE := "res://assets/models/characters/witch_palette.png"
const CITY_EMISSION := "res://assets/models/city/citybits_emission.png"
const GHOST_SHADER := "res://shaders/ghost.gdshader"
const CITY_SHADER := "res://shaders/city_night.gdshader"

static var _cache := {}   ## Matériaux retouchés, partagés entre toutes les instances.


static func load_scene(path: String) -> Node3D:
	var packed: PackedScene = load(path)
	return packed.instantiate() as Node3D


static func animation_player(node: Node) -> AnimationPlayer:
	var found := node.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if not found.is_empty() else null


## Joue une animation du modèle, en boucle par défaut. Renvoie le lecteur (ou null s'il n'y en a pas).
static func play(node: Node, anim: String, looped := true, speed := 1.0) -> AnimationPlayer:
	var player := animation_player(node)
	if player == null or not player.has_animation(anim):
		push_warning("Animation introuvable : %s" % anim)
		return player
	player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
	player.speed_scale = speed
	player.play(anim)
	return player


## Taille du modèle (boîte englobante de ses maillages), dans son propre repère.
static func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var a := m.get_aabb()
		# Position du maillage par rapport au modèle (le modèle n'est pas encore forcément dans l'arbre).
		var t := Transform3D.IDENTITY
		var n: Node = m
		while n != null and n != node:
			if n is Node3D:
				t = (n as Node3D).transform * t
			n = n.get_parent()
		a = t * a
		result = a if first else result.merge(a)
		first = false
	return result


## Cache un nœud du modèle par son nom (ex. les accessoires du mage qu'on ne veut pas voir).
static func hide(node: Node, node_name: String) -> void:
	var target := node.find_child(node_name, true, false)
	if target is Node3D:
		(target as Node3D).visible = false


## Remplace la texture de tous les matériaux du modèle par une autre (ex. une palette recolorée).
static func retexture(node: Node, texture_path: String) -> void:
	var texture: Texture2D = load(texture_path)
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var base := m.get_active_material(s) as StandardMaterial3D
			if base == null:
				continue
			var key := [base, texture_path]
			if not _cache.has(key):
				var copy := base.duplicate() as StandardMaterial3D
				copy.albedo_texture = texture
				_cache[key] = copy
			m.set_surface_override_material(s, _cache[key])


## Donne au modèle une lueur d'esprit : sa texture d'origine, teintée et éclairée de l'intérieur.
## Renvoie les matériaux, pour pouvoir faire varier la lueur (paramètre "glow").
## (Un shader à nous : l'émission par texture d'un StandardMaterial3D éclairait tout en blanc ici.)
static func ghostify(node: Node, color: Color, glow: float) -> Array[ShaderMaterial]:
	var materials: Array[ShaderMaterial] = []
	var shader: Shader = load(GHOST_SHADER)
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var base := m.get_active_material(s) as StandardMaterial3D
			if base == null:
				continue
			var key := [base, color, glow]
			if not _cache.has(key):
				var material := ShaderMaterial.new()
				material.shader = shader
				material.set_shader_parameter("albedo_tex", base.albedo_texture)
				material.set_shader_parameter("tint", color)
				material.set_shader_parameter("glow", glow)
				_cache[key] = material
			m.set_surface_override_material(s, _cache[key])
			materials.append(_cache[key])
	return materials


## Allume les fenêtres des bâtiments de la ville la nuit, grâce à un masque d'émission.
static func light_windows(node: Node) -> void:
	var shader: Shader = load(CITY_SHADER)
	var mask: Texture2D = load(CITY_EMISSION)
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		for s in m.mesh.get_surface_count():
			var base := m.get_active_material(s) as StandardMaterial3D
			if base == null:
				continue
			var key := [base, "fenetres"]
			if not _cache.has(key):
				var material := ShaderMaterial.new()
				material.shader = shader
				material.set_shader_parameter("albedo_tex", base.albedo_texture)
				material.set_shader_parameter("window_mask", mask)
				_cache[key] = material
			m.set_surface_override_material(s, _cache[key])
