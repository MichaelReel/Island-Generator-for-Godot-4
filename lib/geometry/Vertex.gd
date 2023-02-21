class_name Vertex
extends Model
"""
Vertex data model and tools
"""

var _pos: Vector3
var _height_set: bool = false

func _init(x: float = 0.0, z: float = 0.0) -> void:
	_pos = Vector3(x, 0.0, z)

func get_vector() -> Vector3:
	return _pos

func get_vector_at_height(height: float) -> Vector3:
	return Vector3(_pos.x, height, _pos.z)

func height_set() -> bool:
	return _height_set

func set_height(height: float) -> void:
	_height_set = true
	_pos.y = height

func get_height() -> float:
	return _pos.y

func raise_terrain(add_height: float) -> void:
	_pos.y += add_height

static func sort_vert_inv_hortz(a: Vertex, b: Vertex) -> bool:
	"""This will sort by Y desc, then X asc"""
	if a._pos.y > b._pos.y:
		return true
	elif a._pos.y == b._pos.y and a._pos.x < b._pos.x:
			return true
	return false

static func sort_height(a: Vertex, b: Vertex) -> bool:
	return a.get_height() <= b.get_height()
