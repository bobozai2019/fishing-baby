class_name HookController
extends Node2D

signal state_changed(previous: HookState, current: HookState)
signal catch_attached(player_id: int, catchable: Catchable)
signal delivery_completed(player_id: int, catchable_id: StringName, score_value: int)
signal shot_completed(player_id: int, caught_something: bool)
signal powerup_collected(player_id: int, definition: PowerupDefinition)

enum HookState { DISABLED, SWINGING, EXTENDING, RETRACTING_EMPTY, RETRACTING_CATCH }

const HOOK_CENTER_FROM_ROPE_ATTACH := 38.08
const HOOK_COLLISION_FROM_ROPE_ATTACH := 52.0
const HOOK_COLLISION_RADIUS := 26.0

@export var level_definition: LevelDefinition
@export var player_id: int = 1

var state: HookState = HookState.DISABLED
var input_enabled: bool = false
var rope_length: float = 72.0
var swing_angle_degrees: float = 0.0
var _swing_direction: float = 1.0
var _carried: Catchable
var speed_multiplier: float = 1.0
var size_multiplier: float = 1.0
var seabed_y: float = INF

var _base_hook_scale: Vector2
var _base_collision_scale: Vector2

@onready var rope: Line2D = $Rope
@onready var tip: Area2D = $Tip
@onready var hook_sprite: Sprite2D = $Tip/HookSprite
@onready var collision_shape: CollisionShape2D = $Tip/CollisionShape2D


func _ready() -> void:
	if level_definition == null or not level_definition.is_valid_definition():
		push_error("HookController requires a valid LevelDefinition")
		return
	rope_length = level_definition.initial_rope_length
	_base_hook_scale = hook_sprite.scale
	_base_collision_scale = collision_shape.scale
	tip.area_entered.connect(_on_tip_area_entered)
	_update_visuals()


func _physics_process(delta: float) -> void:
	if level_definition == null:
		return
	match state:
		HookState.SWINGING:
			swing_angle_degrees += _swing_direction * level_definition.swing_speed_deg_per_sec * delta
			if swing_angle_degrees >= level_definition.swing_max_degrees or swing_angle_degrees <= level_definition.swing_min_degrees:
				swing_angle_degrees = clampf(swing_angle_degrees, level_definition.swing_min_degrees, level_definition.swing_max_degrees)
				_swing_direction *= -1.0
		HookState.EXTENDING:
			rope_length += level_definition.extend_speed * speed_multiplier * delta
			var max_length := _get_max_rope_length()
			if rope_length >= max_length:
				rope_length = max_length
				_change_state(HookState.RETRACTING_EMPTY)
		HookState.RETRACTING_EMPTY:
			rope_length -= level_definition.base_retract_speed * speed_multiplier * delta
			if rope_length <= level_definition.initial_rope_length:
				_finish_shot(false)
		HookState.RETRACTING_CATCH:
			var weight := _carried.definition.weight_multiplier if is_instance_valid(_carried) else 1.0
			rope_length -= level_definition.base_retract_speed * speed_multiplier / weight * delta
			if rope_length <= level_definition.initial_rope_length:
				_finish_shot(true)
	_update_visuals()
	if is_instance_valid(_carried):
		_carried.sync_to_carrier()


func try_launch() -> bool:
	if not input_enabled or state != HookState.SWINGING:
		return false
	_change_state(HookState.EXTENDING)
	return true


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if enabled and state == HookState.DISABLED:
		_change_state(HookState.SWINGING)
	elif not enabled and state == HookState.SWINGING:
		_change_state(HookState.DISABLED)


func reset_hook() -> void:
	_carried = null
	rope_length = level_definition.initial_rope_length if level_definition != null else 72.0
	swing_angle_degrees = 0.0
	_swing_direction = 1.0
	_change_state(HookState.SWINGING if input_enabled else HookState.DISABLED)
	_update_visuals()


func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = maxf(multiplier, 0.01)


func set_size_multiplier(multiplier: float) -> void:
	size_multiplier = maxf(multiplier, 0.01)
	_update_visuals()


func set_seabed_y(value: float) -> void:
	seabed_y = value


func _get_max_rope_length() -> float:
	if is_inf(seabed_y):
		return level_definition.max_rope_length
	var direction_y := cos(deg_to_rad(swing_angle_degrees))
	if direction_y <= 0.0:
		return level_definition.max_rope_length
	var hook_clearance := (HOOK_COLLISION_FROM_ROPE_ATTACH + HOOK_COLLISION_RADIUS) * size_multiplier
	var length_to_seabed := (seabed_y - position.y) / direction_y - hook_clearance
	return maxf(length_to_seabed, level_definition.initial_rope_length)


func clear_modifiers() -> void:
	speed_multiplier = 1.0
	size_multiplier = 1.0
	_update_visuals()


func _on_tip_area_entered(area: Area2D) -> void:
	if state != HookState.EXTENDING or _carried != null:
		return
	if area is PowerupPickup:
		var powerup := area as PowerupPickup
		if powerup.consume():
			print("[HOOK][POWERUP] player=%d name=%s definition_id=%s instance_id=%s" % [player_id, powerup.definition.display_name, powerup.definition.id, powerup.instance_id])
			powerup_collected.emit(player_id, powerup.definition)
		return
	if not area is Catchable:
		return
	var catchable := area as Catchable
	if catchable.attach_to_hook(collision_shape):
		_carried = catchable
		collision_shape.set_deferred("disabled", true)
		_print_catchable_log("CAUGHT", catchable)
		catch_attached.emit(player_id, catchable)
		_change_state(HookState.RETRACTING_CATCH)


func _finish_shot(caught_something: bool) -> void:
	rope_length = level_definition.initial_rope_length
	var delivered := (
		caught_something
		and is_instance_valid(_carried)
		and _carried.state == Catchable.CatchableState.HOOKED
	)
	if delivered:
		var delivered_id := _carried.instance_id
		var delivered_score := _carried.definition.score_value
		_print_catchable_log("DELIVERED", _carried)
		_carried.collect()
		delivery_completed.emit(player_id, delivered_id, delivered_score)
	else:
		print("[HOOK][EMPTY] player=%d" % player_id)
	_carried = null
	collision_shape.set_deferred("disabled", false)
	_change_state(HookState.SWINGING if input_enabled else HookState.DISABLED)
	shot_completed.emit(player_id, delivered)


func _print_catchable_log(event_name: String, catchable: Catchable) -> void:
	var category_name := CatchableDefinition.CatchableCategory.keys()[catchable.definition.category] as String
	print("[HOOK][%s] player=%d name=%s category=%s definition_id=%s instance_id=%s score=%d" % [event_name, player_id, catchable.definition.display_name, category_name, catchable.definition.id, catchable.instance_id, catchable.definition.score_value])


func _change_state(next_state: HookState) -> void:
	if state == next_state:
		return
	var previous := state
	state = next_state
	state_changed.emit(previous, state)


func _update_visuals() -> void:
	var direction := Vector2(sin(deg_to_rad(swing_angle_degrees)), cos(deg_to_rad(swing_angle_degrees)))
	var endpoint := direction * rope_length
	tip.position = endpoint
	hook_sprite.rotation = -deg_to_rad(swing_angle_degrees)
	hook_sprite.scale = _base_hook_scale * size_multiplier
	collision_shape.scale = _base_collision_scale * size_multiplier
	hook_sprite.position = direction * HOOK_CENTER_FROM_ROPE_ATTACH * size_multiplier
	collision_shape.position = direction * HOOK_COLLISION_FROM_ROPE_ATTACH * size_multiplier
	rope.points = PackedVector2Array([Vector2.ZERO, endpoint])
