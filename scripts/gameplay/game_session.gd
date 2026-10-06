class_name GameSession
extends Node

signal state_changed(previous: SessionState, current: SessionState)

enum SessionState { MODE_SELECT, CHARACTER_SELECT, READY, PLAYING, RESULT }
enum GameMode { NONE, SINGLE, LOCAL_MULTI }

@export var characters: Array[Resource] = []
@export var multiplayer_character_ids: Array[StringName] = [&"boy", &"girl"]

var state: SessionState = SessionState.MODE_SELECT
var mode: GameMode = GameMode.NONE
var selected_character_ids: Dictionary = {}
var active_player_ids: Array[int] = []


func is_catalog_valid() -> bool:
	if characters.is_empty():
		return false
	var seen: Dictionary = {}
	for character in characters:
		if character == null or not character.is_valid_definition() or seen.has(character.id):
			return false
		seen[character.id] = true
	return true


func get_characters_sorted() -> Array[Resource]:
	var result := characters.duplicate()
	result.sort_custom(func(left: Resource, right: Resource) -> bool:
		if left.sort_order == right.sort_order:
			return str(left.id) < str(right.id)
		return left.sort_order < right.sort_order
	)
	return result


func get_character(character_id: StringName) -> Resource:
	for character in characters:
		if character != null and character.id == character_id:
			return character
	return null


func select_single() -> bool:
	if state != SessionState.MODE_SELECT or not is_catalog_valid():
		return false
	mode = GameMode.SINGLE
	selected_character_ids.clear()
	active_player_ids.clear()
	_change_state(SessionState.CHARACTER_SELECT)
	return true


func select_local_multi() -> bool:
	if state != SessionState.MODE_SELECT or not is_catalog_valid() or multiplayer_character_ids.size() != 2:
		return false
	var first := get_character(multiplayer_character_ids[0])
	var second := get_character(multiplayer_character_ids[1])
	if first == null or second == null:
		return false
	mode = GameMode.LOCAL_MULTI
	selected_character_ids = {1: first.id, 2: second.id}
	active_player_ids = [1, 2]
	_change_state(SessionState.READY)
	return true


func confirm_single_character(character_id: StringName) -> bool:
	if state != SessionState.CHARACTER_SELECT or mode != GameMode.SINGLE:
		return false
	var character := get_character(character_id)
	if character == null:
		return false
	selected_character_ids = {1: character.id}
	active_player_ids = [1]
	_change_state(SessionState.READY)
	return true


func mark_playing() -> bool:
	if state != SessionState.READY or not is_configured():
		return false
	_change_state(SessionState.PLAYING)
	return true


func mark_result() -> bool:
	if state != SessionState.PLAYING:
		return false
	_change_state(SessionState.RESULT)
	return true


func mark_ready_after_restart() -> bool:
	if state != SessionState.RESULT or not is_configured():
		return false
	_change_state(SessionState.READY)
	return true


func return_to_mode_select() -> bool:
	if state == SessionState.PLAYING or state == SessionState.MODE_SELECT:
		return false
	mode = GameMode.NONE
	selected_character_ids.clear()
	active_player_ids.clear()
	_change_state(SessionState.MODE_SELECT)
	return true


func return_to_mode_from_character_select() -> bool:
	return return_to_mode_select()


func is_configured() -> bool:
	if mode == GameMode.SINGLE:
		return state >= SessionState.READY and active_player_ids == [1] and selected_character_ids.has(1)
	if mode == GameMode.LOCAL_MULTI:
		return state >= SessionState.READY and active_player_ids == [1, 2] and selected_character_ids.has(1) and selected_character_ids.has(2)
	return false


func _change_state(next_state: SessionState) -> void:
	if state == next_state:
		return
	var previous := state
	state = next_state
	state_changed.emit(previous, state)
