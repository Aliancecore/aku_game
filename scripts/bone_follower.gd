class_name BoneFollower
extends Node3D
## Un nœud qui suit un os d'un squelette (la tête pour un chapeau, la main pour un balai).
## Il prend la position et l'orientation de l'os, sans son échelle : on le dimensionne donc en mètres.
## (Les modèles FBX ont un squelette à l'échelle ×100 : un BoneAttachment3D agrandirait tout ce qu'on lui accroche.)

var skeleton: Skeleton3D
var bone := -1


func setup(p_skeleton: Skeleton3D, bone_name: String) -> BoneFollower:
	skeleton = p_skeleton
	bone = p_skeleton.find_bone(bone_name)
	process_priority = 100   # après l'animation, pour ne pas traîner d'une image
	if bone < 0:
		push_warning("Os introuvable : %s" % bone_name)
	return self


func _process(_delta: float) -> void:
	if skeleton == null or bone < 0:
		return
	var t := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	global_transform = Transform3D(t.basis.orthonormalized(), t.origin)
