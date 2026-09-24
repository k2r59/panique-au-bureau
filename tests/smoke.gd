extends SceneTree
var failures := 0
var game: Control
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + name + ".png")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	# Preserve the player's save data during the smoke test.
	var old_records: Array = game.records.duplicate(true)
	var old_record: int = game.record
	var old_name: String = game.player_name
	var old_avatar: int = game.player_avatar
	game.records = []
	game.record = 0
	game.player_name = ""
	await snap("home")
	game._primary()
	check(game.screen == "profile", "Play opens required nickname view")
	game.name_input.text = " "
	game._submit_name()
	check(game.screen == "profile" and not game.name_error.is_empty(), "Blank nickname rejected")
	game.name_input.text = "Camille"
	game.name_input.text_changed.emit("Camille")
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = game.fit_offset + Vector2(290, 610) * game.fit_scale
	game._input(press)
	var drag := InputEventMouseMotion.new()
	drag.position = game.fit_offset + Vector2(80, 610) * game.fit_scale
	game._input(drag)
	check(game.avatar_scroll.scroll_horizontal > 150, "Avatar carousel moves horizontally on drag")
	press.pressed = false
	press.position = drag.position
	var avatar_before: int = game.player_avatar
	game._input(press)
	check(game.player_avatar == avatar_before, "Dragging does not accidentally select an avatar")
	game.avatar_buttons[4].pressed.emit()
	check(game.player_avatar == 5, "Avatar button selects portrait")
	await snap("profile")
	game._submit_name()
	check(game.player_name == "Camille", "Nickname accepted")
	check(game.countdown == 3 and game.screen == "game", "Start opens countdown")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.round_model.paused, "Focus loss pauses countdown")
	game._primary()
	check(not game.round_model.paused, "Countdown can resume")
	game._process(3.1)
	check(game.countdown == 0 and game.cell_buttons[0].visible, "Countdown unlocks board")
	for i in range(6):
		game.round_model.targets[i] = {"name": ["ghost", "candy", "zombie", "colleague", "vampire", "pumpkin"][i], "born": -1, "expires": 2}
	await snap("game")
	game.cell_buttons[0].pressed.emit()
	check(game.round_model.score == 50, "Button scores")
	game._pause()
	var before: float = game.round_model.remaining
	game._process(5)
	check(game.round_model.remaining == before, "Pause freezes time")
	await snap("pause")
	game._pause()
	game._process(60)
	check(game.screen == "results" and game.records.size() > 0, "Results save a finished round")
	game.result_age = 2
	await snap("results")
	game.records.clear()
	game._load_save()
	check(game.records.any(func(e): return e.score == 50 and e.avatar == 5), "Score retains chosen avatar after reload")
	check(game.player_avatar == 5, "Selected avatar preference survives reload")
	game.screen = "home"
	game._primary()
	check(game.screen == "game" and game.player_name == "Camille" and game.player_avatar == 5, "Saved profile skips setup on subsequent play")
	game.player_name = "Camille"
	game.round_model.score = 25
	game._finish()
	check(game._personal_record() == 50, "A lower score cannot replace a personal best")
	check(game.records.filter(func(e): return e.get("name", "") == "Camille").size() == 1, "One leaderboard row per player")
	game.player_name = "Alex"
	check(game._personal_record() == 0, "Personal best does not leak between players")
	game.round_model.score = 100
	game._finish()
	check(game._personal_record() == 100 and game.records[0].name == "Alex", "Leaderboard orders players by best score")
	game.records = old_records
	game.record = old_record
	game.player_name = old_name
	game.player_avatar = old_avatar
	game._save()
	game._start_game()
	check(game.round_model.score == 0 and game.round_model.combo == 1, "Replay resets round")
	print("Scene smoke tests: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
