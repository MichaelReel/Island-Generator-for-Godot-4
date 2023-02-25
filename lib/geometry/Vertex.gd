class_name Vertex
extends Model
"""
Vertex data model and tools
"""

var _pos: Vector3
var _connections: Array[Edge] = []
var _triangles: Array[Triangle] = []
var _height_set: bool = false

func _init(x: float = 0.0, z: float = 0.0) -> void:
	_pos = Vector3(x, 0.0, z)

func get_connection_to_point(point: Vertex) -> Object:  # --> Edge | null
	for con in _connections:
		if con.other_point(self) == point:
			return con
	return null

func has_connection_to_point(point: Vertex) -> bool:
	return get_connection_to_point(point) != null

func height_set() -> bool:
	return _height_set

func set_height(height: float) -> void:
	_height_set = true
	_pos.y = height

func raise_terrain(add_height: float) -> void:
	_pos.y += add_height

func get_height() -> float:
	return _pos.y

func add_connection(edge: Edge) -> void:
	if not edge in _connections:
		_connections.append(edge)

func add_polygon(triangle: Triangle) -> void:
	if not triangle in _triangles:
		_triangles.append(triangle)

func remove_polygon(triangle: Triangle) -> void:
	if triangle in _triangles:
		_triangles.erase(triangle)

func get_vector() -> Vector3:
	return _pos

func get_vector_at_height(height: float) -> Vector3:
	return Vector3(_pos.x, height, _pos.z)

func get_connections() -> Array[Edge]:
	return _connections

func get_connected_points() -> Array[Vertex]:
	"""Returns a new array each time of the connected points"""
	var connected_points: Array[Vertex] = []
	for con in _connections:
		connected_points.append(con.other_point(self))
	return connected_points

func get_triangles() -> Array[Triangle]:
	return _triangles

func duplicate_to(new_vertex: Vertex) -> Vertex:
	"""Create a copy of this vertex for splitting parts of the terrain"""
	new_vertex._pos = _pos
	new_vertex._connections = _connections.duplicate()
	new_vertex._triangles = _triangles.duplicate()
	new_vertex._height_set = _height_set
	return new_vertex

static func sort_vert_inv_hortz(a: Vertex, b: Vertex) -> bool:
	"""This will sort by Y desc, then X asc"""
	if a._pos.y > b._pos.y:
		return true
	elif a._pos.y == b._pos.y and a._pos.x < b._pos.x:
			return true
	return false

static func sort_height(a: Vertex, b: Vertex) -> bool:
	return a.get_height() <= b.get_height()

# ~~~~~~~~~~~~~~~
# Region Data:
# ~~~~~~~~~~~~~~~

func has_polygon_with_parent(parent: Object) -> bool:  # (parent: Region | null)
	for triangle in _triangles:
		if triangle.get_parent() == parent:
			return true
	return false

# ~~~~~~~~~~~~~~~
# Lake Data:
# ~~~~~~~~~~~~~~~

var _exit_for: Object = null  # Region | null

func set_as_exit_point(lake: Object) -> void:  # (lake: Region | null)
	_exit_for = lake

func is_exit() -> bool:
	return true if _exit_for else false

func get_exit_for() -> Object:  # Region | null
	return _exit_for

# ~~~~~~~~~~~~~~~

#var _river: Object  # EdgePath | null
#var _is_head: bool = false
#var _is_mouth: bool = false
#var _eroded_depth: float = 0.0

#func get_uneroded_vector() -> Vector3:
#	return get_vector_at_height(_pos.y + _eroded_depth)
#
#func set_river(river: Object) -> void:  # (river: EdgePath | null)
#	_river = river
#
#func has_river() -> bool:
#	return true if _river else false
#

#
#func set_as_head() -> void:
#	_is_head = true
#
#func is_head() -> bool:
#	return _is_head
#
#func set_as_mouth() -> void:
#	_is_mouth = true
#
#func is_mouth() -> bool:
#	return _is_mouth
#
#func erode(erode_depth: float) -> void:
#	_eroded_depth += erode_depth
#	_pos.y -= erode_depth
#
#func get_erosion() -> float:
#	return _eroded_depth
