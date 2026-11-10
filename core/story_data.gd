class_name StoryData
extends RefCounted

## Loads and validates data/story.json.
##
## The JSON is a flat array of levels:
##   [{ title, req_card, prop_img, cards: [{id, text, img, vo}], ... }]
## Any malformed level is reported and skipped so one bad row can never
## crash the game for a child.

const DEFAULT_BG := "res://assets/bgs/bg_bedroom.png"


static func load_levels(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Story file not found: " + path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open story file: " + path)
		return []
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("story.json is not valid JSON")
		return []
	if typeof(parsed) != TYPE_ARRAY:
		push_error("story.json must contain an array of levels")
		return []

	var levels: Array = []
	var source: Array = parsed
	for i in source.size():
		var entry: Variant = source[i]
		if typeof(entry) != TYPE_DICTIONARY:
			push_warning("Level %d is not an object; skipped" % i)
			continue
		var level: Dictionary = entry
		var problem := _validate(level, i)
		if problem != "":
			push_error("Level %d is invalid: %s" % [i, problem])
			continue
		level["index"] = levels.size()
		if not level.has("id") or String(level["id"]).is_empty():
			level["id"] = "level_%d" % i
		if not level.has("title_en"):
			level["title_en"] = String(level["title"])
		if not level.has("hint"):
			level["hint"] = "把 %s 卡片拖到道具上" % _card_text(level, String(level["req_card"]))
		if not level.has("bg_img") or not ResourceLoader.exists(String(level["bg_img"])):
			level["bg_img"] = DEFAULT_BG
		levels.append(level)

	if levels.is_empty():
		push_error("No playable levels found in " + path)
	return levels


static func _validate(level: Dictionary, index: int) -> String:
	for key in ["title", "req_card", "prop_img"]:
		if not level.has(key) or String(level[key]).is_empty():
			return "missing '%s'" % key

	var prop_img := String(level["prop_img"])
	if not ResourceLoader.exists(prop_img):
		return "prop image not found: " + prop_img

	var cards: Variant = level.get("cards", [])
	if typeof(cards) != TYPE_ARRAY or (cards as Array).is_empty():
		return "cards must be a non-empty array"

	var req_card := String(level["req_card"])
	var has_req := false
	var ids: Dictionary = {}
	for card in cards:
		if typeof(card) != TYPE_DICTIONARY:
			return "every card must be an object"
		var c: Dictionary = card
		var card_id := String(c.get("id", ""))
		if card_id.is_empty():
			return "a card is missing 'id'"
		if ids.has(card_id):
			return "duplicate card id: " + card_id
		ids[card_id] = true
		if String(c.get("text", "")).is_empty():
			return "card '%s' is missing 'text'" % card_id
		if card_id == req_card:
			has_req = true

	if not has_req:
		return "req_card '%s' is not in cards" % req_card
	level["cards"] = cards
	return ""


static func _card_text(level: Dictionary, card_id: String) -> String:
	for card in level.get("cards", []):
		if String(card.get("id", "")) == card_id:
			return String(card.get("text", card_id))
	return card_id
