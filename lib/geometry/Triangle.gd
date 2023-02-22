class_name Triangle
extends Model
"""Triangle data model and tools"""

var _points: Array[Vertex]
var _index_row: int
var _index_col: int
var _edges: Array[Edge]
var _neighbours: Array[Triangle] = []
var _corner_neighbours: Array[Triangle] = []
#var _parent: Object = null
#var _is_potential_settlement: bool = false
#var _roads: Array = []  # Array[TrianglePath]
#var _junction: bool = false
#var _cliff_edge: Object = null  # Edge | null
#var _cliff_point: Object = null  # Vertex | null
#var _special_debug_edge: Object = null  # Edge | null
#var _special_debug_point: Object = null  # Vertex | null

func _init(points: Array[Vertex], index_col: int = -1, index_row: int = -1) -> void:
	_points = points
	_index_col = index_col
	_index_row = index_row
	_edges = [
		points[0].get_connection_to_point(points[1]) as Edge,
		points[1].get_connection_to_point(points[2]) as Edge,
		points[2].get_connection_to_point(points[0]) as Edge,
	]
	for point in _points:
		point.add_polygon(self)
	for edge in _edges:
		edge.set_border_of(self)

func update_neighbours_from_edges() -> void:
	for edge in _edges:
		for tri in edge.get_bordering_triangles():
			if tri != self:
				_neighbours.append(tri)
	for point in _points:
		for tri in point.get_triangles():
			if not tri in _neighbours and not tri in _corner_neighbours and not tri == self:
				_corner_neighbours.append(tri)

#func get_neighbours_with_parent(parent: Object) -> Array[Triangle]:  # (parent: Region | null)
#	var parented_neighbours: Array[Triangle] = []
#	for neighbour in _neighbours:
#		if neighbour.get_parent() == parent:
#			parented_neighbours.append(neighbour)
#	return parented_neighbours
#
#func count_neighbours_with_parent(parent: Object) -> int:  # (parent: Region | null)
#	return get_neighbours_with_parent(parent).size()
#
#func get_corner_neighbours_with_parent(parent: Object) -> Array[Triangle]:  # (parent: Region | null)
#	var parented_corner_neighbours: Array[Triangle] = []
#	for corner_neighbour in _corner_neighbours:
#		if corner_neighbour.get_parent() == parent:
#			parented_corner_neighbours.append(corner_neighbour)
#	return parented_corner_neighbours
#
#func count_corner_neighbours_with_parent(parent: Object) -> int:  # (parent: Region | null)
#	return get_corner_neighbours_with_parent(parent).size()
#
#func get_neighbour_borders_with_parent(parent: Object) -> Array[Edge]:  # (parent: Region | null)
#	var borders : Array[Edge] = []
#	for edge in _edges:
#		for tri in edge.get_bordering_triangles():
#			if tri != self and tri.get_parent() == parent:
#				borders.append(edge)
#	return borders
#
#func set_parent(parent: Object) -> void:  # (parent: Region | null)
#	_parent = parent

func is_on_grid_boundary() -> bool:
	return len(_neighbours) < len(_edges)

func get_edges_on_grid_boundary() -> Array[Edge]:
	var boundary_edges : Array[Edge] = []
	for edge in _edges:
		if len(edge.get_bordering_triangles()) == 1:
			boundary_edges.append(edge)
	return boundary_edges

func get_color():  # -> Color | null:
#	if _parent:
#		return _parent.get_color()
	return null

func get_vertices() -> Array[Vertex]:
	return _points

func get_river_vertex_colors(debug_color_dict: DebugColorDict) -> Dictionary:  # Dictionary[Vertex, Color]
	"""This is just for creating the development and debug meshes"""
#	var river_color = debug_color_dict.river_color
	var null_color = debug_color_dict.base_color
#	var head_color = debug_color_dict.head_color
#	var mouth_color = debug_color_dict.mouth_color
#	var settlement_color = debug_color_dict.settlement_color
##	var road_cell_color = debug_color_dict.road_cell_color
#	var cliff_color = debug_color_dict.cliff_color
#	var special_debug_color = debug_color_dict.special_debug_color
	var point_color_dict := {}
#
#	if _is_potential_settlement:
#		for point in _points:
#			point_color_dict[point] = settlement_color
#		return point_color_dict
#
#	# if contains_road():
#	# 	for point in _points:
#	# 		point_color_dict[point] = road_cell_color
#	# 	return point_color_dict

	for point in _points:
		point_color_dict[point] = get_color()
		if point_color_dict[point] == null:
			point_color_dict[point] = null_color
#		if point.has_river():
#			point_color_dict[point] = river_color
#		if point.is_head():
#			point_color_dict[point] = head_color
#		if point.is_mouth():
#			point_color_dict[point] = mouth_color
#
#	if _cliff_edge:
#		for point in _cliff_edge.get_points():
#			point_color_dict[point] = cliff_color
#
#	if _cliff_point:
#		point_color_dict[_cliff_point] = cliff_color
#
#	if _special_debug_edge:
#		for point in _special_debug_edge.get_points():
#			point_color_dict[point] = special_debug_color
#
#	if _special_debug_point:
#		point_color_dict[_special_debug_point] = special_debug_color

	return point_color_dict

func get_edges() -> Array[Edge]:
	return _edges

func get_shared_edge(triangle: Triangle) -> Object:  # -> Edge | null
	for edge in _edges:
		if edge.other_triangle(self) == triangle:
			return edge
	return null

#func get_parent() -> Object:  # -> Region | null
#	return _parent

func get_neighbours() -> Array[Triangle]:  # -> Array[Triangle]
	return _neighbours

#func is_surrounded_by_region(region: Object) -> bool:  # (region: Region | null)
#	for point in _points:
#		if not point.has_polygon_with_parent(region):
#			return false
#	return true

func get_center() -> Vector3:
	# Can't remember which center this is, but being equalateral means it doesnt matter much
	return (_points[0].get_vector() + _points[1].get_vector() + _points[2].get_vector()) / 3.0

func get_normal() -> Vector3:
	return (_points[1].get_vector() - _points[0].get_vector()).cross(_points[1].get_vector() - _points[2].get_vector())

func get_height_in_plane(x: float, z: float) -> float:
	var normal: Vector3 = get_normal()
	var position: Vector3 = _points[1].get_vector()
	# nx(x - px) + ny(y - py) + nz(z - pz) = 0
	# ny(y - py) = -(nz(z-pz)+nx(x-px))
	# y - py = -(nz(z-pz)+nx(x-px)) / ny
	# y = py-(nz(z-pz)+nx(x-px))/ny
	return position.y - (normal.z * (z - position.z) + normal.x * (x - position.x)) / normal.y
	
func is_flat() -> bool:
	return (
		_points[0].get_height() == _points[1].get_height() 
		and _points[0].get_height() == _points[2].get_height()
	)

func get_height_diff() -> float:
	var heights = [_points[0].get_height(), _points[1].get_height(), _points[2].get_height()]
	heights.sort()
	return heights[2] - heights[0]

func get_lowest_edge() -> Edge:
	var points = _points.duplicate()
	points.sort_custom(sort_height) # BUG: Should use Vertex.sort_height
	return points[0].get_connection_to_point(points[1])

# Copied from Vertex to get around bug
static func sort_height(a: Vertex, b: Vertex) -> bool:
	return a.get_height() <= b.get_height()

#func set_potential_settlement() -> void:
#	_is_potential_settlement = true
#
#func add_road(road: Object) -> void:  # (road: TrianglePath)
#	_roads.append(road)
#
#func set_junction() -> void:
#	_junction = true
#
#func is_junction() -> bool:
#	return _junction
#
#func contains_road() -> bool:
#	return len(_roads) == 0
#
#func road_crossing() -> bool:
#	return len(_roads) > 1
#
#func get_road() -> Array:  # -> Array[TrianglePath]
#	return _roads
#
#func is_junction_or_settlement() -> bool:
#	return _junction or _is_potential_settlement
#
#func remove_road(road: Object) -> void:  # (road: TrianglePath)
#	_roads.erase(road)

func order_clockwise(edge_1: Edge, edge_2: Edge) -> Array[Edge]:
	"""Assuming the given edges are in this triangle, return them in clockwise order"""
	for i in range(3):
		if _edges[i] == edge_1 and _edges[(i + 1) % 3] == edge_2:
			return [edge_1, edge_2]
		if _edges[i] == edge_2 and _edges[(i + 1) % 3] == edge_1:
			return [edge_2, edge_1]
	printerr("One or more edges not in this triangle")
	return []
	
#func set_cliff_edge(edge: Object) -> void:  # (edge: Edge | null)
#	_cliff_edge = edge
#
#func set_cliff_point(point: Object) -> void:  # (point: Vertex | null)
#	_cliff_point = point

#func touches_river() -> bool:
#	for point in _points:
#		if point.has_river():
#			return true
#	return false

func points_in_draw_order(a: Vertex, b: Vertex) -> bool:
	var a_ind = _points.find(a)
	var b_ind = _points.find(b)
	if a_ind < 0 or b_ind < 0:
		printerr("Testing draw order for points that are not in this triangle")
	return (a_ind + 1) % 3 == b_ind

func replace_existing_edge_with(existing: Edge, replacement: Edge) -> void:
	"""
	This should entirely replace an existing edge (including points) with the new edge.

	The edge points should be in equivalent order within the edge.
	"""
	# Replace the exising points
	var existing_points = existing.get_points()
	var replacement_points = replacement.get_points()
	for j in range(len(_points)):
		for i in range(len(existing_points)):
			if _points[j] == existing_points[i]:
				_points[j] = replacement_points[i]
	
	# Replace the existing edge
	_edges[_edges.find(existing)] = replacement

	# Modify the replacement sub elements to point to this triangle
	existing.remove_border_of(self)
	replacement.set_border_of(self)
	for point in existing_points:
		point.remove_polygon(self)
	for point in replacement_points:
		point.add_polygon(self)

func replace_existing_point_with(existing: Vertex, replacement: Vertex) -> void:
	"""
	This should entirely replace an existing point with the new point.
	"""
	# Replace the exising point
	_points[_points.find(existing)] = replacement
	
	# Modify the replacement sub element to point to this triangle
	existing.remove_polygon(self)
	replacement.add_polygon(self)

#func set_special_debug_point(debug_point: Vertex) -> void:
#	_special_debug_point = debug_point
#
#func set_special_debug_edge(debug_edge: Edge) -> void:
#	_special_debug_edge = debug_edge
