class_name Enemy
extends Node3D
## Ce que tous les esprits ont en commun : santé, taille de collision, points rapportés.
## Les esprits sont dans le groupe "enemies" ; game.gd gère les collisions.

var game                    ## Le nœud principal (game.gd), pour tirer.
var health := 1
var max_health := 1
var radius := 1.0
var score := 100
var drop_chance := 0.0      ## Probabilité de lâcher un bonus quand il est vaincu.
var color := Color.WHITE


## Retire des points de vie. Renvoie true si l'esprit est vaincu.
func take_damage(amount: int) -> bool:
	health -= amount
	_on_damaged()
	return health <= 0


func _on_damaged() -> void:
	pass
