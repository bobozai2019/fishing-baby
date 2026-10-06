class_name CharacterDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var portrait: Texture2D
@export var head_texture: Texture2D
@export_range(0, 1000, 1) var sort_order: int = 0


func is_valid_definition() -> bool:
	return not id.is_empty() \
		and not display_name.strip_edges().is_empty() \
		and portrait != null \
		and head_texture != null \
		and sort_order >= 0
