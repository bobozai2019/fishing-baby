class_name PowerupEffectController
extends Node

signal effect_time_changed(effect_kind: PowerupDefinition.EffectKind, player_id: int, seconds_left: int)

var _hooks_by_player: Dictionary = {}
var _active_player_ids: Array[int] = [1, 2]
var _effects: Dictionary = {}


func configure(hooks_by_player: Dictionary, active_player_ids: Array[int] = [1, 2]) -> void:
	_hooks_by_player = hooks_by_player
	_active_player_ids = active_player_ids.duplicate()


func activate(definition: PowerupDefinition, player_id: int) -> bool:
	if definition == null or not definition.is_valid_definition():
		return false
	var effect_player_id := 0 if definition.effect_kind == PowerupDefinition.EffectKind.FREEZE_AQUATIC else player_id
	if effect_player_id != 0 and (not _hooks_by_player.has(effect_player_id) or not _active_player_ids.has(effect_player_id)):
		return false
	var key := _effect_key(definition.effect_kind, effect_player_id)
	_effects[key] = {
		"definition": definition,
		"player_id": effect_player_id,
		"remaining": definition.duration_seconds,
		"shown_seconds": ceili(definition.duration_seconds),
	}
	_apply_effect(definition, effect_player_id, true)
	effect_time_changed.emit(definition.effect_kind, effect_player_id, ceili(definition.duration_seconds))
	return true


func clear_all() -> void:
	for effect in _effects.values():
		var definition := effect.definition as PowerupDefinition
		_apply_effect(definition, effect.player_id, false)
		effect_time_changed.emit(definition.effect_kind, effect.player_id, 0)
	_effects.clear()
	for hook in _hooks_by_player.values():
		if hook is HookController:
			(hook as HookController).clear_modifiers()
	_set_aquatic_paused(false)


func _process(delta: float) -> void:
	for key in _effects.keys():
		var effect: Dictionary = _effects[key]
		effect.remaining = maxf(0.0, effect.remaining - delta)
		var seconds_left := ceili(effect.remaining)
		if seconds_left != effect.shown_seconds:
			effect.shown_seconds = seconds_left
			var definition := effect.definition as PowerupDefinition
			effect_time_changed.emit(definition.effect_kind, effect.player_id, seconds_left)
		_effects[key] = effect
		if effect.remaining <= 0.0:
			var definition := effect.definition as PowerupDefinition
			_apply_effect(definition, effect.player_id, false)
			_effects.erase(key)


func _apply_effect(definition: PowerupDefinition, player_id: int, active: bool) -> void:
	match definition.effect_kind:
		PowerupDefinition.EffectKind.HOOK_SPEED:
			(_hooks_by_player[player_id] as HookController).set_speed_multiplier(definition.magnitude if active else 1.0)
		PowerupDefinition.EffectKind.HOOK_SIZE:
			(_hooks_by_player[player_id] as HookController).set_size_multiplier(definition.magnitude if active else 1.0)
		PowerupDefinition.EffectKind.FREEZE_AQUATIC:
			_set_aquatic_paused(active)


func _set_aquatic_paused(paused: bool) -> void:
	get_tree().call_group("aquatic_life", "set_movement_paused", paused)


func _effect_key(effect_kind: PowerupDefinition.EffectKind, player_id: int) -> String:
	return "%d:%d" % [effect_kind, player_id]
