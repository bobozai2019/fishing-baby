extends Node2D

const SANDBED_HEIGHT := 130.0
const SEABED_DECOR_OFFSET_Y := -75.0

@onready var background: NinePatchRect = $Environment/SkyWaterSand
@onready var seabed_decor: Sprite2D = $Environment/SeabedDecor
@onready var sandbed: NinePatchRect = $Environment/Sandbed
@onready var surface_waves: Sprite2D = $Environment/SurfaceWaves


func apply_viewport_rect(viewport_rect: Rect2) -> float:
	background.position = viewport_rect.position
	background.size = viewport_rect.size
	var seabed_y := viewport_rect.end.y - SANDBED_HEIGHT
	sandbed.position = Vector2(viewport_rect.position.x, seabed_y)
	sandbed.size = Vector2(viewport_rect.size.x, SANDBED_HEIGHT)
	seabed_decor.position = Vector2(viewport_rect.get_center().x, seabed_y + SEABED_DECOR_OFFSET_Y)
	surface_waves.position.x = viewport_rect.get_center().x
	surface_waves.scale.x = viewport_rect.size.x / surface_waves.texture.get_width()
	return seabed_y
