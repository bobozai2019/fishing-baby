extends Node

@export var character_id: StringName


func _ready() -> void:
	call_deferred("_apply_state")


func _apply_state() -> void:
	var main := get_parent()
	main._on_single_requested()
	if not character_id.is_empty():
		main._on_character_selected(character_id)
