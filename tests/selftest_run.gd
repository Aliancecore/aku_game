extends SceneTree
## Test de l'atterrissage et du décollage. Lancer :
##   godot-4 --headless --path . --script res://tests/selftest_run.gd

var game
var witch
var step := 0
var wait_until := 0.0
var failures := 0


func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)


func _now() -> float:
	return witch._time


func _check(label: String, ok: bool) -> void:
	print(("OK     " if ok else "ECHEC  "), label, "   (mode=", witch.mode, " y=", snappedf(witch.position.y, 0.01), ")")
	if not ok:
		failures += 1


func _tap_up() -> void:
	Input.action_press("move_up")
	await physics_frame
	await physics_frame
	Input.action_release("move_up")


func _process(_delta: float) -> bool:
	if witch == null:
		witch = game.witch   # la scène est prête après la première image
		return false
	if _now() < wait_until:
		return false
	match step:
		0:
			game._start_game()
			_check("au départ : en vol", witch.mode == Witch.Mode.FLYING)
			Input.action_press("move_down")
			wait_until = _now() + 1.5
		1:
			Input.action_release("move_down")
			_check("en descendant vers le sol : elle court", witch.mode == Witch.Mode.RUNNING)
			_check("elle est posée au sol", is_equal_approx(witch.position.y, GameConfig.RUN_Y))
			wait_until = _now() + 0.5
		2:
			_tap_up()
			wait_until = _now() + 0.2
		3:
			_check("un seul appui : elle continue de courir", witch.mode == Witch.Mode.RUNNING)
			wait_until = _now() + 0.8
		4:
			_tap_up()
			wait_until = _now() + 0.8
		5:
			_check("deux appuis trop espacés : elle court toujours", witch.mode == Witch.Mode.RUNNING)
			_tap_up()
			wait_until = _now() + 0.15
		6:
			_tap_up()
			wait_until = _now() + 0.1
		7:
			_check("deux appuis rapides : elle décolle", witch.mode == Witch.Mode.TAKING_OFF or witch.mode == Witch.Mode.FLYING)
			wait_until = _now() + 1.0
		8:
			_check("elle vole de nouveau", witch.mode == Witch.Mode.FLYING)
			_check("à la hauteur de décollage", is_equal_approx(witch.position.y, GameConfig.TAKEOFF_Y))
			wait_until = _now() + 0.3
		9:
			print("---- ", "TOUS LES TESTS PASSENT" if failures == 0 else "%d ECHEC(S)" % failures)
			quit()
	step += 1
	return false
