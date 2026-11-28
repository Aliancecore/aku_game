extends SceneTree
## Test des collisions avec les obstacles du sol et du saut. Lancer :
##   godot-4 --headless --path . --script res://tests/selftest_obstacles.gd 2>&1 | grep -E "OK|ECHEC|TOUS"
## On pose une vraie voiture de la ville sur la sorcière et on regarde si une vie est perdue.

var game
var witch
var city
var failures := 0


func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_run()


func _check(label: String, ok: bool) -> void:
	print(("OK     " if ok else "ECHEC  "), label, "   (vies=", game.lives, " pieds=", snappedf(witch.feet_y() - GameConfig.GROUND_Y, 0.01), " m)")
	if not ok:
		failures += 1


## Pose la première voiture de la ville exactement sur la sorcière.
func _put_car_on_witch() -> void:
	var car: Node3D = city._cars[0]
	car.position = Vector3(witch.position.x, GameConfig.GROUND_Y, witch.position.z)


func _run() -> void:
	await process_frame
	await process_frame
	witch = game.witch
	city = game._city
	game._start_game()
	game.set_physics_process(false)   # on gèle le jeu et la ville : on contrôle la scène à la main
	city.set_process(false)

	witch.start_running()
	await physics_frame
	_check("la sorcière mesure 1,9 m et la voiture 1,6 m (taille réaliste)", absf(Models.bounds(Models.load_scene(Models.MAGE)).size.y * Witch.MODEL_SCALE - 1.9) < 0.1)

	# 1. À pied, au sol : la voiture la renverse.
	var lives0: int = game.lives
	_put_car_on_witch()
	game._check_obstacles()
	_check("à pied, une voiture la renverse : -1 vie", game.lives == lives0 - 1)

	# 2. Juste après : elle est invincible quelques secondes, pas de second coup.
	game._check_obstacles()
	_check("invincible après le choc : pas de second coup", game.lives == lives0 - 1)

	# 3. Elle saute : au sommet, la voiture passe dessous.
	witch.invincible = 0.0
	witch.start_jump()
	var guard := 0
	while witch.jump_height() < 2.0 and guard < 120:
		await physics_frame
		guard += 1
	var lives1: int = game.lives
	_put_car_on_witch()
	game._check_obstacles()
	_check("en plein saut (%.1f m) : elle passe par-dessus la voiture" % witch.jump_height(), game.lives == lives1)

	# 4. Une fois retombée, la même voiture la renverse de nouveau.
	guard = 0
	while witch.is_jumping() and guard < 120:
		await physics_frame
		guard += 1
	witch.invincible = 0.0
	_put_car_on_witch()
	game._check_obstacles()
	_check("retombée au sol : la voiture la renverse", game.lives == lives1 - 1)

	# 5. En vol, elle passe très haut au-dessus des voitures.
	witch.invincible = 0.0
	witch._set_mode(Witch.Mode.FLYING, false)
	witch.position.y = 0.5
	var lives2: int = game.lives
	_put_car_on_witch()
	game._check_obstacles()
	_check("en vol : les voitures ne la touchent pas", game.lives == lives2)

	# 6. Une voiture à côté d'elle ne la touche pas (en vue 3D).
	witch.start_running()
	await physics_frame
	witch.invincible = 0.0
	var car: Node3D = city._cars[0]
	car.position = Vector3(witch.position.x + 3.0, GameConfig.GROUND_Y, witch.position.z)
	game._check_obstacles()
	_check("une voiture 3 m à côté : pas de choc", game.lives == lives2)

	# 7. En vue 2D la profondeur est ignorée : la même voiture la touche.
	game._set_side_view(true, false)
	car.position = Vector3(witch.position.x + 3.0, GameConfig.GROUND_Y, witch.position.z)
	game._check_obstacles()
	_check("vue 2D : la voiture (voie de derrière) la touche quand même", game.lives == lives2 - 1)

	# 8. Les saut est assez haut pour passer une voiture : on le vérifie sur la courbe.
	var best := 0.0
	for i in 100:
		var t := GameConfig.JUMP_TIME * i / 99.0
		var g := 8.0 * GameConfig.JUMP_HEIGHT / (GameConfig.JUMP_TIME * GameConfig.JUMP_TIME)
		best = maxf(best, 4.0 * GameConfig.JUMP_HEIGHT / GameConfig.JUMP_TIME * t - 0.5 * g * t * t)
	_check("le saut monte à %.1f m, plus haut qu'une voiture (%.1f m)" % [best, City.CAR_HEIGHT], best > City.CAR_HEIGHT + 0.5)

	print("---- ", "TOUS LES TESTS PASSENT" if failures == 0 else "%d ECHEC(S)" % failures)
	quit()
