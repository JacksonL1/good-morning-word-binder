class_name Character
extends Node2D

## The little kid. Poses are swapped and tweened; the director waits for the
## action animation before showing the "done" line.
##
## data/levels/morning_routine.json drives the setup:
##   "action": "wake|drink|brush|wash|shirt|shoes",
##   "char": { "pos": [930,505], "scale": 0.62,
##             "start_pose": "lying", "start_pos": [640,330], "start_scale": 0.62 }

const CHAR_DIR := "res://assets/char/"
const FEET_OFFSET := -212.0

var action := "stand"
var idle_pos := Vector2(930, 505)
var idle_scale := 0.62

var _start_pose := ""
var _start_pos := Vector2.ZERO
var _start_scale := 0.62
var _pose := ""
var _busy := false
var _token := 0
var _idle_tween: Tween
var _bubbles: CPUParticles2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_bubbles = CPUParticles2D.new()
	_bubbles.texture = load("res://assets/ui/bubble.png") if ResourceLoader.exists("res://assets/ui/bubble.png") else null
	_bubbles.emitting = false
	_bubbles.amount = 14
	_bubbles.lifetime = 1.1
	_bubbles.explosiveness = 0.35
	_bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_bubbles.emission_sphere_radius = 55.0
	_bubbles.direction = Vector2(0, -1)
	_bubbles.spread = 45.0
	_bubbles.initial_velocity_min = 20.0
	_bubbles.initial_velocity_max = 70.0
	_bubbles.gravity = Vector2(0, -30)
	_bubbles.scale_amount_min = 0.25
	_bubbles.scale_amount_max = 0.7
	_bubbles.position = Vector2(0, -180)
	add_child(_bubbles)


func setup(level: Dictionary) -> void:
	_token += 1
	_busy = false
	_stop_idle()
	var cfg: Dictionary = level.get("char", {})
	action = String(level.get("action", "stand"))
	idle_pos = _vec(cfg.get("pos", [930, 505]))
	idle_scale = float(cfg.get("scale", 0.62))
	_start_pose = String(cfg.get("start_pose", "stand"))
	_start_pos = _vec(cfg.get("start_pos", idle_pos))
	_start_scale = float(cfg.get("start_scale", idle_scale))

	if _start_pose != "stand" and cfg.has("start_pose"):
		_set_pose(_start_pose, _start_pos, _start_scale)
	else:
		_set_pose("stand", idle_pos, idle_scale)
	_start_idle()


func play_action(audio: Dictionary, action_override: String = "") -> void:
	if _busy:
		return
	_busy = true
	_token += 1
	var token := _token
	_stop_idle()
	var kind := action_override if not action_override.is_empty() else action
	match kind:
		"wake":
			await _act_wake(audio, token)
		"drink":
			await _act_drink(audio, token)
		"brush":
			await _act_brush(audio, token)
		"wash":
			await _act_wash(audio, token)
		"shirt":
			await _act_shirt(audio, token)
		"pants":
			await _act_pants(audio, token)
		"shoes":
			await _act_shoes(audio, token)
		_:
			await _timer(0.4)
	if token != _token:
		return
	_busy = false
	_settle_pose()
	_start_idle()


## Walk / fade to another pose and screen position (used by cutscenes).
func show_at(pose: String, pos: Vector2, new_scale: float, duration: float = 0.5) -> void:
	_stop_idle()
	idle_pos = pos
	idle_scale = new_scale
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", pos, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * new_scale, duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if _pose != pose:
		_set_pose(pose, pos, new_scale)


func play_wince() -> void:
	if _busy:
		return
	_stop_idle()
	var base_x := position.x
	var tween := create_tween()
	for dx in [10.0, -10.0, 7.0, -7.0, 0.0]:
		tween.tween_property(self, "position:x", base_x + dx, 0.05)
	tween.tween_callback(_start_idle)


func play_happy() -> void:
	_stop_idle()
	_set_pose("happy", idle_pos, idle_scale)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * idle_scale * 1.08, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * idle_scale, 0.25)


# ------------------------------------------------------------------ actions --
func _act_wake(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("action", "")))
	await _fade_to("sit", Vector2(760, 470), 0.58, 0.55)
	if token != _token:
		return
	await _timer(0.35)
	if token != _token:
		return
	await _fade_to("stand", idle_pos, idle_scale, 0.50)
	await _timer(0.2)


func _act_drink(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("action", "")))
	await _swap_pose("drink", idle_pos, idle_scale, 0.28)
	if token != _token:
		return
	_schedule_vo(String(audio.get("sip", "")), 1.6, token)
	for i in 2:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE * idle_scale * 1.035, 0.13)
		tween.tween_property(self, "scale", Vector2.ONE * idle_scale, 0.17)
		await tween.finished
		await _timer(0.25)
		if token != _token:
			return
	await _swap_pose("stand", idle_pos, idle_scale, 0.25)


func _act_brush(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("left", "")))
	_schedule_vo(String(audio.get("right", "")), 0.9, token)
	_schedule_vo(String(audio.get("all", "")), 1.8, token)
	_set_pose("brush_a", idle_pos, idle_scale)
	for i in 10:
		if token != _token:
			return
		_set_pose("brush_a" if i % 2 == 0 else "brush_b", idle_pos, idle_scale)
		Audio.play_sfx("brush", -12.0)
		var tween := create_tween()
		tween.tween_property(sprite, "rotation_degrees", -4.0 if i % 2 == 0 else 4.0, 0.10) \
				.set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "rotation_degrees", 0.0, 0.12) \
				.set_trans(Tween.TRANS_SINE)
		await tween.finished
		await _timer(0.06)
	sprite.rotation_degrees = 0.0
	await _swap_pose("stand", idle_pos, idle_scale, 0.22)


func _act_wash(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("loop", "")))
	await _swap_pose("wash", idle_pos, idle_scale, 0.25)
	if token != _token:
		return
	Audio.play_sfx("splash", -6.0)
	_bubbles.emitting = true
	for i in 6:
		if token != _token:
			break
		var tween := create_tween()
		tween.tween_property(sprite, "rotation_degrees", -4.0 if i % 2 == 0 else 4.0, 0.14) \
				.set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(self, "position", idle_pos + Vector2(4 if i % 2 == 0 else -4, -3), 0.14)
		tween.tween_property(sprite, "rotation_degrees", 0.0, 0.14)
		tween.parallel().tween_property(self, "position", idle_pos, 0.14)
		await tween.finished
		await _timer(0.10)
	_bubbles.emitting = false
	sprite.rotation_degrees = 0.0
	await _swap_pose("stand", idle_pos, idle_scale, 0.25)


func _act_shirt(audio: Dictionary, token: int) -> void:
	Audio.play_sfx("sparkle", -2.0)
	await _swap_pose("shirt", idle_pos, idle_scale * 1.05, 0.22)
	if token != _token:
		return
	await _timer(0.15)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * idle_scale, 0.30) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	await _timer(0.30)


func _act_pants(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("action", "")))
	# bend down, then pop upright wearing the pants
	await _swap_pose("shoes", idle_pos, idle_scale * 0.96, 0.22)
	if token != _token:
		return
	await _timer(0.45)
	Audio.play_sfx("sparkle", -4.0)
	await _swap_pose("shirt", idle_pos, idle_scale * 1.04, 0.26)
	await _timer(0.2)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * idle_scale, 0.28) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	await _timer(0.25)


func _act_shoes(audio: Dictionary, token: int) -> void:
	Audio.play_vo(String(audio.get("left", "")))
	_schedule_vo(String(audio.get("right", "")), 1.3, token)
	await _swap_pose("shoes", idle_pos, idle_scale, 0.30)
	if token != _token:
		return
	await _timer(0.55)
	var tween := create_tween()
	tween.tween_property(sprite, "rotation_degrees", -5.0, 0.18) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation_degrees", 5.0, 0.24) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.18)
	await tween.finished
	Audio.play_sfx("snap", -2.0)
	await _swap_pose("stand_shoes", idle_pos, idle_scale, 0.28)


# ------------------------------------------------------------------ helpers --
func _settle_pose() -> void:
	if action == "shirt":
		_set_pose("shirt", idle_pos, idle_scale)
	elif action == "shoes":
		_set_pose("stand_shoes", idle_pos, idle_scale)
	elif action == "wake":
		_set_pose("stand", idle_pos, idle_scale)
	else:
		_set_pose("stand", idle_pos, idle_scale)


func _set_pose(pose: String, pos: Vector2, new_scale: float) -> void:
	var path := CHAR_DIR + "char_%s.png" % pose
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	_pose = pose
	sprite.offset = Vector2.ZERO if pose == "lying" else Vector2(0, FEET_OFFSET)
	sprite.position = Vector2.ZERO
	position = pos
	scale = Vector2.ONE * new_scale
	sprite.modulate = Color.WHITE
	sprite.rotation_degrees = 0.0


func _swap_pose(pose: String, pos: Vector2, new_scale: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	await tween.finished
	_set_pose(pose, pos, new_scale)
	sprite.modulate.a = 0.0
	var tween2 := create_tween()
	tween2.tween_property(sprite, "modulate:a", 1.0, duration)
	await tween2.finished


func _fade_to(pose: String, pos: Vector2, new_scale: float, duration: float) -> void:
	await _swap_pose(pose, pos, new_scale, duration)


func _start_idle() -> void:
	_stop_idle()
	if _busy:
		return
	if _pose == "lying":
		# gentle breathing while the child is still asleep
		var base_scale := scale
		_idle_tween = create_tween().set_loops()
		_idle_tween.tween_property(self, "scale", base_scale * 1.015, 1.3) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_idle_tween.tween_property(self, "scale", base_scale, 1.3) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return
	var base := position
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "position:y", base.y - 4.0, 0.95) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "position:y", base.y, 0.95) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null


func _schedule_vo(path: String, delay: float, token: int) -> void:
	if path.is_empty():
		return
	await get_tree().create_timer(delay).timeout
	if token == _token:
		Audio.play_vo(path)


func _timer(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _vec(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return idle_pos
