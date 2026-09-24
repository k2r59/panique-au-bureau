extends SceneTree
const Model = preload("res://scripts/round.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var game = Model.new()
	game.start()
	check(game.remaining == 60 and game.score == 0 and game.targets.size() == 9, "Fresh round")
	for i in range(3):
		game.targets[0] = {"name": "ghost", "born": 0, "expires": 3}
		game.hit(0)
	check(game.score == 150 and game.combo == 2, "Three hits unlock combo 2")
	game.targets[0] = {"name": "candy", "born": 0, "expires": 3}
	game.hit(0)
	check(game.score == 350, "Candy multiplies base points")
	check(game.hit(0).is_empty() and game.score == 350, "Cannot hit twice")
	game.targets[0] = {"name": "colleague", "born": 0, "expires": 3}
	game.hit(0)
	check(game.score == 250 and game.combo == 1 and game.mistakes == 1, "Trap penalty")
	game.paused = true
	game.advance(15)
	check(game.remaining == 60, "Pause freezes clock")
	game.targets[0] = {"name": "ghost", "born": 0, "expires": 3}
	check(game.hit(0).is_empty(), "Cannot hit during pause")
	game.paused = false
	game.combo = 4
	game.advance(3.1)
	check(game.combo == 1 and game.missed == 1, "Missed monster resets combo")
	check(game.advance(60), "Round ends")
	check(game.remaining == 0 and not game.playing and game.hit(0).is_empty(), "No scoring after end")
	game.start()
	for i in range(20):
		game.targets[0] = {"name": "ghost", "born": 0, "expires": 3}
		game.hit(0)
	check(game.combo == 5 and game.best_combo == 5, "Combo capped at five")
	game.start()
	game.targets[0] = {"name": "pumpkin", "born": 0, "expires": 3}
	game.hit(0)
	check(game.score == 0, "Score cannot go negative")
	game.start()
	game.spawn_in = 10
	game.targets[0] = {"name": "ghost", "born": 0, "expires": 2}
	game.hit(0)
	check(game.targets[0].has("leaving"), "Hit character stays visible while descending")
	check(game.hit(0).is_empty(), "Descending character cannot score twice")
	game.advance(0.12)
	check(not game.targets[0].is_empty(), "Character remains during exit animation")
	game.advance(0.13)
	check(game.targets[0].is_empty(), "Desk becomes available after descent")
	game.targets[1] = {"name": "zombie", "born": 0, "expires": game.elapsed}
	game.advance(0.01)
	check(game.targets[1].has("leaving") and game.missed == 1, "Expired character descends and counts one miss")
	game.advance(0.3)
	check(game.targets[1].is_empty() and game.missed == 1, "Exit completion does not count a second miss")
	game.start()
	game.rng.seed = 42
	for i in range(3600):
		game.advance(1.0 / 60.0)
		check(game.targets.size() == 9, "Board remains bounded")
	print("Round tests: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
