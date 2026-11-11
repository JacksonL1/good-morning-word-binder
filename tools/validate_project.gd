extends SceneTree

## Headless content check: every asset referenced by the game/level/room data
## must exist, load and be non-empty. Run with:
##   godot --headless --path . --script res://tools/validate_project.gd

const LevelDataScript := preload("res://core/level_data.gd")

const CHAR_POSES := ["stand", "happy", "drink", "brush_a", "brush_b", "wash",
		"shirt", "stand_shoes", "sit", "shoes", "lying"]

var errors := 0
var warnings := 0
var checked := 0


func _init() -> void:
	var data: Dictionary = LevelDataScript.load_all()
	var levels: Array = data.get("levels", [])
	var rooms: Dictionary = data.get("rooms", {})
	print("levels: ", levels.size(), "  rooms: ", rooms.size())
	if levels.is_empty():
		errors += 1

	for room_id in rooms:
		var room: Dictionary = rooms[room_id]
		_check_asset(String(room.get("bg", "")), "room bg " + String(room_id))
		_check_audio(String(room.get("ambience", "")), "room ambience " + String(room_id))

	for level in levels:
		var level_id := String(level.get("id", "?"))
		for step in level.get("steps", []):
			var step_id := "%s/%s" % [level_id, String(step.get("id", "?"))]
			var kind := String(step.get("type", ""))
			if not room_exists(rooms, String(step.get("room", ""))):
				_fail("step %s references unknown room '%s'" % [step_id, step.get("room", "")])
			match kind:
				"drag":
					_check_asset(String((step.get("prop", {}) as Dictionary).get("img", "")),
							"prop " + step_id)
				"pair":
					for entry in step.get("props", []):
						_check_asset(String(entry.get("img", "")), "prop " + step_id)
				"cutscene":
					_check_audio(String(step.get("vo", "")), "cutscene vo " + step_id)
					var video := String(step.get("video", ""))
					if not video.is_empty() and not ResourceLoader.exists(video):
						_warn("cutscene video not present yet (falls back to poses): " + video)
					for entry in step.get("poses", []):
						var pose := String(entry.get("pose", "stand"))
						_check_asset("res://assets/char/char_%s.png" % pose,
								"cutscene pose " + step_id)
				"checklist":
					pass
				_:
					_fail("step %s has unknown type '%s'" % [step_id, kind])

			for card in step.get("cards", []):
				_check_asset(String(card.get("img", "")),
						"card img " + step_id + " " + String(card.get("id", "")))
				_check_audio(String(card.get("vo", "")),
						"card vo " + step_id + " " + String(card.get("id", "")))

			var audio: Dictionary = step.get("audio", {})
			for key in audio:
				_check_audio(String(audio[key]), "%s audio.%s" % [step_id, key])

			if kind == "pair":
				var props: Array = step.get("props", [])
				var req: Array = []
				for entry in props:
					req.append(String(entry.get("req_card", "")))
				if req.size() != 2 or req[0] == req[1]:
					_fail("pair step %s needs two different req_cards" % step_id)

	for pose in CHAR_POSES:
		_check_asset("res://assets/char/char_%s.png" % pose, "character " + pose)
	_check_asset("res://assets/ui/bubble.png", "bubble particle")

	var checklist_text := FileAccess.get_file_as_string("res://data/checklist.json")
	var checklist: Variant = JSON.parse_string(checklist_text)
	if typeof(checklist) != TYPE_DICTIONARY:
		_fail("checklist.json is not valid JSON")
	else:
		var cdata: Dictionary = checklist
		for key in ["intro_vo", "finish_vo", "timeout_vo"]:
			_check_audio(String(cdata.get(key, "")), "checklist " + key)
		for badge in cdata.get("badges", []):
			_check_asset(String(badge.get("icon", "")),
					"checklist icon " + String(badge.get("label", "")))
			_check_audio(String(badge.get("vo", "")),
					"checklist VO " + String(badge.get("label", "")))

	_check_audio("res://assets/audio/vo/success.mp3", "VO success")
	_check_audio("res://assets/audio/vo/try_again.mp3", "VO try_again")
	_check_audio("res://assets/audio/vo/finish.mp3", "VO finish")
	_check_audio("res://assets/audio/vo/hint.mp3", "VO hint")
	for sfx in ["pop", "tap", "success", "error", "level_clear", "finish",
			"brush", "splash", "snap", "sparkle"]:
		_check_audio("res://assets/audio/sfx/%s.wav" % sfx, "SFX " + sfx)
	_check_audio("res://assets/audio/bgm/morning_loop.wav", "BGM")

	var theme: Theme = load("res://assets/ui/kid_theme.tres")
	if theme == null or theme.default_font == null:
		_fail("kid theme/font missing")
	else:
		var font := theme.default_font
		print("theme font: A=", font.has_char(65), " a=", font.has_char(97))
		if not font.has_char(65):
			_fail("theme font cannot render latin text")
		if font.has_char("把".unicode_at(0)):
			_warn("theme font still contains CJK glyphs; the game UI is English only")

	print("checked: ", checked, " errors: ", errors, " warnings: ", warnings)
	quit(1 if errors > 0 else 0)


func room_exists(rooms: Dictionary, room_id: String) -> bool:
	return room_id.is_empty() or rooms.has(room_id)


func _check_asset(path: String, label: String) -> void:
	checked += 1
	if path.is_empty() or not ResourceLoader.exists(path):
		_fail(label + " missing: " + path)
		return
	var res: Resource = load(path)
	if res == null:
		_fail(label + " failed to load: " + path)


func _check_audio(path: String, label: String) -> void:
	checked += 1
	if path.is_empty() or not ResourceLoader.exists(path):
		_fail(label + " missing: " + path)
		return
	var stream: Resource = load(path)
	if stream == null:
		_fail(label + " failed to load: " + path)
		return
	if stream is AudioStream:
		var audio := stream as AudioStream
		if audio.get_length() <= 0.05:
			_fail(label + " is empty: " + path)


func _fail(message: String) -> void:
	errors += 1
	printerr("FAIL: " + message)


func _warn(message: String) -> void:
	warnings += 1
	print("WARN: " + message)
