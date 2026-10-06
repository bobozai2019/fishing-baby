class_name WaveController
extends Node2D

signal wave_started(wave_index: int)

@export var wave_start_elapsed_seconds: PackedFloat32Array = PackedFloat32Array([0.0, 30.0, 60.0])

var _active_wave_count: int = 0


func _ready() -> void:
	reset_waves()


func reset_waves() -> void:
	var waves := get_children()
	for wave_index in range(waves.size()):
		var wave := waves[wave_index]
		for entity in wave.get_children():
			if entity is Catchable:
				(entity as Catchable).reset_catchable(wave_index == 0)
			elif entity is PowerupPickup:
				(entity as PowerupPickup).reset_powerup(wave_index == 0)
	_active_wave_count = mini(1, waves.size())


func update_elapsed(elapsed_seconds: float) -> void:
	var wave_count := mini(get_child_count(), wave_start_elapsed_seconds.size())
	while _active_wave_count < wave_count and elapsed_seconds >= wave_start_elapsed_seconds[_active_wave_count]:
		_activate_wave(_active_wave_count)
		_active_wave_count += 1
		wave_started.emit(_active_wave_count)


func get_active_wave_count() -> int:
	return _active_wave_count


func _activate_wave(wave_index: int) -> void:
	var wave := get_child(wave_index)
	for entity in wave.get_children():
		if entity is Catchable:
			(entity as Catchable).set_wave_active(true)
		elif entity is PowerupPickup:
			(entity as PowerupPickup).set_wave_active(true)
