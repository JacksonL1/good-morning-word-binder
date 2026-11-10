class_name LevelData
extends RefCounted

## Loads the game manifest, the room table and every level file.
##
## data/game.json      -> { title, levels: [ "res://data/levels/x.json" ] }
## data/rooms.json     -> { room_id: { name, name_en, bg, ambience } }
## data/levels/*.json  -> { id, title, title_cn, steps: [ ... ] }
##
## Step types:
##   drag       one prop, one correct card
##   pair       several props, each with its own correct card (left/right shoes)
##   cutscene   inserted animation / video, tap to skip
##   checklist  the door badge check
##
## Unknown or broken steps are skipped with a warning so a content mistake can
## never crash the game for a child.

const GAME_PATH := "res://data/game.json"
const ROOMS_PATH := "res://data/rooms.json"


static func load_all() -> Dictionary:
	var result := {"title": "Good Morning!", "levels": [], "rooms": {}}
	result["rooms"] = _read_json(ROOMS_PATH, TYPE_DICTIONARY)

	var game: Variant = _read_json(GAME_PATH, TYPE_DICTIONARY)
	if typeof(game) != TYPE_DICTIONARY:
		push_error("game.json missing or invalid")
		return result
	var manifest: Dictionary = game
	result["title"] = String(manifest.get("title", "Good Morning!"))

	var level_paths: Array = manifest.get("levels", [])
	for path in level_paths:
		var level: Variant = _read_json(String(path), TYPE_DICTIONARY)
		if typeof(level) != TYPE_DICTIONARY:
			push_error("level file invalid: " + String(path))
			continue
		var cleaned := _clean_level(level)
		if cleaned.is_empty():
			continue
		var rooms: Dictionary = result["rooms"]
		cleaned["has_checklist"] = _has_checklist(cleaned)
		result["levels"].append(cleaned)
		if rooms.is_empty():
			push_error("rooms.json is empty")
	return result


static func _read_json(path: String, expected: int) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("file not found: " + path)
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("invalid JSON: " + path)
		return null
	if typeof(parsed) != expected:
		push_error("unexpected JSON root in " + path)
		return null
	return parsed


static func _has_checklist(level: Dictionary) -> bool:
	for step in level.get("steps", []):
		if String(step.get("type", "")) == "checklist":
			return true
	return false


static func _clean_level(level: Dictionary) -> Dictionary:
	var steps: Array = level.get("steps", [])
	var kept: Array = []
	for i in steps.size():
		var step: Variant = steps[i]
		if typeof(step) != TYPE_DICTIONARY:
			push_warning("step %d is not an object; skipped" % i)
			continue
		var s: Dictionary = step
		var kind := String(s.get("type", ""))
		if kind == "" and s.has("req_card"):
			kind = "drag"
			s["type"] = kind
		if kind == "":
			push_warning("step %d has no type; skipped" % i)
			continue
		if not s.has("id"):
			s["id"] = "step_%d" % i
		if kind == "drag" and String(s.get("req_card", "")).is_empty():
			push_warning("drag step %s has no req_card; skipped" % s["id"])
			continue
		if (kind == "drag" or kind == "pair") and (s.get("cards", []) as Array).is_empty():
			push_warning("step %s has no cards; skipped" % s["id"])
			continue
		if kind == "pair" and (s.get("props", []) as Array).size() < 2:
			push_warning("pair step %s needs two props; skipped" % s["id"])
			continue
		if kind == "drag" and not s.has("prop") and s.has("prop_img"):
			# legacy single-prop layout
			s["prop"] = {
				"img": s["prop_img"],
				"pos": s.get("prop_pos", [640, 340]),
				"scale": s.get("prop_scale", 1.0),
			}
		kept.append(s)
	level["steps"] = kept
	if kept.is_empty():
		push_error("level %s has no playable steps" % level.get("id", "?"))
		return {}
	return level
