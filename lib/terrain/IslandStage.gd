class_name IslandStage
extends Stage
"""Stage for creating the initial island surface area"""

var _grid: Grid
var _island_region: Region
var _cell_limit: int
var _rng := RandomNumberGenerator.new()

func _init(grid: Grid, land_color: Color, cell_limit: int, rng_seed: int):
	_grid = grid
	var start_triangle = grid.get_middle_triangle()
	_island_region = Region.new(start_triangle, land_color)
	_cell_limit = cell_limit
	_rng.seed = rng_seed

func _to_string() -> String:
	return "Island Stage"

func perform() -> void:
	var expansion_done := false
	while not expansion_done:
		var _done = _island_region.expand_into_parent(_rng)
		if _island_region.get_cell_count() >= _cell_limit:
			expansion_done = true
	
	_island_region.perform_expand_smoothing()
	
	var _lines := _island_region.get_perimeter_lines()

func get_region() -> Region:
	return _island_region
