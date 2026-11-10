extends SceneTree

## Headless content check: every path referenced by story.json must exist and
## load, and all audio must be non-empty. Run with:
##   godot --headless --path . --script res://tools/validate_project.gd

const StoryDataScript := preload("res://core/story_data.gd")

var errors := 0
var checked := 0


func _init() -> void:
	var levels: Array = StoryDataScript.load_levels("res://data/story.json")
	print("levels: ", levels.size())
	if levels.is_empty():
		errors += 1

	for level in levels:
		var name := String(level.get("title_en", "?"))
		_check_asset(String(level["bg_img"]), "bg " + name)
		_check_asset(String(level["prop_img"]), "prop " + name)
		for card in level["cards"]:
			_check_asset(String(card.get("img", "")), "card img " + String(card["id"]))
			_check_audio(String(card.get("vo", "")), "VO " + String(card["id"]))
		var audio: Dictionary = level.get("audio", {})
		for key in ["intro", "action", "done", "timeout", "wrong", "left", "right", "all", "sip", "loop"]:
			if audio.has(key):
				_check_audio(String(audio[key]), "%s audio.%s" % [name, key])
		if level.has("ambience"):
			_check_audio(String(level["ambience"]), "%s ambience" % name)

	for pose in ["stand", "happy", "drink", "brush_a", "brush_b", "wash", "shirt",
			"stand_shoes", "sit", "shoes", "lying"]:
		_check_asset("res://assets/char/char_%s.png" % pose, "character " + pose)
	_check_asset("res://assets/ui/bubble.png", "bubble particle")

	var checklist_text := FileAccess.get_file_as_string("res://data/checklist.json")
	var checklist: Variant = JSON.parse_string(checklist_text)
	if typeof(checklist) != TYPE_DICTIONARY:
		_fail("checklist.json is not valid JSON")
	else:
		var data: Dictionary = checklist
		for key in ["intro_vo", "finish_vo", "timeout_vo"]:
			_check_audio(String(data.get(key, "")), "checklist " + key)
		for badge in data.get("badges", []):
			_check_asset(String(badge.get("icon", "")), "checklist icon " + String(badge.get("label", "")))
			_check_audio(String(badge.get("vo", "")), "checklist VO " + String(badge.get("label", "")))

	_check_audio("res://assets/audio/vo/success.mp3", "VO success")
	_check_audio("res://assets/audio/vo/try_again.mp3", "VO try_again")
	_check_audio("res://assets/audio/vo/finish.mp3", "VO finish")
	_check_audio("res://assets/audio/vo/welcome.mp3", "VO welcome")
	_check_audio("res://assets/audio/vo/hint.mp3", "VO hint")
	for sfx in ["pop", "tap", "success", "error", "level_clear", "finish",
			"brush", "splash", "snap", "sparkle"]:
		_check_audio("res://assets/audio/sfx/%s.wav" % sfx, "SFX " + sfx)
	_check_audio("res://assets/audio/bgm/morning_loop.wav", "BGM")
	_check_audio("res://assets/audio/ambience/bedroom.wav", "ambience bedroom")
	_check_audio("res://assets/audio/ambience/bathroom.wav", "ambience bathroom")

	var theme: Theme = load("res://assets/ui/kid_theme.tres")
	if theme == null or theme.default_font == null:
		_fail("kid theme/font missing")
	else:
		var font := theme.default_font
		print("theme font fallbacks=", font.fallbacks.size(),
				" 把=", font.has_char("把".unicode_at(0)),
				" A=", font.has_char(65))
		if not font.has_char("把".unicode_at(0)):
			_fail("theme font cannot render Chinese")

	print("checked: ", checked, " errors: ", errors)
	quit(1 if errors > 0 else 0)


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
