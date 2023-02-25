extends MeshInstance3D

@export var random_seed: int = -6398989897141750821 + 3
@export var stages_in_thread: bool = true
@export var debug_color_dict: Resource
@export_category("Grid Size")
@export var edge_length: float = 10.0
@export var edges_across: int = 100
@export_category("Height Map Settings")
@export var diff_height: float = 2.0
@export var diff_max_multi: int = 3
@export var erode_depth: float = 1.0
@export_category("Generator Settings")
@export var land_cell_limit: int = 4000
@export var river_count: int = 30
@export var road_slope_penalty: float = 5.0
@export var road_river_crossing_penalty: float = 10.0
@export var cliff_min_slope: float = 5.0

var thread: Thread
var high_level_terrain: HighLevelTerrain

@onready var _water_material := preload("res://materials/debug_water_surface.tres")
@onready var _terrain_material := preload("res://materials/debug_terrain_surface.tres")

func _ready() -> void:
	high_level_terrain = HighLevelTerrain.new(
		random_seed,
		edge_length,
		edges_across,
		diff_height,
		diff_max_multi,
		erode_depth,
		land_cell_limit,
		river_count,
		road_slope_penalty,
		road_river_crossing_penalty,
		cliff_min_slope,
		debug_color_dict
	)
	var _err1 = high_level_terrain.connect("all_stages_complete", _on_all_stages_complete)
	var _err2 = high_level_terrain.connect("stage_complete", _on_stage_complete)
	if stages_in_thread:
		thread = Thread.new()
		var _err = thread.start(_stage_thread)
	else:
		_stage_thread()

func _exit_tree():
	if stages_in_thread:
		thread.wait_to_finish()

func _stage_thread() -> void:
	high_level_terrain.perform()

func _on_stage_complete(stage: Stage, duration: int) -> void:
	print("%s completed in %d msecs" % [stage, duration])
	var time_start = Time.get_ticks_msec()
	_update_land_terrain_mesh()
	
	match str(stage):
		"Height Stage":
			_create_water_mesh_instances(_water_material)
#		"River Stage":
#			_create_river_mesh_instances(_water_material)
#		"Civil Stage":
#			_create_road_mesh_instances(_terrain_material)
#			_create_road_sign_debug_meshes(_terrain_material)
#		"Cliff Stage":
#			_create_cliff_mesh_instances(_terrain_material)

	print("%s meshed updated in %d msecs" % [stage, (Time.get_ticks_msec() - time_start)])

func _on_all_stages_complete() -> void:
	print("High Level Terrain stages complete")

func _update_land_terrain_mesh() -> void:
	var island_mesh: Mesh = MeshUtils.get_land_mesh(high_level_terrain, debug_color_dict)
	set_mesh(island_mesh)

func _create_water_mesh_instances(water_material: Material) -> void:
	_insert_meshes(MeshUtils.get_water_body_meshes(high_level_terrain), water_material)

#func _create_river_mesh_instances(water_material: Material) -> void:
#	_insert_meshes(MeshUtils.get_river_surface_meshes(high_level_terrain), water_material)
#
#func _create_road_mesh_instances(terrain_material: Material) -> void:
#	_insert_meshes(MeshUtils.get_all_road_surface_meshes(high_level_terrain, debug_color_dict), terrain_material)
#
#func _create_road_sign_debug_meshes(terrain_material: Material) -> void:
#	_insert_meshes(MeshUtils.get_road_sign_debug_meshes(high_level_terrain, debug_color_dict), terrain_material)
#
#func _create_cliff_mesh_instances(terrain_material: Material) -> void:
#	_insert_meshes(MeshUtils.get_cliff_surface_meshes(high_level_terrain, debug_color_dict), terrain_material)

func _insert_meshes(meshes: Array[Mesh], material: Material) -> void:
	for in_mesh in meshes:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = in_mesh
		mesh_instance.set_surface_override_material(0, material)
		add_child(mesh_instance)
