class_name LakeStage
extends Stage

var _region_stage: RegionStage
var _colors: PackedColorArray
var _regions: Array[Region] = []
var _rng := RandomNumberGenerator.new()


func _init(region_stage: RegionStage, colors: PackedColorArray, rng_seed: int):
	_region_stage = region_stage
	_colors = colors
	_rng.seed = rng_seed

func _to_string() -> String:
	return "Lake Stage"

func perform() -> void:
	_setup_regions()
	
	# Fill up the parent region with lakes
	var expansion_done := false
	while not expansion_done:
		var done = true
		for region in _regions:
			if not region.expand_into_parent(_rng):
				done = false
		if done:
			expansion_done = true
		continue
	
	# Shrink the surface area of each lake a little bit
	_expand_margins()
	
	# Tidy up the lake edges and get the main perimeter
	for region in _regions:
		region.perform_shrink_smoothing()
		var _lines: Array[Edge] = region.get_perimeter_lines(false)
	
	# Get the inner and outer perimeters
	_identify_perimeter_points()
	
	# Remove any "point-less" lakes
	var empty_lakes: Array[Region] = []
	for region in _regions:
		if region.is_empty():
			empty_lakes.append(region)
	for region in empty_lakes:
		_regions.erase(region)

func lake_for_point(point: Vertex) -> Object:  # -> Region | null
	for region in _regions:
		if point.has_polygon_with_parent(region):
			return region
	return null

func get_regions() -> Array[Region]:
	return _regions

func point_in_water_body(point: Vertex) -> bool:
	if _point_has_lake(point) or point.has_polygon_with_parent(null):
		return true
	return false

func triangle_in_water_body(triangle: Triangle) -> bool:
	"""The triangle has null (sea) or lake as a parent"""
	var parent = triangle.get_parent()
	return parent == null or parent in _regions

func triangle_beside_water_body(triangle: Triangle) -> bool:
	return _points_in_water_bodies(triangle) >= 2

func filter_points_no_lake(points: Array[Vertex]) -> Array[Vertex]:
	var filtered_points: Array[Vertex] = []
	for point in points:
		if not _point_has_lake(point):
			filtered_points.append(point)
	return filtered_points

func _points_in_water_bodies(triangle: Triangle) -> int:
	var water_points = 0
	for vertex in triangle.get_vertices():
		if point_in_water_body(vertex):
			water_points += 1
	return water_points

func _expand_margins() -> void:
	for region in _regions:
		region.expand_margins()

func _setup_regions() -> void:
	for parent_region in _region_stage.get_regions():
		# The parent region might not be big enough to have subregions
		var start_triangles = parent_region.get_some_triangles(_rng, len(_colors))
		for i in range(len(start_triangles)):
			_regions.append(Region.new(start_triangles[i], _colors[i], parent_region))

func _point_has_lake(point: Vertex) -> bool:
	return true if lake_for_point(point) else false

func _identify_perimeter_points() -> void:
	for region in _regions:
		region.identify_perimeter_points()
