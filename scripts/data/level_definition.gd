class_name LevelDefinition
extends Resource

@export var id: StringName = &"demo_level"
@export_range(1, 600, 1) var duration_seconds: int = 90
@export_range(1, 100000, 1) var target_score: int = 1800
@export var wave_start_elapsed_seconds: PackedFloat32Array = PackedFloat32Array([0.0, 30.0, 60.0])
@export var swing_min_degrees: float = -65.0
@export var swing_max_degrees: float = 65.0
@export_range(1.0, 360.0, 1.0) var swing_speed_deg_per_sec: float = 55.0
@export_range(1.0, 2000.0, 1.0) var extend_speed: float = 650.0
@export_range(1.0, 2000.0, 1.0) var base_retract_speed: float = 420.0
@export_range(1.0, 2000.0, 1.0) var max_rope_length: float = 880.0
@export_range(1.0, 500.0, 1.0) var initial_rope_length: float = 72.0


func is_valid_definition() -> bool:
	return not id.is_empty() \
		and duration_seconds > 0 \
		and target_score > 0 \
		and _has_valid_wave_thresholds() \
		and swing_min_degrees < swing_max_degrees \
		and swing_speed_deg_per_sec > 0.0 \
		and extend_speed > 0.0 \
		and base_retract_speed > 0.0 \
		and max_rope_length > initial_rope_length \
		and initial_rope_length > 0.0


func _has_valid_wave_thresholds() -> bool:
	if wave_start_elapsed_seconds.is_empty() or not is_zero_approx(wave_start_elapsed_seconds[0]):
		return false
	for index in range(1, wave_start_elapsed_seconds.size()):
		if wave_start_elapsed_seconds[index] <= wave_start_elapsed_seconds[index - 1]:
			return false
	return wave_start_elapsed_seconds[-1] < duration_seconds
