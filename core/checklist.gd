class_name Checklist
extends CanvasLayer

## Act 6: the door checklist. Five badges must be tapped before going to
## school. Uses its own 10-second hint timer and plays the act-6 voice lines.
##
## Data: data/checklist.json (badges, labels, voice paths).

signal completed

const DATA_PATH := "res://data/checklist.json"
const DESIGN := Vector2(1280, 720)

var _data: Dictionary = {}
var _badges: Array = []
var _buttons: Array[Button] = []
var _checks: Array[TextureRect] = []
var _done: Array[bool] = []
var _timer: Timer
var _root: Control
var _progress: Label
var _pulse_tween: Tween
var _busy := false

var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _done_style: StyleBoxFlat
var _glow_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat


func _ready() -> void:
	visible = false
	_load_data()
	_build()
	_timer = Timer.new()
	_timer.wait_time = 10.0
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)


func open() -> void:
	if _busy:
		return
	visible = true
	_root.modulate.a = 0.0
	_busy = false
	_done.clear()
	for i in _badges.size():
		_done.append(false)
	for i in _buttons.size():
		_checks[i].visible = false
		_buttons[i].scale = Vector2.ONE
	_update_cards()
	_update_progress()
	Audio.play_vo(String(_data.get("intro_vo", "")))
	_start_timer()
	_pulse_next()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.30)


func close() -> void:
	_timer.stop()
	_kill_pulse()
	_busy = false
	visible = false


# ------------------------------------------------------------------- build ---
func _load_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("checklist.json missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
		_badges = _data.get("badges", [])


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(1.0, 0.96, 0.88, 0.94)
	_root.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(50, 40)
	panel.size = Vector2(1180, 640)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.style_panel(panel, Color(1, 0.99, 0.96, 1.0), 44,
			Color(1, 1, 1, 0.9), 3, true, Color(0.42, 0.32, 0.24, 0.22), 20)
	_root.add_child(panel)

	var title := Label.new()
	title.text = String(_data.get("title", "Morning Checklist"))
	title.position = Vector2(80, 62)
	title.size = Vector2(700, 64)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#ff8a80"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = String(_data.get("subtitle", "出门前检查清单"))
	subtitle.position = Vector2(82, 128)
	subtitle.size = Vector2(700, 34)
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.42, 0.36, 0.5, 0.85))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(subtitle)

	_progress = Label.new()
	_progress.position = Vector2(900, 68)
	_progress.size = Vector2(260, 60)
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress.add_theme_font_size_override("font_size", 34)
	_progress.add_theme_color_override("font_color", UiKit.INK)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_progress)

	# cheering character
	var kid := TextureRect.new()
	kid.position = Vector2(86, 222)
	kid.size = Vector2(220, 300)
	kid.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kid_path := "res://assets/char/char_happy.png"
	if ResourceLoader.exists(kid_path):
		kid.texture = load(kid_path)
	_root.add_child(kid)

	var hint := Label.new()
	hint.text = "Tap each badge to check!"
	hint.position = Vector2(86, 520)
	hint.size = Vector2(860, 34)
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.42, 0.36, 0.5, 0.55))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(hint)

	_normal_style = UiKit.make_style(Color.WHITE, 26, Color("#b7d9ee"), 3, true,
			Color(0.35, 0.30, 0.45, 0.14), 8, Vector2(0, 4), Vector4(0, 0, 0, 0))
	_hover_style = UiKit.make_style(Color(1, 0.99, 0.92), 26, Color("#ffd166"), 4,
			true, Color(0.35, 0.30, 0.45, 0.18), 10, Vector2(0, 4), Vector4(0, 0, 0, 0))
	_done_style = UiKit.make_style(Color(0.91, 1.0, 0.93), 26, Color("#7fd1ae"), 4,
			true, Color(0.35, 0.30, 0.45, 0.12), 6, Vector2(0, 3), Vector4(0, 0, 0, 0))
	_glow_style = UiKit.make_style(Color(1, 1, 1), 26, Color("#ffb703"), 5,
			true, Color(1.0, 0.72, 0.2, 0.45), 14, Vector2(0, 4), Vector4(0, 0, 0, 0))
	_pressed_style = UiKit.make_style(Color(0.95, 0.94, 0.98), 26, Color("#b7d9ee"), 3,
			false, Color(0, 0, 0, 0), 0, Vector2.ZERO, Vector4(0, 0, 0, 0))

	var box := HBoxContainer.new()
	box.position = Vector2(340, 206)
	box.size = Vector2(820, 250)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(box)

	for i in _badges.size():
		box.add_child(_make_badge(i, _badges[i]))

	var footer := Label.new()
	footer.text = "5 badges · then off to school!"
	footer.position = Vector2(340, 566)
	footer.size = Vector2(820, 34)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 20)
	footer.add_theme_color_override("font_color", Color(0.42, 0.36, 0.5, 0.55))
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(footer)


func _make_badge(index: int, info: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 232)
	button.size = Vector2(150, 232)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _normal_style)
	button.add_theme_stylebox_override("hover", _hover_style)
	button.add_theme_stylebox_override("pressed", _pressed_style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(tap_badge.bind(index))
	_buttons.append(button)

	var icon := TextureRect.new()
	icon.position = Vector2(39, 18)
	icon.size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path := String(info.get("icon", ""))
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	button.add_child(icon)

	var en := Label.new()
	en.text = String(info.get("label", ""))
	en.position = Vector2(10, 106)
	en.size = Vector2(130, 30)
	en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	en.add_theme_font_size_override("font_size", 24)
	en.add_theme_color_override("font_color", UiKit.INK)
	en.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(en)

	var cn := Label.new()
	cn.text = String(info.get("cn", ""))
	cn.position = Vector2(10, 140)
	cn.size = Vector2(130, 26)
	cn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cn.add_theme_font_size_override("font_size", 17)
	cn.add_theme_color_override("font_color", Color(0.42, 0.36, 0.5, 0.7))
	cn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cn)

	var check := TextureRect.new()
	check.position = Vector2(108, 8)
	check.size = Vector2(34, 34)
	check.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	check.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	check.texture = load("res://assets/ui/star.png") if ResourceLoader.exists("res://assets/ui/star.png") else null
	check.visible = false
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(check)
	_checks.append(check)

	return button


# --------------------------------------------------------------- behaviour ---
func tap_badge(index: int) -> void:
	if _busy or index < 0 or index >= _done.size():
		return
	if _done[index]:
		Audio.play_sfx("tap", -8.0)
		return
	_done[index] = true
	_checks[index].visible = true
	_buttons[index].scale = Vector2.ONE
	Audio.play_sfx("tap")
	Audio.play_sfx("sparkle", -4.0)
	var badge: Dictionary = _badges[index]
	Audio.play_vo(String(badge.get("vo", "")))
	_update_cards()
	_update_progress()
	_reset_timer()

	if _done_count() >= _done.size():
		_finish()
	else:
		_pulse_next()


func _finish() -> void:
	_busy = true
	_timer.stop()
	_kill_pulse()
	for i in _buttons.size():
		_buttons[i].add_theme_stylebox_override("normal", _done_style)
	Audio.play_sfx("finish", -4.0)
	Audio.play_vo(String(_data.get("finish_vo", "")))
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color(1.08, 1.08, 1.08), 0.30)
	tween.tween_property(_root, "modulate", Color.WHITE, 0.50)
	await get_tree().create_timer(2.6).timeout
	visible = false
	completed.emit()


func _update_cards() -> void:
	for i in _buttons.size():
		var done := i < _done.size() and _done[i]
		_buttons[i].add_theme_stylebox_override("normal", _done_style if done else _normal_style)
		_buttons[i].modulate = Color(1, 1, 1, 1) if not done else Color(1, 1, 1, 0.95)


func _update_progress() -> void:
	_progress.text = "%d / %d" % [_done_count(), _done.size()]


func completed_count() -> int:
	return _done_count()


func badge_center(index: int) -> Vector2:
	if index < 0 or index >= _buttons.size():
		return Vector2.ZERO
	return _buttons[index].get_global_rect().get_center()


func _done_count() -> int:
	var count := 0
	for done in _done:
		if done:
			count += 1
	return count


func _pulse_next() -> void:
	_kill_pulse()
	_update_cards()
	var index := -1
	for i in _done.size():
		if not _done[i]:
			index = i
			break
	if index < 0:
		return
	var button := _buttons[index]
	button.add_theme_stylebox_override("normal", _glow_style)
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2(1.04, 1.04)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(button, "scale", Vector2(1.09, 1.09), 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	for i in _buttons.size():
		_buttons[i].scale = Vector2.ONE


func _start_timer() -> void:
	_timer.start(10.0)


func _reset_timer() -> void:
	_timer.start(10.0)


func _on_timeout() -> void:
	if _busy or not visible:
		return
	Audio.play_vo(String(_data.get("timeout_vo", "")))
	_pulse_next()
	_timer.start(10.0)
