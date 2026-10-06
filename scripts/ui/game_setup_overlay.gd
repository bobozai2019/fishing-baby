class_name GameSetupOverlay
extends Control

signal single_requested
signal local_multi_requested
signal character_selected(character_id: StringName)
signal back_requested

@onready var mode_page: VBoxContainer = %ModePage
@onready var character_page: VBoxContainer = %CharacterPage
@onready var single_button: Button = %SingleButton
@onready var multi_button: Button = %MultiButton
@onready var back_button: Button = %BackButton
@onready var character_list: HFlowContainer = %CharacterList

var character_buttons: Dictionary = {}


func _ready() -> void:
	single_button.pressed.connect(func() -> void: single_requested.emit())
	multi_button.pressed.connect(func() -> void: local_multi_requested.emit())
	back_button.pressed.connect(func() -> void: back_requested.emit())


func configure_characters(characters: Array[Resource]) -> void:
	for child in character_list.get_children():
		child.queue_free()
	character_buttons.clear()
	for character in characters:
		var button := Button.new()
		button.name = "Character_%s" % character.id
		button.custom_minimum_size = Vector2(260.0, 220.0)
		button.text = character.display_name
		button.icon = character.portrait
		button.expand_icon = true
		button.theme_type_variation = &"CharacterCard"
		button.tooltip_text = "选择%s" % character.display_name
		button.pressed.connect(func() -> void: character_selected.emit(character.id))
		character_list.add_child(button)
		character_buttons[character.id] = button


func show_mode_select() -> void:
	visible = true
	mode_page.visible = true
	character_page.visible = false
	single_button.call_deferred("grab_focus")


func show_character_select() -> void:
	visible = true
	mode_page.visible = false
	character_page.visible = true
	if not character_buttons.is_empty():
		(character_buttons.values()[0] as Button).call_deferred("grab_focus")


func hide_setup() -> void:
	visible = false


func get_character_button(character_id: StringName) -> Button:
	return character_buttons.get(character_id) as Button
