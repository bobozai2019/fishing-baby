extends Node

@export_enum("wave3", "effects") var capture_mode: String = "wave3"

@onready var main: Node = $Main


func _ready() -> void:
	var waves := main.get_node("FishingLevel/DemoCatchables") as WaveController
	waves.update_elapsed(60.0)
	main.get_node("UILayer/GameHud").hide_ready()
	if capture_mode == "effects":
		var effects := main.get_node("FishingLevel/PowerupEffectController") as PowerupEffectController
		effects.activate(load("res://resources/game_data/powerups/speed_reel.tres"), 1)
		effects.activate(load("res://resources/game_data/powerups/giant_hook.tres"), 1)
		effects.activate(load("res://resources/game_data/powerups/freeze_crystal.tres"), 2)
