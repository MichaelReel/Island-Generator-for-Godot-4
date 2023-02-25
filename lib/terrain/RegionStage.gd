class_name RegionStage
extends Stage
"""Stage for sub-dividing island surface area into roughly even sections"""

var _parent: Region
var _colors: PackedColorArray
var _regions: Array[Region] = []
var _rng := RandomNumberGenerator.new()

func _init(parent: Region, colors: PackedColorArray, rng_seed: int):
	_parent = parent
	_colors = colors
	_rng.seed = rng_seed

func _to_string() -> String:
	return "Region Stage"

func perform() -> void:
	_setup_regions()
	
	var expansion_done := false
	while not expansion_done:
		var done = true
		for region in _regions:
			if not region.expand_into_parent(_rng):
				done = false
		if done:
			expansion_done = true
	
	_expand_margins()
	
	for region in _regions:
		var _lines: Array[Edge] = region.get_perimeter_lines(false)

func _expand_margins() -> void:
	for region in _regions:
		region.expand_margins()

func _setup_regions() -> void:
	var start_triangles = _parent.get_some_triangles(_rng, len(_colors))
	for i in range(len(start_triangles)):
		_regions.append(Region.new(start_triangles[i], _colors[i], _parent))

func get_regions() -> Array[Region]:
	return _regions
