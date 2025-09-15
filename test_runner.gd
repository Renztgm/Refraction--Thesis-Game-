extends SceneTree

var test_results = []
var junit_output_path = "res://test_results.xml"

func _init():
	print("Starting Godot Test Suite...")
	print("Godot Version: " + Engine.get_version_info().string)
	
	var all_tests_passed = run_all_test_classes()
	
	print_summary()
	write_junit_report()

	if all_tests_passed:
		print("✅ All tests passed!")
		quit(0)
	else:
		print("❌ Some tests failed!")
		quit(1)

func run_all_test_classes() -> bool:
	var test_classes = [
		"TestSaveManager"
	]
	
	var all_passed = true
	
	for test_class_name in test_classes:
		print("\n" + "=".repeat(60))
		print("Running " + test_class_name)
		print("=".repeat(60))
		
		var success = run_test_class(test_class_name)
		test_results.append({
			"class": test_class_name,
			"passed": success
		})
		
		if not success:
			all_passed = false
	
	return all_passed

func run_test_class(test_class_name: String) -> bool:
	var test_class_path = "res://test/" + test_class_name + ".gd"
	if not ResourceLoader.exists(test_class_path):
		push_error("ERROR: Could not find test class at: " + test_class_path)
		return false
	
	var test_class = load(test_class_path)
	if not test_class:
		push_error("ERROR: Could not load test class: " + test_class_name)
		return false
	
	var test_instance = test_class.new()
	if test_instance.has_method("run_all_tests"):
		return test_instance.run_all_tests()
	else:
		push_error("ERROR: Test class " + test_class_name + " missing run_all_tests() method")
		return false

func print_summary():
	print("\n" + "=".repeat(60))
	print("TEST SUMMARY")
	print("=".repeat(60))
	
	var total_classes = test_results.size()
	var passed_classes = 0
	
	for result in test_results:
		var status = "PASS" if result.passed else "FAIL"
		print(result.class + ": " + status)
		if result.passed:
			passed_classes += 1
	
	print("-".repeat(60))
	print("Classes: " + str(passed_classes) + "/" + str(total_classes) + " passed")
	if total_classes > 0:
		var success_rate = (float(passed_classes) / total_classes) * 100.0
		print("Success Rate: " + str(success_rate) + "%")
	print("=".repeat(60))

func write_junit_report():
	print("📄 Writing JUnit report to: " + junit_output_path)

	var xml = "<?xml version='1.0' encoding='UTF-8'?>\n"
	xml += "<testsuites>\n"

	for result in test_results:
		xml += "  <testsuite name='%s' tests='1' failures='%d'>\n" % [
			result.class,
			(0 if result.passed else 1)
		]

		xml += "    <testcase classname='%s' name='run_all_tests'>" % result.class
		if not result.passed:
			xml += "<failure message='Test failed'/>"
		xml += "</testcase>\n"

		xml += "  </testsuite>\n"

	xml += "</testsuites>\n"

	var file = FileAccess.open(junit_output_path, FileAccess.WRITE)
	if file:
		file.store_string(xml)
		file.close()
		print("✅ JUnit report written")
	else:
		push_error("❌ Failed to write JUnit report")
