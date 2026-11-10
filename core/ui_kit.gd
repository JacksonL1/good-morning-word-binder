class_name UiKit
extends RefCounted

## Shared look & feel helpers: the kid-friendly theme and the rounded,
## flat-cartoon style boxes used by every panel and button.
##
## Everything is created in code so the .tscn files stay readable and no
## binary theme resource has to be edited by hand.

const INK := Color("#4a4a6a")
const CORAL := Color("#ff8a80")
const TEAL := Color("#60cdc4")
const GREEN := Color("#7fd1ae")
const YELLOW := Color("#ffd166")
const CREAM := Color("#fff8ec")


static func make_style(fill: Color, radius: int = 24, border: Color = Color(0, 0, 0, 0),
		border_width: int = 0, shadow: bool = false,
		shadow_color: Color = Color(0.35, 0.30, 0.45, 0.16),
		shadow_size: int = 10, shadow_offset: Vector2 = Vector2(0, 6),
		padding: Vector4 = Vector4(18, 10, 18, 10)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_detail = 8
	style.anti_aliasing = true
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	if shadow:
		style.shadow_color = shadow_color
		style.shadow_size = shadow_size
		style.shadow_offset = shadow_offset
	style.content_margin_left = padding.x
	style.content_margin_top = padding.y
	style.content_margin_right = padding.z
	style.content_margin_bottom = padding.w
	return style


static func style_panel(panel: Panel, fill: Color, radius: int = 24,
		border: Color = Color(0, 0, 0, 0), border_width: int = 0,
		shadow: bool = false, shadow_color: Color = Color(0.35, 0.30, 0.45, 0.16),
		shadow_size: int = 10) -> void:
	var style := make_style(fill, radius, border, border_width, shadow,
			shadow_color, shadow_size, Vector2(0, 6), Vector4(0, 0, 0, 0))
	panel.add_theme_stylebox_override("panel", style)


static func style_button(button: Button, fill: Color, hover: Color, pressed: Color,
		radius: int = 32, font_color: Color = Color.WHITE, font_size: int = 34,
		border: Color = Color(0, 0, 0, 0), border_width: int = 0,
		shadow: bool = true) -> void:
	button.add_theme_stylebox_override("normal", make_style(fill, radius, border,
			border_width, shadow, Color(0.35, 0.30, 0.45, 0.22), 10, Vector2(0, 6),
			Vector4(26, 14, 26, 16)))
	button.add_theme_stylebox_override("hover", make_style(hover, radius, border,
			border_width, shadow, Color(0.35, 0.30, 0.45, 0.18), 8, Vector2(0, 4),
			Vector4(26, 14, 26, 16)))
	button.add_theme_stylebox_override("pressed", make_style(pressed, radius, border,
			border_width, false, Color(0, 0, 0, 0), 0, Vector2.ZERO,
			Vector4(26, 18, 26, 12)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_font_size_override("font_size", font_size)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
