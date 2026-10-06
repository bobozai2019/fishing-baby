class_name Catchable
extends Area2D

signal hooked(catchable_id: StringName)
signal collected(catchable_id: StringName, score_value: int)

enum CatchableState { AVAILABLE, HOOKED, COLLECTED }

@export var definition: CatchableDefinition
@export var instance_id: StringName
@export var movement_min_x: float = 100.0
@export var movement_max_x: float = 1820.0
@export var movement_min_y: float = 410.0
@export var movement_max_y: float = 1010.0
@export var initial_direction: float = 1.0

var state: CatchableState = CatchableState.AVAILABLE
var _initial_position: Vector2
var _initial_z_index: int
var _direction: float = 1.0
var _carrier: Node2D
var _movement_time: float = 0.0
var _movement_paused: bool = false
var _wave_active: bool = true
var _hooked_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var instance_id_label: Label = $InstanceIdLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_initial_position = position
	_initial_z_index = z_index
	_direction = signf(initial_direction) if initial_direction != 0.0 else 1.0
	if not _apply_definition():
		push_error("Catchable has an invalid definition: %s" % name)
	elif definition.category == CatchableDefinition.CatchableCategory.FISH or definition.category == CatchableDefinition.CatchableCategory.CREATURE:
		add_to_group("aquatic_life")


func _physics_process(delta: float) -> void:
	if state == CatchableState.HOOKED:
		if is_instance_valid(_carrier):
			_hooked_time += delta
			sync_to_carrier()
			rotation = sin(_hooked_time * 12.0) * 0.14
		return
	if state != CatchableState.AVAILABLE or definition == null or _movement_paused or not _wave_active:
		return
	_movement_time += delta
	match definition.movement_kind:
		CatchableDefinition.MovementKind.HORIZONTAL:
			_move_horizontal(delta)
		CatchableDefinition.MovementKind.DRIFT:
			_move_horizontal(delta)
			position.y = _initial_position.y + sin(TAU * _movement_time * definition.movement_frequency_hz) * definition.movement_amplitude.y
		CatchableDefinition.MovementKind.VERTICAL:
			position.y += _direction * definition.movement_speed * delta
			if position.y <= movement_min_y or position.y >= movement_max_y:
				position.y = clampf(position.y, movement_min_y, movement_max_y)
				_direction *= -1.0
		CatchableDefinition.MovementKind.ZIGZAG:
			_move_horizontal(delta)
			var cycle := fposmod(_movement_time * definition.movement_frequency_hz, 1.0)
			var triangle := 1.0 - 4.0 * absf(cycle - 0.5)
			position.y = _initial_position.y + triangle * definition.movement_amplitude.y
		CatchableDefinition.MovementKind.ELLIPSE:
			var radius := maxf(definition.movement_amplitude.x, definition.movement_amplitude.y)
			var phase := _movement_time * definition.movement_speed / radius if radius > 0.0 else 0.0
			position = _initial_position + Vector2(cos(phase) * definition.movement_amplitude.x, sin(phase) * definition.movement_amplitude.y)


func attach_to_hook(carrier: Node2D) -> bool:
	if state != CatchableState.AVAILABLE or carrier == null:
		return false
	state = CatchableState.HOOKED
	z_index = 19
	_hooked_time = 0.0
	_carrier = carrier
	global_position = carrier.global_position
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)
	if definition.caught_texture != null:
		sprite.texture = definition.caught_texture
	hooked.emit(instance_id)
	return true


func sync_to_carrier() -> void:
	if state == CatchableState.HOOKED and is_instance_valid(_carrier):
		global_position = _carrier.global_position


func collect() -> void:
	if state != CatchableState.HOOKED:
		return
	state = CatchableState.COLLECTED
	visible = false
	z_index = _initial_z_index
	_carrier = null
	collected.emit(instance_id, definition.score_value)


func reset_catchable(wave_active: bool = true) -> void:
	state = CatchableState.AVAILABLE
	z_index = _initial_z_index
	position = _initial_position
	rotation = 0.0
	_direction = signf(initial_direction) if initial_direction != 0.0 else 1.0
	_movement_time = 0.0
	_movement_paused = false
	_wave_active = wave_active
	_hooked_time = 0.0
	_carrier = null
	visible = wave_active
	set_deferred("monitoring", wave_active)
	set_deferred("monitorable", wave_active)
	collision_shape.set_deferred("disabled", not wave_active)
	_apply_definition()


func set_wave_active(active: bool) -> void:
	_wave_active = active
	if not active:
		visible = false
		monitoring = false
		monitorable = false
		collision_shape.disabled = true
	elif state == CatchableState.AVAILABLE:
		visible = true
		monitoring = true
		monitorable = true
		collision_shape.disabled = false


func set_movement_paused(paused: bool) -> void:
	_movement_paused = paused


func _move_horizontal(delta: float) -> void:
	position.x += _direction * definition.movement_speed * delta
	if position.x <= movement_min_x or position.x >= movement_max_x:
		position.x = clampf(position.x, movement_min_x, movement_max_x)
		_direction *= -1.0
		sprite.flip_h = _direction < 0.0


func _apply_definition() -> bool:
	if definition == null or not definition.is_valid_definition() or instance_id.is_empty():
		return false
	sprite.texture = definition.swim_texture
	sprite.scale = Vector2.ONE * definition.visual_scale
	instance_id_label.text = "ID: %s" % instance_id
	instance_id_label.visible = definition.category == CatchableDefinition.CatchableCategory.FISH
	instance_id_label.position.y = -definition.collision_radius - 28.0
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = definition.collision_radius
	return true
