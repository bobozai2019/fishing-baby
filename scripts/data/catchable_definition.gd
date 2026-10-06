class_name CatchableDefinition
extends Resource

enum CatchableCategory { FISH, CREATURE, PICKUP, TRASH }
enum MovementKind { STATIC, HORIZONTAL, DRIFT, VERTICAL, ZIGZAG, ELLIPSE }

@export var id: StringName
@export var display_name: String
@export var category: CatchableCategory = CatchableCategory.FISH
@export_range(0, 10000, 1) var score_value: int = 0
@export_range(0.5, 3.0, 0.05) var weight_multiplier: float = 1.0
@export var movement_kind: MovementKind = MovementKind.STATIC
@export_range(0.0, 500.0, 1.0) var movement_speed: float = 0.0
@export var movement_amplitude: Vector2 = Vector2(0.0, 20.0)
@export_range(0.0, 10.0, 0.01) var movement_frequency_hz: float = 0.25
@export var swim_texture: Texture2D
@export var caught_texture: Texture2D
@export_range(0.01, 2.0, 0.01) var visual_scale: float = 0.16
@export_range(1.0, 200.0, 1.0) var collision_radius: float = 42.0


func is_valid_definition() -> bool:
	if id.is_empty() or display_name.is_empty() or score_value < 0:
		return false
	if weight_multiplier < 0.5 or weight_multiplier > 3.0:
		return false
	if movement_speed < 0.0 or swim_texture == null or visual_scale <= 0.0:
		return false
	if movement_amplitude.x < 0.0 or movement_amplitude.y < 0.0 or movement_frequency_hz < 0.0:
		return false
	if category == CatchableCategory.FISH and caught_texture == null:
		return false
	return collision_radius > 0.0
