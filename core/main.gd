extends Control

## The director.
##
## Content model (all data driven):
##   data/game.json            -> list of level files
##   data/rooms.json           -> backgrounds + ambience per room
##   data/levels/<level>.json  -> ordered `steps`
##
## Step types: drag / pair / cutscene / checklist. Adding a level, a room, a new
## step or an inserted video between steps needs no code change.

const DONE_HOLD := 2.2
const IDLE_HINT_DELAY := 10.0
const ROOM_FADE := 0.32
const PROP_SCENE := preload("res://scenes/PropNode.tscn")

const VO_SUCCESS := "res://assets/audio/vo/success.mp3"
const VO_TRY_AGAIN := "res://assets/audio/vo/try_again.mp3"
const VO_FINISH := "res://assets/audio/vo/finish.mp3"
const VO_HINT := "res://assets/audio/vo/hint.mp3"

const STAR_TEXTURE_PATH := "res://assets/ui/star.png"
const SOUND_ON_TEXTURE := "res://assets/ui/sound_on.png"
const SOUND_OFF_TEXTURE := "res://assets/ui/sound_off.png"

@onready var background: TextureRect = $Background
@onready var props_root: Node2D = %Props
@onready var character: Character = %Character
@onready var binder: BinderUI = %Binder
@onready var ghost: GhostHand = %GhostHand
@onready var idle_timer: Timer = $IdleTimer
@onready var fx: Node2D = %FX
@onready var fx_top: Node2D = %FXTop
@onready var cutscene: Cutscene = %Cutscene
@onready var checklist: Checklist = %Checklist

@onready var title_pill: Panel = %TitlePill
@onready var title_label: Label = %TitleLabel
@onready var title_en: Label = %TitleEn
@onready var hint_pill: Panel = %HintPill
@onready var hint_label: Label = %HintLabel
@onready var progress: HBoxContainer = %Progress
@onready var sound_button: Button = %SoundButton

@onready var start_overlay: Control = %StartOverlay
@onready var start_card: Panel = %StartCard
@onready var start_icons: HBoxContainer = %StartIcons
@onready var play_button: Button = %PlayButton

@onready var finale_overlay: Control = %FinaleOverlay
@onready var finale_card: Panel = %FinaleCard
@onready var replay_button: Button = %ReplayButton

@onready var transition: ColorRect = %Transition

var rooms: Dictionary = {}
var levels: Array = []
var level_index := 0
var steps: Array = []
var step_index := 0
var current_step: Dictionary = {}
var current_room := ""
var game_started := false
var busy := false

var _props: Array[PropNode] = []
var _solved := 0
var _token := 0
var _stars: Array[TextureRect] = []
var _transition_tween: Tween
var _autopilot: Node = null
var _star_texture: Texture2D = null
var _sound_on: Texture2D = null
var _sound_off: Texture2D = null


func _ready() -> void:
	var data := LevelData.load_all()
	levels = data.get("levels", [])
	rooms = data.get("rooms", {})
	_star_texture = load(STAR_TEXTURE_PATH) if ResourceLoader.exists(STAR_TEXTURE_PATH) else null
	_sound_on = load(SOUND_ON_TEXTURE) if ResourceLoader.exists(SOUND_ON_TEXTURE) else null
	_sound_off = load(SOUND_OFF_TEXTURE) if ResourceLoader.exists(SOUND_OFF_TEXTURE) else null

	_apply_styles()
	_build_progress()
	_build_start_icons()
	_wire_signals()
	refresh_sound_icon()

	finale_overlay.visible = false
	transition.visible = false
	start_overlay.visible = true
	cutscene.visible = false
	ghost.hide_hand()

	if levels.is_empty():
		title_label.text = "缺少剧本"
		title_en.text = "Story not found"
		hint_label.text = "请检查 data/game.json"
		push_error("No levels loaded; game cannot start.")
		return

	Audio.play_bgm()
	_maybe_start_autopilot()
	_present_window.call_deferred()


func _wire_signals() -> void:
	idle_timer.timeout.connect(_on_idle_timeout)
	binder.card_pressed.connect(_on_card_pressed)
	binder.drag_started.connect(_on_card_drag_started)
	binder.drag_finished.connect(_on_activity)
	play_button.pressed.connect(_on_play_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	checklist.completed.connect(_on_checklist_completed)
	cutscene.finished.connect(_on_cutscene_finished)


func _apply_styles() -> void:
	UiKit.style_panel(title_pill, Color(1, 1, 1, 0.93), 30, Color(1, 1, 1, 0.75), 2,
			true, Color(0.42, 0.32, 0.24, 0.14), 8)
	UiKit.style_panel(hint_pill, Color(1, 0.99, 0.95, 0.92), 30, Color(1, 1, 1, 0.8), 2,
			true, Color(0.42, 0.32, 0.24, 0.12), 8)
	UiKit.style_panel(start_card, Color(1, 0.99, 0.96, 1.0), 46, Color(1, 1, 1, 0.95), 3,
			true, Color(0.42, 0.32, 0.24, 0.20), 18)
	UiKit.style_panel(finale_card, Color(1, 0.99, 0.96, 1.0), 46, Color(1, 1, 1, 0.95), 3,
			true, Color(0.42, 0.32, 0.24, 0.20), 18)

	UiKit.style_button(play_button, Color("#7fd1ae"), Color("#98e5c7"), Color("#63bea1"),
			40, UiKit.INK, 32, Color(1, 1, 1, 0.65), 3)
	UiKit.style_button(replay_button, UiKit.CORAL, Color("#ffa79e"), Color("#e87b72"),
			40, Color.WHITE, 36, Color(1, 1, 1, 0.45), 3)

	var sound_normal := UiKit.make_style(Color(1, 1, 1, 0.92), 24, Color(1, 1, 1, 0.8), 2,
			true, Color(0.42, 0.32, 0.24, 0.14), 6, Vector2(0, 3), Vector4(8, 8, 8, 8))
	var sound_hover := UiKit.make_style(Color(1, 1, 1, 1.0), 24, Color("#ffd166"), 3,
			true, Color(0.42, 0.32, 0.24, 0.18), 8, Vector2(0, 3), Vector4(8, 8, 8, 8))
	var sound_down := UiKit.make_style(Color(0.94, 0.93, 0.97, 1.0), 24, Color(1, 1, 1, 0.8), 2,
			false, Color(0, 0, 0, 0), 0, Vector2.ZERO, Vector4(8, 8, 8, 8))
	sound_button.add_theme_stylebox_override("normal", sound_normal)
	sound_button.add_theme_stylebox_override("hover", sound_hover)
	sound_button.add_theme_stylebox_override("pressed", sound_down)
	sound_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sound_button.expand_icon = true
	sound_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sound_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _build_progress() -> void:
	for child in progress.get_children():
		child.queue_free()
	_stars.clear()
	if _star_texture == null:
		return
	var total := _total_steps()
	for i in total:
		var star := TextureRect.new()
		star.texture = _star_texture
		star.custom_minimum_size = Vector2(30, 30)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star.modulate = Color(1, 1, 1, 0.25)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.add_child(star)
		_stars.append(star)
	_update_stars(0)


func _total_steps() -> int:
	var total := 0
	for level in levels:
		total += (level.get("steps", []) as Array).size()
	return total


func _build_start_icons() -> void:
	for child in start_icons.get_children():
		child.queue_free()
	var seen: Dictionary = {}
	for level in levels:
		for step in level.get("steps", []):
			var required := String(step.get("req_card", ""))
			for card in step.get("cards", []):
				var card_id := String(card.get("id", ""))
				if not required.is_empty() and card_id != required:
					continue
				if seen.has(card_id) or not ResourceLoader.exists(String(card.get("img", ""))):
					continue
				seen[card_id] = true
				var icon := TextureRect.new()
				icon.texture = load(String(card["img"]))
				icon.custom_minimum_size = Vector2(56, 56)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				start_icons.add_child(icon)


# ------------------------------------------------------------------ flow ----
func start_game() -> void:
	start_overlay.visible = false
	finale_overlay.visible = false
	checklist.close()
	cutscene.visible = false
	game_started = true
	busy = false
	_clear_fx()
	_clear_props()
	_update_stars(0)
	_load_level(0)


func _load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		_show_finale()
		return
	level_index = index
	steps = levels[index].get("steps", [])
	current_room = ""
	step_index = 0
	_title_level(levels[index])
	_goto_step(0)


func _title_level(level: Dictionary) -> void:
	if title_label:
		title_label.text = String(level.get("title_cn", level.get("title", "")))


func _goto_step(index: int) -> void:
	_token += 1
	if index >= steps.size():
		_finish_level()
		return
	step_index = index
	current_step = steps[index]
	busy = false
	idle_timer.stop()
	ghost.hide_hand()
	_clear_props()
	_solved = 0

	var room_id := String(current_step.get("room", ""))
	if room_id != "" and room_id != current_room:
		current_room = room_id
		_apply_room(room_id)

	title_label.text = String(current_step.get("title", levels[level_index].get("title", "")))
	title_en.text = String(current_step.get("title_en", ""))
	_update_stars(_global_step_offset() + index)

	var kind := String(current_step.get("type", "drag"))
	if kind == "cutscene":
		_run_cutscene()
	elif kind == "checklist":
		_run_checklist()
	else:
		_run_drag()


func _global_step_offset() -> int:
	var offset := 0
	for i in level_index:
		offset += (levels[i].get("steps", []) as Array).size()
	return offset


func _apply_room(room_id: String) -> void:
	var room: Dictionary = rooms.get(room_id, {})
	var bg_path := String(room.get("bg", ""))
	if bg_path.is_empty() or not ResourceLoader.exists(bg_path):
		return
	var tex: Texture2D = load(bg_path)
	background.texture = tex
	Audio.play_ambience(String(room.get("ambience", "")))
	var label := String(room.get("name", ""))
	if not label.is_empty():
		hint_label.text = "📍 " + label


# ------------------------------------------------------------- step: drag ---
func _run_drag() -> void:
	binder.visible = true
	hint_label.text = String(current_step.get("hint", ""))
	character.setup(current_step)
	character.visible = true

	var kind := String(current_step.get("type", "drag"))
	if kind == "pair":
		var list: Array = current_step.get("props", [])
		for entry in list:
			_spawn_prop(entry)
	else:
		_spawn_prop(current_step.get("prop", {}))

	binder.show_level(current_step)
	binder.set_locked(false)
	_flash_transition()
	_reset_idle()
	_play_intro_later(String((current_step.get("audio", {}) as Dictionary).get("intro", "")))


func _spawn_prop(cfg: Dictionary) -> void:
	var node := PROP_SCENE.instantiate() as PropNode
	props_root.add_child(node)
	node.setup_prop(cfg, String(cfg.get("req_card", current_step.get("req_card", ""))))
	node.drop_zone.matched.connect(_on_prop_matched)
	node.drop_zone.mismatched.connect(_on_prop_mismatched)
	node.drop_zone.tapped.connect(_on_prop_tapped)
	_props.append(node)


func _clear_props() -> void:
	for node in _props:
		if is_instance_valid(node):
			node.queue_free()
	_props.clear()


func _play_intro_later(path: String) -> void:
	if path.is_empty():
		return
	var token := _token
	await get_tree().create_timer(0.55).timeout
	if token == _token and game_started and not busy:
		Audio.play_vo(path)


# --------------------------------------------------------- step: cutscene ---
func _run_cutscene() -> void:
	binder.visible = false
	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	character.visible = true
	character.setup(current_step)
	hint_label.text = ""
	cutscene.play(current_step, character)


func _on_cutscene_finished() -> void:
	if not game_started:
		return
	busy = false
	_goto_step(step_index + 1)


# -------------------------------------------------------- step: checklist ---
func _run_checklist() -> void:
	binder.visible = false
	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	character.play_happy()
	checklist.open()


func _on_checklist_completed() -> void:
	_finish_level()


func _finish_level() -> void:
	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	if level_index + 1 < levels.size():
		_load_level(level_index + 1)
	else:
		_show_finale()


# ------------------------------------------------------------ interaction ---
func _required_card() -> String:
	for node in _props:
		if is_instance_valid(node) and not node.drop_zone.solved:
			return node.drop_zone.required_card
	return String(current_step.get("req_card", ""))


func _all_solved() -> bool:
	if _props.is_empty():
		return false
	for node in _props:
		if is_instance_valid(node) and not node.drop_zone.solved:
			return false
	return true


func _reset_idle() -> void:
	ghost.hide_hand()
	if game_started and not busy and not _props.is_empty():
		idle_timer.start(IDLE_HINT_DELAY)
	else:
		idle_timer.stop()


func _on_idle_timeout() -> void:
	if not game_started or busy:
		return
	var required := _required_card()
	var card := binder.get_card(required)
	if card == null:
		idle_timer.start(1.0)
		return
	ghost.show_hint(card)
	var audio: Dictionary = current_step.get("audio", {})
	Audio.play_vo(String(audio.get("timeout", VO_HINT)))
	Audio.play_sfx("tap", -10.0)


func _on_play_pressed() -> void:
	Audio.play_sfx("tap")
	start_game()


func _on_replay_pressed() -> void:
	Audio.play_sfx("tap")
	finale_overlay.visible = false
	checklist.close()
	cutscene.visible = false
	_clear_fx()
	start_game()


func _on_card_pressed(_card_id: String) -> void:
	if not game_started or busy:
		return
	_reset_idle()


func _on_card_drag_started(_card_id: String) -> void:
	if not game_started or busy:
		return
	_reset_idle()


func _on_activity(_card_id: String = "") -> void:
	if not game_started or busy:
		return
	_reset_idle()


func _on_prop_tapped() -> void:
	if not game_started or busy:
		return
	var card := binder.get_card(_required_card())
	if card:
		Audio.play_vo(card.vo_path)
	_reset_idle()


func _on_prop_matched(_card_id: String) -> void:
	if not game_started or busy:
		return
	_spawn_stars(character.global_position + Vector2(0, -110))
	if not _all_solved():
		Audio.play_sfx("tap")
		_reset_idle()
		hint_label.text = "再找一找！One more!"
		return

	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	binder.set_locked(true)

	_update_stars(_global_step_offset() + step_index + 1)
	hint_label.text = "太棒了！Great job!"

	var token := _token
	var audio: Dictionary = current_step.get("audio", {})
	await character.play_action(audio)
	if not is_inside_tree() or token != _token:
		return

	Audio.play_sfx("success")
	var done_path := String(audio.get("done", VO_SUCCESS))
	Audio.play_vo(done_path if not done_path.is_empty() else VO_SUCCESS)

	await get_tree().create_timer(DONE_HOLD).timeout
	if not is_inside_tree() or token != _token:
		return
	_goto_step(step_index + 1)


func _on_prop_mismatched(_card_id: String) -> void:
	if not game_started or busy:
		return
	var audio: Dictionary = current_step.get("audio", {})
	Audio.play_sfx("error")
	var wrong := String(audio.get("wrong", VO_TRY_AGAIN))
	Audio.play_vo(wrong if not wrong.is_empty() else VO_TRY_AGAIN)
	character.play_wince()
	hint_label.text = "再试一次吧！Try again!"
	_reset_idle()


# ---------------------------------------------------------------- finale ----
func _show_finale() -> void:
	busy = true
	_token += 1
	idle_timer.stop()
	ghost.hide_hand()
	binder.visible = false
	Audio.stop_ambience()
	Audio.play_sfx("finish")
	Audio.play_vo(VO_FINISH)
	finale_overlay.visible = true
	finale_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(finale_overlay, "modulate:a", 1.0, 0.35)
	_spawn_confetti()


# ------------------------------------------------------------------- UI ------
func _update_stars(filled: int) -> void:
	for i in _stars.size():
		var star := _stars[i]
		var on := i < filled
		star.modulate = Color.WHITE if on else Color(0.55, 0.50, 0.65, 0.25)


func _flash_transition() -> void:
	transition.visible = true
	transition.color = Color(1.0, 0.99, 0.94, 0.92)
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_property(transition, "color:a", 0.0, ROOM_FADE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_callback(func() -> void: transition.visible = false)


func _on_sound_pressed() -> void:
	var muted := Audio.toggle_mute()
	refresh_sound_icon()
	if not muted:
		Audio.play_sfx("tap")


func refresh_sound_icon() -> void:
	if _sound_off == null or _sound_on == null:
		sound_button.text = "♪"
		return
	sound_button.icon = _sound_off if Audio.muted else _sound_on
	sound_button.modulate = Color(1, 1, 1, 0.6) if Audio.muted else Color.WHITE


func _present_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	if window == null:
		return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	if usable.size.x > 0 and usable.size.y > 0:
		var design := Vector2(1280, 720)
		var factor := minf(1.0, minf(
				float(usable.size.x) * 0.94 / design.x,
				float(usable.size.y) * 0.90 / design.y))
		if factor < 0.995:
			window.size = Vector2i(int(design.x * factor), int(design.y * factor))
		window.position = usable.position + (usable.size - window.size) / 2
	window.always_on_top = true
	window.grab_focus()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(window):
		window.always_on_top = false
		window.grab_focus()


# ------------------------------------------------------------------ FX -------
func _spawn_stars(at: Vector2) -> void:
	if _star_texture == null:
		return
	var particles := CPUParticles2D.new()
	particles.texture = _star_texture
	particles.position = at
	particles.amount = 20
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 90.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 110.0
	particles.initial_velocity_max = 320.0
	particles.gravity = Vector2(0, 430)
	particles.scale_amount_min = 0.16
	particles.scale_amount_max = 0.42
	particles.color = Color(1.0, 0.86, 0.40, 1.0)
	particles.z_index = 5
	fx.add_child(particles)
	particles.emitting = true
	_free_later(particles, 2.2)


func _spawn_confetti() -> void:
	if _star_texture == null:
		return
	var particles := CPUParticles2D.new()
	particles.texture = _star_texture
	particles.position = Vector2(640, -30)
	particles.amount = 110
	particles.lifetime = 3.6
	particles.one_shot = true
	particles.explosiveness = 0.35
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(620, 24)
	particles.direction = Vector2(0, 1)
	particles.spread = 35.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 190.0
	particles.gravity = Vector2(0, 260)
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.22
	particles.scale_amount_max = 0.52
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.84, 0.40), Color(1.0, 0.55, 0.55),
		Color(0.45, 0.85, 0.95), Color(0.55, 0.90, 0.70),
	])
	particles.color_ramp = ramp
	particles.z_index = 5
	fx_top.add_child(particles)
	particles.emitting = true
	_free_later(particles, 4.5)


func _free_later(node: Node, seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(_free_node.bind(node))


func _free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _clear_fx() -> void:
	for container in [fx, fx_top]:
		for child in container.get_children():
			child.queue_free()


# --------------------------------------------------------------- autopilot ---
func _maybe_start_autopilot() -> void:
	if not OS.get_cmdline_user_args().has("--autotest"):
		return
	var script: Script = load("res://tools/autopilot.gd")
	if script == null:
		push_error("Autopilot script missing")
		return
	_autopilot = script.new()
	add_child(_autopilot)
	if _autopilot.has_method("setup"):
		_autopilot.setup(self)


## Test hook: behave exactly like a completed drop on the matching prop.
func debug_drop(card_id: String) -> bool:
	if not game_started:
		start_game()
	for node in _props:
		if not is_instance_valid(node) or node.drop_zone.solved:
			continue
		if node.drop_zone.required_card != card_id:
			continue
		var data := {"type": "word_card", "card_id": card_id}
		if not node.drop_zone._can_drop_data(Vector2.ZERO, data):
			return false
		node.drop_zone._drop_data(Vector2.ZERO, data)
		return true
	return false


## Test hook: solve every remaining prop of the current step.
func debug_solve_step() -> bool:
	var solved := false
	for node in _props:
		if is_instance_valid(node) and not node.drop_zone.solved:
			solved = debug_drop(node.drop_zone.required_card) or solved
	return solved


## Test hook: force the zero-frustration hint immediately.
func debug_show_hint() -> void:
	idle_timer.stop()
	_on_idle_timeout()
