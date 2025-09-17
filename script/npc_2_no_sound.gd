extends CharacterBody3D

# --- Settings ---
@export var speed: float = 5.0
@export var idle_threshold: float = 0.1

# --- Grid Reference ---
@onready var grid_system: Node3D = $"../Grid"
@onready var bookstore_marker: Node3D = $"../Structures/Building/Bookstore/BookstoreMarker"


var bookstore_position: Vector3
var current_path: Array[Vector3] = []
var current_grid_path: Array[Vector2] = []  # Path in grid coordinates
var path_index: int = 0

# --- Stuck detection ---
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_timeout: float = 2.0

# --- States ---
enum NPCState { GOING_TO_BOOKSTORE, IDLE_WAITING }
var current_state = NPCState.GOING_TO_BOOKSTORE

@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight
@onready var ray_back: RayCast3D = $RayBack

# --- Pathfinding Node Class ---
class PathNode:
	var pos: Vector2
	var world_pos: Vector3
	var g_cost: float
	var h_cost: float
	var f_cost: float
	var parent: PathNode = null
	
	func _init(pos: Vector2, world_pos: Vector3):
		self.pos = pos
		self.world_pos = world_pos
		self.g_cost = 0
		self.h_cost = 0
		self.f_cost = 0
	
	func calculate_f():
		f_cost = g_cost + h_cost

# --- Ready (Improved with better debugging and plane support) ---
func _ready():
	print("🚀 NPC INITIALIZING...")
	
	if not grid_system:
		print("❌ ERROR: No grid_system assigned! Drag enhanced Grid node to NPC's grid_system property")
		return
	
	if not bookstore_marker:
		print("❌ ERROR: No bookstore_marker assigned!")
		return
	
	# Wait for everything to be ready
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for safety
	
	# Get bookstore position
	bookstore_position = bookstore_marker.global_position
	print("📍 Bookstore at world: ", bookstore_position)
	
	# IMPORTANT: Adjust grid for 200x200 plane
	var plane_size = 200.0
	var needed_grid_size = int(plane_size / grid_system.grid_size) + 10  # +10 for margin
	
	print("🔧 Adjusting grid for 200x200 plane...")
	print("   Current grid dimensions: ", grid_system.grid_dimensions)
	print("   Recommended dimensions: ", Vector2i(needed_grid_size, needed_grid_size))
	
	# Set larger grid dimensions to cover the plane
	if grid_system.grid_dimensions.x < needed_grid_size:
		grid_system.grid_dimensions = Vector2i(needed_grid_size, needed_grid_size)
		grid_system.force_rebuild()
		print("✅ Grid rebuilt to cover plane")
	
	# Auto-adjust grid to include bookstore
	grid_system.auto_adjust_for_target(bookstore_position)
	
	# Debug current state
	debug_movement_issues()
	
	# Try to go to bookstore
	last_position = global_position
	go_to_bookstore()
	
	print("🏁 NPC initialization complete!")

# --- Physics Process ---
func _physics_process(delta: float):
	if not grid_system:
		return
		
	update_state()
	match current_state:
		NPCState.GOING_TO_BOOKSTORE:
			follow_path()
		NPCState.IDLE_WAITING:
			idle_behavior()

	# Stuck detection with better logic
	var moved_distance = global_position.distance_to(last_position)
	var is_trying_to_move = velocity.length() > 0.1
	
	if moved_distance < 0.1 and is_trying_to_move:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("⚠️ NPC STUCK at world: ", global_position)
			print("⚠️ Current grid cell: ", grid_system.world_to_grid(global_position))
			print("⚠️ Is current cell walkable: ", grid_system.is_walkable(grid_system.world_to_grid(global_position)))
			
			if current_state == NPCState.GOING_TO_BOOKSTORE:
				print("🔄 Recalculating path from stuck position...")
				go_to_bookstore()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		
	last_position = global_position
	
	var move_dir: Vector3 = Vector3.ZERO

	if is_wall_ahead():
		move_dir = choose_alternate_direction()
	else:
		move_dir = -transform.basis.z  # local forward

	if move_dir != Vector3.ZERO:
		velocity = move_dir.normalized() * speed
	else:
		velocity = Vector3.ZERO  # stuck case

	move_and_slide()

# --- State Update ---
func update_state():
	match current_state:
		NPCState.GOING_TO_BOOKSTORE:
			if current_path.is_empty() or path_index >= current_path.size():
				current_state = NPCState.IDLE_WAITING
				print("✅ Reached bookstore! Switching to idle state")
				# Clear the route visualization when reached
				grid_system.clear_route()

# --- Movement (Improved with better debugging) ---
func follow_path():
	if current_path.is_empty() or path_index >= current_path.size():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target = current_path[path_index]
	var dir = (target - global_position)
	var distance = dir.length()
	
	# Use a more generous threshold based on grid size
	var reach_threshold = grid_system.grid_size * 0.8
	if distance < reach_threshold:
		path_index += 1
		print("📍 Reached waypoint ", path_index - 1, "/", current_path.size() - 1, " (distance: ", distance, ")")
		
		# Update route visualization to show remaining path
		update_route_visualization()
		return

	# Normalize direction and apply speed
	dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	
	# Face movement direction
	if dir.length() > 0:
		look_at(global_position + dir, Vector3.UP)
	
	# Debug current movement (less frequent to avoid spam)
	if path_index < current_path.size():
		var current_grid_pos = grid_system.world_to_grid(global_position)
		var target_grid_pos = grid_system.world_to_grid(target)
		if randf() < 0.01:  # Print occasionally to avoid spam
			print("🚶 Moving to waypoint ", path_index, ": grid ", target_grid_pos, " | current: ", current_grid_pos, " | dist: ", distance, " | speed: ", speed)

func idle_behavior():
	velocity = Vector3.ZERO
	move_and_slide()

# --- Path Updates (Improved with better validation) ---
func go_to_bookstore():
	if not grid_system or not bookstore_marker:
		print("❌ Missing grid_system or bookstore_marker!")
		return
		
	print("🎯 Calculating path to bookstore...")
	print("   From: ", global_position, " -> ", grid_system.world_to_grid(global_position))
	print("   To: ", bookstore_position, " -> ", grid_system.world_to_grid(bookstore_position))
	
	# Ensure both positions are valid
	var start_grid = grid_system.world_to_grid(global_position)
	var target_grid = grid_system.world_to_grid(bookstore_position)
	
	if not grid_system.is_valid_cell(start_grid):
		print("⚠️ Start position outside grid bounds!")
		print("   Grid bounds: ", grid_system.get_grid_info().world_bounds)
		print("   NPC position: ", global_position)
		return
		
	if not grid_system.is_valid_cell(target_grid):
		print("⚠️ Target position outside grid bounds!")
		print("   Grid bounds: ", grid_system.get_grid_info().world_bounds)
		print("   Bookstore position: ", bookstore_position)
		return
	
	var path_result = find_path(global_position, bookstore_position)
	current_path = path_result.world_path
	current_grid_path = path_result.grid_path
	path_index = 0
	current_state = NPCState.GOING_TO_BOOKSTORE
	
	if current_path.size() > 0:
		print("✅ Path found with ", current_path.size(), " waypoints")
		print("   First waypoint: ", current_path[0])
		print("   Last waypoint: ", current_path[-1])
		# Show the complete route on the grid
		grid_system.set_route(current_grid_path)
	else:
		print("❌ No path found to bookstore!")
		print("   This usually means:")
		print("   - Start or end position is blocked")
		print("   - No walkable connection exists")
		print("   - Grid is too small to contain both positions")
		grid_system.clear_route()

func update_route_visualization():
	"""Update the route visualization to show remaining path"""
	if path_index < current_grid_path.size():
		var remaining_route = current_grid_path.slice(path_index)
		grid_system.set_route(remaining_route)

# --- Enhanced A* Pathfinding ---
func find_path(start: Vector3, target: Vector3) -> Dictionary:
	var start_grid = grid_system.world_to_grid(start)
	var target_grid = grid_system.world_to_grid(target)
	
	print("🔍 Pathfinding from grid ", start_grid, " to ", target_grid)
	
	# Find nearest walkable cells if start/target are blocked
	if not grid_system.is_walkable(start_grid):
		var original_start = start_grid
		start_grid = grid_system.find_nearest_walkable(start_grid)
		print("⚠️ Start ", original_start, " not walkable, using nearest: ", start_grid)
	
	if not grid_system.is_walkable(target_grid):
		var original_target = target_grid
		target_grid = grid_system.find_nearest_walkable(target_grid)
		print("⚠️ Target ", original_target, " not walkable, using nearest: ", target_grid)
	
	# Check if start and target are the same
	if start_grid == target_grid:
		print("✅ Start and target are the same cell!")
		return {
			"world_path": [grid_system.grid_to_world(target_grid)],
			"grid_path": [target_grid]
		}
	
	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start_grid, grid_system.grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)

	var iterations = 0
	var max_iterations = 500  # Increased for larger grid
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		# Pick lowest f_cost
		open_set.sort_custom(func(a, b): return a.f_cost < b.f_cost)
		var current: PathNode = open_set[0]
		open_set.remove_at(0)
		closed_set[current.pos] = current

		# Found target!
		if current.pos == target_grid:
			print("🎯 Path found in ", iterations, " iterations")
			var path_result = reconstruct_path(current)
			print("📊 Path stats: ", path_result.grid_path.size(), " cells, ", path_result.world_path.size(), " waypoints")
			return path_result

		# Check all neighbors (4-directional movement only for simplicity)
		var neighbors = get_valid_neighbors(current.pos)
		for neighbor_pos in neighbors:
			if closed_set.has(neighbor_pos):
				continue

			var move_cost = 10
			var tentative_g = current.g_cost + move_cost
			var neighbor_world = grid_system.grid_to_world(neighbor_pos)

			# Find if neighbor is already in open set
			var neighbor_node: PathNode = null
			for n in open_set:
				if n.pos == neighbor_pos:
					neighbor_node = n
					break

			# Add new node or update existing one
			if neighbor_node == null:
				neighbor_node = PathNode.new(neighbor_pos, neighbor_world)
				neighbor_node.g_cost = tentative_g
				neighbor_node.h_cost = heuristic(neighbor_pos, target_grid)
				neighbor_node.parent = current
				neighbor_node.calculate_f()
				open_set.append(neighbor_node)
			elif tentative_g < neighbor_node.g_cost:
				neighbor_node.g_cost = tentative_g
				neighbor_node.parent = current
				neighbor_node.calculate_f()

	print("❌ No path found after ", iterations, " iterations")
	return {"world_path": [], "grid_path": []}

# Get valid neighbors (4-directional only)
func get_valid_neighbors(pos: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	var directions = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]  # N, E, S, W
	
	for dir in directions:
		var neighbor = pos + dir
		if grid_system.is_valid_cell(neighbor) and grid_system.is_walkable(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

# Manhattan distance heuristic
func heuristic(a: Vector2, b: Vector2) -> float:
	var dx = abs(a.x - b.x)
	var dz = abs(a.y - b.y)
	return (dx + dz) * 10

func reconstruct_path(node: PathNode) -> Dictionary:
	var world_path: Array[Vector3] = []
	var grid_path: Array[Vector2] = []
	var current = node
	
	while current != null:
		world_path.append(current.world_pos)
		grid_path.append(current.pos)
		current = current.parent
	
	world_path.reverse()
	grid_path.reverse()
	
	# Validate path for duplicates (debug check)
	var unique_cells = {}
	var duplicates = 0
	for cell in grid_path:
		if unique_cells.has(cell):
			duplicates += 1
		unique_cells[cell] = true
	
	if duplicates > 0:
		print("⚠️ Path contains ", duplicates, " duplicate cells - pathfinding may have issues")
	
	return {
		"world_path": world_path,
		"grid_path": grid_path
	}

# --- COMPREHENSIVE DEBUG METHOD ---
func debug_movement_issues():
	"""Comprehensive debug method to identify why NPC isn't moving"""
	print("=== NPC MOVEMENT DEBUG ===")
	
	# 1. Check basic setup
	print("🔧 BASIC SETUP:")
	print("  - NPC position: ", global_position)
	print("  - Speed: ", speed)
	print("  - Grid system exists: ", grid_system != null)
	print("  - Bookstore marker exists: ", bookstore_marker != null)
	
	if not grid_system:
		print("❌ CRITICAL: Grid system is null!")
		return
		
	if not bookstore_marker:
		print("❌ CRITICAL: Bookstore marker is null!")
		return
	
	# 2. Check grid dimensions and scale
	print("\n📐 GRID ANALYSIS:")
	var grid_info = grid_system.get_grid_info()
	print("  - Grid dimensions: ", grid_info.dimensions)
	print("  - Grid size (cell size): ", grid_info.grid_size)
	print("  - Total cells: ", grid_info.total_cells)
	print("  - Walkable cells: ", grid_info.walkable_cells)
	print("  - World bounds: ", grid_info.world_bounds)
	
	# 3. Check if plane size matches grid coverage
	var plane_size = 200.0  # Your plane is 200x200
	var grid_coverage_x = grid_info.dimensions.x * grid_info.grid_size
	var grid_coverage_z = grid_info.dimensions.y * grid_info.grid_size
	
	print("\n🌍 SCALE COMPARISON:")
	print("  - Plane size: 200x200")
	print("  - Grid coverage: ", grid_coverage_x, "x", grid_coverage_z)
	
	if grid_coverage_x < plane_size or grid_coverage_z < plane_size:
		print("⚠️ WARNING: Grid doesn't cover entire plane!")
		print("   Recommended grid dimensions: ", int(plane_size / grid_info.grid_size), "x", int(plane_size / grid_info.grid_size))
	
	# 4. Check positions in grid coordinates
	print("\n📍 POSITION ANALYSIS:")
	var npc_grid = grid_system.world_to_grid(global_position)
	var bookstore_grid = grid_system.world_to_grid(bookstore_position)
	
	print("  - NPC world pos: ", global_position)
	print("  - NPC grid pos: ", npc_grid)
	print("  - NPC cell walkable: ", grid_system.is_walkable(npc_grid))
	print("  - NPC cell valid: ", grid_system.is_valid_cell(npc_grid))
	
	print("  - Bookstore world pos: ", bookstore_position)
	print("  - Bookstore grid pos: ", bookstore_grid)
	print("  - Bookstore cell walkable: ", grid_system.is_walkable(bookstore_grid))
	print("  - Bookstore cell valid: ", grid_system.is_valid_cell(bookstore_grid))
	
	# 5. Check path status
	print("\n🛤️ PATH ANALYSIS:")
	print("  - Current state: ", NPCState.keys()[current_state])
	print("  - Path waypoints: ", current_path.size())
	print("  - Current waypoint index: ", path_index)
	print("  - Grid path length: ", current_grid_path.size())
	
	if current_path.size() > 0:
		print("  - Next waypoint: ", current_path[min(path_index, current_path.size()-1)] if path_index < current_path.size() else "NONE")
		print("  - Distance to next: ", global_position.distance_to(current_path[min(path_index, current_path.size()-1)]) if path_index < current_path.size() else "N/A")
	
	# 6. Test pathfinding right now
	print("\n🔍 PATHFINDING TEST:")
	if grid_system.is_valid_cell(npc_grid) and grid_system.is_valid_cell(bookstore_grid):
		var test_path = find_path(global_position, bookstore_position)
		print("  - Test path found: ", test_path.world_path.size() > 0)
		print("  - Test path waypoints: ", test_path.world_path.size())
		print("  - Test grid path: ", test_path.grid_path.size())
		
		if test_path.world_path.size() == 0:
			print("❌ PATHFINDING FAILED - No path found!")
			
			# Check if start and end are too far apart
			var distance = npc_grid.distance_to(bookstore_grid)
			print("  - Grid distance: ", distance)
			
			# Try finding nearest walkable cells
			var nearest_start = grid_system.find_nearest_walkable(npc_grid)
			var nearest_end = grid_system.find_nearest_walkable(bookstore_grid)
			print("  - Nearest walkable to NPC: ", nearest_start)
			print("  - Nearest walkable to bookstore: ", nearest_end)
		else:
			print("✅ Pathfinding works - path found!")
	else:
		print("❌ Cannot test pathfinding - invalid grid positions!")
	
	# 7. Physics and velocity check
	print("\n🏃 MOVEMENT STATUS:")
	print("  - Current velocity: ", velocity)
	print("  - Velocity length: ", velocity.length())
	print("  - Is on floor: ", is_on_floor())
	print("  - Collision layers: ", collision_layer)
	print("  - Collision mask: ", collision_mask)
	
	print("========================")

# --- Public Methods for External Control ---
func set_target(world_pos: Vector3):
	"""Set a new target position for the NPC to navigate to"""
	bookstore_position = world_pos
	var path_result = find_path(global_position, world_pos)
	current_path = path_result.world_path
	current_grid_path = path_result.grid_path
	path_index = 0
	current_state = NPCState.GOING_TO_BOOKSTORE
	
	if current_grid_path.size() > 0:
		grid_system.set_route(current_grid_path)

func get_current_grid_position() -> Vector2:
	"""Get the NPC's current position in grid coordinates"""
	if grid_system:
		return grid_system.world_to_grid(global_position)
	return Vector2.ZERO

func is_at_destination() -> bool:
	"""Check if the NPC has reached its destination"""
	return current_state == NPCState.IDLE_WAITING

func get_path_info() -> Dictionary:
	"""Get information about the current path"""
	var current_grid = grid_system.world_to_grid(global_position) if grid_system else Vector2.ZERO
	var target_grid = grid_system.world_to_grid(bookstore_position) if grid_system else Vector2.ZERO
	
	return {
		"total_waypoints": current_path.size(),
		"current_waypoint": path_index,
		"remaining_waypoints": max(0, current_path.size() - path_index),
		"grid_path_length": current_grid_path.size(),
		"is_moving": current_state == NPCState.GOING_TO_BOOKSTORE,
		"current_grid_pos": current_grid,
		"target_grid_pos": target_grid,
		"current_cell_walkable": grid_system.is_walkable(current_grid) if grid_system else false,
		"target_cell_walkable": grid_system.is_walkable(target_grid) if grid_system else false
	}

# --- Debug Method ---
func print_debug_info():
	"""Print comprehensive debug information"""
	if not grid_system:
		print("❌ No grid system!")
		return
		
	var info = get_path_info()
	var grid_info = grid_system.get_grid_info()
	
	print("=== NPC DEBUG INFO ===")
	print("🌍 World position: ", global_position)
	print("📊 Grid position: ", info.current_grid_pos)
	print("🎯 Target grid: ", info.target_grid_pos)
	print("✅ Current walkable: ", info.current_cell_walkable)
	print("✅ Target walkable: ", info.target_cell_walkable)
	print("🛤️ Path waypoints: ", info.total_waypoints)
	print("📍 Current waypoint: ", info.current_waypoint)
	print("🏃 Is moving: ", info.is_moving)
	print("🔢 Grid total cells: ", grid_info.total_cells)
	print("🚶 Grid walkable: ", grid_info.walkable_cells)
	print("🚫 Grid blocked: ", grid_info.blocked_cells)
	print("====================")

# --- TEST METHOD FOR DEBUGGING ---
func test_npc_debug():
	"""Call this method from anywhere to debug the NPC"""
	debug_movement_issues()

# --- EMERGENCY FIX METHODS ---
func force_recalculate_path():
	"""Force recalculate path - useful for debugging"""
	print("🔄 FORCE RECALCULATING PATH...")
	current_path.clear()
	current_grid_path.clear()
	path_index = 0
	go_to_bookstore()

func teleport_to_walkable_cell():
	"""Emergency teleport to nearest walkable cell"""
	if not grid_system:
		return
	
	var current_grid = grid_system.world_to_grid(global_position)
	var nearest_walkable = grid_system.find_nearest_walkable(current_grid)
	var new_world_pos = grid_system.grid_to_world(nearest_walkable)
	
	print("🚀 TELEPORTING from ", global_position, " to ", new_world_pos)
	global_position = new_world_pos
	
	# Recalculate path after teleporting
	force_recalculate_path()

# --- INPUT HANDLING FOR DEBUGGING ---
func _input(event):
	"""Debug input handling"""
	if event.is_action_pressed("ui_accept"):  # Space key
		print("🔍 MANUAL DEBUG TRIGGER")
		debug_movement_issues()
	elif event.is_action_pressed("ui_select"):  # Enter key
		print("🔄 MANUAL PATH RECALCULATION")
		force_recalculate_path()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print("🚀 TELEPORT TO WALKABLE")
		teleport_to_walkable_cell()

func is_wall_ahead() -> bool:

	if ray_forward.is_colliding():
		var collider: Object = ray_forward.get_collider()
		if collider and collider is CollisionObject3D:
			# Check if collider is on Layer 2 (bit index 1)
			if collider.collision_layer & (1 << 1) != 0:
				return true
	return false
	
func choose_alternate_direction() -> Vector3:
	if not ray_left.is_colliding():
		return -transform.basis.x  # move left
	elif not ray_right.is_colliding():
		return transform.basis.x   # move right
	elif not ray_back.is_colliding():
		return -transform.basis.z  # move back
	else:
		return Vector3.ZERO  # all blocked
