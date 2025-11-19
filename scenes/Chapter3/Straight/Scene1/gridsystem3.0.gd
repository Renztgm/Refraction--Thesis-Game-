extends Node3D
# Attach this to NavigationRegion3D

# =========================
# CONFIG
# =========================
@export var grid_size: float = 2.0
@export var grid_dimensions: Vector2i = Vector2i(20, 20)
@export var auto_size_from_navmesh: bool = true  # Auto-calculate from NavigationRegion3D
@export var padding: float = 1.0  # Extra cells around navmesh bounds
@export var debug_output: bool = true  # Print detailed raycast info
var debug_visible: bool = true  # Toggle with CTRL+F4 (starts hidden)

# =========================
# GRID DATA
# =========================
var grid: Dictionary = {}  # Vector2 -> bool (walkable)
var _height_cache: Dictionary = {}  # Cache raycast heights

# =========================
# VISUALIZATION
# =========================
var grid_mesh_instance: MeshInstance3D
var path_mesh_instance: MeshInstance3D  # For NPC path visualization

# =========================
# READY
# =========================
func _ready():
	# Auto-calculate grid from NavigationRegion3D if enabled
	if auto_size_from_navmesh:
		calculate_grid_from_navmesh()
	
	maze_cell_size = grid_size
	generate_maze()
	print_grid_bounds()
	build_grid()
	draw_grid_visualization()
	print_walkable_cells()
	print("\n💡 Press CTRL+F4 to toggle grid/path visualization")

# =========================
# INPUT HANDLING
# =========================
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_F4:
			toggle_debug_visibility()

func toggle_debug_visibility():
	debug_visible = !debug_visible
	if is_instance_valid(grid_mesh_instance):
		grid_mesh_instance.visible = debug_visible
	if is_instance_valid(path_mesh_instance):
		path_mesh_instance.visible = debug_visible
	print("🔧 Grid/Path debug visibility:", "ON" if debug_visible else "OFF")

# =========================
# GRID GENERATION
# =========================
func calculate_grid_from_navmesh():
	"""Auto-calculate grid dimensions from NavigationRegion3D AABB"""
	var nav_region = get_parent() if get_parent() is NavigationRegion3D else self
	
	if not nav_region is NavigationRegion3D:
		print("⚠️ Auto-size failed: Parent is not NavigationRegion3D")
		return
	
	var navigation_mesh = nav_region.navigation_mesh
	if navigation_mesh == null:
		print("⚠️ Auto-size failed: No NavigationMesh found")
		return
	
	# Get the AABB of the navigation mesh
	var vertices = navigation_mesh.vertices
	if vertices.size() == 0:
		print("⚠️ Auto-size failed: NavigationMesh has no vertices")
		return
	
	# Calculate bounds from vertices
	var min_point = vertices[0]
	var max_point = vertices[0]
	
	for vertex in vertices:
		min_point.x = min(min_point.x, vertex.x)
		min_point.z = min(min_point.z, vertex.z)
		max_point.x = max(max_point.x, vertex.x)
		max_point.z = max(max_point.z, vertex.z)
	
	# Transform to world space if needed
	var transform = nav_region.global_transform
	min_point = transform * min_point
	max_point = transform * max_point
	
	# Calculate dimensions
	var width = abs(max_point.x - min_point.x)
	var height = abs(max_point.z - min_point.z)
	
	# Calculate grid dimensions (add padding)
	var grid_width = ceil(width / grid_size) + int(padding * 2)
	var grid_height = ceil(height / grid_size) + int(padding * 2)
	
	grid_dimensions = Vector2i(grid_width, grid_height)
	
	print("\n🔧 AUTO-SIZED FROM NAVIGATIONMESH:")
	print("   NavMesh bounds: ", width, "x", height, " units")
	print("   Grid dimensions: ", grid_dimensions, " cells")
	print("   Cell size: ", grid_size, " units")
	print("   Total coverage: ", grid_width * grid_size, "x", grid_height * grid_size, " units")

func build_grid():
	grid.clear()
	_height_cache.clear()
	
	var half_w = grid_dimensions.x / 2
	var half_h = grid_dimensions.y / 2
	var walkable_count = 0
	var floor_count = 0
	var obstacle_count = 0
	var sample_checked = false

	for x in range(-half_w, half_w):
		for z in range(-half_h, half_h):
			var cell = Vector2(x, z)
			var world_pos = grid_to_world(cell)

			# --- Check floor (layer 1) ---
			var from = world_pos + Vector3(0, 50, 0)
			var to = world_pos + Vector3(0, -50, 0)
			var ray_params = PhysicsRayQueryParameters3D.create(from, to)
			ray_params.collision_mask = 1  # Floor only
			var ground_hit = get_world_3d().direct_space_state.intersect_ray(ray_params)

			# --- Check for obstacles (layer 2) ---
			var obstacle_params = PhysicsRayQueryParameters3D.create(from, to)
			obstacle_params.collision_mask = 2  # Walls/obstacles only
			var obstacle_hit = get_world_3d().direct_space_state.intersect_ray(obstacle_params)

			var has_floor = not ground_hit.is_empty()
			var has_obstacle = not obstacle_hit.is_empty()
			
			if has_floor:
				floor_count += 1
				# Debug first floor detection
				if floor_count == 1 and debug_output:
					print("\n🟢 FIRST FLOOR DETECTED:")
					print("   Cell:", cell)
					print("   World position:", world_pos)
					print("   Collider:", ground_hit.collider)
					print("   Collider name:", ground_hit.collider.name)
					print("   Collision layer:", ground_hit.collider.collision_layer)
			
			if has_obstacle:
				obstacle_count += 1

			# Debug output for first obstacle found
			if debug_output and has_obstacle and not sample_checked:
				sample_checked = true
				print("\n🔍 OBSTACLE DETECTED at cell:", cell)
				print("   World position:", world_pos)
				print("   Collider:", obstacle_hit.collider)
				print("   Collision layer:", obstacle_hit.collider.collision_layer)
				print("   Collision mask:", obstacle_hit.collider.collision_mask)

			# Walkable if floor exists AND no obstacle
			var walkable = has_floor and not has_obstacle
			grid[cell] = walkable
			if walkable:
				walkable_count += 1

	print("\n🏗 Grid built:")
	print("   Total cells:", grid.size())
	print("   Cells with floor (layer 1):", floor_count)
	print("   Cells with obstacles (layer 2):", obstacle_count)
	print("   Walkable cells:", walkable_count)
	
	if obstacle_count == 0:
		print("\n⚠️ WARNING: No obstacles detected on layer 2!")
		print("   Check that your walls/obstacles have:")
		print("   - Collision Layer 2 enabled (bit 2 checked)")
		print("   - CollisionShape3D with proper shape")
		print("   - Are within the grid bounds")

# =========================
# GRID <-> WORLD CONVERSIONS
# =========================
func grid_to_world(grid_pos: Vector2) -> Vector3:
	var key = Vector2(int(grid_pos.x), int(grid_pos.y))
	var world_x = key.x * grid_size + grid_size * 0.5
	var world_z = key.y * grid_size + grid_size * 0.5

	if _height_cache.has(key):
		return Vector3(world_x, _height_cache[key], world_z)

	var from = Vector3(world_x, 50, world_z)
	var to = Vector3(world_x, -50, world_z)
	var params = PhysicsRayQueryParameters3D.create(from, to)
	params.collision_mask = 1
	var res = get_world_3d().direct_space_state.intersect_ray(params)
	var world_y = global_position.y
	if not res.is_empty() and res.has("position"):
		world_y = res["position"].y

	_height_cache[key] = world_y
	return Vector3(world_x, world_y, world_z)

func world_to_grid(world_pos: Vector3) -> Vector2:
	var gx = floor(world_pos.x / grid_size)
	var gz = floor(world_pos.z / grid_size)
	var half_w = grid_dimensions.x / 2
	var half_h = grid_dimensions.y / 2
	gx = clamp(gx, -half_w, half_w - 1)
	gz = clamp(gz, -half_h, half_h - 1)
	return Vector2(gx, gz)

func is_walkable(cell: Vector2) -> bool:
	return grid.get(cell, false)

# =========================
# DEBUG: Print walkable cells
# =========================
func print_grid_bounds():
	var half_w = grid_dimensions.x / 2
	var half_h = grid_dimensions.y / 2
	var min_cell = Vector2(-half_w, -half_h)
	var max_cell = Vector2(half_w - 1, half_h - 1)
	var min_world = grid_to_world(min_cell)
	var max_world = grid_to_world(max_cell)
	
	print("\n📐 GRID SCANNING AREA:")
	print("   Node position:", global_position)
	print("   Grid dimensions:", grid_dimensions, " cells")
	print("   Cell size:", grid_size, " units")
	print("   Scanning from X:", min_world.x, " to ", max_world.x)
	print("   Scanning from Z:", min_world.z, " to ", max_world.z)
	print("   Total world area:", (max_world.x - min_world.x), "x", (max_world.z - min_world.z), " units\n")

func print_walkable_cells():
	var walkable_cells = 0
	for cell in grid.keys():
		if grid[cell]:
			walkable_cells += 1
	print("✅ Walkable cells:", walkable_cells, " / Total:", grid.size())

# =========================
# HELPERS
# =========================
func add_hollow_square(verts: PackedVector3Array, colors: PackedColorArray,
		center: Vector3, half_size: float, color: Color, line_width: float = 0.1):
	# Create hollow square outline (4 rectangles forming a border)
	var corners = [
		Vector3(center.x - half_size, center.y, center.z - half_size),  # Top-left
		Vector3(center.x + half_size, center.y, center.z - half_size),  # Top-right
		Vector3(center.x + half_size, center.y, center.z + half_size),  # Bottom-right
		Vector3(center.x - half_size, center.y, center.z + half_size)   # Bottom-left
	]
	
	# Draw 4 sides of the square
	for i in range(4):
		var next_i = (i + 1) % 4
		var p1 = corners[i]
		var p2 = corners[next_i]
		var dir = (p2 - p1).normalized()
		var perp = Vector3(-dir.z, 0, dir.x) * line_width
		
		# Create rectangle for this edge
		verts.append(p1 - perp)
		verts.append(p1 + perp)
		verts.append(p2 + perp)
		colors.append(color)
		colors.append(color)
		colors.append(color)
		
		verts.append(p1 - perp)
		verts.append(p2 + perp)
		verts.append(p2 - perp)
		colors.append(color)
		colors.append(color)
		colors.append(color)

func add_x_mark(verts: PackedVector3Array, colors: PackedColorArray,
		center: Vector3, half_size: float, color: Color, line_width: float = 0.15):
	# Draw X using two diagonal lines
	var offset = half_size * 0.7  # Make X slightly smaller than cell
	
	# Diagonal 1: top-left to bottom-right
	var d1_start = Vector3(center.x - offset, center.y, center.z - offset)
	var d1_end = Vector3(center.x + offset, center.y, center.z + offset)
	draw_thick_line(verts, colors, d1_start, d1_end, color, line_width)
	
	# Diagonal 2: top-right to bottom-left
	var d2_start = Vector3(center.x + offset, center.y, center.z - offset)
	var d2_end = Vector3(center.x - offset, center.y, center.z + offset)
	draw_thick_line(verts, colors, d2_start, d2_end, color, line_width)

func draw_thick_line(verts: PackedVector3Array, colors: PackedColorArray,
		start: Vector3, end: Vector3, color: Color, width: float):
	var dir = (end - start).normalized()
	var perp = Vector3(-dir.z, 0, dir.x) * width
	
	# Create rectangle for the line
	verts.append(start - perp)
	verts.append(start + perp)
	verts.append(end + perp)
	colors.append(color)
	colors.append(color)
	colors.append(color)
	
	verts.append(start - perp)
	verts.append(end + perp)
	verts.append(end - perp)
	colors.append(color)
	colors.append(color)
	colors.append(color)

# =========================
# DEBUG VISUALIZATION
# =========================
func draw_grid_visualization():
	if is_instance_valid(grid_mesh_instance):
		grid_mesh_instance.queue_free()

	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var half = grid_size * 0.5

	for cell in grid.keys():
		var world_pos = grid_to_world(cell)
		
		# For unwalkable cells, do a fresh raycast to get proper height
		if not grid[cell]:
			var center_x = cell.x * grid_size + grid_size * 0.5
			var center_z = cell.y * grid_size + grid_size * 0.5
			var from = Vector3(center_x, 50, center_z)
			var to = Vector3(center_x, -50, center_z)
			
			# Try floor first
			var params = PhysicsRayQueryParameters3D.create(from, to)
			params.collision_mask = 1
			var hit = get_world_3d().direct_space_state.intersect_ray(params)
			
			# If no floor, try obstacle
			if hit.is_empty():
				params.collision_mask = 2
				hit = get_world_3d().direct_space_state.intersect_ray(params)
			
			# Use hit position or default to ground level
			if not hit.is_empty() and hit.has("position"):
				world_pos = hit["position"]
			else:
				world_pos.y = 0
		
		var y_offset = world_pos.y + 0.05  # slightly above surface
		var center_pos = Vector3(world_pos.x, y_offset, world_pos.z)
		
		if grid[cell]:
			# Walkable = Green hollow square
			add_hollow_square(verts, colors, center_pos, half, Color(0, 1, 0, 0.8), 0.1)
		else:
			# Not walkable = Red square with X
			add_hollow_square(verts, colors, center_pos, half, Color(1, 0, 0, 0.8), 0.1)
			add_x_mark(verts, colors, center_pos, half, Color(1, 0, 0, 0.8), 0.15)

	if verts.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = colors

		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

		grid_mesh_instance = MeshInstance3D.new()
		grid_mesh_instance.mesh = mesh

		# Unshaded material to see vertex colors
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		grid_mesh_instance.material_override = mat

		grid_mesh_instance.visible = debug_visible
		add_child(grid_mesh_instance)

# =========================
# PATH VISUALIZATION (FOR NPCs)
# =========================
func draw_path_visualization(path: Array, current_index: int = 0):
	"""Draw a path on the grid. Called by NPCs to show their pathfinding route."""
	clear_path_visualization()
	
	if path.size() == 0:
		return
	
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	
	# Draw path from current waypoint onwards
	for i in range(current_index, path.size()):
		var cell = path[i]
		var world_pos = grid_to_world(cell)
		var y_offset = world_pos.y + 0.15  # Above grid
		var half = 0.3  # Smaller than grid cells
		
		# Color gradient: yellow to cyan along path
		var t = float(i - current_index) / max(1, path.size() - current_index - 1)
		var color = Color(1 - t, 1, t, 0.9)  # Yellow -> Cyan
		
		# Draw diamond shape for each waypoint
		add_diamond(verts, colors, Vector3(world_pos.x, y_offset, world_pos.z), half, color)
	
	# Draw lines connecting waypoints
	for i in range(current_index, path.size() - 1):
		var cell1 = path[i]
		var cell2 = path[i + 1]
		var pos1 = grid_to_world(cell1)
		var pos2 = grid_to_world(cell2)
		pos1.y += 0.15
		pos2.y += 0.15
		draw_line_3d(verts, colors, pos1, pos2, Color(1, 1, 0, 0.8), 0.1)
	
	if verts.size() > 0:
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = colors
		
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		
		path_mesh_instance = MeshInstance3D.new()
		path_mesh_instance.mesh = mesh
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		path_mesh_instance.material_override = mat
		path_mesh_instance.visible = debug_visible  # Respect debug visibility
		add_child(path_mesh_instance)

func clear_path_visualization():
	"""Clear the path visualization."""
	if is_instance_valid(path_mesh_instance):
		path_mesh_instance.queue_free()
		path_mesh_instance = null

func add_diamond(verts: PackedVector3Array, colors: PackedColorArray, center: Vector3, size: float, color: Color):
	# Create diamond shape (4 triangles)
	var top = center + Vector3(0, 0, -size)
	var right = center + Vector3(size, 0, 0)
	var bottom = center + Vector3(0, 0, size)
	var left = center + Vector3(-size, 0, 0)
	
	# Top triangle
	verts.append(center); verts.append(top); verts.append(right)
	colors.append(color); colors.append(color); colors.append(color)
	# Right triangle
	verts.append(center); verts.append(right); verts.append(bottom)
	colors.append(color); colors.append(color); colors.append(color)
	# Bottom triangle
	verts.append(center); verts.append(bottom); verts.append(left)
	colors.append(color); colors.append(color); colors.append(color)
	# Left triangle
	verts.append(center); verts.append(left); verts.append(top)
	colors.append(color); colors.append(color); colors.append(color)

func draw_line_3d(verts: PackedVector3Array, colors: PackedColorArray, start: Vector3, end: Vector3, color: Color, width: float):
	var dir = (end - start).normalized()
	var perp = Vector3(-dir.z, 0, dir.x) * width
	
	verts.append(start - perp); verts.append(start + perp); verts.append(end + perp)
	colors.append(color); colors.append(color); colors.append(color)
	
	verts.append(start - perp); verts.append(end + perp); verts.append(end - perp)
	colors.append(color); colors.append(color); colors.append(color)


# =========================
# MAZE GENERATION
# =========================
@export var maze_width: int = 51
@export var maze_height: int = 51
@export var maze_cell_size: float = 2.0
@export var maze_wall_height: float = 6.0

var maze: Array = []
var parent: Dictionary = {}

func generate_maze():
	var w = maze_width | 1
	var h = maze_height | 1

	# Initialize maze grid (true = wall, false = passage)
	maze.clear()
	for x in range(w):
		var row = []
		for y in range(h):
			row.append(true)
		maze.append(row)

	# Initialize disjoint sets
	parent.clear()
	for x in range(1, w, 2):
		for y in range(1, h, 2):
			var key = Vector2(x, y)
			parent[key] = key
			maze[x][y] = false  # mark cell as passage

	# Create wall list between adjacent cells
	var walls = []
	for x in range(1, w, 2):
		for y in range(1, h, 2):
			if x + 2 < w:
				walls.append([Vector2(x, y), Vector2(x + 2, y), Vector2(x + 1, y)])  # horizontal wall
			if y + 2 < h:
				walls.append([Vector2(x, y), Vector2(x, y + 2), Vector2(x, y + 1)])  # vertical wall

	walls.shuffle()

	# Process walls
	for wall in walls:
		var cell1 = wall[0]
		var cell2 = wall[1]
		var between = wall[2]

		if find(cell1) != find(cell2):
			maze[int(between.x)][int(between.y)] = false
			union(cell1, cell2)

	# Build walls
	for x in range(w):
		for y in range(h):
			if maze[x][y]:
				var pos = Vector3(x * maze_cell_size, 0, y * maze_cell_size)
				create_wall(pos)

func find(cell: Vector2) -> Vector2:
	while parent[cell] != cell:
		cell = parent[cell]
	return cell

func union(a: Vector2, b: Vector2):
	var root_a = find(a)
	var root_b = find(b)
	parent[root_b] = root_a

func create_wall(pos: Vector3):
	var wall_body := StaticBody3D.new()
	wall_body.position = pos + Vector3(maze_cell_size * 0.5, 0, maze_cell_size * 0.5)
	add_child(wall_body)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maze_cell_size, maze_wall_height, maze_cell_size)
	shape.shape = box
	wall_body.add_child(shape)

	var csg := CSGBox3D.new()
	csg.size = box.size
	csg.position = Vector3(0, maze_wall_height * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.645, 0.391, 0.641, 1.0)
	csg.material = mat
	wall_body.add_child(csg)
	
	print("Wall at:", wall_body.position)
