extends ScrollContainer

var rows := Control.new()
var entries: Array = []
var game: Control
var dragging := false
var drag_y := 0.0
var drag_scroll := 0
var touch_index := -1

func _ready() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	vertical_scroll_mode = SCROLL_MODE_AUTO
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rows)
	rows.draw.connect(_draw_rows)
	var bar := get_v_scroll_bar()
	bar.custom_minimum_size.x = 5
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("dda856")
		style.set_corner_radius_all(3)
		bar.add_theme_stylebox_override(state, style)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("23132e")
	bar.add_theme_stylebox_override("scroll", track)

func update_ranking(source: Array, owner_game: Control) -> void:
	game = owner_game
	entries = source.duplicate(true)
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	rows.custom_minimum_size = Vector2(342, maxi(5, entries.size()) * 45)
	for i in range(entries.size()):
		var portrait := TextureRect.new()
		portrait.position = Vector2(51, 7 + i * 45)
		portrait.size = Vector2(30, 30)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture = game.textures["avatar-%d" % clampi(int(entries[i].get("avatar", 1)), 1, 6)]
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/ui/rounded-portrait.gdshader")
		material.set_shader_parameter("radius", 0.5)
		portrait.material = material
		rows.add_child(portrait)
	rows.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		touch_index = -1
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1 and get_global_rect().has_point(event.position):
			touch_index = event.index
			drag_y = event.position.y
			drag_scroll = scroll_vertical
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		scroll_vertical = drag_scroll - int((event.position.y - drag_y) / get_global_transform().get_scale().y)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	# The wheel and scrollbar retain the native ScrollContainer behavior.
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_y = event.global_position.y
		drag_scroll = scroll_vertical
	elif event is InputEventMouseMotion and dragging:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			scroll_vertical = drag_scroll - int((event.global_position.y - drag_y) / get_global_transform().get_scale().y)
		else:
			dragging = false

func _label(value: String, x: float, y: float, size_px: int, centered := false, muted := false) -> void:
	var face: Font = game.font if muted else game.bold
	var width := face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	rows.draw_string(face, Vector2(x - width / 2 if centered else x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, game.MUTED if muted else game.CREAM)

func _draw_rows() -> void:
	if game == null:
		return
	for i in range(maxi(5, entries.size())):
		var y := float(5 + i * 45)
		var active: bool = i < entries.size() and (str(entries[i].get("id", "")) == game.cloud_user_id if game.cloud_available else str(entries[i].get("name", "Moi")).to_lower() == game.player_name.to_lower())
		if active:
			rows.draw_texture_rect(game.textures["leaderboard-row-active"], Rect2(0, y - 5, 342, 45), false)
		elif i > 0:
			rows.draw_line(Vector2(10, y - 5), Vector2(337, y - 5), Color("52385f"), 1)
		rows.draw_texture_rect(game.textures["rank-%d" % (i + 1 if i < 3 else 0)], Rect2(8, y, 33, 33), false)
		if i >= 3:
			_label(str(i + 1), 24, y + 23, 14, true)
		if i < entries.size():
			rows.draw_circle(Vector2(66, y + 17), 16.5, Color("ffe7a3") if active else Color("ba96cd"), true, -1, true)
			_label(str(entries[i].get("name", "Moi")).left(13), 97, y + 24, 15)
			_label(game._score_label(int(entries[i].score)), 306, y + 24, 17, true)
		else:
			_label("À toi de jouer…", 97, y + 24, 12, false, true)
