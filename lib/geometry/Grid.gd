class_name Grid
extends Model
"""Grid data model and tools"""

var _color: Color
var _tri_side: float
var _tri_height: float
var _mesh_center: Vector2
var _grid_points: Array[Array] = []  # Array[Array[Vertex]]
var _grid_lines: Array[Edge] = []
var _grid_tris: Array[Array] = []  # Array[Array[Triangle]]
var _cell_count: int = 0
var _debug_content: String = ""

func _init(edge_size: float, row_points: int, color: Color) -> void:
	_tri_side = edge_size
	_color = color
	_tri_height = sqrt(0.75) * _tri_side
	# Find the number of rows to keep the mesh roughly square
	var row_width: float = (row_points + 0.5) * _tri_side
	var row_count: int = int(row_width / _tri_height)
	var half_full_width: float = edge_size * row_points / 2.0
	_mesh_center = Vector2(half_full_width, half_full_width)
	
	# Lay out points
	for row_ind in range(row_count):
		var point_row: Array = []
		var offset: float = (row_ind % 2) * (_tri_side / 2.0)
		var z: float = _tri_height * row_ind
		for col_ind in range(row_points):
			var x: float = offset + (_tri_side * col_ind)
			var new_point = Vertex.new(x - _mesh_center.x, z - _mesh_center.y)
			point_row.append(new_point)
		_grid_points.append(point_row)
	
	# Layout and record edges between points
	for row_ind in range(row_count):
		var parity: int = (row_ind % 2) * 2 - 1  # +1 on odd, -1 on even
		for col_ind in range(row_points):
			var point = _grid_points[row_ind][col_ind]
			if col_ind > 0:
				_add_grid_line(point, _grid_points[row_ind][col_ind - 1])
			if row_ind > 0 and col_ind < len(_grid_points[row_ind - 1]):
				_add_grid_line(point, _grid_points[row_ind - 1][col_ind])
			if row_ind > 0 and col_ind + parity >= 0 and col_ind + parity < len(_grid_points[row_ind - 1]):
				_add_grid_line(point, _grid_points[row_ind - 1][col_ind + parity])
	
	# Go through the points and create triangles
	for tri_row_ind in range(row_count - 1):
		var tri_row: Array = []
		for tri_col_ind in range((row_points - 1) * 2):
			var new_triangle: Triangle = _create_triangle(tri_row_ind, tri_col_ind)
			tri_row.append(new_triangle)
		_grid_tris.append(tri_row)
	
	# Catalogue the neighbours to each triangle
	for tri_row in _grid_tris:
		for tri in tri_row:
			tri.update_neighbours_from_edges()
		
	_update_debug_content()

func get_point_rows() -> Array:  # Array[Array[Vertex]]
	"""Returns the array of rows of points"""
	return _grid_points

func get_cell_count() -> int:
	return _cell_count

func get_island_points() -> Array:  # Array[Vertex]
	var point_list: Array = []
	for row in _grid_points:
		for point in row:
			if _point_is_not_sea(point):
				point_list.append(point)
	return point_list

func get_triangles() -> Array:  # Array[Array[Triangles]]
	"""Returns array of arrays of triangles in a grid layout"""
	return _grid_tris

func get_middle_triangle() -> Triangle:
	"""Get a middle(ish) triangle"""
	var mid_row = _grid_tris[_grid_tris.size() / 2]
	return mid_row[mid_row.size() / 2]

func get_color() -> Color:
	return _color

func get_height_at_xz(x: float, z: float) -> float:
	# Find triangle we're in
	var triangle = get_triangle_at(x, z)
	if triangle:
		return triangle.get_height_in_plane(x, z)

	return 0.0

func get_triangle_at(x: float, z: float) -> Object:  # -> Triangle | null
	"""Try to locate the triangle where the (x, z) point lies"""
	var internal_pos = Vector2(x, z) + _mesh_center
	var row := int(floor(internal_pos.y / _tri_height))
	if row > 0 and row < len(_grid_tris):
		var even_row: bool = row % 2 == 0
		# col is trickier than row as it relies on both x and z
		var col := int(floor(internal_pos.x / (_tri_side * 0.5)))
		var even_raw_col: bool = col % 2 == 0
		# Get internal positions in row and raw_col
		var y_in_row: float = internal_pos.y - (row * _tri_height)
		var x_in_raw_col: float = internal_pos.x - (col * 0.5 * _tri_side)
		# Get scaled position of point in the row and raw_col
		var scaled_y: float = y_in_row / _tri_height
		var scaled_x: float = x_in_raw_col / (0.5 * _tri_side)
		if even_row == even_raw_col:
			# If both odd, or both even  |\|
			# -1 to row_col if the position is below the diagonal line
			# If internal x pos ratio is less than the internal y pos ratio
			# The point is below the line
			if scaled_y > scaled_x:
				col -= 1
		else:
			# If odd/even or even/odd  |/|
			# -1 to row_col if position is above the diagonal line
			# If 1.0 - internal x pos ration is less that the internal y pos ratio
			# The point is below the line
			if scaled_y < (1.0 - scaled_x):
				col -= 1
		if col > 0 and col < len(_grid_tris[row]):
			return _grid_tris[row][col]
	
	return null

func _add_grid_line(a: Vertex, b: Vertex) -> void:
	var new_line := Edge.new(a, b)
	_grid_lines.append(new_line)

func _create_triangle(row: int, col: int) -> Triangle:
	var row_even: bool = row % 2 == 0
	var column_even: bool = col % 2 == 0
	var points: Array[Vertex] = []
	if row_even:
		if column_even:
			points.append(_grid_points[row  ][col/2])
			points.append(_grid_points[row  ][(col/2)+1])
			points.append(_grid_points[row+1][col/2])
		else:  # (col_odd)
			points.append(_grid_points[row  ][(col/2)+1])
			points.append(_grid_points[row+1][(col/2)+1])
			points.append(_grid_points[row+1][col/2])
	else:  # (row_odd)
		if column_even:
			points.append(_grid_points[row  ][col/2])
			points.append(_grid_points[row+1][(col/2)+1])
			points.append(_grid_points[row+1][col/2])
		else:  # (col_odd)
			points.append(_grid_points[row  ][col/2])
			points.append(_grid_points[row  ][(col/2)+1])
			points.append(_grid_points[row+1][(col/2)+1])
	return Triangle.new(points, row, col)

func _point_is_not_sea(point: Vertex) -> bool:
	return not point.has_polygon_with_parent(null)

func _update_debug_content() -> void:
	# Just list the last few rows
	_debug_content = ""
	for row in range(len(_grid_tris)-4, len(_grid_tris)):
		for col in range(len(_grid_tris[row])-6, len(_grid_tris[row])):
			_debug_content += str(_grid_tris[row][col]) + "\n"
		_debug_content += "\n"
