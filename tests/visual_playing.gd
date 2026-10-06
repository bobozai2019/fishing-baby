extends Node


func _ready() -> void:
	$Main.call_deferred("_try_start_round")
