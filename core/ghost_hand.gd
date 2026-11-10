class_name GhostHand
extends Control

## Zero-frustration hint: a translucent ghost hand that floats above the
## correct word card and bounces until the child touches it.
##
## Main.gd shows this after 10 idle seconds and hides it on any interaction.

const VIEWPORT := Vector2(1280, 720)

var _move_tween: Tween
var _bounce_tween: Tween
var _hand_home := Vector2.ZERO

@onready var hand: TextureRect = $Hand
@onready var hint_label: Label = $Hint


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	UiKit.style_panel($Bubble, Color(1, 1, 1, 0.95), 24, Color(1, 1, 1, 0.9), 2,
			true, Color(0.35, 0.30, 0.45, 0.18), 8)
	_hand_home = hand.position


func show_hint(card: WordCard) -> void:
	if card == null:
		return
	var target := Vector2(
		card.global_position.x + card.size.x * 0.5 - size.x * 0.5,
		card.global_position.y - size.y + 18.0
	)
	target.x = clampf(target.x, 8.0, VIEWPORT.x - size.x - 8.0)
	target.y = clampf(target.y, 8.0, VIEWPORT.y - size.y - 8.0)
	show_at(target, "拖到道具上!")


func show_at(target: Vector2, message: String = "") -> void:
	_kill_tweens()
	hint_label.text = message if not message.is_empty() else "拖这张卡片!"
	position = target + Vector2(0, 26)
	modulate.a = 0.0
	visible = true
	hand.position = _hand_home

	_move_tween = create_tween()
	_move_tween.set_parallel(true)
	_move_tween.tween_property(self, "position", target, 0.55) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "modulate:a", 1.0, 0.30)
	_move_tween.chain().tween_callback(_start_bounce)


func _start_bounce() -> void:
	if not visible:
		return
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	_bounce_tween = create_tween().set_loops()
	_bounce_tween.tween_property(hand, "position:y", _hand_home.y - 16.0, 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bounce_tween.tween_property(hand, "position:y", _hand_home.y, 0.42) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func hide_hand() -> void:
	_kill_tweens()
	visible = false
	modulate.a = 0.0
	if hand:
		hand.position = _hand_home


func _kill_tweens() -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	_move_tween = null
	_bounce_tween = null
