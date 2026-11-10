class_name BaseProp
extends Control

## The "receiver" half of the drag & drop mechanic.
##
## This Control is a child of `PropNode` and is deliberately larger than the
## visible sprite (+30% hit area for small fingers). It changes the colour of
## the sibling `$"../Sprite2D"`, and reports both outcomes through signals so
## the director (Main.gd) owns all game flow.

signal matched(card_id: String)
signal mismatched(card_id: String)
signal tapped

@export var required_card: String = ""
@export var hit_padding: float = 1.30

var solved := false

var _base_sprite_scale := Vector2.ONE
var _base_sprite_position := Vector2.ZERO
var _anim: Tween
var _hovered := false

@onready var sprite: Sprite2D = $"../Sprite2D"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_base_sprite_position = sprite.position
	set_process_input(true)


func configure(card_id: String, sprite_size: Vector2) -> void:
	required_card = card_id
	var area := sprite_size * hit_padding
	custom_minimum_size = area
	size = area
	position = -area * 0.5
	_base_sprite_scale = sprite.scale
	_base_sprite_position = sprite.position
	reset_state()


func get_base_scale() -> Vector2:
	return _base_sprite_scale


func reset_state() -> void:
	solved = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_hovered = false
	if _anim and _anim.is_valid():
		_anim.kill()
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = _base_sprite_scale
		sprite.position = _base_sprite_position
	modulate = Color.WHITE


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if solved:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = data
	if String(payload.get("type", "")) != "word_card":
		return false
	# A correct card gets a soft golden glow while hovering, a wrong one stays
	# neutral — the colour verdict only happens after release.
	var correct := String(payload.get("card_id", "")) == required_card
	sprite.modulate = Color(1.0, 0.98, 0.78) if correct else Color(0.96, 0.96, 1.0)
	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = data
	var card_id := String(payload.get("card_id", ""))
	if card_id == required_card:
		_play_success()
		matched.emit(card_id)
	else:
		_play_mismatch()
		mismatched.emit(card_id)


func _play_success() -> void:
	solved = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_anim()
	sprite.modulate = Color(0.58, 1.0, 0.66)
	_anim = create_tween()
	_anim.tween_property(sprite, "scale", _base_sprite_scale * 1.12, 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim.tween_property(sprite, "scale", _base_sprite_scale, 0.32) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_anim.tween_interval(0.9)
	_anim.tween_property(sprite, "modulate", Color.WHITE, 0.35)


func _play_mismatch() -> void:
	_kill_anim()
	sprite.modulate = Color(1.0, 0.56, 0.56)
	var origin := _base_sprite_position
	_anim = create_tween()
	for offset in [12.0, -12.0, 9.0, -9.0, 4.0, 0.0]:
		_anim.tween_property(sprite, "position:x", origin.x + offset, 0.055) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_anim.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.55) \
			.set_delay(0.15)


func _kill_anim() -> void:
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = null
	sprite.position = _base_sprite_position
	sprite.scale = _base_sprite_scale


func _on_mouse_entered() -> void:
	if solved:
		return
	_hovered = true


func _on_mouse_exited() -> void:
	_hovered = false
	if not solved:
		# Leaving the prop mid-drag must clear the hover tint, otherwise a
		# prop the child brushed past would stay highlighted.
		sprite.modulate = Color.WHITE


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not solved:
		sprite.modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if solved:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			tapped.emit()
			_bounce_hint()


## Small "I'm here" wiggle when a child taps the prop instead of dragging.
func _bounce_hint() -> void:
	if solved:
		return
	var base := _base_sprite_scale
	var tween := create_tween()
	tween.tween_property(sprite, "scale", base * 1.06, 0.10) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", base, 0.16) \
			.set_trans(Tween.TRANS_SINE)

