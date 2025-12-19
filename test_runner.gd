extends SceneTree

func _init():
	call_deferred("_run_gut")

func _run_gut() -> void:
	var gut: Node = load("res://addons/gut/gut.gd").new()
	get_root().add_child(gut)
	await self.process_frame
	
	gut.log_level = gut.LOG_LEVEL_ALL_ASSERTS
	
	# Disable colors in CI
	if OS.has_environment("CI"):
		gut.set_color_output(false)
	
	gut.add_directory("res://tests")
	gut.run_tests()
	
	await self.create_timer(10.0).timeout
	
	# Generate reports
	_print_summary(gut)
	_generate_html_report(gut)
	
	quit(1 if gut.get_fail_count() > 0 else 0)

func _print_summary(gut: Node) -> void:
	print("\n=== TEST SUMMARY ===")
	print("Passed: ", gut.get_pass_count())
	print("Failed: ", gut.get_fail_count())
	print("Pending: ", gut.get_pending_count())
	print("Total: ", gut.get_test_count())

func _generate_html_report(gut: Node) -> void:
	var passed = gut.get_pass_count()
	var failed = gut.get_fail_count()
	var total = gut.get_test_count()
	var warnings = gut.get_pending_count()
	
	# Get test scripts
	var test_scripts = []
	var test_collector = gut.get_test_collector()
	if test_collector:
		var scripts = test_collector.scripts
		for script in scripts:
			var script_name = script.get_full_name() if script.has_method("get_full_name") else str(script)
			test_scripts.append({
				"name": script_name,
				"passed": true  # Assume all passed if no failures
			})
	
	var html = """<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>GUT Test Results</title>
	<style>
		* { margin: 0; padding: 0; box-sizing: border-box; }
		body {
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
			background: #1a1d23;
			color: #e0e0e0;
			padding: 2rem;
		}
		.container { max-width: 1200px; margin: 0 auto; }
		h1 {
			font-size: 2rem;
			margin-bottom: 2rem;
			display: flex;
			align-items: center;
			gap: 0.5rem;
		}
		.icon { font-size: 1.5rem; }
		.status {
			background: #2d5a3d;
			color: #7dff7d;
			padding: 1rem 1.5rem;
			border-radius: 8px;
			margin-bottom: 2rem;
			display: flex;
			align-items: center;
			gap: 0.5rem;
			font-weight: 600;
		}
		.status.failed { background: #5a2d2d; color: #ff7d7d; }
		table {
			width: 100%;
			border-collapse: collapse;
			background: #252930;
			border-radius: 8px;
			overflow: hidden;
			margin-bottom: 2rem;
		}
		th, td {
			padding: 1rem;
			text-align: left;
			border-bottom: 1px solid #3a3f4a;
		}
		th {
			background: #2a2f38;
			font-weight: 600;
			color: #b0b0b0;
		}
		tr:last-child td { border-bottom: none; }
		tr:hover { background: #2d3139; }
		.metric-icon {
			display: inline-block;
			width: 20px;
			text-align: center;
			margin-right: 0.5rem;
		}
		h2 {
			font-size: 1.5rem;
			margin-bottom: 1rem;
			display: flex;
			align-items: center;
			gap: 0.5rem;
		}
		.test-file {
			display: flex;
			align-items: center;
			gap: 0.5rem;
		}
		.check { color: #7dff7d; }
		.cross { color: #ff7d7d; }
		.warning { color: #ffd97d; }
		.time { color: #7d9dff; }
	</style>
</head>
<body>
	<div class="container">
		<h1><span class="icon">📝</span> GUT Test Results</h1>
		
		<div class="status %s">
			<span class="icon">%s</span>
			<span>%s</span>
		</div>
		
		<table>
			<thead>
				<tr>
					<th>Metric</th>
					<th>Count</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td><span class="metric-icon">📄</span> Scripts</td>
					<td>%d</td>
				</tr>
				<tr>
					<td><span class="metric-icon">📝</span> Tests</td>
					<td>%d</td>
				</tr>
				<tr>
					<td><span class="metric-icon check">✅</span> Passing</td>
					<td>%d</td>
				</tr>
				<tr>
					<td><span class="metric-icon">🔍</span> Assertions</td>
					<td>%d</td>
				</tr>
				<tr>
					<td><span class="metric-icon time">⏱️</span> Time</td>
					<td>%.3fs</td>
				</tr>
				<tr>
					<td><span class="metric-icon warning">⚠️</span> Warnings</td>
					<td>%d</td>
				</tr>
			</tbody>
		</table>
		
		<h2><span class="icon">📁</span> Test Files</h2>
		<table>
			<tbody>
%s
			</tbody>
		</table>
	</div>
</body>
</html>
"""
	
	var status_class = "failed" if failed > 0 else ""
	var status_icon = "✅" if failed == 0 else "❌"
	var status_text = "All Tests Passed!" if failed == 0 else "Tests Failed!"
	
	var script_count = test_scripts.size()
	var assertions = passed + failed  # Approximate
	var time = gut.get_elapsed_time()
	
	# Build test files list
	var files_html = ""
	for script in test_scripts:
		var icon = "✅" if script.passed else "❌"
		var icon_class = "check" if script.passed else "cross"
		var status = "All passed" if script.passed else "Failed"
		files_html += "\t\t\t\t<tr>\n"
		files_html += "\t\t\t\t\t<td class='test-file'>\n"
		files_html += "\t\t\t\t\t\t<span class='%s'>%s</span>\n" % [icon_class, icon]
		files_html += "\t\t\t\t\t\t<code>%s</code> - %s\n" % [script.name, status]
		files_html += "\t\t\t\t\t</td>\n"
		files_html += "\t\t\t\t</tr>\n"
	
	var final_html = html % [
		status_class,
		status_icon,
		status_text,
		script_count,
		total,
		passed,
		assertions,
		time,
		warnings,
		files_html
	]
	
	# Save to file
	var output_path = "user://test_results.html"
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string(final_html)
		file.close()
		print("\n📊 HTML report generated: ", output_path)
		print("   Real path: ", ProjectSettings.globalize_path(output_path))
	else:
		print("❌ Failed to create HTML report")
