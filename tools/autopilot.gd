extends Node

## Dev-only driver used to verify the whole game end to end and capture shots.
## Only instantiated when launched with `-- --autotest`.
##
##   godot --path . --audio-driver Dummy -- --autotest --shots=D:/tmp/shots

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
	get_window().size = Vector2i(1280, 720)
	get_window().position = Vector2i(0, 0)
	await get_tree().process_frame

	if OS.get_cmdline_user_args().has("--idletest"):
		await _idle_test()
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
	await _click(play_center)
	await _wait(1.0)
	print("[autopilot] play click: started=", main.game_started)
	if not main.game_started:
		push_warning("play button did not start the game; falling back")
		main.start_game()
	await _wait(0.3)
	await _shot("02_step_1_wake")
	_report_state()

	# Wrong card first.
	main.debug_drop(_decoy_card())
	await _wait(0.5)
	await _shot("03_mismatch")

	# Idle hint.
	main.debug_show_hint()
	await _wait(1.5)
	await _shot("04_ghost_hint")

	# Real synthetic drag on the correct card.
	var ok := await _drag_correct_card("05_dragging")
	if not ok:
		push_warning("synthetic drag failed; using direct drop")
		main.debug_solve_step()
	await _wait(0.8)
	await _shot("06_action")
	await _wait_until_step_change(12.0)

	# Walk the rest of the level.
	var guard := 0
	while guard < 40:
		guard += 1
		if main.finale_overlay.visible:
			break
		if main.checklist.visible:
			print("[autopilot] checklist reached")
			await _wait(0.6)
			await _shot("08_checklist")
			await _complete_checklist()
			print("[autopilot] checklist done, waiting for finale")
			var waited := 0.0
			while waited < 8.0 and not main.finale_overlay.visible:
				await get_tree().create_timer(0.1).timeout
				waited += 0.1
			await _wait(0.8)
			break
		if main.cutscene.visible:
			print("[autopilot] cutscene: ", main.current_step.get("id", ""),
					" room=", main.current_step.get("room", ""))
			await _wait(0.7)
			await _shot("cut_%s" % String(main.current_step.get("id", "x")))
			main.cutscene.skip()
			await _wait(0.6)
			continue
		var step: Dictionary = main.current_step
		var kind := String(step.get("type", "drag"))
		print("[autopilot] step=", step.get("id", ""), " type=", kind,
				" room=", step.get("room", ""))
		if kind == "drag" or kind == "pair":
			# let the room flash overlay finish before capturing
			await _wait(0.60)
			await _shot("lvl_%02d_%s" % [main.step_index + 1, String(step.get("id", "x"))])
			main.debug_solve_step()
			await _wait(0.9)
			await _wait_until_step_change(14.0)
		else:
			await _wait(0.5)

	await _wait(0.8)
	print("[autopilot] finale visible=", main.finale_overlay.visible,
			" level=", main.level_index)
	await _shot("09_finale")

	if main.replay_button and main.finale_overlay.visible:
		var replay_center: Vector2 = main.replay_button.get_global_rect().get_center()
		await _click(replay_center)
		await _wait(1.2)
		print("[autopilot] replay click: started=", main.game_started,
				" step=", main.step_index)
		await _shot("10_replay")
	print("[autopilot] done")
	await _wait(0.3)
	get_tree().quit()


func _report_state() -> void:
	print("[state] room=", main.current_room,
			" step=", main.step_index,
			" of ", (main.steps as Array).size(),
			" id=", main.current_step.get("id", ""),
			" props=", main._props.size(),
			" char_pose=", main.character._pose)


func _decoy_card() -> String:
	var required := String(main.current_step.get("req_card", ""))
	for node in main._props:
		if node.drop_zone.solved:
			continue
		required = node.drop_zone.required_card
		break
	for card in main.current_step.get("cards", []):
		if String(card.get("id", "")) != required:
			return String(card.get("id", ""))
	return required


func _wait_until_step_change(previous_step: int, timeout: float = 12.0) -> bool:
	# step index or overlay state must change
	var start_index := int(main.step_index)
	var elapsed := 0.0
	while elapsed < timeout:
		if main.finale_overlay.visible or main.checklist.visible or main.cutscene.visible:
			return true
		if int(main.step_index) != start_index:
			return true
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return false


func _drag_correct_card(shot_name: String) -> bool:
	var target: Node = null
	for node in main._props:
		if not node.drop_zone.solved:
			target = node
			break
	if target == null:
		return false
	var card: Control = main.binder.get_card(target.drop_zone.required_card)
	if card == null:
		return false
	var from := _to_window(card.global_position + card.size * 0.5)
	var to := _to_window(target.global_position)

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

	await _wait(0.2)
	print("[drag] dragging=", get_viewport().gui_is_dragging(),
			" data=", get_viewport().gui_get_drag_data())
	await _shot(shot_name)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = to
	release.global_position = to
	Input.parse_input_event(release)
	await _wait(0.3)
	return bool(target.drop_zone.solved)


func _complete_checklist() -> void:
	var count: int = main.checklist._badges.size()
	for i in count:
		if i == 0:
			var pos: Vector2 = main.checklist.badge_center(0)
			await _click(pos)
			await _wait(0.8)
			print("[autopilot] checklist real click count=",
					main.checklist.completed_count())
		else:
			main.checklist.tap_badge(i)
			await _wait(0.8)


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


func _flow_test() -> void:
	main.start_game()
	await _wait(0.8)
	for i in range(3):
		print("[flow] step=", main.step_index, " id=", main.current_step.get("id", ""),
				" room=", main.current_room, " cutscene=", main.cutscene.visible)
		await _wait(0.4)
	get_tree().quit()


func _anim_test() -> void:
	main.start_game()
	await _wait(0.8)
	var guard := 0
	while guard < 40 and not main.finale_overlay.visible:
		guard += 1
		if main.cutscene.visible:
			main.cutscene.skip()
			await _wait(0.6)
			continue
		if main.checklist.visible:
			break
		var kind := String(main.current_step.get("type", ""))
		if kind != "drag" and kind != "pair":
			await _wait(0.4)
			continue
		var seen: Array[String] = []
		main.debug_solve_step()
		for i in 9:
			await _wait(0.35)
			var tex: Texture2D = main.character.sprite.texture
			var pose_name: String = tex.resource_path.get_file() if tex else "<null>"
			if not seen.has(pose_name):
				seen.append(pose_name)
		print("[anim] step=", main.current_step.get("id", ""),
				" action=", main.character.action, " poses=", seen)
		await _wait_until_step_change(14.0)
		await _wait(0.4)
	get_tree().quit()


func _to_window(pos: Vector2) -> Vector2:
	var win := Vector2(get_window().size)
	var design := Vector2(1280, 720)
	var factor := minf(win.x / design.x, win.y / design.y)
	var offset := (win - design * factor) * 0.5
	return offset + pos * factor


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
