extends Control

const RoundModel = preload("res://scripts/round.gd")
const CREAM := Color("fff5e6")
const MINT := Color("93ffcf")
const MUTED := Color("cbb1dd")
const ORANGE := Color("ffae55")
const SAVE_PATH := "user://records.json"
var round_model = RoundModel.new()
var textures: Dictionary = {}
var sounds: Dictionary = {}
var font: Font = preload("res://assets/fonts/DejaVuSans.ttf")
var display_font: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
var bold: Font = preload("res://assets/fonts/DejaVuSans-Bold.ttf")
var screen := "home"
var clock := 0.0
var effects: Array[Dictionary] = []
var records: Array = []
var record := 0
var new_record := false
var sound_enabled := false
var motion_enabled := true
var save_available := true
var countdown := 0.0
var result_age := 0.0
var combo_age := 10.0
var error_age := 10.0
var last_second := 60
var primary: Button
var volume_button: Button
var last_frame_ms := Time.get_ticks_msec()
var cell_buttons: Array[Button] = []
var players: Array[AudioStreamPlayer] = []
var player_name := ""
var player_avatar := 1
var avatar_buttons: Array[Button] = []
var ranking_portraits: Array[TextureRect] = []
var avatar_scroll: ScrollContainer
var avatar_dragging := false
var avatar_drag_moved := false
var avatar_drag_start := Vector2.ZERO
var avatar_drag_origin := 0
var name_error := ""
var name_input: LineEdit
var ui_layer: Control
var fit_scale := 1.0
var fit_offset := Vector2.ZERO
var current_entry_id := ""
var cloud_url := ""
var cloud_token := ""
var cloud_user_id := ""
var cloud_records: Array = []
var cloud_available := false
var cloud_busy := false
var cloud_pending_score := -1
var panel_cache: Dictionary = {}
func _ready() -> void:
	_load_assets()
	_load_save()
	ui_layer = Control.new()
	ui_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_layer)
	resized.connect(_fit_view)
	for i in range(5):
		var player := AudioStreamPlayer.new()
		player.volume_db = -12
		add_child(player)
		players.append(player)
	for i in range(9):
		var button := _button(_cell(i), "", _hit.bind(i), "Case %d · touche %d" % [i + 1, i + 1], true)
		cell_buttons.append(button)
	name_input = LineEdit.new()
	name_input.position = Vector2(48, 441)
	name_input.size = Vector2(294, 54)
	name_input.max_length = 16
	name_input.placeholder_text = "Ton pseudo"
	name_input.add_theme_font_override("font", bold)
	name_input.add_theme_font_size_override("font_size", 21)
	name_input.add_theme_color_override("font_color", CREAM)
	name_input.add_theme_color_override("caret_color", ORANGE)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color("20132e")
	input_style.border_color = Color("ac72ce")
	input_style.set_border_width_all(2)
	input_style.set_corner_radius_all(13)
	input_style.content_margin_left = 16
	name_input.add_theme_stylebox_override("normal", input_style)
	name_input.add_theme_stylebox_override("focus", input_style)
	name_input.text_changed.connect(func(_value): name_error = "")
	name_input.text_submitted.connect(func(_value): _submit_name())
	ui_layer.add_child(name_input)
	avatar_scroll = ScrollContainer.new()
	avatar_scroll.position = Vector2(24, 563)
	avatar_scroll.size = Vector2(342, 120)
	avatar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	avatar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui_layer.add_child(avatar_scroll)
	var avatar_row := HBoxContainer.new()
	avatar_row.add_theme_constant_override("separation", 14)
	avatar_scroll.add_child(avatar_row)
	for i in range(6):
		var avatar_button := Button.new()
		avatar_button.custom_minimum_size = Vector2(104, 112)
		var portrait := TextureRect.new()
		portrait.texture = textures["avatar-%d" % (i + 1)]
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(5, 9)
		portrait.size = Vector2(94, 94)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rounded := ShaderMaterial.new()
		rounded.shader = preload("res://assets/ui/rounded-portrait.gdshader")
		portrait.material = rounded
		avatar_button.add_child(portrait)
		avatar_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		avatar_button.pressed.connect(_select_avatar.bind(i + 1))
		avatar_button.focus_entered.connect(func(): avatar_scroll.ensure_control_visible(avatar_button))
		avatar_row.add_child(avatar_button)
		avatar_buttons.append(avatar_button)
	_style_avatars()
	for i in range(5):
		var portrait := TextureRect.new()
		portrait.position = Vector2(69, 399 + i * 45)
		portrait.size = Vector2(34, 34)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/ui/rounded-portrait.gdshader")
		material.set_shader_parameter("radius", 0.5)
		portrait.material = material
		ui_layer.add_child(portrait)
		ranking_portraits.append(portrait)
	primary = _button(Rect2(58, 708, 274, 63), "JOUER", _primary, "Commencer une partie", true)
	_create_volume_button()
	_fit_view()
	_sync_buttons()
	_configure_cloud()

func _create_volume_button() -> void:
	volume_button = _button(Rect2(326, 5, 54, 56), "", _toggle_sound, "Activer le son", true)
	volume_button.toggle_mode = true
	volume_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		volume_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	volume_button.add_theme_color_override("icon_normal_color", Color.WHITE)
	volume_button.add_theme_color_override("icon_pressed_color", Color.WHITE)
	volume_button.add_theme_color_override("icon_hover_color", Color(1.12, 1.08, 1.12))
	volume_button.add_theme_color_override("icon_hover_pressed_color", Color(1.12, 1.08, 1.12))

func _fit_view() -> void:
	var safe_origin := Vector2.ZERO
	var safe_size := size
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("JSON.stringify(['left','top','right','bottom'].map(x=>parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-'+x))||0))")
		var insets = JSON.parse_string(str(raw))
		if insets is Array and insets.size() == 4:
			var pixel_scale := size.x / maxf(1, DisplayServer.window_get_size().x)
			safe_origin = Vector2(float(insets[0]), float(insets[1])) * pixel_scale
			safe_size -= safe_origin + Vector2(float(insets[2]), float(insets[3])) * pixel_scale
	fit_scale = minf(safe_size.x / 390.0, safe_size.y / 844.0)
	fit_offset = safe_origin + (safe_size - Vector2(390, 844) * fit_scale) / 2
	if is_instance_valid(ui_layer):
		ui_layer.position = fit_offset
		ui_layer.scale = Vector2.ONE * fit_scale

func _load_assets() -> void:
	textures["desks-atlas"] = load("res://assets/generated/desks-atlas.png")
	for name in ["office", "cubicle", "desk", "welcome-logo", "welcome-desk", "welcome-plant", "welcome-pumpkin", "ghost", "zombie", "vampire", "colleague", "candy", "pumpkin", "trophy", "prop-laptop", "prop-lamp", "prop-folders", "prop-mug", "prop-succulent"]:
		textures[name] = load("res://assets/webp/%s.webp" % name)
	for name in ["button-normal", "cobweb", "poster-frame", "bat", "halo", "steam", "combo-burst", "score-burst", "tap-ring", "rank-1", "rank-2", "rank-3", "rank-0", "confetti-orange", "confetti-mint", "confetti-purple", "confetti-cream", "rule-card", "legend-card", "leaderboard-row-active", "next-rank-card", "record-title"]:
		textures[name] = load("res://assets/components/%s.png" % name)
	for name in ["play", "replay", "crown"]:
		textures[name] = load("res://assets/ui/%s.png" % name)
	textures["replay"] = load("res://assets/ui/replay-polished.svg")
	textures["play"] = load("res://assets/ui/play-polished.svg")
	textures["trophy-perspective"] = load("res://assets/generated/trophy-perspective.png")
	textures["trophy-shadow"] = load("res://assets/ui/trophy-shadow.svg")
	textures["record-medal"] = load("res://assets/ui/record-medal.svg")
	textures["result-rays"] = load("res://assets/ui/result-rays.svg")
	textures["game-guide"] = load("res://assets/ui/game-guide.svg")
	for i in range(1, 7):
		textures["avatar-%d" % i] = load("res://assets/webp/avatar-%d.webp" % i)
	for i in range(1, 6):
		textures["combo-x%d" % i] = load("res://assets/components/combo-x%d.png" % i)
	for name in ["tap", "bonus", "error", "countdown", "record", "click"]:
		sounds[name] = load("res://assets/audio/%s.wav" % name)

func _button(rect: Rect2, caption: String, callback: Callable, hint: String, invisible := false) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = caption
	button.tooltip_text = hint
	button.add_theme_font_override("font", bold)
	button.add_theme_font_size_override("font_size", 16)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.24, 0.85) if not invisible else Color.TRANSPARENT
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color(0.8, 0.65, 1, 0.09)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = ORANGE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	button.add_theme_stylebox_override("focus", focus)
	if invisible:
		button.add_theme_color_override("font_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	button.pressed.connect(callback)
	ui_layer.add_child(button)
	return button

func _sync_rank_avatars() -> void:
	var ranking: Array = cloud_records if cloud_available else records
	for i in range(ranking_portraits.size()):
		ranking_portraits[i].visible = screen == "results" and i < ranking.size()
		if i < ranking.size():
			ranking_portraits[i].texture = textures["avatar-%d" % clampi(int(ranking[i].get("avatar", 1)), 1, 6)]

func _sync_buttons() -> void:
	_sync_rank_avatars()
	queue_redraw()
	volume_button.icon = load("res://assets/ui/volume-on.svg" if sound_enabled else "res://assets/ui/volume-off.svg")
	volume_button.set_pressed_no_signal(sound_enabled)
	volume_button.tooltip_text = "Désactiver le son" if sound_enabled else "Activer le son"
	name_input.visible = screen == "profile"
	avatar_scroll.visible = screen == "profile"
	for button in cell_buttons:
		button.visible = screen == "game" and countdown <= 0
	primary.visible = screen != "game"
	volume_button.modulate.a = 0.35 if screen == "game" and countdown > 0 else 1.0
	primary.position = Vector2(58, 708) if screen == "home" else Vector2(58, 767)
	primary.size = Vector2(274, 63)
	if screen == "results":
		primary.position = Vector2(58, 720)
	primary.text = "JOUER" if screen == "home" else "Rejouer"
	if screen == "profile":
		primary.position = Vector2(58, 720)
		primary.text = "C’EST PARTI !"

func _primary() -> void:
	if screen == "profile":
		_submit_name()
	elif player_name.strip_edges().length() >= 2:
		_start_game()
	else:
		screen = "profile"
		name_error = ""
		name_input.text = player_name
		_sync_buttons()
		name_input.grab_focus()
		name_input.select_all()

func _submit_name() -> void:
	var cleaned := name_input.text.strip_edges()
	if cleaned.length() < 2:
		name_error = "Entre au moins 2 caractères."
		name_input.grab_focus()
		return
	player_name = cleaned.left(16)
	for entry in records:
		if str(entry.get("name", "Moi")).to_lower() == player_name.to_lower():
			entry.avatar = player_avatar
	name_input.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	_save()
	_sync_cloud(_personal_record())
	_start_game()

func _start_game() -> void:
	round_model.start()
	screen = "game"
	last_frame_ms = Time.get_ticks_msec()
	countdown = 3.0
	effects.clear()
	combo_age = 10.0
	error_age = 10.0
	last_second = 60
	_play("click")
	_sync_buttons()

func _go_home() -> void:
	round_model.playing = false
	round_model.paused = false
	screen = "home"
	countdown = 0.0
	effects.clear()
	_sync_buttons()

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	if not sound_enabled:
		for player in players:
			player.stop()
	_save()
	_sync_buttons()
	_play("click")

func _toggle_motion() -> void:
	motion_enabled = not motion_enabled
	_save()
	_sync_buttons()

func _play(name: String) -> void:
	if not sound_enabled:
		return
	for player in players:
		if not player.playing:
			player.stream = sounds[name]
			player.play()
			return

func _hit(index: int) -> void:
	if countdown > 0:
		return
	var previous: int = round_model.combo
	var result: Dictionary = round_model.hit(index)
	if result.is_empty():
		return
	var center := _cell(index).get_center()
	effects.append({"pos": center, "age": 0.0, "text": ("+" if result.points > 0 else "") + str(result.points), "bad": result.bad})
	if result.bad:
		error_age = 0.0
		_play("error")
	else:
		_play("bonus" if result.name == "candy" else "tap")
		if round_model.combo > previous:
			combo_age = 0.0

func _input(event: InputEvent) -> void:
	if screen == "profile" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = (event.position - fit_offset) / fit_scale
		if event.pressed and Rect2(24, 563, 342, 120).has_point(point):
			avatar_dragging = true
			avatar_drag_moved = false
			avatar_drag_start = point
			avatar_drag_origin = avatar_scroll.scroll_horizontal
			get_viewport().set_input_as_handled()
			return
		elif not event.pressed and avatar_dragging:
			avatar_dragging = false
			if not avatar_drag_moved and Rect2(24, 563, 342, 120).has_point(point):
				var content_x := point.x - 24 + avatar_scroll.scroll_horizontal
				var index := int(content_x / 118)
				if index >= 0 and index < 6 and fmod(content_x, 118) < 104:
					_select_avatar(index + 1)
			get_viewport().set_input_as_handled()
			return
	if screen == "profile" and event is InputEventMouseMotion and avatar_dragging:
		var delta_x: float = (event.position.x - fit_offset.x) / fit_scale - avatar_drag_start.x
		if absf(delta_x) > 6:
			avatar_drag_moved = true
		if avatar_drag_moved:
			avatar_scroll.scroll_horizontal = avatar_drag_origin - int(delta_x)
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if screen == "profile" and name_input.has_focus():
		return
	if event.keycode == KEY_ENTER and primary.visible and not avatar_buttons.has(get_viewport().gui_get_focus_owner()):
		_primary()
		get_viewport().set_input_as_handled()
	elif screen == "game":
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
			_hit(event.physical_keycode - KEY_1)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_hit(event.keycode - KEY_1)
		elif event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_9:
			var n: int = event.keycode - KEY_KP_1
			_hit((2 - n / 3) * 3 + n % 3)

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	var elapsed := maxf(delta, (now - last_frame_ms) / 1000.0)
	last_frame_ms = now
	clock += delta
	if screen == "game":
		var play_elapsed := elapsed
		if countdown > 0:
			var before := ceili(countdown)
			play_elapsed = maxf(0, elapsed - countdown)
			countdown = maxf(0, countdown - elapsed)
			if ceili(countdown) != before:
				_play("countdown")
			if countdown <= 0:
				_sync_buttons()
		if play_elapsed > 0:
			if round_model.advance(play_elapsed):
				_finish()
			var second := ceili(round_model.remaining)
			if second <= 10 and second != last_second and second > 0:
				_play("countdown")
			last_second = second
	combo_age += delta
	error_age += delta
	for effect in effects:
		effect.age += delta
	effects = effects.filter(func(e): return e.age < 0.75)
	result_age += delta
	queue_redraw()

func _finish() -> void:
	screen = "results"
	new_record = round_model.score > _personal_record()
	record = maxi(record, round_model.score)
	current_entry_id = str(Time.get_unix_time_from_system())
	var previous := _personal_record()
	if round_model.score >= previous:
		records = records.filter(func(entry): return str(entry.get("name", "Moi")).to_lower() != player_name.to_lower())
		records.append({"score": round_model.score, "name": player_name, "avatar": player_avatar, "id": current_entry_id, "date": Time.get_date_string_from_system()})
	records.sort_custom(func(a, b): return a.score > b.score)
	if records.size() > 100:
		records.resize(100)
	result_age = 0.0
	_save()
	_sync_cloud(round_model.score)
	_play("record" if new_record else "click")
	_sync_buttons()

func _personal_record() -> int:
	var best := 0
	for entry in records:
		if str(entry.get("name", "Moi")).to_lower() == player_name.to_lower():
			best = maxi(best, int(entry.score))
	return best

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_available = false
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	cloud_token = str(data.get("cloud_token", ""))
	player_name = str(data.get("player_name", "")).left(16)
	player_avatar = clampi(int(data.get("player_avatar", 1)), 1, 6)
	sound_enabled = data.get("sound", false) == true
	motion_enabled = data.get("motion", true) != false
	var saved = data.get("records", [])
	if saved is Array:
		for entry in saved:
			if entry is Dictionary and entry.get("score") is float and entry.score >= 0 and entry.get("date") is String:
				records.append({"score": int(entry.score), "date": entry.date.left(10), "name": str(entry.get("name", "Moi")).left(16), "id": str(entry.get("id", "")), "avatar": clampi(int(entry.get("avatar", posmod(str(entry.get("name", "Moi")).to_lower().hash(), 6) + 1)), 1, 6)})
		records.sort_custom(func(a, b): return a.score > b.score)
		var seen: Dictionary = {}
		var unique: Array = []
		for entry in records:
			var key := str(entry.get("name", "Moi")).to_lower()
			if not seen.has(key):
				seen[key] = true
				unique.append(entry)
		records = unique.slice(0, 100)
	if not records.is_empty():
		record = records[0].score

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_available = false
		return
	file.store_string(JSON.stringify({"cloud_token": cloud_token, "records": records, "player_name": player_name, "player_avatar": player_avatar, "sound": sound_enabled, "motion": motion_enabled}))
	file.close()
	save_available = true

func _configure_cloud() -> void:
	if not OS.has_feature("web"):
		return
	cloud_url = str(JavaScriptBridge.eval("(location.hostname === 'localhost' || location.hostname === '127.0.0.1') && location.port !== '8787' ? '' : location.origin"))
	if cloud_url.is_empty():
		return
	if cloud_token.length() != 64:
		cloud_token = Crypto.new().generate_random_bytes(32).hex_encode()
		_save()
	if player_name.length() >= 2:
		_sync_cloud(_personal_record())

func _cloud_request(path: String, method: int, payload: Dictionary = {}) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + cloud_token])
	var error := http.request(cloud_url + path, headers, method, "" if method == HTTPClient.METHOD_GET else JSON.stringify(payload))
	if error != OK:
		http.queue_free()
		return {}
	var response: Array = await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	return data if data is Dictionary else {}

func _sync_cloud(score := -1) -> void:
	if cloud_url.is_empty() or player_name.length() < 2:
		return
	if cloud_busy:
		cloud_pending_score = maxi(cloud_pending_score, score)
		return
	cloud_busy = true
	var profile := await _cloud_request("/api/profile", HTTPClient.METHOD_PUT, {"name": player_name, "avatar": player_avatar})
	if profile.get("player") is Dictionary:
		cloud_user_id = str(profile.player.id)
		if score >= 0:
			var saved := await _cloud_request("/api/score", HTTPClient.METHOD_POST, {"score": score})
			if saved.is_empty():
				cloud_available = false
		var ranking := await _cloud_request("/api/leaderboard", HTTPClient.METHOD_GET)
		cloud_available = ranking.get("players") is Array
		if cloud_available:
			cloud_records = ranking.players
	else:
		cloud_available = false
	cloud_busy = false
	_sync_rank_avatars()
	queue_redraw()
	if cloud_pending_score >= 0:
		var pending := cloud_pending_score
		cloud_pending_score = -1
		_sync_cloud(pending)

func _cell(i: int) -> Rect2:
	return Rect2(12 + (i % 3) * 123, 200 + (i / 3) * 135, 120, 133)

func _pic(name: String, rect: Rect2, alpha := 1.0, fitted := true) -> void:
	var texture: Texture2D = textures.get(name)
	if texture == null:
		return
	var dest := rect
	if fitted:
		var factor := minf(rect.size.x / texture.get_width(), rect.size.y / texture.get_height())
		dest.size = texture.get_size() * factor
		dest.position += (rect.size - dest.size) / 2
	draw_texture_rect(texture, dest, false, Color(1, 1, 1, alpha))

func _sprite(name: String, rect: Rect2, _offset := 0) -> void:
	_pic(name, rect)

func _text(value: String, x: float, y: float, size_px := 16, color := CREAM, centered := false, heavy := true) -> void:
	var face := (display_font if size_px >= 19 else bold) if heavy else font
	var width := face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	draw_string(face, Vector2(x - width / 2 if centered else x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _panel(rect: Rect2, fill := Color("31203f")) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("67467e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	draw_style_box(style, rect)

func _action(rect: Rect2, caption: String) -> void:
	_pic("button-normal", rect, 1, false)
	var has_icon := caption in ["JOUER", "Rejouer"]
	var label_size := 32 if caption == "JOUER" else 30
	var label_width := display_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var icon_size := 30.0
	var gap := 12.0
	var group_width := label_width + (icon_size + gap if has_icon else 0.0)
	var start_x := rect.get_center().x - group_width / 2.0
	if has_icon:
		_pic("play" if caption == "JOUER" else "replay", Rect2(Vector2(start_x, rect.get_center().y - icon_size / 2), Vector2.ONE * icon_size))
	var label_x := start_x + (icon_size + gap if has_icon else 0.0)
	var baseline := rect.get_center().y + (display_font.get_ascent(label_size) - display_font.get_descent(label_size)) / 2.0
	_text(caption, label_x, baseline, label_size, CREAM)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	_pic("office", Rect2(Vector2.ZERO, size), 1, false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.02, 0.10, 0.62))
	draw_set_transform(fit_offset, 0, Vector2.ONE * fit_scale)
	_pic("cobweb", Rect2(0, 55, 67, 67), 0.45)
	_pic("welcome-plant", Rect2(-38, 693, 130, 170), 0.45)
	if screen == "home":
		_draw_home()
	elif screen == "profile":
		_draw_profile()
	elif screen == "game":
		_draw_game()
	else:
		_draw_results()
	for effect in effects:
		var progress: float = effect.age / 0.75
		var point: Vector2 = effect.pos
		var tint := Color("ff887c") if effect.bad else MINT
		tint.a = 1 - progress
		_text(effect.text, point.x, point.y - (progress * 20 if motion_enabled else 0), 26, tint, true)
		if motion_enabled:
			var radius := 22 + progress * 9
			_pic("tap-ring", Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2), (1 - progress) * 0.4)
	if screen == "game" and countdown > 0:
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.02, 0.08, 0.87))
		draw_set_transform(fit_offset, 0, Vector2.ONE * fit_scale)
		_text(str(ceili(countdown)), 195, 414, 92, ORANGE, true)
		_text("Prépare-toi !", 195, 465, 20, CREAM, true)

func _hero(y: float, trophy := false) -> void:
	var bob := sin(clock * TAU / 4.8) * 6.0 if motion_enabled else 0.0
	_pic("bat", Rect2(45, y + 37, 49, 30), 0.8)
	_sprite("ghost", Rect2(65, y + bob, 254, 254))
	_pic("welcome-desk", Rect2(-4, y + 111, 398, 196))
	_pic("halo", Rect2(-8, y + 168, 100, 100), 0.65)
	_pic("welcome-pumpkin", Rect2(6, y + 174, 76, 70))
	if trophy:
		var float_y := sin(clock * TAU / 4.6 + 1.1) * 5.0 if motion_enabled else 0.0
		var shadow_width := 76.0 + float_y * 1.5
		_pic("trophy-shadow", Rect2(314 - shadow_width / 2, y + 263, shadow_width, 19), 0.62 + float_y * 0.025, false)
		_pic("trophy-perspective", Rect2(255, y + 22 + float_y, 123, 146))

func _draw_home() -> void:
	_hero(24)
	draw_texture_rect_region(textures["welcome-logo"], Rect2(35, 253, 320, 128), Rect2(15, 128, 930, 375))
	_text("60 secondes pour battre ton record", 195, 398, 13, CREAM, true, false)
	var rows := [
		["ghost", "Tape les monstres", "50 points par touche.", "Enchaîne les touches."],
		["candy", "Attrape les bonbons", "100 points avant le combo.", "Jusqu’à 500 points !"],
		["colleague", "Évite les pièges", "Humains et citrouilles : −100.", "Une erreur annule le combo."]]
	for i in range(3):
		var y := 412 + i * 94
		_pic("rule-card", Rect2(18, y, 354, 87), 1, false)
		_sprite(rows[i][0], Rect2(22, y + 3, 81, 81))
		if i == 2:
			_pic("pumpkin", Rect2(70, y + 40, 40, 40))
		_text(rows[i][1], 115, y + 28, 15)
		_text(rows[i][2], 115, y + 50, 13, CREAM, false, false)
		_text(rows[i][3], 115, y + 67, 13, CREAM, false, false)
	_action(Rect2(58, 708, 274, 63), "JOUER")

func _avatar_rect(index: int) -> Rect2:
	return Rect2(24 + index * 118, 563, 104, 112)

func _style_avatars() -> void:
	for i in range(avatar_buttons.size()):
		var selected := player_avatar == i + 1
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("49304f") if selected else Color("291a39")
			style.border_color = Color("ffce77") if selected else Color("67467e")
			if state == "focus":
				style.border_color = CREAM
			style.set_border_width_all(3 if selected else 1)
			style.set_corner_radius_all(23)
			style.set_content_margin_all(5)
			style.anti_aliasing = true
			avatar_buttons[i].add_theme_stylebox_override(state, style)

func _select_avatar(id: int) -> void:
	player_avatar = clampi(id, 1, 6)
	_style_avatars()
	avatar_scroll.ensure_control_visible(avatar_buttons[player_avatar - 1])
	name_input.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	_play("click")
	queue_redraw()

func _draw_profile() -> void:
	_hero(25)
	_text("Qui sauve le bureau ?", 195, 362, 28, CREAM, true)
	_text("Choisis ton pseudo et ton avatar.", 195, 393, 13, MUTED, true, false)
	_text("TON PSEUDO", 48, 426, 11, MUTED)
	_text(name_error if not name_error.is_empty() else "De 2 à 16 caractères", 48, 522, 12, Color("ffab91") if not name_error.is_empty() else MUTED, false, false)
	_text("TON AVATAR", 48, 549, 11, MUTED)
	_text("‹   Fais glisser pour choisir   ›", 195, 704, 11, MUTED, true, false)
	_action(Rect2(58, 720, 274, 63), "C’EST PARTI !")

func _capsule(rect: Rect2, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(rect.size.y / 2))
	style.anti_aliasing = true
	draw_style_box(style, rect)

func _draw_desk(index: int) -> void:
	var rect := _cell(index)
	var atlas: Texture2D = textures["desks-atlas"]
	var tile_size := atlas.get_size() / 3.0
	var source := Rect2(Vector2(index % 3, index / 3) * tile_size, tile_size)
	draw_texture_rect_region(atlas, rect, source)
	var target: Dictionary = round_model.targets[index]
	if not target.is_empty():
		var is_object: bool = target.name in ["candy", "pumpkin"]
		var settle := (1.0 - clampf((round_model.elapsed - float(target.born)) / 0.14, 0, 1)) * 4 if motion_enabled else 0.0
		if not is_object:
			_sprite(target.name, Rect2(rect.position + Vector2(2, -4 + settle), Vector2(116, 116)), index)
		# Redraw furniture over the target using atlas regions; no new bitmap copies.
		var occluders := [Rect2(0, 0.79, 1, 0.21), Rect2(0.31, 0.51, 0.41, 0.29), Rect2(0, 0.56, 0.28, 0.24), Rect2(0.80, 0.55, 0.20, 0.25)]
		for box in occluders:
			draw_texture_rect_region(atlas, Rect2(rect.position + box.position * rect.size, box.size * rect.size), Rect2(source.position + box.position * source.size, box.size * source.size))

		if is_object:
			_sprite(target.name, Rect2(rect.position + Vector2(21, 4 + settle), Vector2(81, 81)), index)

func _draw_game() -> void:
	_text("SCORE", 20, 77, 10, MUTED)
	_text(str(round_model.score), 20, 110, 29, MINT)
	var warning: bool = round_model.remaining <= 10
	var fill := Color("eb9652") if warning else Color("b854e7")
	_capsule(Rect2(132, 77, 132, 23), Color("1f1336"), Color("795995"))
	var width: float = 124 * round_model.remaining / 60
	if width > 2:
		_capsule(Rect2(136, 81, width, 15), fill, fill.lightened(0.25))
		if width > 8:
			draw_line(Vector2(141, 84), Vector2(132 + width, 84), fill.lightened(0.35), 1.5, true)
	# Small clock icon, aligned with the numeric timer.
	draw_arc(Vector2(284, 89), 8, 0, TAU, 24, ORANGE, 2, true)
	draw_line(Vector2(284, 89), Vector2(284, 83), ORANGE, 1.6, true)
	draw_line(Vector2(284, 89), Vector2(289, 89), ORANGE, 1.6, true)
	_text("%02d:%02d" % [ceili(round_model.remaining) / 60, ceili(round_model.remaining) % 60], 300, 97, 19, ORANGE)
	if round_model.combo > 1:
		_text("COMBO ×%d" % round_model.combo, 195, 180, 35, ORANGE, true)
	else:
		_text("Enchaîne 3 touches pour un combo", 195, 170, 12, MUTED, true, false)
	for i in range(9):
		_draw_desk(i)
	_pic("game-guide", Rect2(12, 628, 366, 106), 1, false)
	_text("ATTRAPE !", 104, 648, 14, MINT, true)
	_text("ÉVITE !", 286, 648, 14, Color("ffab91"), true)
	_sprite("ghost", Rect2(51, 651, 49, 49))
	_sprite("candy", Rect2(110, 657, 41, 41))
	_sprite("colleague", Rect2(232, 651, 49, 49))
	_sprite("pumpkin", Rect2(291, 657, 41, 41))
	_text("+50 / +100 pts", 104, 718, 10, MINT, true)
	_text("−100 pts", 286, 718, 10, Color("ffab91"), true)
	_capsule(Rect2(82, 754, 226, 53), Color("25172e"), Color("74523e"))
	_pic("record-medal", Rect2(89, 758, 46, 46))
	_text("MEILLEUR SCORE", 216, 772, 9, Color("e5c59d"), true)
	_text("%d pts" % record, 216, 796, 22, Color("ffe1a1"), true)
	_text("Clavier : touches 1 à 9", 195, 829, 9, MUTED, true, false)
	if error_age < 0.2:
		draw_rect(Rect2(0, 58, 390, 786), Color(1, 0.2, 0.2, 0.08))

func _score_label(value: int) -> String:
	var digits := str(value)
	var label := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			label += " "
		label += digits[i]
	return label

func _draw_results() -> void:
	var ranking: Array = cloud_records if cloud_available else records
	draw_set_transform(fit_offset + Vector2(29, 0) * fit_scale, 0, Vector2.ONE * fit_scale * 0.85)
	_hero(5, true)
	draw_set_transform(fit_offset, 0, Vector2.ONE * fit_scale)
	for i in range(10):
		_pic("confetti-" + ["orange", "mint", "purple", "cream"][i % 4], Rect2(47 + fmod(i * 79.0, 298), 28 + fmod(i * 43.0, 150), 5, 9))
	var title := "Nouveau record !" if new_record else "Bien joué, %s !" % player_name.left(10)
	var title_width := display_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	draw_string_outline(display_font, Vector2(195 - title_width / 2, 277), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color("1a0c24"))
	_text(title, 195, 277, 30, CREAM, true)
	var score_text := _score_label(round_model.score)
	var score_size := 64 if score_text.length() < 6 else 54
	var number_width := display_font.get_string_size(score_text, HORIZONTAL_ALIGNMENT_LEFT, -1, score_size).x
	var unit_width := display_font.get_string_size("pts", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var score_x := 195 - (number_width + 9 + unit_width) / 2
	_pic("result-rays", Rect2(24, 298, 342, 48), 1, false)
	_text(score_text, score_x + 1, 347, score_size, Color("16423c"))
	_text(score_text, score_x, 343, score_size, MINT)
	_text("pts", score_x + number_width + 9, 335, 24, CREAM)
	_text("Ton meilleur score compte", 195, 374, 14, CREAM, true, false)
	_panel(Rect2(18, 389, 354, 237))
	for i in range(5):
		var y := 399 + i * 45
		var active: bool = i < ranking.size() and (str(ranking[i].get("id", "")) == cloud_user_id if cloud_available else str(ranking[i].get("name", "Moi")).to_lower() == player_name.to_lower())
		if active:
			_pic("leaderboard-row-active", Rect2(20, y - 5, 350, 45), 1, false)
		elif i > 0:
			draw_line(Vector2(30, y - 5), Vector2(360, y - 5), Color("52385f"), 1)
		_pic("rank-%d" % (i + 1 if i < 3 else 0), Rect2(28, y, 33, 33))
		if i >= 3:
			_text(str(i + 1), 44, y + 23, 14, CREAM, true)
		if i < ranking.size():
			draw_circle(Vector2(86, y + 17), 18, Color("ba96cd"), true, -1, true)
			_text(str(ranking[i].get("name", "Moi")).left(13), 117, y + 24, 15)
			_text(_score_label(int(ranking[i].score)), 326, y + 24, 17, CREAM, true)
		else:
			_text("À toi de jouer…", 117, y + 24, 12, MUTED, false, false)
	_pic("next-rank-card", Rect2(18, 637, 354, 64), 1, false)
	var next_player: Dictionary = {}
	for entry in ranking:
		if int(entry.score) > _personal_record():
			if next_player.is_empty() or int(entry.score) < int(next_player.score):
				next_player = entry
	if not next_player.is_empty():
		draw_polyline(PackedVector2Array([Vector2(44, 681), Vector2(51, 665), Vector2(59, 671), Vector2(70, 652)]), Color("ffd26a"), 4, true)
		draw_polyline(PackedVector2Array([Vector2(61, 654), Vector2(70, 652), Vector2(70, 662)]), Color("ffd26a"), 4, true)
		_text("Plus que %s points" % _score_label(int(next_player.score) - _personal_record() + 1), 220, 662, 14, MINT, true)
		_text("pour dépasser %s !" % str(next_player.name).left(12), 220, 684, 12, CREAM, true, false)
	else:
		_pic("record-medal", Rect2(40, 647, 43, 43))
		_text("Ton record : %d pts" % _personal_record(), 224, 662, 14, MINT, true)
		_text("À toi de faire encore mieux !", 224, 684, 12, CREAM, true, false)
	_action(Rect2(58, 720, 274, 63), "Rejouer")
	_text("Classement en ligne" if cloud_available else ("Classement local" if save_available else "Sauvegarde indisponible"), 195, 810, 10, MUTED, true, false)
