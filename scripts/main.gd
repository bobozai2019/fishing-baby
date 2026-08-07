extends Node

@onready var round_controller: RoundController = $RoundController
@onready var hook_controllers: Dictionary = {
	1: $FishingLevel/HookRigP1,
	2: $FishingLevel/HookRigP2,
}
@onready var catchables: Node2D = $FishingLevel/DemoCatchables
@onready var feedback_label: Label = $FishingLevel/FeedbackLabel
@onready var fishing_level: Node2D = $FishingLevel
@onready var water_bounds: ReferenceRect = $FishingLevel/Bounds
@onready var hud: GameHud = $UILayer/GameHud
@onready var result_overlay: RoundResultOverlay = $UILayer/RoundResultOverlay

var _feedback_tween: Tween


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_viewport_layout)
	round_controller.score_changed.connect(hud.set_score)
	round_controller.time_changed.connect(hud.set_time)
	round_controller.round_state_changed.connect(_on_round_state_changed)
	round_controller.round_finished.connect(_on_round_finished)
	for player_id in hook_controllers:
		var hook_controller := hook_controllers[player_id] as HookController
		hook_controller.delivery_completed.connect(_on_delivery_completed)
		hook_controller.catch_attached.connect(_on_catch_attached)
		hook_controller.shot_completed.connect(_on_shot_completed)
	hud.start_requested.connect(_try_start_round)
	result_overlay.restart_requested.connect(_restart_round)
	hud.set_score(1, 0, round_controller.level_definition.target_score)
	hud.set_score(2, 0, round_controller.level_definition.target_score)
	if round_controller.state == RoundController.RoundState.READY:
		hud.show_ready()
	_apply_viewport_layout()
	_set_hooks_input_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_round"):
		if _try_start_round():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart_round") and (round_controller.state == RoundController.RoundState.WON or round_controller.state == RoundController.RoundState.LOST or round_controller.state == RoundController.RoundState.DRAW):
		_restart_round()
		get_viewport().set_input_as_handled()
	elif round_controller.state == RoundController.RoundState.PLAYING:
		var player_id := _resolve_launch_player(event)
		if player_id != 0 and _try_launch(player_id):
			get_viewport().set_input_as_handled()


func _try_start_round() -> bool:
	if not round_controller.ensure_ready_state():
		return false
	if round_controller.start_round():
		hud.hide_ready()
		_set_hooks_input_enabled(true)
		return true
	return false


func _on_delivery_completed(player_id: int, catchable_id: StringName, score_value: int) -> void:
	if round_controller.add_score(catchable_id, score_value, player_id):
		_show_feedback("P%d 抓到 %d 分" % [player_id, score_value], Color(1.0, 0.88, 0.22, 1.0))


func _on_catch_attached(player_id: int, _catchable: Catchable) -> void:
	_show_feedback("P%d 抓住了！" % player_id, Color(0.45, 1.0, 0.72, 1.0))


func _on_shot_completed(player_id: int, caught_something: bool) -> void:
	if not caught_something and round_controller.state == RoundController.RoundState.PLAYING:
		_show_feedback("P%d 没抓到，再试一次！" % player_id, Color(0.9, 0.96, 1.0, 1.0))


func _on_round_state_changed(_previous: RoundController.RoundState, current: RoundController.RoundState) -> void:
	if current == RoundController.RoundState.READY:
		hud.show_ready()
	_set_hooks_input_enabled(current == RoundController.RoundState.PLAYING)


func _on_round_finished(result: RoundController.RoundResult, winner_player_id: int, p1_score: int, p2_score: int, target_score: int) -> void:
	_set_hooks_input_enabled(false)
	result_overlay.show_result(result, winner_player_id, p1_score, p2_score, target_score)


func _restart_round() -> void:
	for child in catchables.get_children():
		if child is Catchable:
			(child as Catchable).reset_catchable()
	for player_id in hook_controllers:
		var hook_controller := hook_controllers[player_id] as HookController
		hook_controller.reset_hook()
	result_overlay.hide_result()
	round_controller.restart_round()


func _apply_viewport_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var design_size := Vector2(1920.0, 1080.0)
	var world_scale := minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)
	var scaled_size := design_size * world_scale
	$FishingLevel.scale = Vector2.ONE * world_scale
	$FishingLevel.position = (viewport_size - scaled_size) * 0.5


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
	if event.is_action_pressed("cast_hook_p1"):
		if event is InputEventMouseButton and not _is_point_in_water(event.position):
			return 0
		return 1
	if event.is_action_pressed("cast_hook_p2"):
		if event is InputEventMouseButton and not _is_point_in_water(event.position):
			return 0
		return 2
	if event.is_action_pressed("cast_hook"):
		if event is InputEventKey:
			return 1
		if event is InputEventMouseButton:
			if not event.pressed:
				return 0
			if event.button_index != MOUSE_BUTTON_LEFT:
				return 0
			if not _is_point_in_water(event.position):
				return 0
			return _player_id_for_point(event.position)
		if event is InputEventScreenTouch:
			if not event.pressed or not _is_point_in_water(event.position):
				return 0
			return _player_id_for_point(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _is_point_in_water(event.position):
		return _player_id_for_point(event.position)
	if event is InputEventScreenTouch and event.pressed and _is_point_in_water(event.position):
		return _player_id_for_point(event.position)
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
		hook_controller.set_input_enabled(enabled)
