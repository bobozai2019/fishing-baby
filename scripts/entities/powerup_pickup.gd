class_name PowerupPickup
extends Area2D

enum PowerupState { AVAILABLE, CONSUMED }

@export var definition: PowerupDefinition
@export var instance_id: StringName

var state: PowerupState = PowerupState.AVAILABLE
var _wave_active: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if not _apply_definition():
		push_error("PowerupPickup has an invalid definition: %s" % name)


func consume() -> bool:
	if state != PowerupState.AVAILABLE or not _wave_active:
		return false
	state = PowerupState.CONSUMED
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)
	return true


func reset_powerup(wave_active: bool = true) -> void:
	state = PowerupState.AVAILABLE
	_wave_active = wave_active
	visible = wave_active
	monitoring = wave_active
	monitorable = wave_active
	collision_shape.set_deferred("disabled", not wave_active)
	_apply_definition()


func set_wave_active(active: bool) -> void:
	_wave_active = active
	if not active:
		visible = false
		monitoring = false
		monitorable = false
		collision_shape.disabled = true
	elif state == PowerupState.AVAILABLE:
		visible = true
		monitoring = true
		monitorable = true
		collision_shape.disabled = false


func _apply_definition() -> bool:
	if definition == null or not definition.is_valid_definition() or instance_id.is_empty():
		return false
	sprite.texture = definition.texture
	sprite.scale = Vector2.ONE * definition.visual_scale
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = definition.collision_radius
	return true
