class_name BinderUI
extends CanvasLayer

## The persistent bottom "Word Binder".
##
## Cards are rebuilt from data/levels/morning_routine.json on every level. Their order is shuffled
## with a deterministic seed so the correct card is not always in the same
## place (otherwise children quickly learn position instead of the word).

signal card_pressed(card_id: String)
signal drag_started(card_id: String)
signal drag_finished(card_id: String)

const WORD_CARD_SCENE := preload("res://scenes/WordCard.tscn")

@onready var root: Control = $Root
@onready var board: NinePatchRect = $Root/Board
@onready var scroll: ScrollContainer = $Root/Scroll
@onready var cards_box: HBoxContainer = $Root/Scroll/CardsBox


func _ready() -> void:
	root.resized.connect(_sync_width)
	_sync_width()


func show_level(level: Dictionary) -> void:
	_clear_cards()
	var cards: Array = level.get("cards", [])
	var order := _shuffled_indices(cards, String(level.get("id", "")))
	for i in order.size():
		var card := WORD_CARD_SCENE.instantiate() as WordCard
		cards_box.add_child(card)
		card.setup(cards[order[i]])
		card.card_pressed.connect(_forward.bind(card_pressed))
		card.drag_started.connect(_forward.bind(drag_started))
		card.drag_finished.connect(_forward.bind(drag_finished))
		card.modulate.a = 0.0
		card.scale = Vector2(0.86, 0.86)
		var tween := card.create_tween()
		tween.tween_interval(0.04 * i)
		tween.tween_property(card, "modulate:a", 1.0, 0.22)
		tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.28) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sync_width()
	call_deferred("_sync_width")


func _forward(card_id: String, target: Signal) -> void:
	target.emit(card_id)


func get_card(card_id: String) -> WordCard:
	for child in cards_box.get_children():
		var card := child as WordCard
		if card and card.card_id == card_id:
			return card
	return null


func set_locked(locked: bool) -> void:
	for child in cards_box.get_children():
		var card := child as WordCard
		if card:
			card.set_locked(locked)


func _clear_cards() -> void:
	for child in cards_box.get_children():
		cards_box.remove_child(child)
		child.queue_free()


func _shuffled_indices(cards: Array, level_id: String) -> Array:
	var indices: Array = []
	for i in cards.size():
		indices.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(level_id)
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	return indices


func _sync_width() -> void:
	if scroll == null or cards_box == null:
		return
	# The ScrollContainer may show fewer cards than it has room for; making the
	# HBox as wide as the viewport keeps `alignment = center` centred.
	cards_box.custom_minimum_size.x = maxf(scroll.size.x - 8.0, 0.0)
