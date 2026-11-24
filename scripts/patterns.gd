class_name Patterns
extends RefCounted
## Trajectoires des esprits, comme LinearPattern / SinePattern du R-Type :
## la position dépend seulement du point de départ et du temps écoulé.
## Les esprits avancent vers la caméra (+Z) ; le pattern dessine leur mouvement en X/Y.


static func compute(pattern: String, origin: Vector3, t: float, speed: float) -> Vector3:
	var z := origin.z + speed * t
	var angle := TAU * GameConfig.SINE_FREQUENCY * t
	match pattern:
		"sine":
			return Vector3(origin.x + GameConfig.SINE_AMPLITUDE * sin(angle), origin.y, z)
		"zigzag":
			var tri := (2.0 / PI) * asin(sin(angle))
			return Vector3(origin.x, origin.y + GameConfig.ZIGZAG_AMPLITUDE * tri, z)
		"spiral":
			var r := GameConfig.SPIRAL_RADIUS
			return Vector3(origin.x + r * cos(angle), origin.y + r * sin(angle), z)
		"hover":
			return _hover(origin, t, speed)
		_:
			return Vector3(origin.x, origin.y, z)


## Arrive jusqu'à HOVER_Z, flotte devant la sorcière en tirant, puis fonce sur elle.
static func _hover(origin: Vector3, t: float, speed: float) -> Vector3:
	var arrival := (GameConfig.HOVER_Z - origin.z) / speed
	if t < arrival:
		return Vector3(origin.x, origin.y, origin.z + speed * t)
	var drift := Vector3(2.5 * sin((t - arrival) * 1.3), 1.2 * sin((t - arrival) * 2.1), 0.0)
	var z := GameConfig.HOVER_Z
	if t > arrival + GameConfig.HOVER_TIME:
		z += speed * 1.3 * (t - arrival - GameConfig.HOVER_TIME)
	return Vector3(origin.x, origin.y, z) + drift
