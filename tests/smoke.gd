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
	for cycle in range(5):
		game.name_input.grab_focus()
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.position = game.fit_offset + (game.name_input.position + game.name_input.size / 2) * game.fit_scale
		game._input(touch)
		check(game.name_input.has_focus(), "Touch inside nickname keeps focus")
		touch.position = game.fit_offset + Vector2(16, 240) * game.fit_scale
		game._input(touch)
		check(not game.name_input.has_focus(), "Touch outside nickname dismisses focus")
		check(game.name_input.text == "Camille" and game.screen == "profile", "Dismissal preserves nickname and profile screen")
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
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.round_model.paused, "Focus loss cannot pause the game")
	game._process(3.1)
	check(game.countdown == 0 and game.cell_buttons[0].visible, "Countdown unlocks board")
	for i in range(6):
		game.round_model.targets[i] = {"name": ["ghost", "candy", "zombie", "colleague", "vampire", "pumpkin"][i], "born": -1, "expires": 2}
	await snap("game")
	game.cell_buttons[0].pressed.emit()
	check(game.round_model.score == 50, "Button scores")
	var before: float = game.round_model.remaining
	for key in [KEY_P, KEY_ESCAPE]:
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = key
		game._input(event)
	game.last_frame_ms = Time.get_ticks_msec() - 5000
	game._process(0.016)
	check(game.round_model.remaining <= before - 5, "Elapsed background time counts; P and Escape cannot pause")
	game._process(60)
	check(game.screen == "results" and game.records.size() > 0, "Results save a finished round")
	game.result_age = 2
	await snap("results")
	var saved_ranking: Array = game.records.duplicate(true)
	game.records = []
	for i in range(20):
		game.records.append({"name": "Joueur %02d" % (i + 1), "avatar": i % 6 + 1, "score": 20000 - i * 100})
	game._sync_buttons()
	await process_frame
	await process_frame
	check(game.ranking_list.get_v_scroll_bar().visible, "Long ranking exposes scrollbar")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = game.fit_offset + Vector2(180, 510) * game.fit_scale
	Input.parse_input_event(wheel)
	await process_frame
	check(game.ranking_list.scroll_vertical > 0, "Mouse wheel scrolls ranking")
	game.ranking_list.scroll_vertical = 0
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = game.fit_offset + Vector2(180, 585) * game.fit_scale
	Input.parse_input_event(touch)
	await process_frame
	for step in range(1, 8):
		var swipe := InputEventScreenDrag.new()
		swipe.index = 0
		swipe.position = game.fit_offset + Vector2(180, 585 - step * 20) * game.fit_scale
		swipe.relative = Vector2(0, -20) * game.fit_scale
		Input.parse_input_event(swipe)
		await process_frame
	touch.pressed = false
	touch.position = game.fit_offset + Vector2(180, 445) * game.fit_scale
	Input.parse_input_event(touch)
	await process_frame
	check(game.ranking_list.scroll_vertical > 0, "Touch swipe scrolls ranking")
	game.ranking_list.scroll_vertical = 10000
	await snap("ranking-bottom")
	check(game.ranking_list.scroll_vertical == 675, "Last of twenty rows is reachable without overflow")
	game.records = saved_ranking
	game._sync_buttons()
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
	game.screen = "home"
	game._edit_profile()
	game.name_input.text = "Alex modifié"
	game._select_avatar(3)
	game._submit_name()
	check(game.screen == "home" and game.player_avatar == 3, "Profile editing saves without starting a round")
	check(game._personal_record() == 100, "Renaming keeps the local personal record")
	game._open_gifts()
	check(game.screen == "gifts", "Gift button opens rewards")
	await snap("gifts")
	game._primary()
	check(game.screen == "home", "Rewards returns to previous screen")
	game.records = old_records
	game.record = old_record
	game.player_name = old_name
	game.player_avatar = old_avatar
	game._save()
	game._start_game()
	check(game.round_model.score == 0 and game.round_model.combo == 1, "Replay resets round")
	print("Scene smoke tests: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
