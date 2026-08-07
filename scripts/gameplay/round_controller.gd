class_name RoundController
extends Node

signal round_state_changed(previous: RoundState, current: RoundState)
signal score_changed(player_id: int, score: int, target_score: int)
signal time_changed(seconds_left: int)
signal round_finished(result: RoundResult, winner_player_id: int, score_player_1: int, score_player_2: int, target_score: int)

enum RoundState { BOOT, READY, PLAYING, WON, LOST, DRAW }
enum RoundResult { WON, LOST, DRAW }

@export var level_definition: LevelDefinition

var state: RoundState = RoundState.BOOT
var scores: Dictionary = {1: 0, 2: 0}
var seconds_left: int = 0
var _time_remaining: float = 0.0
var _settled_instances: Dictionary = {}


func _ready() -> void:
	if level_definition == null or not level_definition.is_valid_definition():
		push_error("RoundController requires a valid LevelDefinition")
		return
	_prepare_ready_state()


func _process(delta: float) -> void:
	if state != RoundState.PLAYING:
		return
	_time_remaining = maxf(0.0, _time_remaining - delta)
	var display_seconds := ceili(_time_remaining)
	if display_seconds != seconds_left:
		seconds_left = display_seconds
		time_changed.emit(seconds_left)
	if _time_remaining <= 0.0:
		var winner := _compare_scores()
		if winner == 0:
			_finish_round(RoundResult.DRAW, 0)
		else:
			_finish_round(RoundResult.WON, winner)


func start_round() -> bool:
	if state != RoundState.READY:
		return false
	scores[1] = 0
	scores[2] = 0
	_time_remaining = float(level_definition.duration_seconds)
	seconds_left = level_definition.duration_seconds
	_settled_instances.clear()
	_change_state(RoundState.PLAYING)
	for player_id in scores.keys():
		score_changed.emit(player_id, scores[player_id], level_definition.target_score)
	time_changed.emit(seconds_left)
	return true


func ensure_ready_state() -> bool:
	if state == RoundState.READY:
		return true
	if state == RoundState.BOOT:
		if level_definition == null or not level_definition.is_valid_definition():
			return false
		_prepare_ready_state()
		return true
	return false


func add_score(catchable_id: StringName, amount: int, player_id: int) -> bool:
	if state != RoundState.PLAYING or catchable_id.is_empty() or amount < 0 or not scores.has(player_id):
		return false
	if _settled_instances.has(catchable_id):
		return false
	_settled_instances[catchable_id] = true
	scores[player_id] += amount
	score_changed.emit(player_id, scores[player_id], level_definition.target_score)
	if scores[player_id] >= level_definition.target_score:
		_finish_round(RoundResult.WON, player_id)
	return true


func restart_round() -> void:
	if state != RoundState.WON and state != RoundState.LOST and state != RoundState.DRAW:
		return
	_prepare_ready_state()


func force_time_expired_for_test() -> void:
	if state == RoundState.PLAYING:
		_time_remaining = 0.0
		_process(0.0)


func _prepare_ready_state() -> void:
	scores[1] = 0
	scores[2] = 0
	seconds_left = level_definition.duration_seconds
	_time_remaining = float(seconds_left)
	_settled_instances.clear()
	_change_state(RoundState.READY)
	for player_id in scores.keys():
		score_changed.emit(player_id, scores[player_id], level_definition.target_score)
	time_changed.emit(seconds_left)


func _finish_round(result: RoundResult, winner_player_id: int = 0) -> void:
	if state != RoundState.PLAYING:
		return
	var final_result := result
	var final_winner := winner_player_id
	if final_result == RoundResult.WON and final_winner == 0:
		final_winner = _compare_scores()
		if final_winner == 0:
			final_result = RoundResult.DRAW
		else:
			final_result = RoundResult.WON
	_change_state(RoundState.WON if final_result == RoundResult.WON else RoundState.DRAW if final_result == RoundResult.DRAW else RoundState.LOST)
	round_finished.emit(final_result, final_winner, scores.get(1, 0), scores.get(2, 0), level_definition.target_score)


func _change_state(next_state: RoundState) -> void:
	if state == next_state:
		return
	var previous := state
	state = next_state
	round_state_changed.emit(previous, state)


func _compare_scores() -> int:
	var score_1: int = scores.get(1, 0)
	var score_2: int = scores.get(2, 0)
	if score_1 > score_2:
		return 1
	if score_2 > score_1:
		return 2
	return 0
