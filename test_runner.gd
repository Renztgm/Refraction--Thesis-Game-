extends SceneTree

func _init():
    var gut = load("res://addons/gut/gut.gd").new()
    root.add_child(gut)

    # Set test directories
    gut.set_directories(["res://tests"])

    # Output format for CI logs
    gut.set_print_format(gut.PRINT_VERBOSE)  # More detailed than PRINT_DETAIL

    # Optional: Save JUnit-style XML for CI parsing
    gut.set_junit_file("user://test_results/results.xml")

    # Optional: Save plain text summary
    gut.set_summary_file("user://test_results/summary.txt")

    # Optional: Include subdirectories
    gut.include_subdirectories(true)

    # Optional: Exit Godot after tests
    gut.set_exit_on_finish(true)

    # Run tests
    gut.run_tests()
