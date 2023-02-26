class_name CivilStage
extends Stage

var _grid: Grid
var _lake_stage: LakeStage
var _slope_penalty: float
var _river_penalty: float
var _settlement_cells: Array[Triangle] = []
var _road_paths: Array[TrianglePath] = []
var _junctions: Array[Triangle] = []
var _triangle_searchcell_map: Dictionary = {}  # Dictionary[Triangle, SearchCell]
var _best_settlement_pair_cost: Dictionary = {}  # Dictionary[String, Dictionary{cell_a, cell_b, cost}]

const _NORMAL_COST: float = 1.0

func _init(grid: Grid, lake_stage: LakeStage, slope_penalty: float, river_penalty: float):
	_grid = grid
	_lake_stage = lake_stage
	_slope_penalty = slope_penalty
	_river_penalty = river_penalty

func _to_string() -> String:
	return "Civil Stage"

func perform() -> void:
	_locate_settlements()
	_path_from_every_settlement()

func get_road_paths() -> Array[TrianglePath]:
	return _road_paths

func get_junctions() -> Array[Triangle]:
	return _junctions

func _locate_settlements() -> void:
	for row in _grid.get_triangles():
		for triangle in row:
			if not triangle.is_flat():
				continue
			if _lake_stage.triangle_in_water_body(triangle):
				continue
			if not _lake_stage.triangle_beside_water_body(triangle):
				continue
			
			triangle.set_potential_settlement()
			_settlement_cells.append(triangle)

func _create_search_cell_for_triangle(triangle: Triangle, cost: float, path: Object = null) -> SearchCell:
	var search_cell = SearchCell.new(triangle, cost, path)
	_triangle_searchcell_map[triangle.get_instance_id()] = search_cell
	return search_cell

func _get_search_cell_for_triangle(triangle: Triangle) -> Object:  # -> SearchCell | null
	var key = triangle.get_instance_id()
	if key in _triangle_searchcell_map.keys():
		return _triangle_searchcell_map[key]
	return null

func _get_all_search_cells() -> Array:
	return _triangle_searchcell_map.values()

func _get_all_neighbour_search_cells(search_cell: SearchCell) -> Array[SearchCell]:
	var neighbour_search_cells: Array[SearchCell] = []
	for neighbour_triangle in search_cell.get_triangle().get_neighbours():
		var neighbour_search_cell: SearchCell = _get_search_cell_for_triangle(neighbour_triangle)
		if neighbour_search_cell != null:
			neighbour_search_cells.append(neighbour_search_cell)
	return neighbour_search_cells

func _get_cell_path_key(search_cell_a: SearchCell, search_cell_b: SearchCell) -> String:
	"""Get a key unique to the destination paths of the search cells, order should be unimportant"""
	var part_a: int = search_cell_a.get_destination().get_triangle().get_instance_id()
	var part_b: int = search_cell_b.get_destination().get_triangle().get_instance_id()
	return "%d:%d" % ([part_a, part_b] if part_a < part_b else [part_b, part_a])

func _update_smallest_path_cost_table(search_cell_a: SearchCell, search_cell_b: SearchCell) -> void:
	var key = _get_cell_path_key(search_cell_a, search_cell_b)
	var total_cost = search_cell_a.get_cost() + search_cell_b.get_cost()
	var details: Dictionary = {"cell_a": search_cell_a, "cell_b": search_cell_b, "cost": total_cost}
	if not key in _best_settlement_pair_cost.keys():
		_best_settlement_pair_cost[key] = details
		return
	var current_cost: float = _best_settlement_pair_cost[key]["cost"]
	if total_cost < current_cost:
		_best_settlement_pair_cost[key] = details

func _path_from_every_settlement() -> void:
	var search_front: Array[SearchCell] = []
	# Start by setting a search cell in each settlement with a zero score
	# No need to order yet, as all have the same cost
	for settlement in _settlement_cells:
		var search_cell: SearchCell = _create_search_cell_for_triangle(settlement, 0.0)
		search_front.append(search_cell)
	
	while not search_front.is_empty():
		var search_cell = search_front.pop_front()
		
		# Get neighbour cells to valid path
		for neighbour_tri in search_cell.get_triangle().get_neighbours():
			if _lake_stage.triangle_in_water_body(neighbour_tri):
				continue

			# Up the cost for each new step
			var journey_cost: float = search_cell.get_cost()
			journey_cost += _NORMAL_COST

			# Up the cost if crossing a river
			var shared_edge = search_cell.get_triangle().get_shared_edge(neighbour_tri)
			if shared_edge.has_river():
				journey_cost += _river_penalty

			# Up the cost a little if going up/down a slope
			journey_cost += abs(
				neighbour_tri.get_center().y - search_cell.get_triangle().get_center().y
			) * _slope_penalty

			# Check if there's an exising cell
			var neighbour_search_cell = _get_search_cell_for_triangle(neighbour_tri)
			if neighbour_search_cell != null:
				# update it if cost is cheaper, and re-insert to propagate
				if neighbour_search_cell.get_cost() > journey_cost:
					neighbour_search_cell.update_path(journey_cost, search_cell)
					var ind = search_front.bsearch_custom(neighbour_search_cell, _sort_by_cost)
					search_front.insert(ind, neighbour_search_cell)
				continue

			# Insert a new search cell into the queue, sorted by journey cost
			neighbour_search_cell = _create_search_cell_for_triangle(neighbour_tri, journey_cost, search_cell)
			var ind = search_front.bsearch_custom(neighbour_search_cell, _sort_by_cost)
			search_front.insert(ind, neighbour_search_cell)

	# Off all the search cells, find all the best search cell pairs that link any 2 settlements
	for search_cell in _get_all_search_cells():
		for neighbour_search_cell in _get_all_neighbour_search_cells(search_cell):
			# For now, lets skip cells pairs in settlements
			if search_cell.get_cost() == 0.0 or neighbour_search_cell.get_cost() == 0.0:
				continue
			# Skip pairs of cells that point to the same destination
			if search_cell.get_destination() == neighbour_search_cell.get_destination():
				continue
			# Submit this cell pair for evaluation
			_update_smallest_path_cost_table(search_cell, neighbour_search_cell)
	
	# Create the paths from all the best settlement meetings we cound find
	for path_details in _best_settlement_pair_cost.values():
		var search_cell_a: SearchCell = path_details["cell_a"]
		var search_cell_b: SearchCell = path_details["cell_b"]
		var road_path: TrianglePath = TrianglePath.new()
		_junctions.append(search_cell_a.get_triangle())
		
		# Work back to cell_a as origin
		var to_origin = search_cell_a
		while to_origin != to_origin.get_destination():
			road_path.extend_to_origin(to_origin.get_triangle())
			to_origin = to_origin.get_path()
		road_path.set_origin(to_origin.get_triangle())
		
		# Work forward to cell_b as path destination
		var to_destination = search_cell_b
		while to_destination != to_destination.get_destination():
			road_path.extend_to_destination(to_destination.get_triangle())
			to_destination = to_destination.get_path()
		road_path.set_destination(to_destination.get_triangle())
		
		_road_paths.append(road_path)
		

static func _sort_by_cost(a: SearchCell, b: SearchCell) -> bool:
	return a.get_cost() < b.get_cost()
