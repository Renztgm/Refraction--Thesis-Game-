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

	# --- Stuck detection ---
	var moved_distance = global_position.distance_to(last_position)
	var is_trying_to_move = velocity.length() > 0.1
	
	if moved_distance < 0.1 and is_trying_to_move and current_state == NPCState.GOING_TO_BOOKSTORE:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("⚠️ NPC STUCK at world: ", global_position)
			print("⚠️ Recalculating path...")
			go_to_bookstore()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		
	last_position = global_position

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
	
	var reach_threshold = grid_system.grid_size * 0.8
	if distance < reach_threshold:
		path_index += 1
		update_route_visualization()
		return

	dir = dir.normalized()

	# ✅ Only apply wall avoidance while moving
	if is_wall_ahead():
		dir = choose_alternate_direction()

	velocity = dir * speed
	move_and_slide()
	
	if dir.length() > 0:
		look_at(global_position + dir, Vector3.UP)

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
		var wp: Array[Vector3] = [ grid_system.grid_to_world(target_grid) ]
		var gp: Array[Vector2]  = [ target_grid ]
		return {"world_path": wp, "grid_path": gp}

	
	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start_grid, grid_system.grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)

	var iterations = 0
	var max_iterations = 5000  # Increased for larger grid
	
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

			var dx = abs(neighbor_pos.x - current.pos.x)
			var dy = abs(neighbor_pos.y - current.pos.y)
			var move_cost = 14 if dx == 1 and dy == 1 else 10  # diagonal = 14, straight = 10
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
	var empty_world: Array[Vector3] = []
	var empty_grid: Array[Vector2] = []
	return {"world_path": empty_world, "grid_path": empty_grid}



# Get valid neighbors (8-directional movement)
func get_valid_neighbors(pos: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	var directions = [
		Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0),
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	for dir in directions:
		var neighbor = pos + dir
		if grid_system.is_valid_cell(neighbor) and grid_system.is_walkable(neighbor):
			neighbors.append(neighbor)
	return neighbors

# Octile distance heuristic (better for 8-directional grids)
func heuristic(a: Vector2, b: Vector2) -> float:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	return 10 * (dx + dy) + (4 * min(dx, dy))  # same as 14 * diagonal + 10 * straight


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
