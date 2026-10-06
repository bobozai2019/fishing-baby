class_name RoundResultOverlay
extends Control

signal restart_requested
signal return_mode_requested

@onready var title_label: Label = %TitleLabel
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var return_mode_button: Button = %ReturnModeButton

var _is_single_player := false
var _player_one_name := "P1"


func _ready() -> void:
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	return_mode_button.pressed.connect(func() -> void: return_mode_requested.emit())
	visible = false


func configure_session(is_single_player: bool, player_one_name: String) -> void:
	_is_single_player = is_single_player
	_player_one_name = player_one_name if not player_one_name.is_empty() else "P1"


func show_result(result: RoundController.RoundResult, winner_player_id: int, score_player_1: int, score_player_2: int, target: int) -> void:
	if _is_single_player:
		title_label.text = "%s 大丰收！" % _player_one_name if result == RoundController.RoundResult.WON else "潮水退去"
		result_label.text = "%s: %d / %d" % [_player_one_name, score_player_1, target]
		visible = true
		restart_button.grab_focus()
		return
	if result == RoundController.RoundResult.WON:
		if winner_player_id <= 0:
			title_label.text = "平局"
		else:
			title_label.text = "P%d 获胜！" % winner_player_id
	elif result == RoundController.RoundResult.DRAW:
		title_label.text = "平局"
	else:
		title_label.text = "潮水退去"
	result_label.text = "P1: %d / %d\nP2: %d / %d" % [score_player_1, target, score_player_2, target]
	visible = true
	restart_button.grab_focus()


func hide_result() -> void:
	visible = false
