class_name HeightStage
extends Stage

var _island: Region
var _lake_stage: LakeStage
var _diff_height: float
var _diff_height_max_multiplier: int
var _sealevel_points: Array[Vertex] = []
var _downhill_front: Array[Vertex] = []
var _downhill_height: float
var _uphill_front: Array[Vertex] = []
var _uphill_height: float
var _sealevel_started: bool = false
var _height_fronts_started: bool = false
var _downhill_complete: bool = false
var _uphill_complete: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(island: Region, lake_stage: LakeStage, diff_height: float, diff_max_multi: int, rng_seed: int) -> void:
	_island = island
	_lake_stage = lake_stage
	_diff_height = diff_height
	_diff_height_max_multiplier = diff_max_multi
	_downhill_height = -_diff_height
	_uphill_height = _diff_height
	_rng.seed = rng_seed
	
func _to_string() -> String:
	return "Height Stage"

func perform() -> void:
	while not _uphill_complete:
		if not _sealevel_started:
			_setup_sealevel()
			_sealevel_started = true
			continue
		
		if not _height_fronts_started:
			_setup_height_fronts()
			_height_fronts_started = true
			continue
		
		if not _downhill_complete:
			_step_downhill()
			if _downhill_front.is_empty():
				_downhill_complete = true
			continue
		
		if not _uphill_complete:
			_step_uphill()
			if _uphill_front.is_empty():
				_uphill_complete = true
			continue

func _setup_sealevel() -> void:
	_sealevel_points = []
	for line in _island.get_perimeter_lines():
		for point in line.get_points():
			if not point in _sealevel_points:
				point.set_height(0.0)
				_sealevel_points.append(point)

func _setup_height_fronts() -> void:
	for center_point in _sealevel_points:
		for point in center_point.get_connected_points():
			if not point.height_set():
				# Uphill or downhill neighbour?
				if point.has_polygon_with_parent(_island):
					point.set_height(_uphill_height)
					_uphill_front.append(point)
				else:
					point.set_height(_downhill_height)
					_downhill_front.append(point)

func _step_downhill() -> void:
	_downhill_height -= _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
	var new_downhill_front: Array[Vertex] = []
	for center_point in _downhill_front:
		for point in center_point.get_connected_points():
			if not point.height_set():
				point.set_height(_downhill_height)
				new_downhill_front.append(point)
	_downhill_front = new_downhill_front

func _step_uphill() -> void:
	_uphill_height += _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
	var new_uphill_front: Array[Vertex] = []
	for center_point in _uphill_front:
		for point in center_point.get_connected_points():
			if not point.height_set():
				new_uphill_front.append(point)
				# If this point is on a sub-region lake,
				var lake : Region = _lake_stage.lake_for_point(point)
				if lake and not lake.has_exit_point():
					# Assume water can exit on this side, and lake is at this height
					lake.set_exit_point(point)
					lake.set_water_height(_uphill_height)
					# Add the lake perimeter points to the uphill
					new_uphill_front.append_array(lake.get_outer_perimeter_points())
					# Add any inside points to the downhill
					var inside_points : Array[Vertex] = lake.get_inner_perimeter_points()
					if not inside_points.is_empty():
						# Reset the downhill state, and set the downhill height
						_downhill_height = _uphill_height - _diff_height * (_rng.randi() % _diff_height_max_multiplier + 1) 
						_downhill_front.append_array(inside_points)
						_downhill_complete = false

	for point in new_uphill_front:
		point.set_height(_uphill_height)
	_uphill_front = new_uphill_front

	# If a lake edge encountered, setup the downhill to form the bowl
	if not _downhill_front.is_empty():
		for point in _downhill_front:
			point.set_height(_downhill_height)
