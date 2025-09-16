extends SceneTree

func _init():
	var gut = preload("res://addons/gut/gut.gd").new()
	gut.run([
		"--dirs=res://tests",   # directory with your test_*.gd files
		"--include_subdirs",    # optional
		"--log=1"               # show test results in console
	])
	quit() # exit after running
