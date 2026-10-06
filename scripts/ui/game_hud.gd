class_name GameHud
extends Control

signal start_requested
signal mode_select_requested

@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var prompt_panel: PanelContainer = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var start_button: Button = %StartButton
@onready var mode_select_button: Button = %ModeSelectButton
@onready var p1_effects: Label = %P1Effects
@onready var global_effects: Label = %GlobalEffects
@onready var p2_effects: Label = %P2Effects

var player_scores: Dictionary = {1: 0, 2: 0}
var effect_seconds: Dictionary = {}
var _is_single_player := false
var _player_one_name := "P1"
var _target_score := 0


func _ready() -> void:
	start_button.pressed.connect(func() -> void: start_requested.emit())
	mode_select_button.pressed.connect(func() -> void: mode_select_requested.emit())


func configure_session(is_single_player: bool, player_one_name: String, target: int) -> void:
	_is_single_player = is_single_player
	_player_one_name = player_one_name if not player_one_name.is_empty() else "P1"
	_target_score = target
	effect_seconds.clear()
	_update_score_label()
	_update_effect_labels()


func set_score(player_id: int, score: int, target: int) -> void:
	player_scores[player_id] = score
	_target_score = target
	_update_score_label()


func set_time(seconds_left: int) -> void:
	time_label.text = "%02d" % maxi(0, seconds_left)


func set_effect_time(effect_kind: PowerupDefinition.EffectKind, player_id: int, seconds_left: int) -> void:
	var key := "%d:%d" % [effect_kind, player_id]
	if seconds_left > 0:
		effect_seconds[key] = seconds_left
	else:
		effect_seconds.erase(key)
	_update_effect_labels()


func show_ready() -> void:
	if _is_single_player:
		prompt_label.text = "准备好了吗？\n%s 单人出海\n点击水域、按 Q 或空格出钩" % _player_one_name
	else:
		prompt_label.text = "准备好了吗？\nP1 与 P2 点击准备后同场竞技\n手机可左右分区分别出钩"
	prompt_panel.visible = true
	start_button.visible = true
	mode_select_button.visible = true


func hide_ready() -> void:
	prompt_panel.visible = false


func show_result(_result: RoundController.RoundResult, _score: int, _target: int) -> void:
	prompt_panel.visible = false


func _update_effect_labels() -> void:
	_set_personal_effect_label(p1_effects, 1)
	_set_personal_effect_label(p2_effects, 2)
	var freeze_key := "%d:0" % PowerupDefinition.EffectKind.FREEZE_AQUATIC
	var freeze_seconds := int(effect_seconds.get(freeze_key, 0))
	global_effects.text = "冰冻 %d" % freeze_seconds if freeze_seconds > 0 else ""
	global_effects.visible = freeze_seconds > 0


func _set_personal_effect_label(label: Label, player_id: int) -> void:
	var parts: Array[String] = []
	var speed := int(effect_seconds.get("%d:%d" % [PowerupDefinition.EffectKind.HOOK_SPEED, player_id], 0))
	var size := int(effect_seconds.get("%d:%d" % [PowerupDefinition.EffectKind.HOOK_SIZE, player_id], 0))
	if speed > 0:
		parts.append("加速 %d" % speed)
	if size > 0:
		parts.append("巨钩 %d" % size)
	var player_name := _player_one_name if _is_single_player and player_id == 1 else "P%d" % player_id
	label.text = "%s  %s" % [player_name, "  ".join(parts)] if not parts.is_empty() else ""
	label.visible = not parts.is_empty() and (not _is_single_player or player_id == 1)


func _update_score_label() -> void:
	if _is_single_player:
		score_label.text = "%s: %d / %d" % [_player_one_name, player_scores.get(1, 0), _target_score]
	else:
		score_label.text = "P1: %d / %d\nP2: %d / %d" % [player_scores.get(1, 0), _target_score, player_scores.get(2, 0), _target_score]
	p2_effects.visible = not _is_single_player and not p2_effects.text.is_empty()
