extends Node

## Dev-only driver used to verify the MVP end to end and capture screenshots.
## It is only instantiated when the game is launched with `-- --autotest`.
##
##   godot --path . -- --autotest --shots=D:/tmp/shots

var main: Node
var out_dir := ProjectSettings.globalize_path("user://autotest_shots")


func setup(game: Node) -> void:
	main = game
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out_dir = arg.substr("--shots=".length())
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	print("[autopilot] screenshot dir: ", out_dir)
	# Capture at the full design resolution even if the physical screen is smaller.
	get_window().size = Vector2i(1280, 720)
	get_window().position = Vector2i(0, 0)
	await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--idletest"):
		await _idle_test()
		return
	if OS.get_cmdline_user_args().has("--uitest"):
		await _ui_test()
		return
	if OS.get_cmdline_user_args().has("--chartest"):
		await _char_test()
		return
	if OS.get_cmdline_user_args().has("--flowtest"):
		await _flow_test()
		return
	if OS.get_cmdline_user_args().has("--animtest"):
		await _anim_test()
		return
	await _wait(0.9)
	await _shot("01_start")

	var play_center: Vector2 = main.play_button.get_global_rect().get_center()
	print("[ui] play rect=", main.play_button.get_global_rect(),
			" overlay=", main.start_overlay.visible,
			" checklist=", main.checklist.visible)
	await _click(play_center)
	await _wait(1.0)
	print("[autopilot] play click: started=", main.game_started)
	if not main.game_started:
		push_warning("play button did not start the game; falling back")
		main.start_game()
	await _wait(0.2)
	await _shot("02_level_1")
	_report_layout()

	# A deliberate wrong card: the prop must turn red, the timer must reset.
	main.debug_drop(_decoy_id())
	await _wait(0.45)
	await _shot("03_mismatch")

	# Force the 10 second idle hint so the capture does not need to wait.
	await _wait(0.8)
	main.debug_show_hint()
	await _wait(0.9)
	await _shot("04_ghost_hint")
	await _wait(0.9)
	await _shot("05_ghost_bounce")

	# Correct drop -> character animation, then the next level.
	# This one uses a real synthetic mouse drag so the whole Godot drag &
	# drop path (drag data, translucent preview, _can_drop_data) is exercised.
	var required := String(main.current_level["req_card"])
	var dragged := await _drag_card(required, "05b_dragging")
	if not dragged:
		push_warning("synthetic drag did not solve the prop; using direct drop")
		main.debug_drop(required)
	await _wait(0.9)
	await _shot("06_action")
	await _wait(0.8)
	await _shot("06b_action")
	await _wait_for(func() -> bool: return main.level_index >= 1 or main.checklist.visible or main.finale_overlay.visible, 10.0)
	await _wait(0.6)
	await _shot("07_level_2")

	# Blast through the remaining levels.
	var guard := 0
	while not main.checklist.visible and not main.finale_overlay.visible and guard < 10:
		var before := int(main.level_index)
		print("[autopilot] loop level_index=", before, " busy=", main.busy,
				" req=", main.current_level.get("req_card", ""))
		print("[char] before shot level=", before + 1,
				" node_visible=", main.character.visible,
				" in_tree=", main.character.is_visible_in_tree(),
				" pos=", main.character.position,
				" gpos=", main.character.global_position,
				" scale=", main.character.scale,
				" mod=", main.character.sprite.modulate,
				" visible=", main.character.sprite.visible,
				" z=", main.character.z_index,
				" tex=", main.character.sprite.texture.resource_path
						if main.character.sprite.texture else "<null>")
		await _shot("level_%02d" % (before + 1))
		var dropped: bool = main.debug_drop(String(main.current_level["req_card"]))
		print("[autopilot]   dropped=", dropped)
		await _wait_for(func() -> bool: return main.level_index != before or main.checklist.visible or main.finale_overlay.visible, 12.0)
		guard += 1
		if guard < 10:
			await _wait(0.6)

	await _wait(0.8)
	print("[autopilot] checklist visible=", main.checklist.visible,
			" level=", main.level_index)
	await _shot("08_checklist")

	for i in 5:
		if i == 0:
			# Use a real click on the first badge to validate the checklist UI.
			var badge_pos: Vector2 = main.checklist.badge_center(0)
			await _click(badge_pos)
			await _wait(0.9)
			print("[autopilot] checklist real click count=",
					main.checklist.completed_count())
		else:
			main.checklist.tap_badge(i)
			await _wait(0.9)
	await _wait_for(func() -> bool: return main.finale_overlay.visible, 8.0)
	await _wait(0.8)
	print("[autopilot] finale visible=", main.finale_overlay.visible)
	await _shot("09_finale")

	var replay_center: Vector2 = main.replay_button.get_global_rect().get_center()
	await _click(replay_center)
	await _wait(1.2)
	print("[autopilot] replay click: started=", main.game_started,
			" level=", main.level_index, " finale=", main.finale_overlay.visible)
	await _shot("10_replay")
	print("[autopilot] done: level_index=", main.level_index, " levels=", main.levels.size())
	await _wait(0.4)
	get_tree().quit()


func _char_test() -> void:
	main.start_game()
	await _wait(0.8)
	for idx in [1, 2, 3, 4, 5]:
		main._load_level(idx)
		await _wait(1.0)
		var c = main.character
		print("[char] level=", idx, " pos=", c.position, " scale=", c.scale,
				" visible=", c.visible, " mod=", c.sprite.modulate,
				" tex=", c.sprite.texture.resource_path if c.sprite.texture else "<null>",
				" z=", c.z_index)
		await _shot("char_%02d" % (idx + 1))
	get_tree().quit()


func _anim_test() -> void:
	main.start_game()
	await _wait(0.8)
	for idx in range(6):
		if int(main.level_index) != idx:
			main._load_level(idx)
		await _wait(0.8)
		var required := String(main.current_level["req_card"])
		var seen: Array[String] = []
		main.debug_drop(required)
		for step in 9:
			await _wait(0.35)
			var tex: Texture2D = main.character.sprite.texture
			var pose_name: String = tex.resource_path.get_file() if tex else "<null>"
			if not seen.has(pose_name):
				seen.append(pose_name)
			print("[anim] lvl=", idx, " t=", "%.2f" % (0.35 * (step + 1)),
					" pose=", pose_name,
					" pos=", main.character.position,
					" alpha=", main.character.sprite.modulate.a)
		print("[anim] LEVEL ", idx, " POSES: ", seen)
		await _wait_for(func() -> bool: return int(main.level_index) != idx or main.checklist.visible, 12.0)
		await _wait(0.5)
		if main.checklist.visible:
			break
	get_tree().quit()


func _flow_test() -> void:
	main.start_game()
	await _wait(1.0)
	while int(main.level_index) < 4:
		var before := int(main.level_index)
		main.debug_drop(String(main.current_level["req_card"]))
		await _wait_for(func() -> bool: return int(main.level_index) != before, 12.0)
		await _wait(0.4)
	await _wait(1.0)
	var c = main.character
	print("[flow] level=", main.level_index, " pos=", c.position,
			" sprite_mod=", c.sprite.modulate, " self_mod=", c.self_modulate,
			" z=", c.z_index, " in_tree=", c.is_visible_in_tree())
	await _shot("flow_a")
	c.z_index = 10
	await _wait(0.4)
	await _shot("flow_b")
	get_tree().quit()


func _ui_test() -> void:
	await _wait(1.0)
	var pc: Vector2 = main.play_button.get_global_rect().get_center()
	print("[ui] play rect=", main.play_button.get_global_rect(),
			" center=", pc,
			" overlay=", main.start_overlay.visible,
			" checklist=", main.checklist.visible,
			" finale=", main.finale_overlay.visible)
	var hover := InputEventMouseMotion.new()
	var hover_pos := _to_window(pc)
	hover.position = hover_pos
	hover.global_position = hover_pos
	Input.parse_input_event(hover)
	await _wait(0.2)
	var hovered := get_viewport().gui_get_hovered_control()
	print("[ui] hovered=", hovered, " path=", hovered.get_path() if hovered else "<null>")
	print("[ui] play_path=", main.play_button.get_path(),
			" parent=", main.play_button.get_parent().name,
			" mouse=", get_viewport().get_mouse_position(),
			" window=", get_window().size,
			" content_scale=", get_window().content_scale_factor)
	for node in [main.start_overlay, main.start_card, main.play_button, main.checklist]:
		var control := node as Control
		if control:
			print("[ui] node ", control.name, " rect=", control.get_global_rect(),
					" visible=", control.is_visible_in_tree(),
					" filter=", control.mouse_filter,
					" disabled=", (control as Button).disabled if control is Button else "-")
	await _click(pc)
	await _wait(0.6)
	print("[ui] started=", main.game_started, " busy=", main.busy,
			" level=", main.level_index)
	get_tree().quit()


func _wait_for(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if bool(condition.call()):
			return true
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return false


func _click(pos: Vector2) -> void:
	var local := _to_window(pos)
	var motion := InputEventMouseMotion.new()
	motion.position = local
	motion.global_position = local
	Input.parse_input_event(motion)
	await get_tree().process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = local
	press.global_position = local
	Input.parse_input_event(press)
	await _wait(0.12)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = local
	release.global_position = local
	Input.parse_input_event(release)
	await get_tree().process_frame


## Design-space (1280x720) -> window client coordinates, respecting the
## canvas_items stretch + keep-aspect letterboxing.
func _to_window(pos: Vector2) -> Vector2:
	var win := Vector2(get_window().size)
	var design := Vector2(1280, 720)
	var factor := minf(win.x / design.x, win.y / design.y)
	var offset := (win - design * factor) * 0.5
	return offset + pos * factor


func _decoy_id() -> String:
	var required := String(main.current_level["req_card"])
	for card in main.current_level["cards"]:
		if String(card["id"]) != required:
			return String(card["id"])
	return required


func _idle_test() -> void:
	main.start_game()
	await _wait(1.0)
	await _shot("idle_00")
	await _wait(10.6)
	print("[idle] ghost visible=", main.ghost.visible,
			" rect=", main.ghost.get_global_rect())
	await _shot("idle_01")
	main._on_prop_tapped()
	await _wait(0.4)
	print("[idle] ghost after tap=", main.ghost.visible,
			" timer=", main.idle_timer.time_left)
	await _shot("idle_02")
	get_tree().quit()


func _drag_card(card_id: String, shot_name: String) -> bool:
	var card: Control = main.binder.get_card(card_id)
	if card == null:
		push_warning("drag source not found: " + card_id)
		return false
	var from_design := card.global_position + card.size * 0.5
	var to_design: Vector2 = main.prop.global_position + Vector2(0, 10)
	var from := _to_window(from_design)
	var to := _to_window(to_design)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	press.global_position = from
	Input.parse_input_event(press)
	await _wait(0.08)

	var steps := 14
	for i in range(1, steps + 1):
		var pos := from.lerp(to, float(i) / float(steps))
		var motion := InputEventMouseMotion.new()
		motion.position = pos
		motion.global_position = pos
		motion.relative = (pos - from) if i == 1 else Vector2.ZERO
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await get_tree().process_frame

	await _wait(0.15)
	print("[drag] dragging=", get_viewport().gui_is_dragging(),
			" data=", get_viewport().gui_get_drag_data())
	for node in get_tree().root.find_children("DragPreview", "Control", true, false):
		var pc := node as Control
		print("[drag] preview=", pc, " rect=", pc.get_global_rect(),
				" visible=", pc.visible, " modulate=", pc.modulate,
				" parent=", pc.get_parent())
	await _shot(shot_name)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = to
	release.global_position = to
	Input.parse_input_event(release)
	await _wait(0.20)
	return bool(main.prop.drop_zone.solved)


func _report_layout() -> void:
	var label: Label = main.hint_label
	var font: Font = label.get_theme_font("font")
	print("[layout] viewport=", get_viewport().get_visible_rect().size)
	print("[layout] window=", get_window().size, " theme=", get_window().theme != null)
	print("[layout] hint font=", font, " size=", label.get_theme_font_size("font_size"))
	print("[layout] hint font path=", font.resource_path if font else "<null>",
			" fallbacks=", font.fallbacks.size() if font else -1,
			" has 把=", font.has_char("把".unicode_at(0)) if font else false,
			" has A=", font.has_char(65) if font else false)
	print("[layout] binder root=", main.binder.root.get_global_rect(),
			" scroll=", main.binder.scroll.get_global_rect())
	print("[layout] cardsbox=", main.binder.cards_box.get_global_rect())
	for child in main.binder.cards_box.get_children():
		var card := child as Control
		print("[layout] card ", card.name, " ", card.get_global_rect(),
				" modulate=", card.modulate)
	print("[layout] prop=", main.prop.get_global_position(),
			" drop=", main.prop.drop_zone.get_global_rect())
	print("[layout] ghost=", main.ghost.visible, " pos=", main.ghost.position)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_warning("empty screenshot: " + label)
		return
	var path := out_dir.path_join(label + ".png")
	var error := image.save_png(path)
	if error != OK:
		push_warning("could not save screenshot %s (%d)" % [path, error])
	else:
		print("[autopilot] shot ", path)
