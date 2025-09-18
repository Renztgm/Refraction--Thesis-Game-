extends SceneTree

func _init():
	var gut = load("res://addons/gut/gut.gd").new()
	root.add_child(gut)

	# Tell GUT which folder(s) to look in
	gut.set_directories(["res://tests"])

	# Configure output (use constants from gut instance instead of Gut.PRINT_DETAIL)
	gut.set_print_format(gut.PRINT_DETAIL)
	# gut.set_verbose(true) # if you also want asserts printed

	# Run tests
	gut.run_tests()
