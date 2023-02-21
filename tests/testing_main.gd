extends Control

@onready var test_output_box = $RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	test_output_box.add_text("\nPreparing tests\n")
	
	var test_files: Array[String] = find_test_files("res://tests/")
	var tests: Array[String] = []
	for test_file in test_files:
		for test in load_test_script_methods(test_file):
			tests.append(test_file + "::" + test)
	
	for test in tests:
		run_test(test)


func find_test_files(path: String) -> Array[String]:
	var test_files: Array[String] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				test_files.append_array(find_test_files(path + "/"+ file_name))
			else:
				if file_name.begins_with("test_") and file_name.ends_with(".gd"):
					test_files.append(path + "/"+ file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return test_files


func load_test_script_methods(file_path: String) -> Array[String]:
	var test_methods: Array[String] = []
	var test_script: Resource = load(file_path)
	var test_node = Node.new()
	test_node.set_script(test_script)
	var method_dict: Array[Dictionary] = test_node.get_method_list()
	var method_names: Array = method_dict.map(func(details) -> String: return details["name"])
	for method_name in method_names:
		if method_name.begins_with("test_"):
			test_methods.append(method_name)
	return test_methods


func run_test(test_name: String) -> void:
	var file_test_split: PackedStringArray = test_name.split("::", false, 2)
	var file: String = file_test_split[0]
	var test: String = file_test_split[1]
	var test_node = Node.new()
	test_node.set_script(load(file))
	
	var result = test_node.call(test)
	test_output_box.add_text("\n" + test_name + " - " + ("PASS" if result else "FAILED"))
