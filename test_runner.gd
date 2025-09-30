extends SceneTree

func _init():
	# 🛠️ Skip SQLite/autoload setup if running in CI
	if OS.has_environment("CI"):
		print("⚠️ Running in CI mode - skipping SQLite and heavy autoloads")

		# Use root to check/remove autoloads
		if root.has_node("SaveManager"):
			root.get_node("SaveManager").queue_free()
		if root.has_node("AudioManager"):
			root.get_node("AudioManager").queue_free()

	# Normal GUT setup
	var gut = load("res://addons/gut/gut.gd").new()
	root.add_child(gut)

	gut.set_directories(["res://tests"])
	gut.set_print_format(gut.PRINT_DETAIL)

	# Run tests
	gut.run_tests()
