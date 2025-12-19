extends SceneTree
func _init():
	call_deferred("_run_gut")

func _run_gut() -> void:
	var gut: Node = load("res://addons/gut/gut.gd").new()
	get_root().add_child(gut)
	await self.process_frame
	
	gut.log_level = gut.LOG_LEVEL_ALL_ASSERTS
	gut.add_directory("res://tests")
	gut.run_tests()
	
	# Simple fixed delay - adjust based on your test suite duration
	await self.create_timer(10.0).timeout
	
	print("\n=== TEST SUMMARY ===")
	print("Passed: ", gut.get_pass_count())
	print("Failed: ", gut.get_fail_count())
	print("Pending: ", gut.get_pending_count())
	print("Total: ", gut.get_test_count())
	
	quit(1 if gut.get_fail_count() > 0 else 0)
