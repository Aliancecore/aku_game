extends SceneTree
## Test : rejouer avec Entrée après un Game Over ne doit produire aucune erreur. Lancer :
##   godot-4 --headless --path . --script res://tests/selftest_restart.gd 2>&1 | grep -c ERROR
## Le résultat doit être 0.

var game
var frames := 0


func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		game._start_game()
		game.lives = 1
		game._hurt_player()
		print("état après la dernière vie perdue : ", game.state, " (GAME_OVER = ", game.State.GAME_OVER, ")")
	elif frames == 10:
		Input.action_press("start")
	elif frames == 12:
		Input.action_release("start")
	elif frames == 30:
		print("scène rechargée : ", current_scene != game and current_scene != null)
		quit()
	return false
