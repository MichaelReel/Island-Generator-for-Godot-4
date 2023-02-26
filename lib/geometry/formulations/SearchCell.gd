class_name SearchCell
extends Object

var _triangle: Triangle
var _cost_to_nearest: float
var _path_to_nearest: SearchCell
var _destination: SearchCell

func _init(triangle: Triangle, cost: float, path: Object = null) -> void:  # (path: SearchCell | null)
	_triangle = triangle
	_cost_to_nearest = cost
	_path_to_nearest = path
	if _path_to_nearest != null:
		_destination = _path_to_nearest.get_destination()

func update_path(cost: float, path: SearchCell) -> void:
	_cost_to_nearest = cost
	_path_to_nearest = path
	if _path_to_nearest != null:
		_destination = _path_to_nearest.get_destination()

func get_triangle() -> Triangle:
	return _triangle

func get_cost() -> float:
	return _cost_to_nearest

func get_path() -> Object:  # -> SearchCell | null
	return _path_to_nearest

func get_destination() -> SearchCell:
	if _path_to_nearest == null:
		return self
	elif _destination != null:
		return _destination
	return _path_to_nearest.get_destination()

