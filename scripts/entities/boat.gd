extends Node2D

const HEAD_SWAY_ANGLE := 6.0

@onready var head: Sprite2D = $Head

var _head_sway_tween: Tween


func set_head_texture(texture: Texture2D) -> void:
	head.texture = texture


func celebrate_catch() -> void:
	if _head_sway_tween != null and _head_sway_tween.is_valid():
		_head_sway_tween.kill()
	head.rotation = 0.0
	_head_sway_tween = create_tween()
	_head_sway_tween.tween_property(head, "rotation", deg_to_rad(-HEAD_SWAY_ANGLE), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_head_sway_tween.tween_property(head, "rotation", deg_to_rad(HEAD_SWAY_ANGLE), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_head_sway_tween.tween_property(head, "rotation", deg_to_rad(-HEAD_SWAY_ANGLE * 0.6), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_head_sway_tween.tween_property(head, "rotation", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
