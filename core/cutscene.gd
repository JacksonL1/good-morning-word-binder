class_name Cutscene
extends CanvasLayer

## Inserted animation / video between gameplay steps.
##
## Priority:
##   1. `video`  — a real .mp4/.ogv played in a VideoStreamPlayer (full screen)
##   2. `poses`  — the character walks/fades through the given positions
##   3. `character_action` — the character performs a gameplay animation
##
## Always ends after `duration` seconds, or immediately when the child taps.
## A "tap to continue" hint appears after `skip_after` seconds so the child is
## never stuck.

signal finished

var _root: Control
var _caption_pill: Panel
var _caption: Label
var _hint: Label
var _video: VideoStreamPlayer
var _skip_button: Button
var _token := 0
var _running := false
var _duration := 2.5
var _elapsed := 0.0
var _skip_after := 1.2


func _ready() -> void:
	visible = false
	layer = 6
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_root.add_child(_video)

	_caption_pill = Panel.new()
	_caption_pill.position = Vector2(390, 560)
	_caption_pill.size = Vector2(500, 74)
	_caption_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.style_panel(_caption_pill, Color(1, 1, 1, 0.94), 30,
			Color(1, 1, 1, 0.85), 2, true, Color(0.35, 0.30, 0.45, 0.16), 10)
	_root.add_child(_caption_pill)

	_caption = Label.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 24)
	_caption.add_theme_color_override("font_color", UiKit.INK)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_pill.add_child(_caption)

	_hint = Label.new()
	_hint.text = "Tap to continue"
	_hint.position = Vector2(440, 648)
	_hint.size = Vector2(400, 30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.42, 0.36, 0.5, 0.55))
	_hint.modulate.a = 0.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)

	# Tap anywhere to skip.
	_skip_button = Button.new()
	_skip_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skip_button.flat = true
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_skip_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_skip_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_skip_button.pressed.connect(_on_skip)
	_root.add_child(_skip_button)


## Plays one cutscene step and returns when it is over.
## `on_midpoint` is called when the character is off-screen, so the caller can
## swap the room background while nobody is looking.
func play(step: Dictionary, character: Character,
		on_midpoint: Callable = Callable()) -> void:
	_token += 1
	var token := _token
	_running = true
	_elapsed = 0.0
	_duration = float(step.get("duration", 2.5))
	_skip_after = float(step.get("skip_after", 1.2))

	_caption.text = String(step.get("caption", ""))
	_caption_pill.visible = not _caption.text.is_empty()
	_hint.modulate.a = 0.0
	visible = true
	_root.modulate.a = 0.0

	var video_path := String(step.get("video", ""))
	var has_video := not video_path.is_empty() and ResourceLoader.exists(video_path) \
			and video_path.ends_with(".ogv")

	if has_video:
		var stream: Resource = load(video_path)
		_video.stream = stream
		_video.visible = true
		_video.play()
	else:
		_video.visible = false

	Audio.play_vo(String(step.get("vo", "")))

	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 0.28)
	await tween.finished

	if not has_video:
		if bool(step.get("walk", false)):
			await _play_walk(step, character, on_midpoint, token)
		else:
			await _play_character_part(step, character, token)

	# Wait out the remaining time, allowing a tap to finish early.
	var remaining := maxf(_duration - 1.6, 0.2)
	var waited := 0.0
	while waited < remaining:
		if not _running or token != _token:
			break
		await get_tree().create_timer(0.05).timeout
		waited += 0.05
		if waited >= _skip_after:
			_hint.modulate.a = 1.0

	_finish(token)


## Walk out of the room, let the caller swap the background, walk back in.
func _play_walk(step: Dictionary, character: Character, on_midpoint: Callable,
		token: int) -> void:
	if character == null:
		on_midpoint.call_deferred()
		return
	var screen := Vector2(1280, 720)
	var out_right := String(step.get("walk_out", "right")) == "right"
	var exit_x := 1420.0 if out_right else -140.0
	var enter_x := -140.0 if out_right else 1420.0
	var in_pos: Vector2 = _vec(step.get("walk_in_pos", [640, 505]))

	var walk_y := character.position.y
	if walk_y < 200.0 or walk_y > 700.0:
		walk_y = 505.0

	# 1. walk to the exit edge
	await character.walk_to(Vector2(exit_x, walk_y), 1.05)
	if token != _token:
		return

	# 2. nobody on screen: swap the room
	if on_midpoint.is_valid():
		on_midpoint.call()
	await get_tree().create_timer(0.12).timeout
	if token != _token:
		return

	# 3. come back in from the other side and walk to the spot
	character.teleport_to(Vector2(enter_x, in_pos.y), character.idle_scale, "stand")
	await get_tree().create_timer(0.06).timeout
	if token != _token:
		return
	await character.walk_to(in_pos, 1.15)


func _play_character_part(step: Dictionary, character: Character, token: int) -> void:
	if character == null:
		return
	var poses: Array = step.get("poses", [])
	if not poses.is_empty():
		for entry in poses:
			if token != _token:
				return
			var cfg: Dictionary = entry
			character.show_at(String(cfg.get("pose", "stand")),
					_vec(cfg.get("pos", [640, 505])),
					float(cfg.get("scale", 0.62)), 0.55)
			await get_tree().create_timer(0.62).timeout
		return
	var action := String(step.get("character_action", ""))
	if not action.is_empty():
		character.play_action({"left": "", "right": "", "all": "", "loop": "",
				"action": ""}, action)


func _finish(token: int) -> void:
	if token != _token or not _running:
		return
	_running = false
	_token += 1
	_video.stop()
	_video.visible = false
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.22)
	await tween.finished
	visible = false
	finished.emit()


func skip() -> void:
	_on_skip()


func _on_skip() -> void:
	if not _running:
		return
	_token += 1
	var token := _token
	_running = false
	_video.stop()
	_video.visible = false
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.18)
	await tween.finished
	visible = false
	finished.emit()


func _vec(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2(640, 505)
