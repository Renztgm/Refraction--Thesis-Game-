extends SceneTree
func _init():
	call_deferred("_run_gut")
	
func _run_gut() -> void:
	var gut: Node = load("res://addons/gut/gut.gd").new()
	get_root().add_child(gut)
	await self.process_frame
	
	# Configure GUT (remove the invalid method)
	gut.log_level = gut.LOG_LEVEL_ALL_ASSERTS
	
	gut.add_directory("res://tests")
	gut.run_tests()
	
	# Wait for tests to complete
	await gut.tests_finished
	
	# Print summary
	print("\n=== TEST SUMMARY ===")
	print("Passed: ", gut.get_pass_count())
	print("Failed: ", gut.get_fail_count())
	print("Pending: ", gut.get_pending_count())
	print("Total: ", gut.get_test_count())
	
	await self.create_timer(1.0).timeout
	quit()
