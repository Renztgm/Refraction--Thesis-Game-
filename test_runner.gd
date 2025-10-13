extends SceneTree

func _init():
	call_deferred("_run_gut")

func _run_gut() -> void:
	var gut: Node = load("res://addons/gut/gut.gd").new()
	get_root().add_child(gut)
	await self.process_frame
	
	gut.call("add_directory", "res://tests")
	gut.call("run_tests")
	
	await self.create_timer(2.0).timeout
	
	# Exit - CI will check logs for pass/fail
	quit()
