class_name MeshUtils
extends Object

static func get_land_mesh(high_level_terrain: HighLevelTerrain, debug_color_dict: DebugColorDict) -> Mesh:
	var grid = high_level_terrain.get_grid()
	var surface_tool: SurfaceTool = SurfaceTool.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			var color_dict: Dictionary = triangle.get_debug_vertex_colors(debug_color_dict)
			for vertex in triangle.get_vertices():
				var position: Vector3 = vertex.get_vector()
				var color: Color = color_dict[vertex]
				surface_tool.set_color(color_dict[vertex])
				surface_tool.add_vertex(vertex.get_vector())
	surface_tool.generate_normals()
	return surface_tool.commit()

static func get_water_body_meshes(high_level_terrain: HighLevelTerrain) -> Array[Mesh]:
	var meshes: Array[Mesh] = []
	for lake in high_level_terrain.get_lakes():
		meshes.append(_get_water_body_mesh(lake))
	meshes.append(_get_sea_level_mesh(high_level_terrain.get_grid()))
	return meshes

#static func get_river_surface_meshes(high_level_terrain: HighLevelTerrain) -> Array:  # -> Array[Mesh]
#	var meshes: Array = []
#	for river in high_level_terrain.get_rivers():
#		meshes.append(_get_river_surface_mesh(river, high_level_terrain._lake_stage))
#	return meshes
#
#static func get_all_road_surface_meshes(
#	high_level_terrain: HighLevelTerrain,
#	debug_color_dict: DebugColorDict,
#	width: float = 0.25,
#	clearance: float = 0.1
#) -> Array:  # -> Array[Mesh]
#	var meshes: Array = []
#	for road_path in high_level_terrain.get_road_paths():
#		if road_path.no_path():
#			continue
#		meshes.append(_get_road_surface_mesh_for_path(road_path, debug_color_dict, width, clearance))
#	return meshes
#
#static func get_road_sign_debug_meshes(
#	high_level_terrain: HighLevelTerrain, debug_color_dict: DebugColorDict
#) -> Array:  # -> Array[Mesh]
#	var meshes: Array = []
#	for junction in high_level_terrain.get_road_junctions():
#		meshes.append(_draw_marker_on_triangle(junction, debug_color_dict.junction_marker_color, 3.0))
#	return meshes
#
#static func get_cliff_surface_meshes(
#	high_level_terrain: HighLevelTerrain, debug_color_dict: DebugColorDict
#) -> Array:  # -> Array[Mesh]
#	var meshes: Array = []
#	for cliff_surface in high_level_terrain.get_cliff_surfaces():
#		meshes.append(_get_cliff_surface_mesh(cliff_surface, debug_color_dict.cliff_color))
#	return meshes

static func _get_water_body_mesh(lake: Region) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var lake_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in lake.get_cells():
		for vertex in triangle.get_vertices():
			surface_tool.add_vertex(vertex.get_vector_at_height(lake.get_water_height()))
	
	surface_tool.generate_normals()
	return surface_tool.commit()

static func _get_sea_level_mesh(grid: Grid) -> Mesh:
	var surface_tool: SurfaceTool = SurfaceTool.new()
	var sea_mesh: Mesh = Mesh.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in grid.get_triangles():
		for triangle in row:
			if triangle.get_parent() != null:
				continue
	
			for vertex in triangle.get_vertices():
				surface_tool.add_vertex(vertex.get_vector_at_height(0.0))
	
	surface_tool.generate_normals()
	return surface_tool.commit()

#static func _get_river_surface_mesh(river: EdgePath, lake_stage: LakeStage) -> Mesh:
#	var ratio = 0.75
#	var surface_tool: SurfaceTool = SurfaceTool.new()
#	var river_mesh: Mesh = Mesh.new()
#	var drop_depth = Vector3.DOWN * river.get_eroded_depth() * ratio
#
#	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#
#	for triangle in river.get_adjacent_triangles():
#		for vertex in triangle.get_vertices():
#			if lake_stage.point_in_water_body(vertex):
#				surface_tool.add_vertex(vertex.get_uneroded_vector())
#			else:
#				surface_tool.add_vertex(vertex.get_uneroded_vector() + drop_depth)
#
#	surface_tool.generate_normals()
#	var _err = surface_tool.commit(river_mesh)
#
#	return river_mesh
#
#static func _get_road_surface_mesh_for_path(road_path: TrianglePath, debug_color_dict: DebugColorDict, width: float, clearance: float) -> Mesh:
#	var surface_tool: SurfaceTool = SurfaceTool.new()
#	var road_mesh: Mesh = Mesh.new()
#	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#	# Draw a little bit of road for each pair of edges
#	var edge_pair_list = road_path.get_path_pair_edges()
#	for edge_pair in edge_pair_list:
#		var vertices = _get_road_vertices_for_edges(edge_pair[0], edge_pair[1], width, clearance)
#		for vertex in vertices:
#			surface_tool.add_color(debug_color_dict.road_color)
#			surface_tool.add_vertex(vertex + clearance * Vector3.UP)
#
#	surface_tool.generate_normals()
#	var _err = surface_tool.commit(road_mesh)
#	return road_mesh
#
#static func _get_road_vertices_for_edges(edge_1: Edge, edge_2: Edge, width: float, clearance: float) -> Array:  # -> Array[Vector3]
#	var shared_point = edge_1.shared_point(edge_2)
#	var other_1 = edge_1.other_point(shared_point)
#	var other_2 = edge_2.other_point(shared_point)
#	var clearance_adjust = clearance * Vector3.UP
#	var vertices = [
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_2.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 + 0.5 * width) + clearance_adjust,
#		lerp(shared_point.get_vector(), other_1.get_vector(), 0.5 - 0.5 * width) + clearance_adjust,
#	]
#	return vertices
#
#static func _get_cliff_surface_mesh(cliff_surface: Array, color: Color) -> Mesh:
#	# (cliff_surface: Array[Triangle])
#	var surface_tool: SurfaceTool = SurfaceTool.new()
#	var cliff_mesh: Mesh = Mesh.new()
#	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#	# Draw a little bit of road for each pair of edges
#	for cliff_triangle in cliff_surface:
#		for vertex in cliff_triangle.get_vertices():
#			surface_tool.add_color(color)
#			surface_tool.add_vertex(vertex.get_vector())
#
#	surface_tool.generate_normals()
#	var _err = surface_tool.commit(cliff_mesh)
#	return cliff_mesh
#
#static func _draw_marker_on_triangle(junction: Triangle, color: Color, size: float) -> Mesh:
#	# Just draw some kind of marker
#	var pos: Vector3 = junction.get_center()
#	var vertices = [
#		[
#			pos,
#			pos + (Vector3.UP * size) + (Vector3.LEFT * size * 0.5),
#			pos + (Vector3.UP * size) + (Vector3.RIGHT * size * 0.5),
#		],
#		[
#			pos,
#			pos + (Vector3.UP * size) + (Vector3.FORWARD * size * 0.5),
#			pos + (Vector3.UP * size) + (Vector3.BACK * size * 0.5),
#		]
#	]
#
#	var surface_tool: SurfaceTool = SurfaceTool.new()
#	var road_mesh: Mesh = Mesh.new()
#	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#
#	for poly in vertices:
#		for _i in range(2):
#			for vertex in poly:
#				surface_tool.add_color(color)
#				surface_tool.add_vertex(vertex)
#			poly.invert()
#
#	surface_tool.generate_normals()
#	var _err = surface_tool.commit(road_mesh)
#	return road_mesh
