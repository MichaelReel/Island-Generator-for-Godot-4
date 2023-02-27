class_name Region
extends Object
"""A specific area that a grid's cells can belong to"""

var _parent: Object  # Region | null
var _color: Color
var _cells: Array[Triangle] = []
var _perimeter_points: Array[Vertex] = []
var _perimeter_lines: Array[Edge] = []
var _inner_perimeter: Array[Vertex] = []
var _region_front: Array[Triangle]
var _exit_point: Vertex  # Only relevant once the height map sets lake drains
var _perimeter_height: float = 0.0
var _perimeter_outlined: bool = false
var _points_collected: bool = false
var _points: Array[Vertex]

func _init(start_triangle: Triangle, color: Color, parent: Region = null) -> void:
	_parent = parent
	_color = color
	_region_front = [start_triangle]

func add_triangle_as_cell(triangle: Triangle) -> void:
	# Don't add a triangle we already have
	if triangle in _cells:
		return
	
	# Remove the triangle from it's current parent
	if triangle.get_parent() != null:
		triangle.get_parent()._cells.erase(triangle)
	
	# Integrate this cell from the the region edges
	triangle.set_parent(self)
	_cells.append(triangle)
	_region_front.erase(triangle)
	
	# Add neighbours with specific parent to the region frontier
	for neighbour in triangle.get_neighbours_with_parent(_parent):
		if not neighbour in _region_front:
			_region_front.append(neighbour)
	
	# Preload edges on the grid boundary into perimeter_lines
	if triangle.is_on_grid_boundary():
		_perimeter_lines.append_array(triangle.get_edges_on_grid_boundary())

func remove_triangle_as_cell(triangle: Triangle) -> void:
	if not triangle in _cells:
		return
	_cells.erase(triangle)
	if _parent:
		_parent._cells.append(triangle)
	triangle.set_parent(_parent)

func expand_into_parent(rng: RandomNumberGenerator) -> bool:
	"""
	Extend by a cell into the parent medium
	Return true if there is no space left
	"""
	if _region_front.is_empty():
		return true
	ArrayUtils.shuffle(rng, _region_front)
	add_triangle_as_cell(_region_front.back())
	return _region_front.is_empty()

func expand_margins() -> void:
	var border_cells: Array[Triangle] = _find_inner_border_cells()
	
	# Return the border cells to the parent and mark as frontier
	for border_cell in border_cells:
		remove_triangle_as_cell(border_cell)
	
	# Recreate the frontier for this region, subset of removed cells
	var new_region_front: Array[Triangle] = []
	for border_cell in border_cells:
		if border_cell.count_neighbours_with_parent(self) > 0:
			new_region_front.append(border_cell)
	_region_front = new_region_front

func get_some_triangles(rng: RandomNumberGenerator, count: int) -> Array[Triangle]:
	"""Get upto count random cells from this region"""
	var actual_count := int(min(count, len(_cells)))
	var random_cells = _cells.duplicate()
	ArrayUtils.shuffle(rng, random_cells)
	return random_cells.slice(0, actual_count - 1)

func identify_perimeter_points() -> void:
	var region_points : Array[Vertex] = get_points_in_region()
	for point in region_points:
		if point.has_polygon_with_parent(_parent):
			_perimeter_points.append(point)
	
	for outer_point in _perimeter_points:
		for point in outer_point.get_connected_points():
			if (
				not point in _perimeter_points 
				and point in region_points
				and not point in _inner_perimeter
			):
				_inner_perimeter.append(point)

func get_color() -> Color:
	return _color

func get_outer_perimeter_points() -> Array[Vertex]:
	return _perimeter_points

func get_inner_perimeter_points() -> Array[Vertex]:
	return _inner_perimeter

func has_exit_point() -> bool:
	return true if _exit_point else false

func set_exit_point(point: Vertex) -> void:
	_exit_point = point
	point.set_as_exit_point(self)

func get_exit_point() -> Vertex:
	return _exit_point

func get_cell_count() -> int:
	return len(_cells)

func set_water_height(perimeter_height: float) -> void:
	_perimeter_height = perimeter_height

func get_water_height() -> float:
	return _perimeter_height

func is_empty() -> bool:
	return _cells.is_empty()

func get_cells() -> Array[Triangle]:
	return _cells

func get_perimeter_lines(fill_in: bool = true) -> Array[Edge]:
	if _perimeter_outlined:
		return _perimeter_lines
	
	if _cells == null or _cells.is_empty():
		return []
	
	var region_front := _region_front.duplicate()
	
	# using the _region_front, get all the lines joining to parented cells
	while not region_front.is_empty():
		var outer_triangle : Triangle = region_front.pop_back()
		var borders : Array[Edge] = outer_triangle.get_neighbour_borders_with_parent(self)
		_perimeter_lines.append_array(borders)
	
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array[Array] = Region._get_looped_chains_from_lines(_perimeter_lines)  # Array[Array[Edge]]
	
	# Set the _perimeter to the longest chain
	var max_chain: Array[Edge] = chains.back()
	for chain in chains:
		if len(max_chain) < len(chain):
			max_chain = chain
			
	_perimeter_lines = max_chain
	
	# Include threshold triangles that are not on the perimeter path
	if fill_in:
		_add_non_perimeter_boundaries()
	else:
		chains.erase(max_chain)
		_remove_small_portion_boundaries(chains)
	
	_perimeter_outlined = true
	return _perimeter_lines

func get_points_in_region() -> Array[Vertex]:
	"""Get all the points within the region"""
	if not _points_collected:
		_points = []
		for triangle in _cells:
			for point in triangle.get_vertices():
				if not point in _points:
					_points.append(point)
		_points_collected = true
	return _points

func perform_expand_smoothing() -> void:
	"""
	Triangles on the frontier should be incorporated anytime they are
	surrounded on three corners by this region
	"""
	# For each frontier triangle, check if it is "surrounded"
	var still_smoothing: bool = true
	while still_smoothing:
		still_smoothing = false
		for front_cell in _region_front:
			if front_cell.is_surrounded_by_region(self):
				add_triangle_as_cell(front_cell)
				still_smoothing = true

func perform_shrink_smoothing() -> void:
	"""
	Triangles on the inner edges should be released anytime they are
	surrounded by the parent region
	"""
	# Don't remove cells while we interate, remove later
	var cells_for_removal: Array[Triangle] = []
	# Record cells currently in the frontier we will want to re-assess
	var reassess_cells: Array[Triangle] = []
	
	# For each inner edge triangle, check if it is "surrounded" by the parent
	for cell in _cells:
		if cell.is_surrounded_by_region(_parent):
			# record adjoining frontier triangles
			for neighbour in cell.get_neighbours():
				if neighbour in _region_front and not neighbour in reassess_cells:
					reassess_cells.append(neighbour)
			
			# Move this cell back into the frontier, and into the parent region
			cells_for_removal.append(cell)
	
	# Remove the cells we know need to go back to the frontier
	for cell in cells_for_removal:
		remove_triangle_as_cell(cell)
		_region_front.append(cell)
	
	# Check if we need to remove any frontier cells
	for border_cell in reassess_cells:
		if border_cell.count_neighbours_with_parent(self) <= 0:
			_region_front.erase(border_cell)

func _find_inner_border_cells() -> Array[Triangle]:
	"""Find the cells on the edge, but inside the notional perimeter"""
	var border_cells: Array[Triangle] = []
	# Find cells on the boundaries of the region
	for cell in _cells:
		if cell.count_neighbours_with_parent(self) < 3:
			border_cells.append(cell)
		elif cell.count_corner_neighbours_with_parent(self) < 9:
			border_cells.append(cell)
	return border_cells

func _add_non_perimeter_boundaries() -> void:
	"""
	Find triangles on the boundary front that aren't against the perimeter and
	assume they're inside the total shape. Add them and any unparented neighbours
	to the blob.
	"""
	# TODO: Potentially refactor this with add_triangle_as_cell
	var remove_from_front: Array = []
	# Discover all the non perimeter triangles
	for front_triangle in _region_front:
		var has_edge_in_perimeter := false
		for edge in front_triangle.get_edges():
			if edge in _perimeter_lines:
				has_edge_in_perimeter = true
				break
		
		# This frontier triangle does not have an edge on the main perimeter
		# This is basically add_triangle_as_cell but with a delayed erase
		if not has_edge_in_perimeter:
			front_triangle.set_parent(self)
			_cells.append(front_triangle)
			remove_from_front.append(front_triangle)
			# Is there are any triangles adjacent that are null parented, add to end of _region_front
			for neighbour_triangle in front_triangle.get_neighbours():
				if neighbour_triangle.get_parent() == null and not neighbour_triangle in _region_front:
					_region_front.append(neighbour_triangle)
	
	# Remove non-perimeter triangles from the frontier, delayed erase
	for front_triangle in remove_from_front:
		_region_front.erase(front_triangle)

func _remove_small_portion_boundaries(chains: Array[Array]) -> void:  # (chains: Array[Array[Edge]])
	"""
	Remove any triangles and boundaries that arent the main body
	chains are the non-main perimeter outlines
	"""
	if chains.is_empty():
		return
	
	# Filter the frontier cells to keep only those against the max perimeter
	var new_region_front: Array[Triangle] = []
	for front_cell in _region_front:
		var on_new_perimeter = false
		for edge in front_cell.get_edges():
			if edge in _perimeter_lines:
				on_new_perimeter = true
		if on_new_perimeter:
			new_region_front.append(front_cell)
	
	_region_front = new_region_front
	
	# Easier to work with a single array
	var non_perimeter_edges: Array[Edge] = []
	for chain in chains:
		non_perimeter_edges.append_array(chain)
	
	# Create a front of cells to be removed
	var inward_front: Array[Triangle] = []
	for non_perimeter_edge in non_perimeter_edges:
		for tri in non_perimeter_edge.get_bordering_triangles():
			if tri.get_parent() == self and not tri in inward_front:
				inward_front.append(tri)
	
	while not inward_front.is_empty():
		var tri = inward_front.pop_back()
		for neighbour in tri.get_neighbours():
			if neighbour.get_parent() == self and not neighbour in inward_front:
				inward_front.append(neighbour)
		remove_triangle_as_cell(tri)

static func _get_looped_chains_from_lines(perimeter: Array[Edge]) -> Array[Array]:  # -> Array[Array[Edge]]
	"""
	Given an array of unordered Edges on the perimeter of a shape
	Return an array, each element of which is an array of Edges ordered by
	the path around the perimeter. One of the arrays will be the outer shape and the
	rest will be internal "holes" with in the shape of the longest chain.
	"""
	var perimeter_lines := perimeter.duplicate()
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array[Array] = []  # Array[Array[Edge]]
	while not perimeter_lines.is_empty():
		# Setup the next chain, pick the end of a line
		var chain_done = false
		var chain_flipped = false
		var chain: Array[Edge] = []
		var next_chain_line: Edge = perimeter_lines.pop_back()
		var start_chain_point: Vertex = next_chain_line.get_points().front()
		var next_chain_point: Vertex = next_chain_line.other_point(start_chain_point)
		# Follow the lines until we reach back to the beginning
		while not chain_done:
			chain.append(next_chain_line)
			
			# Do we have a complete chain now?
			if len(chain) >= 3 and chain.front().shares_a_point_with(chain.back()):
				chains.append(chain)
				chain_done = true
				continue
			
			# Which directions can we go from here?
			var connections = next_chain_point.get_connections()
			var directions: Array[Edge] = []
			for line in connections:
				# Skip the current line
				if line == next_chain_line:
					continue
				if perimeter_lines.has(line):
					directions.append(line)
			
			# If there's no-where to go, something went wrong
			if len(directions) <= 0:
				printerr("FFS: This line goes nowhere!")
			
			# If there's only one way to go, go that way
			elif len(directions) == 1:
				next_chain_line = directions.front()
				next_chain_point = next_chain_line.other_point(next_chain_point)
				perimeter_lines.erase(next_chain_line)
			
			else:
				# Any links that link back to start of the current chain?
				var loop = false
				for line in directions:
					if line.other_point(next_chain_point) == start_chain_point:
						loop = true
						next_chain_line = line
						next_chain_point = next_chain_line.other_point(next_chain_point)
						perimeter_lines.erase(line)
				
				if not loop:
					# Multiple directions with no obvious loop, 
					# Reverse the chain to extend it in the opposite direction
					if chain_flipped:
						# This chain has already been flipped, both ends are trapped
						# Push this chain back into the pool of lines and try again
						chain.append_array(perimeter_lines)
						perimeter_lines = chain
						chain_done = true
						continue
					
					chain.reverse()
					var old_start_point : Vertex = start_chain_point
					start_chain_point = next_chain_point
					next_chain_line = chain.pop_back()
					next_chain_point = old_start_point
					chain_flipped = true
	
	return chains
