extends Node

const E2E_BRIDGE_SCRIPT := preload("res://scripts/tools/e2e_bridge.gd")
const GAME_SESSION_SCRIPT := preload("res://scripts/gameplay/game_session.gd")
const DESIGN_WIDTH := 1920.0
const PORTRAIT_UI_WIDTH := 1080.0

@onready var round_controller: RoundController = $RoundController
@onready var game_session: Node = $GameSession
@onready var hook_controllers: Dictionary = {
	1: $FishingLevel/HookRigP1,
	2: $FishingLevel/HookRigP2,
}
@onready var boats: Dictionary = {
	1: $FishingLevel/OceanEnvironment/Boat,
	2: $FishingLevel/OceanEnvironment/Boat2,
}
@onready var wave_controller: WaveController = $FishingLevel/DemoCatchables
@onready var effect_controller: PowerupEffectController = $FishingLevel/PowerupEffectController
@onready var feedback_label: Label = $FishingLevel/FeedbackLabel
@onready var fishing_level: Node2D = $FishingLevel
@onready var water_bounds: ReferenceRect = $FishingLevel/Bounds
@onready var hud: GameHud = $UILayer/GameHud
@onready var result_overlay: RoundResultOverlay = $UILayer/RoundResultOverlay
@onready var setup_overlay: Control = $UILayer/GameSetupOverlay
@onready var ocean_environment: Node2D = $FishingLevel/OceanEnvironment

var _feedback_tween: Tween


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_viewport_layout)
	round_controller.score_changed.connect(hud.set_score)
	round_controller.time_changed.connect(hud.set_time)
	round_controller.time_changed.connect(_on_time_changed)
	round_controller.round_state_changed.connect(_on_round_state_changed)
	round_controller.round_finished.connect(_on_round_finished)
	for player_id in hook_controllers:
		var hook_controller := hook_controllers[player_id] as HookController
		hook_controller.delivery_completed.connect(_on_delivery_completed)
		hook_controller.catch_attached.connect(_on_catch_attached)
		hook_controller.shot_completed.connect(_on_shot_completed)
		hook_controller.powerup_collected.connect(_on_powerup_collected)
	effect_controller.configure(hook_controllers)
	effect_controller.effect_time_changed.connect(hud.set_effect_time)
	wave_controller.wave_started.connect(_on_wave_started)
	hud.start_requested.connect(_try_start_round)
	hud.mode_select_requested.connect(_return_to_mode_select)
	result_overlay.restart_requested.connect(_restart_round)
	result_overlay.return_mode_requested.connect(_return_to_mode_select)
	setup_overlay.single_requested.connect(_on_single_requested)
	setup_overlay.local_multi_requested.connect(_on_local_multi_requested)
	setup_overlay.character_selected.connect(_on_character_selected)
	setup_overlay.back_requested.connect(_on_setup_back_requested)
	setup_overlay.configure_characters(game_session.get_characters_sorted())
	hud.set_score(1, 0, round_controller.level_definition.target_score)
	hud.set_score(2, 0, round_controller.level_definition.target_score)
	hud.hide_ready()
	setup_overlay.show_mode_select()
	_apply_viewport_layout()
	_set_hooks_input_enabled(false)
	if OS.has_feature("web") and OS.has_feature("e2e") and E2E_BRIDGE_SCRIPT.is_requested():
		var e2e_bridge := E2E_BRIDGE_SCRIPT.new()
		e2e_bridge.name = "E2EBridge"
		add_child(e2e_bridge)
		e2e_bridge.configure(self)


func _unhandled_input(event: InputEvent) -> void:
	if game_session.state == GAME_SESSION_SCRIPT.SessionState.READY and round_controller.state == RoundController.RoundState.READY and event.is_action_pressed("start_round"):
		if _try_start_round():
			get_viewport().set_input_as_handled()
	elif game_session.state == GAME_SESSION_SCRIPT.SessionState.RESULT and event.is_action_pressed("restart_round") and (round_controller.state == RoundController.RoundState.WON or round_controller.state == RoundController.RoundState.LOST or round_controller.state == RoundController.RoundState.DRAW):
		_restart_round()
		get_viewport().set_input_as_handled()
	elif game_session.state == GAME_SESSION_SCRIPT.SessionState.PLAYING and round_controller.state == RoundController.RoundState.PLAYING:
		var player_id := _resolve_launch_player(event)
		if player_id != 0 and _try_launch(player_id):
			get_viewport().set_input_as_handled()


func _try_start_round() -> bool:
	if game_session.state != GAME_SESSION_SCRIPT.SessionState.READY or not game_session.is_configured() or not round_controller.ensure_ready_state():
		return false
	if round_controller.start_round():
		game_session.mark_playing()
		hud.hide_ready()
		_set_hooks_input_enabled(true)
		return true
	return false


func _on_delivery_completed(player_id: int, catchable_id: StringName, score_value: int) -> void:
	if round_controller.add_score(catchable_id, score_value, player_id):
		_show_feedback("%s 抓到 %d 分" % [_player_label(player_id), score_value], Color(1.0, 0.88, 0.22, 1.0))


func _on_catch_attached(player_id: int, catchable: Catchable) -> void:
	_show_feedback("%s 抓住了！" % _player_label(player_id), Color(0.45, 1.0, 0.72, 1.0))
	if catchable.definition.category == CatchableDefinition.CatchableCategory.FISH:
		var boat := boats.get(player_id) as Node
		if boat != null and boat.has_method("celebrate_catch"):
			boat.call("celebrate_catch")


func _on_shot_completed(player_id: int, caught_something: bool) -> void:
	if not caught_something and round_controller.state == RoundController.RoundState.PLAYING:
		_show_feedback("%s 没抓到，再试一次！" % _player_label(player_id), Color(0.9, 0.96, 1.0, 1.0))


func _on_powerup_collected(player_id: int, definition: PowerupDefinition) -> void:
	if effect_controller.activate(definition, player_id):
		_show_feedback("%s 获得%s！" % [_player_label(player_id), definition.display_name], Color(0.45, 0.9, 1.0, 1.0))


func _on_time_changed(seconds_left: int) -> void:
	var elapsed_seconds := round_controller.level_definition.duration_seconds - seconds_left
	wave_controller.update_elapsed(float(elapsed_seconds))


func _on_wave_started(wave_index: int) -> void:
	_show_feedback("第 %d 波出现！" % wave_index, Color(1.0, 0.88, 0.22, 1.0))


func _on_round_state_changed(_previous: RoundController.RoundState, current: RoundController.RoundState) -> void:
	if current == RoundController.RoundState.READY:
		if game_session.state == GAME_SESSION_SCRIPT.SessionState.READY:
			hud.show_ready()
	_set_hooks_input_enabled(current == RoundController.RoundState.PLAYING)


func _on_round_finished(result: RoundController.RoundResult, winner_player_id: int, p1_score: int, p2_score: int, target_score: int) -> void:
	_set_hooks_input_enabled(false)
	effect_controller.clear_all()
	game_session.mark_result()
	result_overlay.show_result(result, winner_player_id, p1_score, p2_score, target_score)


func _restart_round() -> void:
	if game_session.state != GAME_SESSION_SCRIPT.SessionState.RESULT:
		return
	wave_controller.reset_waves()
	effect_controller.clear_all()
	for player_id in hook_controllers:
		var hook_controller := hook_controllers[player_id] as HookController
		hook_controller.reset_hook()
	result_overlay.hide_result()
	round_controller.restart_round()
	game_session.mark_ready_after_restart()
	hud.show_ready()


func _on_single_requested() -> void:
	if game_session.select_single():
		setup_overlay.show_character_select()


func _on_local_multi_requested() -> void:
	if game_session.select_local_multi():
		_apply_session_configuration()


func _on_character_selected(character_id: StringName) -> void:
	if game_session.confirm_single_character(character_id):
		_apply_session_configuration()


func _on_setup_back_requested() -> void:
	if game_session.return_to_mode_from_character_select():
		setup_overlay.show_mode_select()


func _return_to_mode_select() -> void:
	if game_session.state == GAME_SESSION_SCRIPT.SessionState.PLAYING or game_session.state == GAME_SESSION_SCRIPT.SessionState.MODE_SELECT:
		return
	wave_controller.reset_waves()
	effect_controller.clear_all()
	for player_id in hook_controllers:
		(hook_controllers[player_id] as HookController).reset_hook()
	if round_controller.state == RoundController.RoundState.WON or round_controller.state == RoundController.RoundState.LOST or round_controller.state == RoundController.RoundState.DRAW:
		round_controller.restart_round()
	result_overlay.hide_result()
	hud.hide_ready()
	if game_session.return_to_mode_select():
		_restore_default_presentation()
		setup_overlay.show_mode_select()


func _apply_session_configuration() -> void:
	var active_players: Array[int] = game_session.active_player_ids
	if not round_controller.configure_active_players(active_players):
		push_error("Unable to configure active players")
		return
	effect_controller.clear_all()
	effect_controller.configure(hook_controllers, active_players)
	var single_player: bool = game_session.mode == GAME_SESSION_SCRIPT.GameMode.SINGLE
	var player_one: Resource = game_session.get_character(game_session.selected_character_ids.get(1, &"") as StringName)
	var player_two: Resource = game_session.get_character(game_session.selected_character_ids.get(2, &"") as StringName)
	if player_one == null:
		push_error("Configured session has no P1 character")
		return
	boats[1].set_head_texture(player_one.head_texture)
	if player_two != null:
		boats[2].set_head_texture(player_two.head_texture)
	boats[1].visible = true
	boats[2].visible = not single_player
	hook_controllers[1].visible = true
	hook_controllers[2].visible = not single_player
	var player_one_name: String = player_one.display_name if single_player else "P1"
	hud.configure_session(single_player, player_one_name, round_controller.level_definition.target_score)
	result_overlay.configure_session(single_player, player_one_name)
	hud.set_score(1, 0, round_controller.level_definition.target_score)
	if not single_player:
		hud.set_score(2, 0, round_controller.level_definition.target_score)
	setup_overlay.hide_setup()
	hud.show_ready()
	_set_hooks_input_enabled(false)


func _restore_default_presentation() -> void:
	var boy: Resource = game_session.get_character(&"boy")
	var girl: Resource = game_session.get_character(&"girl")
	if boy != null:
		boats[1].set_head_texture(boy.head_texture)
	if girl != null:
		boats[2].set_head_texture(girl.head_texture)
	boats[1].visible = true
	boats[2].visible = true
	hook_controllers[1].visible = true
	hook_controllers[2].visible = true
	round_controller.configure_active_players([1, 2])
	effect_controller.configure(hook_controllers, [1, 2])


func _apply_viewport_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	fishing_level.scale = Vector2.ONE
	fishing_level.position = Vector2((viewport_size.x - DESIGN_WIDTH) * 0.5, 0.0)
	var local_viewport := Rect2(-fishing_level.position, viewport_size)
	var seabed_y: float = ocean_environment.apply_viewport_rect(local_viewport)
	water_bounds.position = Vector2(local_viewport.position.x + 90.0, 410.0)
	water_bounds.size = Vector2(local_viewport.size.x - 180.0, seabed_y - 410.0)
	for hook_controller in hook_controllers.values():
		(hook_controller as HookController).set_seabed_y(seabed_y)
	_apply_ui_layout(viewport_size)


func _apply_ui_layout(viewport_size: Vector2) -> void:
	var portrait := viewport_size.y > viewport_size.x
	var ui_scale := DESIGN_WIDTH / PORTRAIT_UI_WIDTH if portrait else 1.0
	for control in [hud, result_overlay, setup_overlay]:
		if portrait:
			control.set_anchors_preset(Control.PRESET_TOP_LEFT)
			control.position = Vector2.ZERO
			control.size = viewport_size / ui_scale
			control.scale = Vector2.ONE * ui_scale
		else:
			control.scale = Vector2.ONE
			control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var effect_width := 400.0 if portrait else 520.0
	hud.p1_effects.custom_minimum_size.x = effect_width
	hud.p2_effects.custom_minimum_size.x = effect_width


func _show_feedback(message: String, color: Color) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_label.position.y = 315.0
	feedback_label.scale = Vector2(0.86, 0.86)
	_feedback_tween = create_tween().set_parallel(true)
	_feedback_tween.tween_property(feedback_label, "position:y", 260.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.75).set_delay(0.35)


func _resolve_launch_player(event: InputEvent) -> int:
	if event is InputEventMouseButton:
		if not event.pressed or not _is_point_in_water(event.position):
			return 0
		if event.button_index == MOUSE_BUTTON_LEFT:
			return 1 if game_session.mode == GAME_SESSION_SCRIPT.GameMode.SINGLE else _player_id_for_point(event.position)
		return 2 if game_session.active_player_ids.has(2) and event.is_action_pressed("cast_hook_p2") else 0
	if event is InputEventScreenTouch:
		if not event.pressed or not _is_point_in_water(event.position):
			return 0
		return 1 if game_session.mode == GAME_SESSION_SCRIPT.GameMode.SINGLE else _player_id_for_point(event.position)
	if game_session.active_player_ids.has(1) and event.is_action_pressed("cast_hook_p1"):
		return 1
	if game_session.active_player_ids.has(2) and event.is_action_pressed("cast_hook_p2"):
		return 2
	if game_session.active_player_ids.has(1) and event.is_action_pressed("cast_hook"):
		return 1
	return 0


func _player_id_for_point(point: Vector2) -> int:
	if not is_instance_valid(water_bounds):
		return 0
	var local_point := fishing_level.to_local(point)
	var bounds := water_bounds.get_rect()
	var center_x := bounds.position.x + bounds.size.x * 0.5
	return 1 if local_point.x <= center_x else 2


func _is_point_in_water(point: Vector2) -> bool:
	if not is_instance_valid(fishing_level) or not is_instance_valid(water_bounds):
		return false
	var local_point := fishing_level.to_local(point)
	return water_bounds.get_rect().has_point(local_point)


func _try_launch(player_id: int) -> bool:
	var hook_controller: HookController = hook_controllers.get(player_id) as HookController
	if hook_controller == null:
		return false
	return hook_controller.try_launch()


func _set_hooks_input_enabled(enabled: bool) -> void:
	for player_id in hook_controllers:
		var hook_controller := hook_controllers[player_id] as HookController
		hook_controller.set_input_enabled(enabled and game_session.active_player_ids.has(player_id))


func _player_label(player_id: int) -> String:
	if game_session.mode == GAME_SESSION_SCRIPT.GameMode.SINGLE and player_id == 1:
		var character: Resource = game_session.get_character(game_session.selected_character_ids.get(1, &"") as StringName)
		if character != null:
			return character.display_name
	return "P%d" % player_id
