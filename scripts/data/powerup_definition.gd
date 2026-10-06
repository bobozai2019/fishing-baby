class_name PowerupDefinition
extends Resource

enum EffectKind { HOOK_SPEED, HOOK_SIZE, FREEZE_AQUATIC }

@export var id: StringName
@export var display_name: String
@export var effect_kind: EffectKind = EffectKind.HOOK_SPEED
@export_range(0.01, 60.0, 0.01) var duration_seconds: float = 5.0
@export_range(0.01, 10.0, 0.01) var magnitude: float = 1.0
@export var texture: Texture2D
@export_range(0.01, 2.0, 0.01) var visual_scale: float = 0.12
@export_range(1.0, 200.0, 1.0) var collision_radius: float = 36.0


func is_valid_definition() -> bool:
	return not id.is_empty() \
		and not display_name.is_empty() \
		and effect_kind >= EffectKind.HOOK_SPEED \
		and effect_kind <= EffectKind.FREEZE_AQUATIC \
		and duration_seconds > 0.0 \
		and magnitude > 0.0 \
		and texture != null \
		and visual_scale > 0.0 \
		and collision_radius > 0.0
