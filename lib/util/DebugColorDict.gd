class_name DebugColorDict
extends Resource

@export var base_color: Color = Color8(24, 64, 24, 255)
@export var land_color: Color = Color8(32, 96, 32, 255)
@export var region_colors := PackedColorArray([
	land_color, # Color8(  0,   0, 192, 255),
	land_color, # Color8(  0, 192,   0, 255),
	land_color, # Color8(192,   0,   0, 255),
	land_color, # Color8(  0, 192, 192, 255),
	land_color, # Color8(192, 192,   0, 255),
	land_color, # Color8(192,   0, 192, 255),
])
@export var river_color: Color = Color8(32, 32, 192, 255)
@export var head_color: Color = river_color # Color8(0, 0, 86, 255)
@export var mouth_color: Color = river_color # Color8(128, 128, 255, 255)
@export var lake_colors := PackedColorArray([
	river_color, # Color8( 48,  48, 192, 255),
	river_color, # Color8( 32,  32, 192, 255),
	river_color, # Color8( 16,  16, 192, 255),
])
@export var settlement_color: Color = Color8(64, 64, 64, 255)
@export var road_cell_color: Color = Color8(32, 96, 32, 255)
@export var road_color: Color = Color8(48, 80, 48, 255)
@export var junction_marker_color: Color = Color8(64, 48, 32, 255)
@export var cliff_color: Color = Color8(176, 192, 176, 255)
@export var special_debug_color: Color = Color8(192, 32, 192, 255)
