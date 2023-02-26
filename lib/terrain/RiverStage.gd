class_name RiverStage
extends Stage

var _rivers: Array[EdgePath]
var _grid: Grid
var _lake_stage: LakeStage
var _river_count: int
var _erode_depth: float
var _rng := RandomNumberGenerator.new()

func _init(
	grid: Grid, lake_stage: LakeStage, river_count: int, erode_depth: float, rng_seed: int
) -> void:
	_grid = grid
	_lake_stage = lake_stage
	_river_count = river_count
	_erode_depth = erode_depth
	_rng.seed = rng_seed

func _to_string() -> String:
	return "River Stage"

func perform() -> void:
	_setup_rivers()

func get_rivers() -> Array[EdgePath]:
	return _rivers

func _setup_rivers():
	_rivers = []
	
	# For each outlet, get the lowest downhill point not _inside_ the lake
	for lake in _lake_stage.get_regions():
		var outlet_point: Vertex = lake.get_exit_point()
		if not outlet_point:
			printerr("Lake didn't have an exit point, probably empty ¯\\_(ツ)_/¯")
			continue
		
		var river: EdgePath = create_river(outlet_point)
		_rivers.append(river)
	
	# Include some random points that are not in a lake or river already
	var island_points: Array[Vertex] = _grid.get_island_points()
	island_points = _lake_stage.filter_points_no_lake(island_points)
	ArrayUtils.shuffle(_rng, island_points)
	
	if len(island_points) > _river_count:
		island_points.resize(_river_count)
	
	for island_point in island_points:
		var river: EdgePath = create_river(island_point)
		# Filter out any silly short rivers
		if river.edge_length() > 1:
			_rivers.append(river)
	
	for river in _rivers:
		river.erode(_erode_depth)

func create_river(start_point: Vertex) -> EdgePath:
	"""Create a chain of edges that represent a river"""
	start_point.set_as_head()
	var river: EdgePath = EdgePath.new(start_point, _lake_stage)
	
	var neighbour_points: Array[Vertex] = start_point.get_connected_points()
	neighbour_points.sort_custom(sort_height)  # BUG: Cannot find member "sort_height" in base "Vertex".
	var connection_point = neighbour_points.pop_front()
	
	# The exit shouldn't be inside the lake, assuming anyway
	if start_point.is_exit():
		while connection_point.has_polygon_with_parent(start_point.get_exit_for()):
			connection_point = neighbour_points.pop_front()
	
	# Get the downhill end, then extend until we hit the coast or a lake
	var next_edge: Edge = start_point.get_connection_to_point(connection_point)
	while (
		not _lake_stage.point_in_water_body(connection_point)
		and not next_edge.has_river()
	):
		river.extend_by_edge(next_edge)
		# Find the next lowest connected point
		neighbour_points = connection_point.get_connected_points()
		neighbour_points.sort_custom(sort_height)  # BUG: Cannot find member "sort_height" in base "Vertex".
		var lowest_neighbour = neighbour_points.front()
		next_edge = connection_point.get_connection_to_point(lowest_neighbour)
		connection_point = lowest_neighbour
	
	# Add the last step, unless it's already a river
	if not next_edge.has_river():
		river.extend_by_edge(next_edge)
		connection_point.set_as_mouth()
	
	return river

# Copied from Vertex to get around bug, for now or until I figure the "real" issue
static func sort_height(a: Vertex, b: Vertex) -> bool:
	return a.get_height() <= b.get_height()
