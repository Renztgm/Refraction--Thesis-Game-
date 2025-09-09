extends SceneTree

var test_results = []

func _init():
	print("Starting Godot Test Suite...")
	print("Godot Version: " + Engine.get_version_info().string)
	
	# Run all test classes
	var all_tests_passed = run_all_test_classes()
	
	print_summary()
	
	if all_tests_passed:
		print("✅ All tests passed!")
		quit(0)  # Exit with success code
	else:
		print("❌ Some tests failed!")
		quit(1)  # Exit with error code

func run_all_test_classes() -> bool:
	var test_classes = [
		"TestSaveManager",
		# Add other test classes here as you create them
		# "TestPlayerController",
		# "TestInventorySystem",
	]
	
	var all_passed = true
	
	for test_class_name in test_classes:
		print("\n" + "=" * 60)
		print("Running %s" % test_class_name)
		print("=" * 60)
		
		var success = run_test_class(test_class_name)
		test_results.append({
			"class": test_class_name,
			"passed": success
		})
		
		if not success:
			all_passed = false
	
	return all_passed

func run_test_class(class_name: String) -> bool:
	# Load the test class
	var test_class_path = "res://test/" + class_name + ".gd"
	if not ResourceLoader.exists(test_class_path):
		print("ERROR: Could not find test class at: " + test_class_path)
		return false
	
	var test_class = load(test_class_path)
	if not test_class:
		print("ERROR: Could not load test class: " + class_name)
		return false
	
	# Create instance and run tests
	var test_instance = test_class.new()
	
	# Check if it has run_all_tests method
	if test_instance.has_method("run_all_tests"):
		return test_instance.run_all_tests()
	else:
		print("ERROR: Test class %s missing run_all_tests() method" % class_name)
		return false

func print_summary():
	print("\n" + "=" * 60)
	print("TEST SUMMARY")
	print("=" * 60)
	
	var total_classes = test_results.size()
	var passed_classes = 0
	
	for result in test_results:
		var status = "✅ PASS" if result.passed else "❌ FAIL"
		print("%s: %s" % [result.class, status])
		if result.passed:
			passed_classes += 1
	
	print("-" * 60)
	print("Classes: %d/%d passed" % [passed_classes, total_classes])
	print("Success Rate: %.1f%%" % ((float(passed_classes) / total_classes) * 100.0))
	print("=" * 60)
