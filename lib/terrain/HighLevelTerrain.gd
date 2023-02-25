class_name HighLevelTerrain
extends Object
"""
This object is collects stages for generating a highlevel outline of a terrain.
This works out the land edges and the major bodies of water
and can be used as a base reference for other terrain features
"""

signal stage_complete(stage, duration)
signal all_stages_complete()


var _grid: Grid
var _island_stage: IslandStage
var _regions_stage: RegionStage
var _lake_stage: LakeStage
#var _height_stage: HeightStage
#var _river_stage: RiverStage
#var _civil_stage: CivilStage
#var _cliff_stage: CliffStage

func _init(
	random_seed: int,
	edge_length: float,
	edges_across: int,
	diff_height: float,
	diff_max_multi: int,
	erode_depth: float,
	land_cell_limit: int,
	river_count: int,
	slope_penalty: float,
	river_penalty: float,
	cliff_min_slope: float,
	debug_color_map: DebugColorDict
) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed
	_grid = Grid.new(edge_length, edges_across, debug_color_map.base_color)
	_grid.perform()  # Need the grid in place before further stages can be instantiated
	_island_stage = IslandStage.new(_grid, debug_color_map.land_color, land_cell_limit, rng.randi())
	_regions_stage = RegionStage.new(_island_stage.get_region(), debug_color_map.region_colors, rng.randi())
	_lake_stage = LakeStage.new(_regions_stage, debug_color_map.lake_colors, rng.randi())
#	_height_stage = HeightStage.new(_island_stage.get_region(), _lake_stage, diff_height, diff_max_multi, rng.randi())
#	_river_stage = RiverStage.new(grid, _lake_stage, river_count, debug_color_map.river_color, erode_depth, rng.randi())
#	_civil_stage = CivilStage.new(grid, _lake_stage, slope_penalty, river_penalty)
#	_cliff_stage = CliffStage.new(grid, _lake_stage, debug_color_map.cliff_color, cliff_min_slope)


func perform() -> void:
	var stages = [
		_island_stage,
		_regions_stage,
		_lake_stage,
#		_height_stage,
#		_river_stage,
#		_civil_stage,
#		_cliff_stage,
	]
	
	for stage in stages:
		var time_start = Time.get_ticks_msec()
		stage.perform()
		emit_signal("stage_complete", stage, Time.get_ticks_msec() - time_start)
	
	emit_signal("all_stages_complete")

func get_grid() -> Grid:
	return _grid

#func get_lakes() -> Array:  # -> Array[Region]
#	return _lake_stage.get_regions()
#
#func get_rivers() -> Array:  # -> Array[EdgePath]
#	return _river_stage.get_rivers()
#
#func get_road_paths() -> Array:  # -> Array[TrianglePaths]
#	return _civil_stage.get_road_paths()
#
#func get_road_junctions() -> Array:  # -> Array[Triangle]
#	return _civil_stage.get_junctions()
#
#func get_cliff_surfaces() -> Array:  # -> Array[Array[Triangle]]
#	return _cliff_stage.get_cliff_surfaces()
