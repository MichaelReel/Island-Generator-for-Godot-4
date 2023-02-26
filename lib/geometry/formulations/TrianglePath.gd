class_name TrianglePath
extends Object

var _origin: Triangle
var _destination: Triangle
var _path: Array[Triangle] = []


func extend_to_origin(road: Triangle) -> void:
	_path.push_front(road)
	road.add_road(self)

func extend_to_destination(road: Triangle) -> void:
	_path.push_back(road)
	road.add_road(self)

func set_origin(origin: Triangle) -> void:
	_origin = origin

func set_destination(destination: Triangle) -> void:
	_destination = destination

func get_path_pair_edges() -> Array[Array]:  # -> Array[Array[Edge]]
	"""Return a list of edge pairs, where the edges are in clockwise rotation order"""
	
	if no_path():
		return []
	
	var edge_list: Array[Object] = [_origin.get_shared_edge(_path.front())]
	for i in range(len(_path) - 1):
		edge_list.append(_path[i].get_shared_edge(_path[i+1]))
	edge_list.append(_path.back().get_shared_edge(_destination))
	
	var edge_pair_list: Array[Array] = []  # Array[Array[Edge]]
	for i in range(len(edge_list) - 1):
		edge_pair_list.append(_path[i].order_clockwise(edge_list[i], edge_list[i + 1]))
	
	return edge_pair_list

func no_path() -> bool:
	return _path.is_empty()
