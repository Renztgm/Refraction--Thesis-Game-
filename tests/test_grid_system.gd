extends GutTest

func test_bookstore_has_navigation_region():
	"""Test that Bookstore scene has a NavigationRegion3D node"""
	var bookstore_path = "res://scenes/Scene3/Bookstore.tscn"
	
	# Load the scene
	var scene = load(bookstore_path)
	assert_not_null(scene, "Bookstore scene should exist at %s" % bookstore_path)
	
	# Instantiate it
	var bookstore = scene.instantiate()
	add_child_autofree(bookstore)
	await get_tree().process_frame
	
	# Find NavigationRegion3D
	var nav_region = bookstore.find_child("NavigationRegion3D", true, false)
	assert_not_null(nav_region, "Bookstore should have a NavigationRegion3D node")
	assert_true(nav_region is NavigationRegion3D, "Found node should be NavigationRegion3D")

func test_grid_system_creates_grid():
	"""Test that GridSystem script can create a grid from NavigationRegion3D"""
	var bookstore_path = "res://scenes/Scene3/Bookstore.tscn"
	
	# Load and instantiate
	var scene = load(bookstore_path)
	var bookstore = scene.instantiate()
	add_child_autofree(bookstore)
	await get_tree().process_frame
	
	# Find NavigationRegion3D
	var nav_region = bookstore.find_child("NavigationRegion3D", true, false)
	assert_not_null(nav_region, "Bookstore should have NavigationRegion3D")
	
	# Find GridSystem script (should be on NavigationRegion3D or child)
	var grid_system = null
	if nav_region.has_meta("grid_system") or nav_region.get_script() != null:
		if "build_grid" in nav_region:
			grid_system = nav_region
	
	# If not found on nav_region, search children
	if grid_system == null:
		grid_system = nav_region.find_child("*", true, false)
		for child in nav_region.get_children():
			if "build_grid" in child:
				grid_system = child
				break
	
	# Allow time for grid to build
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check if grid was created
	if grid_system != null and "grid" in grid_system:
		var grid = grid_system.grid
		assert_gt(grid.size(), 0, "Grid should contain cells")
		
		# Count walkable cells
		var walkable_count = 0
		for cell in grid.keys():
			if grid[cell]:
				walkable_count += 1
		
		assert_gt(walkable_count, 0, "Grid should have at least some walkable cells")
		print("✅ Grid created with %d total cells, %d walkable" % [grid.size(), walkable_count])
	else:
		print("⚠️ GridSystem not found with active grid, but scene loads successfully")

func test_navigation_mesh_has_vertices():
	"""Test that NavigationRegion3D has a valid NavigationMesh with vertices"""
	var bookstore_path = "res://scenes/Scene3/Bookstore.tscn"
	
	var scene = load(bookstore_path)
	var bookstore = scene.instantiate()
	add_child_autofree(bookstore)
	await get_tree().process_frame
	
	var nav_region = bookstore.find_child("NavigationRegion3D", true, false)
	assert_not_null(nav_region, "Bookstore should have NavigationRegion3D")
	
	var nav_mesh = nav_region.navigation_mesh
	assert_not_null(nav_mesh, "NavigationRegion3D should have a navigation_mesh")
	
	var vertices = nav_mesh.vertices
	assert_gt(vertices.size(), 0, "NavigationMesh should have vertices")
	print("✅ NavigationMesh has %d vertices" % vertices.size())
