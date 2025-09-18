extends Node3D

@export var grid_size: float = 3.0
@export var grid_dimensions: Vector2i = Vector2i(10, 10)  # Starting grid size
@export var obstacle_check_radius: float = 1
@export var auto_expand: bool = true  # Enable automatic grid expansion

# Grid data
var grid: Dictionary = {} # Vector2 -> walkable (true/false)
var current_route: Array[Vector2] = []  # Current path in grid coordinates

# Visual components
var grid_mesh_instance: MeshInstance3D
var route_mesh_instance: MeshInstance3D

func _ready():
	build_grid_for_large_plane()  # Use this instead of build_grid()


func auto_adjust_for_target(target_pos: Vector3):
	"""Automatically adjust grid to include a target position"""
	if not auto_expand:
		print("🔒 Auto-expand disabled, skipping grid adjustment")
		return
		
	var target_grid = world_to_grid(target_pos)
	var half_width = grid_dimensions.x / 2
	var half_height = grid_dimensions.y / 2
	
	var needs_rebuild = false
	var old_dimensions = grid_dimensions
	
	# Check if target is outside current bounds and expand if needed
	if abs(target_grid.x) >= half_width:
		var needed_width = int(abs(target_grid.x) * 2.5)  # 25% margin
		if needed_width > grid_dimensions.x:
			grid_dimensions.x = needed_width
			needs_rebuild = true
		
	if abs(target_grid.y) >= half_height:
		var needed_height = int(abs(target_grid.y) * 2.5)  # 25% margin
		if needed_height > grid_dimensions.y:
			grid_dimensions.y = needed_height
			needs_rebuild = true
		
	if needs_rebuild:
		print("🔄 Auto-expanding grid from ", old_dimensions, " to ", grid_dimensions)
		print("🎯 Target at world: ", target_pos, " -> grid: ", target_grid)
		build_grid_for_large_plane()  # Use this instead of build_grid()
		return true
	else:
		print("✅ Target ", target_grid, " already within grid bounds ", grid_dimensions)
		return false

func build_grid_for_large_plane():
	"""Build grid specifically for 200x200 plane"""
	grid.clear()
	
	# Calculate dimensions needed for 200x200 plane
	var plane_size = 200.0
	var cells_needed = int(plane_size / grid_size) + 4  # +4 for margin
	grid_dimensions = Vector2i(cells_needed, cells_needed)
	
	print("🏗️ Building grid for 200x200 plane:")
	print("   Grid size per cell: ", grid_size)
	print("   Cells needed: ", cells_needed, "x", cells_needed)
	print("   Total coverage: ", cells_needed * grid_size, "x", cells_needed * grid_size)
	
	# Create grid centered around origin to cover the plane
	var half_width = grid_dimensions.x / 2
	var half_height = grid_dimensions.y / 2
	
	var walkable_count = 0
	var blocked_count = 0
	var checked_count = 0
	
	for x in range(-half_width, half_width):
		for z in range(-half_height, half_height):
			var cell = Vector2(x, z)
			var world_pos = grid_to_world(cell)
			
			# Only check cells that are within reasonable bounds of the plane
			if abs(world_pos.x) <= plane_size/2 + 10 and abs(world_pos.z) <= plane_size/2 + 10:
				var is_walkable = not check_obstacle(world_pos)
				grid[cell] = is_walkable
				checked_count += 1
				
				if is_walkable:
					walkable_count += 1
				else:
					blocked_count += 1
			else:
				# Cells far outside plane are not walkable
				grid[cell] = false
				blocked_count += 1
	
	print("✅ Grid built: ", grid.size(), " cells total")
	print("   Checked for obstacles: ", checked_count)
	print("   Walkable: ", walkable_count)
	print("   Blocked: ", blocked_count)
	print("   Unchecked (outside plane): ", grid.size() - checked_count)
	
	draw_grid_visualization()

# Improved obstacle check for large areas
func check_obstacle(world_pos: Vector3) -> bool:
	var half = grid_size * 0.5
	var offsets = [
		Vector3(0, 0, 0),  # center
		Vector3(half, 0, 0),  # right
		Vector3(-half, 0, 0), # left
		Vector3(0, 0, half),  # forward
		Vector3(0, 0, -half), # back
		Vector3(half, 0, half),   # corner
		Vector3(-half, 0, half),
		Vector3(half, 0, -half),
		Vector3(-half, 0, -half)
	]
	
	for offset in offsets:
		if check_single_point(world_pos + offset):
			return true
	
	return false

func check_single_point(point: Vector3) -> bool:
	var sphere = SphereShape3D.new()
	sphere.radius = obstacle_check_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = point
	query.collision_mask = 2  # Obstacle layer
	
	var obstacles = get_world_3d().direct_space_state.intersect_shape(query, 1)
	
	var ground_check = PhysicsRayQueryParameters3D.create(
		point + Vector3(0, 5, 0),
		point + Vector3(0, -5, 0)
	)
	ground_check.collision_mask = 1  # Ground layer
	var ground_hit = get_world_3d().direct_space_state.intersect_ray(ground_check)
	
	return obstacles.size() > 0 or ground_hit.is_empty()


func grid_to_world(grid_pos: Vector2) -> Vector3:
	return Vector3(
		grid_pos.x * grid_size + grid_size * 0.5,
		global_position.y,
		grid_pos.y * grid_size + grid_size * 0.5
	)

func world_to_grid(world_pos: Vector3) -> Vector2:
	return Vector2(
		floorf(world_pos.x / grid_size),
		floorf(world_pos.z / grid_size)
	)

func is_walkable(grid_pos: Vector2) -> bool:
	return grid.get(grid_pos, false)

func is_valid_cell(grid_pos: Vector2) -> bool:
	var half_width = grid_dimensions.x / 2
	var half_height = grid_dimensions.y / 2
	return grid_pos.x >= -half_width and grid_pos.x < half_width and \
		   grid_pos.y >= -half_height and grid_pos.y < half_height

func get_neighbors(cell: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	var directions = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]
	
	for dir in directions:
		var neighbor = cell + dir
		if is_valid_cell(neighbor) and is_walkable(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func find_nearest_walkable(cell: Vector2) -> Vector2:
	if is_walkable(cell):
		return cell
	
	var max_radius = min(grid_dimensions.x, grid_dimensions.y) / 2
	for r in range(1, max_radius):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var neighbor = cell + Vector2(dx, dz)
				if is_valid_cell(neighbor) and is_walkable(neighbor):
					return neighbor
	
	# fallback to center if nothing found
	print("⚠️ No walkable cell found, returning center")
	return Vector2(0, 0)

# --- ROUTE VISUALIZATION METHODS ---

func set_route(route_cells: Array[Vector2]):
	"""Set the current route to visualize on the grid"""
	current_route = route_cells.duplicate()
	draw_route_on_grid()
	print("🎨 Route set with ", current_route.size(), " cells")

func clear_route():
	"""Clear the current route visualization"""
	current_route.clear()
	draw_route_on_grid()
	print("🧹 Route cleared")

func draw_grid_visualization():
	"""Draw the base grid with walkable/blocked cells"""
	# Clear existing grid visualization
	if grid_mesh_instance and grid_mesh_instance.is_inside_tree():
		grid_mesh_instance.queue_free()
	
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	
	# Draw cell borders and backgrounds
	for cell in grid.keys():
		var world_pos = grid_to_world(cell)
		var x = world_pos.x
		var z = world_pos.z
		var half = grid_size * 0.5
		var y_offset = 0.01  # Slightly above ground
		
		if grid[cell]: # walkable cell
			# Draw cell background as a quad
			add_quad_to_arrays(verts, colors, 
				Vector3(x - half, y_offset, z - half),
				Vector3(x + half, y_offset, z - half),
				Vector3(x + half, y_offset, z + half),
				Vector3(x - half, y_offset, z + half),
				Color(0.1, 0.8, 0.1, 0.2))  # Semi-transparent green
			
			# Draw cell border
			add_line_loop_to_arrays(verts, colors,
				[Vector3(x - half, y_offset + 0.01, z - half),
				 Vector3(x + half, y_offset + 0.01, z - half),
				 Vector3(x + half, y_offset + 0.01, z + half),
				 Vector3(x - half, y_offset + 0.01, z + half)],
				Color(0.2, 1.0, 0.2, 0.6))  # Green border
		else:
			# Draw blocked cell as red X
			add_line_to_arrays(verts, colors,
				Vector3(x - half, y_offset + 0.02, z - half),
				Vector3(x + half, y_offset + 0.02, z + half),
				Color.RED)
			add_line_to_arrays(verts, colors,
				Vector3(x - half, y_offset + 0.02, z + half),
				Vector3(x + half, y_offset + 0.02, z - half),
				Color.RED)
	
	# Create mesh
	if verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = colors
		
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		grid_mesh_instance = MeshInstance3D.new()
		grid_mesh_instance.mesh = mesh
		
		# Use vertex colors and make it unshaded
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
		grid_mesh_instance.material_override = mat
		
		add_child(grid_mesh_instance)

func draw_route_on_grid():
	"""Draw the current route on top of the grid"""
	# Clear existing route visualization
	if route_mesh_instance and route_mesh_instance.is_inside_tree():
		route_mesh_instance.queue_free()
	
	if current_route.is_empty():
		return
	
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	
	# Draw route cells with different colors for start, path, and end
	for i in range(current_route.size()):
		var cell = current_route[i]
		var world_pos = grid_to_world(cell)
		var x = world_pos.x
		var z = world_pos.z
		var half = grid_size * 0.4  # Slightly smaller than grid cells
		var y_offset = 0.05  # Above grid
		
		var color: Color
		if i == 0:
			color = Color(0.0, 1.0, 0.0, 0.9)  # Bright green for start
		elif i == current_route.size() - 1:
			color = Color(1.0, 0.0, 0.0, 0.9)  # Bright red for end
		else:
			color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow for path
		
		# Draw route cell as filled quad
		add_quad_to_arrays(verts, colors,
			Vector3(x - half, y_offset, z - half),
			Vector3(x + half, y_offset, z - half),
			Vector3(x + half, y_offset, z + half),
			Vector3(x - half, y_offset, z + half),
			color)
	
	# Draw arrows between route cells
	for i in range(current_route.size() - 1):
		var from_cell = current_route[i]
		var to_cell = current_route[i + 1]
		var from_world = grid_to_world(from_cell)
		var to_world = grid_to_world(to_cell)
		
		# Draw arrow from center to center
		draw_arrow_between_points(verts, colors, 
			Vector3(from_world.x, 0.06, from_world.z),
			Vector3(to_world.x, 0.06, to_world.z),
			Color(0.0, 0.0, 1.0, 1.0))  # Blue arrows
	
	# Create route mesh
	if verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = colors
		
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		route_mesh_instance = MeshInstance3D.new()
		route_mesh_instance.mesh = mesh
		
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		route_mesh_instance.material_override = mat
		
		add_child(route_mesh_instance)

# --- HELPER METHODS FOR MESH GENERATION ---

func add_quad_to_arrays(verts: PackedVector3Array, colors: PackedColorArray, 
	p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, color: Color):
	"""Add a quad (two triangles) to the vertex arrays"""
	# First triangle: p1, p2, p3
	verts.append(p1)
	verts.append(p2)
	verts.append(p3)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	
	# Second triangle: p1, p3, p4
	verts.append(p1)
	verts.append(p3)
	verts.append(p4)
	colors.append(color)
	colors.append(color)
	colors.append(color)

func add_line_to_arrays(verts: PackedVector3Array, colors: PackedColorArray,
	start: Vector3, end: Vector3, color: Color):
	"""Add a line to vertex arrays (as degenerate triangles for visibility)"""
	var thickness = 0.05
	var dir = (end - start).normalized()
	var perp = Vector3(-dir.z, 0, dir.x) * thickness
	
	# Create a thin quad for the line
	add_quad_to_arrays(verts, colors,
		start + perp, end + perp, end - perp, start - perp, color)

func add_line_loop_to_arrays(verts: PackedVector3Array, colors: PackedColorArray,
	points: Array, color: Color):
	"""Add a line loop (closed path) to vertex arrays"""
	for i in range(points.size()):
		var next_i = (i + 1) % points.size()
		add_line_to_arrays(verts, colors, points[i], points[next_i], color)

func draw_arrow_between_points(verts: PackedVector3Array, colors: PackedColorArray,
	start: Vector3, end: Vector3, color: Color):
	"""Draw an arrow from start to end point"""
	var dir = (end - start).normalized()
	var mid = start.lerp(end, 0.7)  # Arrow starts 70% along the line
	
	# Arrow shaft
	add_line_to_arrays(verts, colors, mid, end, color)
	
	# Arrow head
	var arrow_size = grid_size * 0.1
	var perp = Vector3(-dir.z, 0, dir.x) * arrow_size
	var back = end - dir * arrow_size
	
	# Arrow head triangle
	verts.append(end)
	verts.append(back + perp)
	verts.append(back - perp)
	colors.append(color)
	colors.append(color)
	colors.append(color)

# --- PUBLIC INTERFACE ---

func get_grid_info() -> Dictionary:
	var walkable_count = 0
	var blocked_count = 0
	
	for cell in grid.keys():
		if grid[cell]:
			walkable_count += 1
		else:
			blocked_count += 1
	
	return {
		"dimensions": grid_dimensions,
		"total_cells": grid.size(),
		"walkable_cells": walkable_count,
		"blocked_cells": blocked_count,
		"grid_size": grid_size,
		"current_route_length": current_route.size(),
		"world_bounds": {
			"x_min": -grid_dimensions.x / 2 * grid_size,
			"x_max": grid_dimensions.x / 2 * grid_size,
			"z_min": -grid_dimensions.y / 2 * grid_size,
			"z_max": grid_dimensions.y / 2 * grid_size
		}
	}

func update_route_from_world_path(world_path: Array[Vector3]):
	"""Convert world positions to grid cells and update route visualization"""
	var grid_route: Array[Vector2] = []
	for world_pos in world_path:
		var grid_pos = world_to_grid(world_pos)
		if not grid_route.has(grid_pos):  # Avoid duplicates
			grid_route.append(grid_pos)
	
	set_route(grid_route)

func force_rebuild():
	"""Force rebuild the grid (useful for runtime changes)"""
	build_grid_for_large_plane()  # Use this instead of build_grid()
