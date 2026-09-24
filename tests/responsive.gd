extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for resolution in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 932), Vector2i(360, 800), Vector2i(844, 390)]:
		root.size = resolution
		await process_frame
		await process_frame
		game._fit_view()
		for page in ["home", "profile", "game", "results"]:
			game.round_model.start()
			game.screen = page
			game._sync_buttons()
			var bounds := Rect2(game.fit_offset, Vector2(390, 844) * game.fit_scale)
			if not Rect2(Vector2.ZERO, game.size + Vector2.ONE).encloses(bounds):
				push_error("Content exceeds viewport: %s %s" % [resolution, page])
				failures += 1
			await process_frame
			await RenderingServer.frame_post_draw
			if resolution == Vector2i(320, 568) or resolution == Vector2i(430, 932):
				root.get_texture().get_image().save_png("res://build/%s-%dx%d.png" % [page, resolution.x, resolution.y])
	print("Responsive bounds, 5 sizes × 4 views: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
