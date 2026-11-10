extends Control

## The director. Owns the level flow, the zero-frustration FSM and all
## feedback (VO, chimes, stars, confetti).
##
## Data flow:
##   story.json -> StoryData -> Main -> BinderUI / PropNode
##   WordCard drag payload -> BaseProp -> matched/mismatched -> Main
##
## Nothing here knows about specific words: adding a level to story.json is
## enough to extend the game.

const STORY_PATH := "res://data/story.json"
const DONE_HOLD := 2.2
const IDLE_HINT_DELAY := 10.0

const VO_SUCCESS := "res://assets/audio/vo/success.mp3"
const VO_TRY_AGAIN := "res://assets/audio/vo/try_again.mp3"
const VO_FINISH := "res://assets/audio/vo/finish.mp3"
const VO_HINT := "res://assets/audio/vo/hint.mp3"

const STAR_TEXTURE_PATH := "res://assets/ui/star.png"
const SOUND_ON_TEXTURE := "res://assets/ui/sound_on.png"
const SOUND_OFF_TEXTURE := "res://assets/ui/sound_off.png"

@onready var background: TextureRect = $Background
@onready var prop: PropNode = %Prop
@onready var character: Character = %Character
@onready var binder: BinderUI = %Binder
@onready var ghost: GhostHand = %GhostHand
@onready var idle_timer: Timer = $IdleTimer
@onready var fx: Node2D = %FX
@onready var fx_top: Node2D = %FXTop

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
@onready var checklist: Checklist = %Checklist

@onready var transition: ColorRect = %Transition

var levels: Array = []
var level_index := 0
var current_level: Dictionary = {}
var game_started := false
var busy := false

var _level_token := 0
var _stars: Array[TextureRect] = []
var _transition_tween: Tween
var _autopilot: Node = null
var _star_texture: Texture2D = null
var _sound_on: Texture2D = null
var _sound_off: Texture2D = null


func _ready() -> void:
	levels = StoryData.load_levels(STORY_PATH)
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
	ghost.hide_hand()

	if levels.is_empty():
		title_label.text = "缺少剧本"
		title_en.text = "Story not found"
		hint_label.text = "请检查 data/story.json"
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
	prop.drop_zone.matched.connect(_on_prop_matched)
	prop.drop_zone.mismatched.connect(_on_prop_mismatched)
	prop.drop_zone.tapped.connect(_on_prop_tapped)
	play_button.pressed.connect(_on_play_pressed)
	replay_button.pressed.connect(_on_replay_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	checklist.completed.connect(_on_checklist_completed)


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
	for i in levels.size():
		var star := TextureRect.new()
		star.texture = _star_texture
		star.custom_minimum_size = Vector2(34, 34)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star.modulate = Color(1, 1, 1, 0.25)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress.add_child(star)
		_stars.append(star)
	_update_stars(0)


func _build_start_icons() -> void:
	for child in start_icons.get_children():
		child.queue_free()
	var seen: Dictionary = {}
	for level in levels:
		var required := String(level.get("req_card", ""))
		for card in level.get("cards", []):
			var card_id := String(card.get("id", ""))
			if card_id != required or seen.has(card_id):
				continue
			if not ResourceLoader.exists(String(card.get("img", ""))):
				continue
			seen[card_id] = true
			var icon := TextureRect.new()
			icon.texture = load(String(card["img"]))
			icon.custom_minimum_size = Vector2(64, 64)
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
	game_started = true
	busy = false
	_clear_fx()
	_update_stars(0)
	_load_level(0)


func _load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	_level_token += 1
	level_index = index
	busy = false
	current_level = levels[index]
	ghost.hide_hand()
	idle_timer.stop()

	var bg_path := String(current_level.get("bg_img", ""))
	if ResourceLoader.exists(bg_path):
		background.texture = load(bg_path)

	if binder.visible == false:
		binder.visible = true
	prop.setup(current_level)
	character.setup(current_level)
	binder.show_level(current_level)
	binder.set_locked(false)

	Audio.play_ambience(String(current_level.get("ambience", "")))

	title_label.text = String(current_level.get("title", ""))
	title_en.text = String(current_level.get("title_en", ""))
	hint_label.text = String(current_level.get("hint", ""))
	_update_stars(level_index)
	_flash_transition()
	_reset_idle()

	var audio: Dictionary = current_level.get("audio", {})
	_play_intro_later(String(audio.get("intro", "")), _level_token)


func _play_intro_later(path: String, token: int) -> void:
	if path.is_empty():
		return
	await get_tree().create_timer(0.55).timeout
	if token == _level_token and game_started and not busy:
		Audio.play_vo(path)


func _reset_idle() -> void:
	ghost.hide_hand()
	if game_started and not busy and not levels.is_empty():
		idle_timer.start(IDLE_HINT_DELAY)
	else:
		idle_timer.stop()


func _on_idle_timeout() -> void:
	if not game_started or busy:
		return
	var required := String(current_level.get("req_card", ""))
	var card := binder.get_card(required)
	if card == null:
		# Cards may still be fading in; try again shortly.
		idle_timer.start(1.0)
		return
	ghost.show_hint(card)
	var audio: Dictionary = current_level.get("audio", {})
	Audio.play_vo(String(audio.get("timeout", VO_HINT)))
	Audio.play_sfx("tap", -10.0)


func _on_play_pressed() -> void:
	Audio.play_sfx("tap")
	start_game()


func _on_replay_pressed() -> void:
	Audio.play_sfx("tap")
	finale_overlay.visible = false
	checklist.close()
	_clear_fx()
	start_game()


# ------------------------------------------------------------- interaction --
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
	var card := binder.get_card(String(current_level.get("req_card", "")))
	if card:
		Audio.play_vo(card.vo_path)
	_reset_idle()


func _on_prop_matched(_card_id: String) -> void:
	if not game_started or busy:
		return
	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	binder.set_locked(true)

	_update_stars(level_index + 1)
	hint_label.text = "太棒了！Great job!"

	var token := _level_token
	var audio: Dictionary = current_level.get("audio", {})
	await character.play_action(audio)
	if not is_inside_tree() or token != _level_token:
		return

	Audio.play_sfx("success")
	var done_path := String(audio.get("done", VO_SUCCESS))
	Audio.play_vo(done_path if not done_path.is_empty() else VO_SUCCESS)
	_spawn_stars(character.global_position + Vector2(0, -110))

	await get_tree().create_timer(DONE_HOLD).timeout
	if not is_inside_tree() or token != _level_token:
		return
	if level_index + 1 < levels.size():
		_load_level(level_index + 1)
	else:
		_open_checklist()


func _on_prop_mismatched(_card_id: String) -> void:
	if not game_started or busy:
		return
	var audio: Dictionary = current_level.get("audio", {})
	Audio.play_sfx("error")
	var wrong := String(audio.get("wrong", VO_TRY_AGAIN))
	Audio.play_vo(wrong if not wrong.is_empty() else VO_TRY_AGAIN)
	character.play_wince()
	hint_label.text = "再试一次吧！Try again!"
	_reset_idle()
	_restore_hint_later(2.4)


func _restore_hint_later(seconds: float) -> void:
	var token := _level_token
	await get_tree().create_timer(seconds).timeout
	if not is_inside_tree() or token != _level_token or busy:
		return
	hint_label.text = String(current_level.get("hint", ""))


# ---------------------------------------------------------------- finale -----
func _open_checklist() -> void:
	busy = true
	idle_timer.stop()
	ghost.hide_hand()
	binder.set_locked(true)
	character.play_happy()
	checklist.open()


func _on_checklist_completed() -> void:
	_show_finale(false)


func _show_finale(with_vo: bool = true) -> void:
	busy = true
	_level_token += 1
	idle_timer.stop()
	ghost.hide_hand()
	binder.set_locked(true)
	_update_stars(levels.size())
	Audio.stop_ambience()
	if with_vo:
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
		if on:
			star.pivot_offset = star.size * 0.5
			star.scale = Vector2(1.2, 1.2)
			var tween := star.create_tween()
			tween.tween_property(star, "scale", Vector2.ONE, 0.3) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash_transition() -> void:
	transition.visible = true
	transition.color = Color(1.0, 0.99, 0.94, 0.92)
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_property(transition, "color:a", 0.0, 0.45) \
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


## Make sure the game is actually visible when launched from a .bat file:
## Windows may put a newly spawned window behind the console/browser.
func _present_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	if window == null:
		return
	_fit_window_to_screen(window)
	# Pop above the launcher console / browser for a moment, then release the
	# top-most flag so the window behaves normally afterwards.
	window.always_on_top = true
	window.grab_focus()
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(window):
		window.always_on_top = false
		window.grab_focus()


func _fit_window_to_screen(window: Window) -> void:
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var design := Vector2(1280, 720)
	var factor := minf(1.0, minf(
			float(usable.size.x) * 0.94 / design.x,
			float(usable.size.y) * 0.90 / design.y))
	if factor < 0.995:
		window.size = Vector2i(int(design.x * factor), int(design.y * factor))
	# Always re-center so a window restored on a disconnected monitor is visible.
	window.position = usable.position + (usable.size - window.size) / 2


# ------------------------------------------------------------------ FX -------
func _spawn_stars(at: Vector2) -> void:
	if _star_texture == null:
		return
	var particles := CPUParticles2D.new()
	particles.texture = _star_texture
	particles.position = at
	particles.amount = 22
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 90.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 110.0
	particles.initial_velocity_max = 330.0
	particles.gravity = Vector2(0, 430)
	particles.scale_amount_min = 0.18
	particles.scale_amount_max = 0.45
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


## Test hook: behave exactly like a completed drop on the current prop.
func debug_drop(card_id: String) -> bool:
	if not game_started:
		start_game()
	var data := {"type": "word_card", "card_id": card_id}
	if not prop.drop_zone._can_drop_data(Vector2.ZERO, data):
		return false
	prop.drop_zone._drop_data(Vector2.ZERO, data)
	return true


## Test hook: force the zero-frustration hint immediately.
func debug_show_hint() -> void:
	idle_timer.stop()
	_on_idle_timeout()
