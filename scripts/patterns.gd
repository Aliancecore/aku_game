class_name Patterns
extends RefCounted
## Trajectoires des esprits, comme LinearPattern / SinePattern du R-Type :
## la position dépend seulement du point de départ et du temps écoulé.


static func compute(pattern: String, origin: Vector3, elapsed: float, speed: float) -> Vector3:
	var x := origin.x - speed * elapsed
	match pattern:
		"sine":
			var angle := TAU * GameConfig.SINE_FREQUENCY * elapsed
			return Vector3(x, origin.y + GameConfig.SINE_AMPLITUDE * sin(angle), 0.0)
		"zigzag":
			# Onde triangulaire : monte et descend en ligne droite.
			var tri := (2.0 / PI) * asin(sin(TAU * GameConfig.SINE_FREQUENCY * elapsed))
			return Vector3(x, origin.y + GameConfig.ZIGZAG_AMPLITUDE * tri, 0.0)
		_:
			return Vector3(x, origin.y, 0.0)
