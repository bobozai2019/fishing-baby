extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_scene_contract()
	await _test_character_and_session_contracts()
	await _test_single_player_integration()
	await _test_round_controller()
	await _test_hook_state_machine()
	await _test_hook_capture_delivery()
	await _test_catchable_state_machine()
	await _test_data_contracts()
	await _test_movement_and_pause()
	await _test_wave_controller()
	await _test_powerup_and_effects()
	if failures.is_empty():
		print("CORE TESTS PASSED (scene, session, single player, round, hook x20, capture, data, movement, waves, powerups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("CORE TESTS FAILED: %d" % failures.size())
		quit(1)


func _test_scene_contract() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main.tscn must load")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var required_paths := [
		"FishingLevel/OceanEnvironment/Boat/Body",
		"FishingLevel/OceanEnvironment/Boat/Head",
		"FishingLevel/OceanEnvironment/Boat/RopeOrigin",
		"FishingLevel/OceanEnvironment/Boat2/Body",
		"FishingLevel/OceanEnvironment/Boat2/Head",
		"FishingLevel/OceanEnvironment/Boat2/RopeOrigin",
		"FishingLevel/DemoCatchables/Wave1/BlueSmall/InstanceIdLabel",
		"FishingLevel/HookRigP1/Rope",
		"FishingLevel/HookRigP1/Tip",
		"FishingLevel/HookRigP2/Rope",
		"FishingLevel/HookRigP2/Tip",
		"FishingLevel/PowerupEffectController",
		"FishingLevel/Bounds",
		"RoundController",
		"GameSession",
		"UILayer/GameHud",
		"UILayer/GameHud/PowerupStatusRow/P1Effects",
		"UILayer/GameHud/PowerupStatusRow/GlobalEffects",
		"UILayer/GameHud/PowerupStatusRow/P2Effects",
		"UILayer/RoundResultOverlay",
		"UILayer/GameSetupOverlay",
	]
	for path in required_paths:
		_expect(main.has_node(path), "missing required node: %s" % path)
	var boat := main.get_node("FishingLevel/OceanEnvironment/Boat")
	var boat_2 := main.get_node("FishingLevel/OceanEnvironment/Boat2")
	_expect(boat.get_node("Body").texture.resource_path == "res://resources/characters/boat_body.png", "boat must use boat_body.png")
	_expect(boat.get_node("Head").texture.resource_path == "res://resources/characters/boy_head.png", "player 1 boat must use boy_head.png")
	_expect(boat_2.get_node("Head").texture.resource_path == "res://resources/characters/girl_head.png", "player 2 boat must use girl_head.png")
	var environment := main.get_node("FishingLevel/OceanEnvironment")
	var portrait_seabed: float = environment.apply_viewport_rect(Rect2(0.0, 0.0, 1920.0, 4155.0))
	var portrait_background := environment.get_node("Environment/SkyWaterSand") as NinePatchRect
	var portrait_sandbed := environment.get_node("Environment/Sandbed") as NinePatchRect
	_expect(portrait_background.size == Vector2(1920.0, 4155.0), "portrait layout must stretch the nine-patch background to the full viewport")
	_expect(is_equal_approx(portrait_seabed, 4025.0) and is_equal_approx(portrait_sandbed.position.y, 4025.0), "portrait layout must anchor the sandbed to the viewport bottom")
	main._apply_viewport_layout()
	var catchables := main.get_node("FishingLevel/DemoCatchables") as WaveController
	var fish_id_label := catchables.get_node("Wave1/BlueSmall/InstanceIdLabel") as Label
	var creature_id_label := catchables.get_node("Wave1/Crab/InstanceIdLabel") as Label
	_expect(fish_id_label.visible and fish_id_label.text == "ID: blue-small-01", "fish must display its full instance ID")
	_expect(not creature_id_label.visible, "non-fish catchables must not display a fish instance ID label")
	_expect(catchables.get_child_count() == 3, "demo level must contain exactly 3 waves")
	_expect(catchables.get_child(0).get_child_count() == 8, "Wave 1 must contain 8 entities")
	_expect(catchables.get_child(1).get_child_count() == 6, "Wave 2 must contain 6 entities")
	_expect(catchables.get_child(2).get_child_count() == 5, "Wave 3 must contain 5 entities")
	var definition_ids: Dictionary = {}
	var instance_ids: Dictionary = {}
	var scoring_count := 0
	var powerup_count := 0
	var total_score := 0
	for wave in catchables.get_children():
		for child in wave.get_children():
			if child is Catchable:
				var catchable := child as Catchable
				definition_ids[catchable.definition.id] = true
				instance_ids[catchable.instance_id] = true
				scoring_count += 1
				total_score += catchable.definition.score_value
				_expect(catchable.definition.is_valid_definition(), "%s definition must be valid" % child.name)
			elif child is PowerupPickup:
				var powerup := child as PowerupPickup
				definition_ids[powerup.definition.id] = true
				instance_ids[powerup.instance_id] = true
				powerup_count += 1
				_expect(powerup.definition.is_valid_definition(), "%s definition must be valid" % child.name)
	_expect(scoring_count == 16 and powerup_count == 3, "demo level must contain 16 scoring targets and 3 powerups")
	_expect(total_score == 3920, "all scoring targets must total 3920")
	_expect(definition_ids.size() == 19, "all 19 definition IDs must be unique")
	_expect(instance_ids.size() == 19, "all 19 instance IDs must be unique")
	_expect(catchables.get_active_wave_count() == 1, "READY must expose only Wave 1")
	_expect(main.game_session.state == GameSession.SessionState.MODE_SELECT, "startup must wait at MODE_SELECT")
	_expect(main.setup_overlay.visible and main.setup_overlay.mode_page.visible, "startup must show mode selection")
	_expect(not main.hud.prompt_panel.visible, "old ready prompt must stay hidden before mode selection")
	main._on_local_multi_requested()
	_expect(main.game_session.state == GameSession.SessionState.READY, "local multiplayer selection must configure the session")
	_expect(main.game_session.active_player_ids == [1, 2], "local multiplayer must activate P1 and P2")
	_expect(not main.setup_overlay.visible and main.hud.prompt_panel.visible, "configured multiplayer must show the ready prompt")
	main.queue_free()
	await process_frame


func _test_character_and_session_contracts() -> void:
	var boy := load("res://resources/game_data/characters/boy.tres") as CharacterDefinition
	var girl := load("res://resources/game_data/characters/girl.tres") as CharacterDefinition
	_expect(boy != null and boy.is_valid_definition() and boy.id == &"boy", "boy character must load and validate")
	_expect(girl != null and girl.is_valid_definition() and girl.id == &"girl", "girl character must load and validate")
	var third := CharacterDefinition.new()
	third.id = &"third"
	third.display_name = "第三名小孩"
	third.portrait = boy.portrait
	third.head_texture = boy.head_texture
	third.sort_order = 15
	var session := GameSession.new()
	session.characters = [girl, third, boy]
	root.add_child(session)
	_expect(session.is_catalog_valid(), "three unique character definitions must form a valid catalog")
	var sorted := session.get_characters_sorted()
	_expect(sorted.size() == 3 and sorted[0].id == &"boy" and sorted[1].id == &"third" and sorted[2].id == &"girl", "character catalog must sort without UI-specific branches")
	var setup := (load("res://scenes/ui/game_setup_overlay.tscn") as PackedScene).instantiate() as GameSetupOverlay
	root.add_child(setup)
	await process_frame
	setup.configure_characters(sorted)
	await process_frame
	_expect(setup.character_buttons.size() == 3 and setup.get_character_button(&"third") != null, "adding a third resource must add a character card without UI branches")
	setup.queue_free()
	_expect(not session.confirm_single_character(&"boy"), "character confirmation before single selection must be rejected")
	_expect(session.select_single(), "MODE_SELECT must accept single mode")
	_expect(session.state == GameSession.SessionState.CHARACTER_SELECT, "single mode must enter CHARACTER_SELECT")
	_expect(not session.confirm_single_character(&"missing"), "unknown character must be rejected without changing state")
	_expect(session.confirm_single_character(&"girl"), "known character must configure single mode")
	_expect(session.is_configured() and session.active_player_ids == [1] and session.selected_character_ids[1] == &"girl", "single mode must configure only logical P1")
	_expect(session.mark_playing(), "configured READY session must enter PLAYING")
	_expect(not session.return_to_mode_select(), "PLAYING session must reject return-to-menu")
	_expect(session.mark_result() and session.mark_ready_after_restart(), "RESULT restart must preserve the configured session")
	_expect(session.selected_character_ids[1] == &"girl", "restart must preserve selected character")
	_expect(session.return_to_mode_select(), "READY session must return to mode selection")
	_expect(session.mode == GameSession.GameMode.NONE and session.selected_character_ids.is_empty() and session.active_player_ids.is_empty(), "return-to-menu must clear selection")
	_expect(session.select_local_multi(), "MODE_SELECT must accept local multiplayer")
	_expect(session.active_player_ids == [1, 2] and session.selected_character_ids[1] == &"boy" and session.selected_character_ids[2] == &"girl", "multiplayer must use default boy/girl roster")
	session.queue_free()
	await process_frame


func _test_single_player_integration() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main._on_single_requested()
	_expect(main.game_session.state == GameSession.SessionState.CHARACTER_SELECT, "single button must open character selection")
	_expect(main.setup_overlay.character_page.visible and main.setup_overlay.character_buttons.size() == 2, "character page must be generated from the two-resource catalog")
	main._on_character_selected(&"girl")
	await process_frame
	_expect(main.game_session.state == GameSession.SessionState.READY, "single character confirmation must enter READY")
	_expect(main.boats[1].get_node("Head").texture.resource_path == "res://resources/characters/girl_head.png", "selected girl must be mounted on the P1 boat")
	_expect(main.boats[1].visible and not main.boats[2].visible, "single mode must show only the P1 boat")
	_expect(main.hook_controllers[1].visible and not main.hook_controllers[2].visible, "single mode must show only the P1 hook")
	_expect(not main.hud.score_label.text.contains("P2"), "single HUD must not expose P2 score")
	_expect(main._try_start_round(), "configured single round must start")
	_expect(main.hook_controllers[1].input_enabled and not main.hook_controllers[2].input_enabled, "single PLAYING must enable only P1 hook")
	_expect(not main.round_controller.add_score(&"single-p2-rejected", 100, 2), "single round must reject P2 scoring")
	main.round_controller.force_time_expired_for_test()
	_expect(main.round_controller.state == RoundController.RoundState.LOST, "single player below target must lose on timeout")
	_expect(main.game_session.state == GameSession.SessionState.RESULT, "single timeout must enter session RESULT")
	main._restart_round()
	_expect(main.game_session.state == GameSession.SessionState.READY and main.game_session.selected_character_ids[1] == &"girl", "single restart must preserve the selected girl")
	main._return_to_mode_select()
	_expect(main.game_session.state == GameSession.SessionState.MODE_SELECT, "ready single session must return to mode selection")
	_expect(main.boats[2].visible and main.hook_controllers[2].visible, "return-to-menu must restore P2 presentation capability")
	main.queue_free()
	await process_frame


func _test_round_controller() -> void:
	var controller := RoundController.new()
	controller.level_definition = load("res://resources/game_data/levels/demo_level.tres")
	root.add_child(controller)
	await process_frame
	_expect(controller.state == RoundController.RoundState.READY, "round must boot into READY")
	_expect(controller.start_round(), "READY round must start")
	_expect(not controller.start_round(), "PLAYING round must reject duplicate start")
	_expect(controller.add_score(&"orange-rare-01", 600, 1), "P1 first delivery must score")
	_expect(not controller.add_score(&"orange-rare-01", 600, 2), "same catch should not score twice across players")
	_expect(controller.add_score(&"treasure-chest-01", 500, 2), "P2 unique delivery must score")
	_expect(controller.add_score(&"blue-small-01", 1200, 1), "P1 target-reaching delivery must score")
	_expect(controller.scores[1] == 1800 and controller.scores[2] == 500, "player scores must be independent")
	_expect(controller.state == RoundController.RoundState.WON, "target score must win immediately")
	controller.restart_round()
	_expect(controller.state == RoundController.RoundState.READY, "restart must return to READY")
	_expect(controller.scores[1] == 0 and controller.scores[2] == 0 and controller.seconds_left == 90, "restart must reset score and time")
	_expect(controller.start_round(), "restarted round must start")
	_expect(controller.add_score(&"regression-p1-01", 100, 1), "scoring regression round must accept player-1 catch")
	_expect(controller.add_score(&"regression-p2-01", 150, 2), "scoring regression round must accept player-2 catch")
	controller.force_time_expired_for_test()
	_expect(controller.state == RoundController.RoundState.WON, "expired sub-target round with player-2 lead should win")
	controller.restart_round()
	_expect(controller.start_round(), "third regression round must start")
	_expect(controller.add_score(&"regression-win-03", 1800, 2), "third regression round must accept a winning delivery")
	_expect(controller.state == RoundController.RoundState.WON, "third regression round must win")
	controller.queue_free()
	await process_frame
	var single_controller := RoundController.new()
	single_controller.level_definition = load("res://resources/game_data/levels/demo_level.tres")
	root.add_child(single_controller)
	await process_frame
	_expect(single_controller.configure_active_players([1]), "READY round must accept a single active player")
	_expect(single_controller.start_round(), "single-player round must start")
	_expect(not single_controller.add_score(&"single-invalid-p2", 100, 2), "inactive P2 must never score in single mode")
	_expect(single_controller.add_score(&"single-valid-p1", 100, 1), "active P1 must score in single mode")
	single_controller.force_time_expired_for_test()
	_expect(single_controller.state == RoundController.RoundState.LOST, "single-player timeout below target must lose instead of compare against P2")
	single_controller.queue_free()
	await process_frame


func _test_hook_state_machine() -> void:
	var hook := (load("res://scenes/gameplay/hook_rig.tscn") as PackedScene).instantiate() as HookController
	var observed := {"deliveries": 0, "caught_shots": 0}
	hook.delivery_completed.connect(func(_player_id: int, _catchable_id: StringName, _score: int) -> void: observed.deliveries += 1)
	hook.shot_completed.connect(func(_player_id: int, caught_something: bool) -> void:
		if caught_something:
			observed.caught_shots += 1
	)
	root.add_child(hook)
	await process_frame
	hook.set_input_enabled(true)
	for shot in range(20):
		_expect(hook.try_launch(), "shot %d must launch from SWINGING" % (shot + 1))
		hook._physics_process(2.0)
		_expect(hook.state == HookController.HookState.RETRACTING_EMPTY, "shot %d must retract at max length" % (shot + 1))
		hook._physics_process(3.0)
		_expect(hook.state == HookController.HookState.SWINGING, "shot %d must return to SWINGING" % (shot + 1))
		_expect(is_equal_approx(hook.rope_length, hook.level_definition.initial_rope_length), "shot %d must restore rope length" % (shot + 1))
	_expect(observed.deliveries == 0, "20 empty shots must not emit a delivery or award score")
	_expect(observed.caught_shots == 0, "20 empty shots must all report caught_something=false")
	hook.position = Vector2(0.0, 250.0)
	hook.set_seabed_y(950.0)
	hook.swing_angle_degrees = 0.0
	_expect(is_equal_approx(hook._get_max_rope_length(), 622.0), "vertical hook limit must stop its collision edge at the seabed")
	hook.swing_angle_degrees = 60.0
	_expect(is_equal_approx(hook._get_max_rope_length(), 1322.0), "angled hook limit must intersect the same seabed line")
	hook.set_size_multiplier(1.6)
	_expect(is_equal_approx(hook._get_max_rope_length(), 1275.2), "giant hook must reserve its enlarged footprint above the seabed")
	hook.set_input_enabled(false)
	_expect(hook.state == HookController.HookState.DISABLED, "disabled hook must stop swinging")
	hook.queue_free()
	await process_frame


func _test_hook_capture_delivery() -> void:
	var hook := (load("res://scenes/gameplay/hook_rig.tscn") as PackedScene).instantiate() as HookController
	var catchable := (load("res://scenes/entities/catchable.tscn") as PackedScene).instantiate() as Catchable
	catchable.definition = load("res://resources/game_data/catchables/crab.tres")
	catchable.instance_id = &"crab-integration-test"
	catchable.position = Vector2(0, 240)
	root.add_child(hook)
	root.add_child(catchable)
	await physics_frame
	var observed := {"score": 0, "deliveries": 0}
	hook.delivery_completed.connect(func(_player_id: int, _catchable_id: StringName, score: int) -> void:
		observed.deliveries += 1
		observed.score += score
	)
	hook.set_input_enabled(true)
	_expect(hook.try_launch(), "capture integration shot must launch")
	var saw_hooked_target := false
	for frame in range(180):
		await physics_frame
		if catchable.state == Catchable.CatchableState.HOOKED:
			saw_hooked_target = true
			var attachment_distance := catchable.global_position.distance_to(hook.collision_shape.global_position)
			_expect(attachment_distance < 0.1, "hooked target must visibly follow the claw collision point (distance %.2f)" % attachment_distance)
			_expect(catchable.z_index < hook.z_index and catchable.z_index > 11, "hooked target must render above level art and below the claw")
		if catchable.state == Catchable.CatchableState.COLLECTED:
			break
	_expect(saw_hooked_target, "delivery must pass through a visible HOOKED state")
	_expect(catchable.state == Catchable.CatchableState.COLLECTED, "hook must capture and deliver a target on its path")
	_expect(observed.deliveries == 1 and observed.score == catchable.definition.score_value, "a hooked target must score exactly once on delivery")
	_expect(hook.state == HookController.HookState.SWINGING, "hook must resume swinging after delivery")
	hook.queue_free()
	catchable.queue_free()
	await process_frame


func _test_catchable_state_machine() -> void:
	var catchable := (load("res://scenes/entities/catchable.tscn") as PackedScene).instantiate() as Catchable
	catchable.definition = load("res://resources/game_data/catchables/blue_small.tres")
	catchable.instance_id = &"blue-small-test"
	var carrier := Node2D.new()
	root.add_child(carrier)
	root.add_child(catchable)
	await process_frame
	_expect(catchable.attach_to_hook(carrier), "available catchable must attach")
	_expect(not catchable.attach_to_hook(carrier), "hooked catchable must reject second attach")
	catchable.collect()
	_expect(catchable.state == Catchable.CatchableState.COLLECTED and not catchable.visible, "collected catchable must hide")
	catchable.reset_catchable()
	_expect(catchable.state == Catchable.CatchableState.AVAILABLE and catchable.visible, "reset catchable must become available")
	catchable.queue_free()
	carrier.queue_free()
	await process_frame


func _test_data_contracts() -> void:
	_expect(CatchableDefinition.MovementKind.STATIC == 0, "STATIC enum value must remain 0")
	_expect(CatchableDefinition.MovementKind.HORIZONTAL == 1, "HORIZONTAL enum value must remain 1")
	_expect(CatchableDefinition.MovementKind.DRIFT == 2, "DRIFT enum value must remain 2")
	_expect(CatchableDefinition.MovementKind.VERTICAL == 3, "VERTICAL enum value must be 3")
	_expect(CatchableDefinition.MovementKind.ZIGZAG == 4, "ZIGZAG enum value must be 4")
	_expect(CatchableDefinition.MovementKind.ELLIPSE == 5, "ELLIPSE enum value must be 5")
	var level := load("res://resources/game_data/levels/demo_level.tres") as LevelDefinition
	_expect(level.is_valid_definition(), "demo level definition must be valid")
	_expect(level.target_score == 1800 and level.duration_seconds == 90, "demo level must use 1800 points and 90 seconds")
	_expect(level.wave_start_elapsed_seconds == PackedFloat32Array([0.0, 30.0, 60.0]), "wave thresholds must be 0/30/60")
	var catchable_paths := ["pufferfish", "seahorse", "squid", "sea_turtle"]
	var expected_scores := [180, 240, 360, 500]
	for index in range(catchable_paths.size()):
		var definition := load("res://resources/game_data/catchables/%s.tres" % catchable_paths[index]) as CatchableDefinition
		_expect(definition != null and definition.is_valid_definition(), "%s definition must load and validate" % catchable_paths[index])
		_expect(definition.score_value == expected_scores[index], "%s score must match contract" % catchable_paths[index])
	var powerup_paths := ["speed_reel", "giant_hook", "freeze_crystal"]
	var expected_magnitudes := [1.75, 1.60, 1.0]
	for index in range(powerup_paths.size()):
		var definition := load("res://resources/game_data/powerups/%s.tres" % powerup_paths[index]) as PowerupDefinition
		_expect(definition != null and definition.is_valid_definition(), "%s definition must load and validate" % powerup_paths[index])
		_expect(is_equal_approx(definition.duration_seconds, 5.0), "%s duration must be 5 seconds" % powerup_paths[index])
		_expect(is_equal_approx(definition.magnitude, expected_magnitudes[index]), "%s magnitude must match contract" % powerup_paths[index])


func _test_movement_and_pause() -> void:
	var catchable := (load("res://scenes/entities/catchable.tscn") as PackedScene).instantiate() as Catchable
	catchable.definition = load("res://resources/game_data/catchables/pufferfish.tres")
	catchable.instance_id = &"pufferfish-movement-test"
	catchable.position = Vector2(500, 720)
	catchable.movement_min_x = 220.0
	catchable.movement_max_x = 850.0
	root.add_child(catchable)
	await process_frame
	var initial_position := Vector2(500, 720)
	var start := catchable.position
	catchable._physics_process(0.5)
	_expect(catchable.position != start, "DRIFT movement must advance using delta")
	catchable.set_movement_paused(true)
	var paused := catchable.position
	catchable._physics_process(1.0)
	_expect(catchable.position == paused, "paused aquatic movement must remain still")
	catchable.set_movement_paused(false)
	catchable.set_wave_active(false)
	_expect(not catchable.visible and not catchable.monitorable, "inactive wave catchable must hide and disable collision")
	catchable.set_wave_active(true)
	_expect(catchable.visible and catchable.monitorable, "reactivated available catchable must restore collision")
	var carrier := Node2D.new()
	root.add_child(carrier)
	catchable.set_movement_paused(true)
	_expect(catchable.attach_to_hook(carrier), "frozen aquatic target must remain catchable")
	carrier.global_position = Vector2(300, 300)
	catchable._physics_process(0.1)
	_expect(catchable.global_position == carrier.global_position, "hooked target must follow hook while movement is paused")
	catchable.reset_catchable()
	_expect(catchable.position == initial_position, "reset must restore movement origin")
	catchable.queue_free()
	carrier.queue_free()
	await process_frame
	for path in ["seahorse", "squid", "sea_turtle"]:
		var mover := (load("res://scenes/entities/catchable.tscn") as PackedScene).instantiate() as Catchable
		mover.definition = load("res://resources/game_data/catchables/%s.tres" % path)
		mover.instance_id = StringName("%s-movement-test" % path)
		mover.position = Vector2(900, 650)
		mover.movement_min_x = 700.0
		mover.movement_max_x = 1100.0
		mover.movement_min_y = 500.0
		mover.movement_max_y = 780.0
		root.add_child(mover)
		await process_frame
		var mover_start := mover.position
		mover._physics_process(0.5)
		_expect(mover.position != mover_start, "%s movement must advance" % path)
		_expect(mover.position.x >= 700.0 and mover.position.x <= 1100.0, "%s movement must remain in horizontal bounds" % path)
		mover.queue_free()
		await process_frame


func _test_wave_controller() -> void:
	var waves := (load("res://scenes/gameplay/demo_catchables.tscn") as PackedScene).instantiate() as WaveController
	root.add_child(waves)
	await process_frame
	await physics_frame
	_expect_future_waves_inactive(waves, "initialization")
	var started: Array[int] = []
	waves.wave_started.connect(func(index: int) -> void: started.append(index))
	waves.update_elapsed(29.9)
	_expect(waves.get_active_wave_count() == 1, "29.9 elapsed seconds must not start Wave 2")
	waves.update_elapsed(30.0)
	_expect(waves.get_active_wave_count() == 2 and started == [2], "30 seconds must start Wave 2 once")
	waves.update_elapsed(30.0)
	_expect(started == [2], "repeated threshold update must be idempotent")
	waves.update_elapsed(90.0)
	_expect(waves.get_active_wave_count() == 3 and started == [2, 3], "large elapsed update must catch up Wave 3")
	var wave_1_target := waves.get_node("Wave1/BlueSmall") as Catchable
	var wave_1_position := wave_1_target.position
	waves.update_elapsed(90.0)
	_expect(wave_1_target.visible and wave_1_target.position == wave_1_position, "later waves must not hide or reset earlier waves")
	var wave_2_powerup := waves.get_node("Wave2/GiantHook") as PowerupPickup
	_expect(wave_2_powerup.consume(), "active Wave 2 powerup must be consumable")
	waves.reset_waves()
	await process_frame
	await physics_frame
	_expect(waves.get_active_wave_count() == 1, "reset must return to Wave 1")
	_expect(wave_2_powerup.state == PowerupPickup.PowerupState.AVAILABLE and not wave_2_powerup.visible, "reset must restore but hide future-wave powerups")
	_expect_future_waves_inactive(waves, "reset")
	waves.queue_free()
	await process_frame


func _expect_future_waves_inactive(waves: WaveController, context: String) -> void:
	for wave_index in range(1, waves.get_child_count()):
		for entity in waves.get_child(wave_index).get_children():
			if entity is Catchable:
				var catchable := entity as Catchable
				_expect(not catchable.visible and not catchable.monitoring and not catchable.monitorable and catchable.collision_shape.disabled, "%s must keep future catchable %s hidden and non-collidable" % [context, catchable.instance_id])
			elif entity is PowerupPickup:
				var powerup := entity as PowerupPickup
				_expect(not powerup.visible and not powerup.monitoring and not powerup.monitorable and powerup.collision_shape.disabled, "%s must keep future powerup %s hidden and non-collidable" % [context, powerup.instance_id])


func _test_powerup_and_effects() -> void:
	var hook_1 := (load("res://scenes/gameplay/hook_rig.tscn") as PackedScene).instantiate() as HookController
	var hook_2 := (load("res://scenes/gameplay/hook_rig.tscn") as PackedScene).instantiate() as HookController
	hook_1.player_id = 1
	hook_2.player_id = 2
	root.add_child(hook_1)
	root.add_child(hook_2)
	await process_frame
	var pickup := (load("res://scenes/entities/powerup_pickup.tscn") as PackedScene).instantiate() as PowerupPickup
	pickup.definition = load("res://resources/game_data/powerups/speed_reel.tres")
	pickup.instance_id = &"speed-reel-consume-test"
	root.add_child(pickup)
	await process_frame
	hook_1.set_input_enabled(true)
	_expect(hook_1.try_launch(), "powerup collision test hook must launch")
	hook_1._on_tip_area_entered(pickup)
	_expect(pickup.state == PowerupPickup.PowerupState.CONSUMED, "powerup must consume immediately")
	_expect(hook_1.state == HookController.HookState.EXTENDING, "powerup must not interrupt extension")
	_expect(not pickup.consume(), "consumed powerup must reject duplicate consumption")
	var effects := PowerupEffectController.new()
	root.add_child(effects)
	effects.configure({1: hook_1, 2: hook_2})
	var speed := load("res://resources/game_data/powerups/speed_reel.tres") as PowerupDefinition
	var size := load("res://resources/game_data/powerups/giant_hook.tres") as PowerupDefinition
	var freeze := load("res://resources/game_data/powerups/freeze_crystal.tres") as PowerupDefinition
	_expect(effects.activate(speed, 1), "P1 speed effect must activate")
	_expect(is_equal_approx(hook_1.speed_multiplier, 1.75) and is_equal_approx(hook_2.speed_multiplier, 1.0), "speed effect must be isolated to collector")
	effects.clear_all()
	effects.configure({1: hook_1, 2: hook_2}, [1])
	_expect(not effects.activate(speed, 2), "inactive P2 must reject personal powerups in single mode")
	_expect(effects.activate(speed, 1), "active P1 must accept personal powerups in single mode")
	effects._process(4.0)
	_expect(effects.activate(speed, 1), "same speed effect must refresh")
	effects._process(2.0)
	_expect(is_equal_approx(hook_1.speed_multiplier, 1.75), "refreshed speed must remain active beyond original expiry")
	_expect(effects.activate(size, 1), "different personal effect must coexist")
	_expect(is_equal_approx(hook_1.size_multiplier, 1.6) and is_equal_approx(hook_1.speed_multiplier, 1.75), "speed and size must coexist without stacking")
	var aquatic := (load("res://scenes/entities/catchable.tscn") as PackedScene).instantiate() as Catchable
	aquatic.definition = load("res://resources/game_data/catchables/pufferfish.tres")
	aquatic.instance_id = &"freeze-aquatic-test"
	aquatic.position = Vector2(500, 720)
	root.add_child(aquatic)
	await process_frame
	_expect(effects.activate(freeze, 2), "global freeze must activate from either player")
	var frozen_position := aquatic.position
	aquatic._physics_process(1.0)
	_expect(aquatic.position == frozen_position, "global freeze must pause aquatic movement")
	effects.clear_all()
	_expect(is_equal_approx(hook_1.speed_multiplier, 1.0) and is_equal_approx(hook_1.size_multiplier, 1.0), "clear_all must restore hook modifiers")
	aquatic._physics_process(0.5)
	_expect(aquatic.position != frozen_position, "clearing freeze must resume aquatic movement")
	pickup.queue_free()
	aquatic.queue_free()
	effects.queue_free()
	hook_1.queue_free()
	hook_2.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
