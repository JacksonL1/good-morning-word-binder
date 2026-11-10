extends Node

## Global audio helper (autoload: "Audio").
##
## Voice-over and sound effects are kept on separate players so a word clip
## never cuts a chime in half. Missing files are tolerated: the game stays
## playable while assets are still being produced.

const BGM_PATH := "res://assets/audio/bgm/morning_loop.wav"
const SFX_PATHS := {
	"pop": "res://assets/audio/sfx/pop.wav",
	"tap": "res://assets/audio/sfx/tap.wav",
	"success": "res://assets/audio/sfx/success.wav",
	"error": "res://assets/audio/sfx/error.wav",
	"clear": "res://assets/audio/sfx/level_clear.wav",
	"finish": "res://assets/audio/sfx/finish.wav",
	"brush": "res://assets/audio/sfx/brush.wav",
	"splash": "res://assets/audio/sfx/splash.wav",
	"snap": "res://assets/audio/sfx/snap.wav",
	"sparkle": "res://assets/audio/sfx/sparkle.wav",
}

var muted := false

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _vo_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _ambience_path := ""
var _vo_cache: Dictionary = {}
var _sfx_cursor := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in 6:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = -2.0
		add_child(player)
		_sfx_players.append(player)

	_vo_player = AudioStreamPlayer.new()
	_vo_player.bus = "Master"
	_vo_player.volume_db = -1.0
	add_child(_vo_player)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -18.0
	add_child(_bgm_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Master"
	_ambience_player.volume_db = -28.0
	add_child(_ambience_player)

	for key in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				_sfx_cache[key] = stream


func play_sfx(name: String, volume_db: float = 0.0) -> void:
	if muted:
		return
	var stream: AudioStream = _sfx_cache.get(name)
	if stream == null:
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db - 2.0
	player.play()


func play_vo(path: String) -> void:
	if muted or path.is_empty():
		return
	var stream: AudioStream = _vo_cache.get(path)
	if stream == null:
		if not ResourceLoader.exists(path):
			return
		stream = load(path)
		if stream == null:
			return
		_vo_cache[path] = stream
	if _vo_player.playing:
		_vo_player.stop()
	_vo_player.stream = stream
	_vo_player.play()


func stop_vo() -> void:
	if _vo_player:
		_vo_player.stop()


func play_bgm() -> void:
	if _bgm_player.playing:
		return
	if not ResourceLoader.exists(BGM_PATH):
		return
	var stream: AudioStream = load(BGM_PATH)
	_enable_wav_loop(stream)
	_bgm_player.stream = stream
	_bgm_player.volume_db = -80.0 if muted else -18.0
	_bgm_player.play()


func play_ambience(path: String) -> void:
	if path == _ambience_path and _ambience_player.playing:
		return
	_ambience_path = path
	_ambience_player.stop()
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	_enable_wav_loop(stream)
	_ambience_player.stream = stream
	_ambience_player.volume_db = -80.0 if muted else -28.0
	_ambience_player.play()


func stop_ambience() -> void:
	_ambience_path = ""
	if _ambience_player:
		_ambience_player.stop()


func _enable_wav_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)


func set_muted(value: bool) -> void:
	muted = value
	if _bgm_player:
		_bgm_player.volume_db = -80.0 if muted else -18.0
	if _ambience_player:
		_ambience_player.volume_db = -80.0 if muted else -28.0
	if muted:
		stop_vo()
		for player in _sfx_players:
			player.stop()


func toggle_mute() -> bool:
	set_muted(not muted)
	return muted
