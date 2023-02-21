extends Node

func test_init() -> bool:
	var test_vertex = Vertex.new()
	
	if not (test_vertex.get_height() == 1.0): return false
	if not (test_vertex.get_vector() == Vector3.ZERO): return false

	return true
