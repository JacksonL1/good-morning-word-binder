class_name WordCard
extends Control

## A draggable word card living in the Word Binder.
##
## Drag & drop contract:
##   * `_get_drag_data()` returns { type = "word_card", card_id, word }
##     together with a translucent copy of the card as the drag preview.
##   * `BaseProp` validates the returned `card_id`.
##   * Signature signals let the director reset its zero-frustration timer.

signal card_pressed(card_id: String)
signal drag_started(card_id: String)
signal drag_finished(card_id: String)

const CARD_TEXTURE := "res://assets/ui/card.png"

@export var card_id: String = ""
@export var word_text: String = ""
@export var vo_path: String = ""
@export var icon_path: String = ""

var _locked := false
var _dragging := false
var _hover_tween: Tween
var _drag_tween: Tween

@onready var card_bg: NinePatchRect = $CardBg
@onready var icon_rect: TextureRect = $Icon
@onready var word_label: Label = $Word


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)
	_on_resized()
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	if word_text != "":
		word_label.text = word_text


## Fills the card with one entry of `cards` from data/levels/morning_routine.json.
func setup(card: Dictionary) -> void:
	card_id = String(card.get("id", ""))
	word_text = String(card.get("text", card_id))
	icon_path = String(card.get("img", ""))
	vo_path = String(card.get("vo", ""))
	if word_label == null:
		# Not in the tree yet: _ready() will apply the values we stored.
		return
	word_label.text = word_text
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	tooltip_text = word_text


func set_locked(locked: bool) -> void:
	_locked = locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.55) if locked else Color.WHITE, 0.20)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.20)


func _on_resized() -> void:
	pivot_offset = size * 0.5


func _on_mouse_entered() -> void:
	if _locked or _dragging:
		return
	_animate_scale(Vector2(1.045, 1.045), 0.16)
	Audio.play_sfx("tap", -12.0)


func _on_mouse_exited() -> void:
	if _dragging:
		return
	_animate_scale(Vector2.ONE, 0.18)


func _animate_scale(target: Vector2, duration: float) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target, duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			# Touching/dragging any card always speaks its word: the audio is
			# the lesson, the drag is the game.
			Audio.play_vo(vo_path)
			card_pressed.emit(card_id)


## Godot's drag API: returns the payload and installs a translucent preview
## that follows the finger/cursor.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if _locked or card_id.is_empty():
		return null
	_dragging = true
	drag_started.emit(card_id)
	Audio.play_sfx("pop", -6.0)
	set_drag_preview(_build_drag_preview())
	if _drag_tween and _drag_tween.is_valid():
		_drag_tween.kill()
	_drag_tween = create_tween()
	_drag_tween.tween_property(self, "modulate", Color(1, 1, 1, 0.35), 0.12)
	return {
		"type": "word_card",
		"card_id": card_id,
		"word": word_text,
	}


func _build_drag_preview() -> Control:
	var preview := Control.new()
	preview.name = "DragPreview"
	preview.size = size
	preview.custom_minimum_size = size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1, 1, 1, 0.78)
	preview.pivot_offset = size * 0.5
	preview.scale = Vector2(0.94, 0.94)

	var background := NinePatchRect.new()
	background.texture = load(CARD_TEXTURE) if ResourceLoader.exists(CARD_TEXTURE) else null
	background.patch_margin_left = 44
	background.patch_margin_top = 44
	background.patch_margin_right = 44
	background.patch_margin_bottom = 44
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(background)

	if icon_rect.texture:
		var icon := TextureRect.new()
		icon.texture = icon_rect.texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = icon_rect.position
		icon.size = icon_rect.size
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(icon)

	var label := Label.new()
	label.text = word_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = word_label.position
	label.size = word_label.size
	label.add_theme_font_override("font", word_label.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", word_label.get_theme_font_size("font_size"))
	label.add_theme_color_override("font_color", word_label.get_theme_color("font_color"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(label)
	return preview


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not _dragging:
			return
		_dragging = false
		if _drag_tween and _drag_tween.is_valid():
			_drag_tween.kill()
		var target := Color(1, 1, 1, 0.55) if _locked else Color.WHITE
		_drag_tween = create_tween()
		_drag_tween.tween_property(self, "modulate", target, 0.18)
		drag_finished.emit(card_id)
