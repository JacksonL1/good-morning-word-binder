class_name PropNode
extends Node2D

## Visual prop + oversized drop receiver.
##
## Node layout follows the white paper:
##   PropNode (Node2D)
##   ├── Sprite2D   <- the artwork (BaseProp tints this node)
##   └── DropZone (Control/BaseProp) <- +30% hit area
##
## `setup()` is fully data driven from one entry of data/levels/morning_routine.json.

const MAX_SIZE := Vector2(560, 440)
# Keep the (invisible) drop receiver out of the top bar and out of the word
# binder: otherwise a card dropped on the UI could accidentally solve a level.
const HIT_TOP_LIMIT := 130.0
const HIT_BOTTOM_LIMIT := 532.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var drop_zone: BaseProp = $DropZone


## Configures this prop from a step's `prop` / `props[]` entry.
func setup_prop(cfg: Dictionary, req_card: String) -> void:
	setup({
		"prop_img": cfg.get("img", ""),
		"prop_pos": cfg.get("pos", [640, 340]),
		"prop_scale": cfg.get("scale", 1.0),
		"req_card": req_card,
	})


func setup(level: Dictionary) -> void:
	var texture: Texture2D = null
	var path := String(level.get("prop_img", ""))
	if ResourceLoader.exists(path):
		texture = load(path)
	if texture:
		sprite.texture = texture

	var tex_size := Vector2(256, 256)
	if sprite.texture:
		tex_size = sprite.texture.get_size()
	var fit := minf(MAX_SIZE.x / tex_size.x, MAX_SIZE.y / tex_size.y)
	var factor := fit * float(level.get("prop_scale", 1.0))
	var final_scale := Vector2.ONE * factor

	sprite.position = Vector2.ZERO
	sprite.scale = final_scale
	sprite.modulate = Color.WHITE

	drop_zone.configure(String(level.get("req_card", "")), tex_size * factor)

	var where: Array = level.get("prop_pos", [640, 372])
	position = Vector2(float(where[0]), float(where[1]))
	_clamp_hit_area()
	play_intro()


func _clamp_hit_area() -> void:
	var top := drop_zone.position.y + position.y
	var bottom := top + drop_zone.size.y
	var new_top := maxf(top, HIT_TOP_LIMIT)
	var new_bottom := minf(bottom, HIT_BOTTOM_LIMIT)
	if new_bottom <= new_top:
		return
	drop_zone.position.y += new_top - top
	drop_zone.custom_minimum_size.y = new_bottom - new_top
	drop_zone.size.y = new_bottom - new_top


func play_intro() -> void:
	if drop_zone == null:
		return
	var final_scale := drop_zone.get_base_scale()
	sprite.scale = final_scale * 0.86
	sprite.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", final_scale, 0.38) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.22)


func set_prop_visible(value: bool) -> void:
	sprite.visible = value
	drop_zone.visible = value
