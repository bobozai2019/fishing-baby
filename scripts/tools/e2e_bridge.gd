extends Node

var _main: Node
var _round: RoundController
var _session: GameSession
var _waves: WaveController
var _effects: PowerupEffectController
var _hooks: Dictionary
var _command_callback: JavaScriptObject
var _events := {
	"catches": [],
	"deliveries": [],
	"shots": [],
	"powerups": [],
	"waves": [],
}
var _last_command := {"id": "", "name": "", "ok": true, "error": ""}


static func is_requested() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).has('e2e')"))


func configure(main: Node) -> void:
	_main = main
	_round = main.round_controller
	_session = main.game_session
	_waves = main.wave_controller
	_effects = main.effect_controller
	_hooks = main.hook_controllers
	_connect_events()
	_command_callback = JavaScriptBridge.create_callback(_on_command)
	var window := JavaScriptBridge.get_interface("window")
	window.__fishingBabyE2ECommand = _command_callback
	_publish_state()


func _process(_delta: float) -> void:
	_publish_state()


func _connect_events() -> void:
	for player_id in _hooks:
		var hook := _hooks[player_id] as HookController
		hook.catch_attached.connect(func(event_player: int, catchable: Catchable) -> void:
			_events.catches.append({"player": event_player, "id": str(catchable.instance_id)})
		)
		hook.delivery_completed.connect(func(event_player: int, catchable_id: StringName, score: int) -> void:
			_events.deliveries.append({"player": event_player, "id": str(catchable_id), "score": score})
		)
		hook.shot_completed.connect(func(event_player: int, caught_something: bool) -> void:
			_events.shots.append({"player": event_player, "caught": caught_something})
		)
		hook.powerup_collected.connect(func(event_player: int, definition: PowerupDefinition) -> void:
			_events.powerups.append({"player": event_player, "id": str(definition.id), "effect_kind": definition.effect_kind})
		)
	_waves.wave_started.connect(func(wave_index: int) -> void: _events.waves.append(wave_index))


func _on_command(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var payload = JSON.parse_string(str(arguments[0]))
	if not payload is Dictionary:
		return
	var command: Dictionary = payload
	var command_id := str(command.get("id", ""))
	var command_name := str(command.get("name", ""))
	var command_args: Dictionary = command.get("args", {}) as Dictionary
	var result := _execute_command(command_name, command_args)
	_last_command = {
		"id": command_id,
		"name": command_name,
		"ok": result.is_empty(),
		"error": result,
	}
	_publish_state()


func _execute_command(command_name: String, args: Dictionary) -> String:
	match command_name:
		"clear_events":
			for event_list in _events.values():
				(event_list as Array).clear()
			return ""
		"clear_field":
			_set_all_entities_active(false)
			return _prepare_hook(int(args.get("player", 1)), float(args.get("angle", 0.0)))
		"prepare_entity":
			return _prepare_entity(str(args.get("id", "")), int(args.get("player", 1)), bool(args.get("isolate", true)))
		"prepare_inactive_entity":
			return _prepare_inactive_entity(str(args.get("id", "")), int(args.get("player", 1)))
		"prepare_powerup_race":
			return _prepare_powerup_race(str(args.get("id", "speed-reel-01")))
		"set_seconds_left":
			return _set_seconds_left(int(args.get("seconds", 90)))
		"advance_effects":
			_effects._process(float(args.get("seconds", 5.1)))
			return ""
		"award_score":
			var player_id := int(args.get("player", 1))
			var amount := int(args.get("amount", 0))
			var instance_id := StringName(str(args.get("id", "e2e-score")))
			return "" if _round.add_score(instance_id, amount, player_id) else "score rejected"
		"force_expire":
			_round.force_time_expired_for_test()
			return ""
		_:
			return "unknown command: %s" % command_name


func _prepare_hook(player_id: int, angle: float) -> String:
	var hook := _hooks.get(player_id) as HookController
	if hook == null:
		return "unknown player: %d" % player_id
	if _round.state != RoundController.RoundState.PLAYING:
		return "round is not playing"
	hook.reset_hook()
	hook.swing_angle_degrees = angle
	hook._swing_direction = 0.0
	hook._update_visuals()
	return ""


func _prepare_entity(instance_id: String, player_id: int, isolate: bool) -> String:
	var entity := _find_entity(instance_id)
	if entity == null:
		return "unknown entity: %s" % instance_id
	if isolate:
		_set_all_entities_active(false)
	else:
		_waves.update_elapsed(60.0)
	var hook := _hooks.get(player_id) as HookController
	if hook == null:
		return "unknown player: %d" % player_id
	var hook_error := _prepare_hook(player_id, 0.0)
	if not hook_error.is_empty():
		return hook_error
	if entity is Catchable:
		var catchable := entity as Catchable
		catchable.reset_catchable()
		catchable.set_wave_active(true)
		catchable.set_movement_paused(true)
	elif entity is PowerupPickup:
		var powerup := entity as PowerupPickup
		powerup.reset_powerup()
		powerup.set_wave_active(true)
	entity.global_position = hook.global_position + Vector2(0.0, 280.0)
	return ""


func _prepare_inactive_entity(instance_id: String, player_id: int) -> String:
	var entity := _find_entity(instance_id)
	if not entity is Catchable:
		return "catchable not found: %s" % instance_id
	_set_all_entities_active(false)
	var hook := _hooks.get(player_id) as HookController
	if hook == null:
		return "unknown player: %d" % player_id
	var hook_error := _prepare_hook(player_id, 0.0)
	if not hook_error.is_empty():
		return hook_error
	var catchable := entity as Catchable
	catchable.reset_catchable(false)
	catchable.set_movement_paused(true)
	catchable.global_position = hook.global_position + Vector2(0.0, 280.0)
	return ""


func _prepare_powerup_race(instance_id: String) -> String:
	var entity := _find_entity(instance_id)
	if not entity is PowerupPickup:
		return "powerup not found: %s" % instance_id
	if _round.state != RoundController.RoundState.PLAYING:
		return "round is not playing"
	_set_all_entities_active(false)
	var powerup := entity as PowerupPickup
	powerup.reset_powerup()
	powerup.set_wave_active(true)
	powerup.global_position = Vector2(960.0, 600.0)
	for player_id in [1, 2]:
		var hook := _hooks[player_id] as HookController
		hook.reset_hook()
		var offset := powerup.global_position - hook.global_position
		hook.swing_angle_degrees = rad_to_deg(atan2(offset.x, offset.y))
		hook._swing_direction = 0.0
		hook._update_visuals()
	return ""


func _set_seconds_left(seconds: int) -> String:
	if _round.state != RoundController.RoundState.PLAYING:
		return "round is not playing"
	var clamped := clampi(seconds, 1, _round.level_definition.duration_seconds)
	_round._time_remaining = float(clamped)
	_round.seconds_left = clamped
	_round.time_changed.emit(clamped)
	return ""


func _set_all_entities_active(active: bool) -> void:
	for wave in _waves.get_children():
		for entity in wave.get_children():
			if entity is Catchable:
				(entity as Catchable).set_wave_active(active)
			elif entity is PowerupPickup:
				(entity as PowerupPickup).set_wave_active(active)


func _find_entity(instance_id: String) -> Node2D:
	for wave in _waves.get_children():
		for entity in wave.get_children():
			if (entity is Catchable or entity is PowerupPickup) and str(entity.instance_id) == instance_id:
				return entity as Node2D
	return null


func _publish_state() -> void:
	if _main == null:
		return
	var state := {
		"ready": true,
		"viewport": _vector(get_viewport().get_visible_rect().size),
		"round": {
			"state": _enum_name(RoundController.RoundState, _round.state),
			"seconds_left": _round.seconds_left,
			"target_score": _round.level_definition.target_score,
			"scores": {"1": int(_round.scores.get(1, 0)), "2": int(_round.scores.get(2, 0))},
		},
		"session": {
			"state": _enum_name(GameSession.SessionState, _session.state),
			"mode": _enum_name(GameSession.GameMode, _session.mode),
			"active_players": _session.active_player_ids,
			"selected_characters": _string_key_dictionary(_session.selected_character_ids),
			"setup_visible": _main.setup_overlay.visible,
		},
		"hud": {
			"score": _main.hud.score_label.text,
			"time": _main.hud.time_label.text,
			"ready_visible": _main.hud.prompt_panel.visible,
			"prompt": _main.hud.prompt_label.text,
			"p1_effects": _main.hud.p1_effects.text,
			"global_effects": _main.hud.global_effects.text,
			"p2_effects": _main.hud.p2_effects.text,
			"feedback": _main.feedback_label.text,
			"result_visible": _main.result_overlay.visible,
			"result_title": _main.result_overlay.title_label.text,
			"result_text": _main.result_overlay.result_label.text,
		},
		"controls": {
			"start": _rect(_main.hud.start_button),
			"ready_return": _rect(_main.hud.mode_select_button),
			"restart": _rect(_main.result_overlay.restart_button),
			"result_return": _rect(_main.result_overlay.return_mode_button),
			"mode_single": _rect(_main.setup_overlay.single_button),
			"mode_multi": _rect(_main.setup_overlay.multi_button),
			"setup_back": _rect(_main.setup_overlay.back_button),
			"character_boy": _rect(_main.setup_overlay.get_character_button(&"boy")),
			"character_girl": _rect(_main.setup_overlay.get_character_button(&"girl")),
		},
		"layout": {
			"score": _rect(_main.hud.score_label),
			"time": _rect(_main.hud.time_label),
			"powerup_row": _rect(_main.hud.get_node("PowerupStatusRow") as Control),
			"p1_effects": _rect(_main.hud.p1_effects),
			"global_effects": _rect(_main.hud.global_effects),
			"p2_effects": _rect(_main.hud.p2_effects),
			"prompt": _rect(_main.hud.prompt_panel),
		},
		"waves": {
			"active_count": _waves.get_active_wave_count(),
		},
		"hooks": _hook_states(),
		"participants": {
			"boat_1_visible": _main.boats[1].visible,
			"boat_2_visible": _main.boats[2].visible,
			"hook_1_visible": _main.hook_controllers[1].visible,
			"hook_2_visible": _main.hook_controllers[2].visible,
			"p1_head": _main.boats[1].get_node("Head").texture.resource_path,
			"p2_head": _main.boats[2].get_node("Head").texture.resource_path,
		},
		"entities": _entity_states(),
		"effects": {"active_count": _effects._effects.size()},
		"events": _events,
		"last_command": _last_command,
	}
	JavaScriptBridge.eval("window.__fishingBabyE2EState = %s;" % JSON.stringify(state))


func _hook_states() -> Dictionary:
	var result := {}
	for player_id in _hooks:
		var hook := _hooks[player_id] as HookController
		result[str(player_id)] = {
			"state": _enum_name(HookController.HookState, hook.state),
			"rope_length": hook.rope_length,
			"angle": hook.swing_angle_degrees,
			"input_enabled": hook.input_enabled,
			"speed_multiplier": hook.speed_multiplier,
			"size_multiplier": hook.size_multiplier,
			"collision_scale": _vector(hook.collision_shape.scale),
			"sprite_scale": _vector(hook.hook_sprite.scale),
			"tip_position": _vector(hook.tip.global_position),
			"collision_position": _vector(hook.collision_shape.global_position),
			"sprite_position": _vector(hook.hook_sprite.global_position),
		}
	return result


func _entity_states() -> Dictionary:
	var result := {}
	for wave_index in range(_waves.get_child_count()):
		var wave := _waves.get_child(wave_index)
		for entity in wave.get_children():
			if entity is Catchable:
				var catchable := entity as Catchable
				var carrier_distance := -1.0
				if catchable.state == Catchable.CatchableState.HOOKED and is_instance_valid(catchable._carrier):
					carrier_distance = catchable.global_position.distance_to(catchable._carrier.global_position)
				result[str(catchable.instance_id)] = {
					"kind": "catchable",
					"state": _enum_name(Catchable.CatchableState, catchable.state),
					"wave": wave_index + 1,
					"visible": catchable.visible,
					"monitorable": catchable.monitorable,
					"collision_disabled": catchable.collision_shape.disabled,
					"position": _vector(catchable.global_position),
					"movement_paused": catchable._movement_paused,
					"category": catchable.definition.category,
					"movement_kind": catchable.definition.movement_kind,
					"score": catchable.definition.score_value,
					"carrier_distance": carrier_distance,
					"z_index": catchable.z_index,
				}
			elif entity is PowerupPickup:
				var powerup := entity as PowerupPickup
				result[str(powerup.instance_id)] = {
					"kind": "powerup",
					"state": _enum_name(PowerupPickup.PowerupState, powerup.state),
					"wave": wave_index + 1,
					"visible": powerup.visible,
					"monitorable": powerup.monitorable,
					"collision_disabled": powerup.collision_shape.disabled,
					"position": _vector(powerup.global_position),
					"effect_kind": powerup.definition.effect_kind,
				}
	return result


func _enum_name(values: Dictionary, value: int) -> String:
	var key = values.find_key(value)
	return str(key) if key != null else str(value)


func _vector(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _rect(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}


func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[str(key)] = str(source[key])
	return result
