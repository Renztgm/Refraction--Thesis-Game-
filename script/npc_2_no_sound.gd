extends CharacterBody3D

# --- Settings ---
@export var speed: float = 5.0
@export var idle_threshold: float = 0.1
@export var recalc_distance: float = 2.0  # Distance to start recalculating path
@export var raycast_distance: float = 2.0  # How far ahead to check for obstacles
@export var player_avoidance_radius: float = 1.5  # Distance to avoid player
@export var player_wait_timeout: float = 3.0  # How long to wait for player to move

# --- Grid Reference ---
@onready var grid_system: Node3D = $"../Grid"
@onready var bookstore_marker: Node3D = $"../Structures/Building/Bookstore/BookstoreMarker"

var bookstore_position: Vector3
var current_path: Array[Vector3] = []
var current_grid_path: Array[Vector2] = []  # Path in grid coordinates
var path_index: int = 0

# --- Stuck detection and path recalibration ---
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_timeout: float = 2.0
var path_blocked: bool = false
var recalc_timer: float = 0.0
var recalc_interval: float = 0.5  # Check for recalc every 0.5 seconds

# --- Player avoidance ---
var player_blocking: bool = false
var player_wait_timer: float = 0.0
var last_known_player_position: Vector3
var player_node: CharacterBody3D = null

# --- States ---
enum NPCState { GOING_TO_BOOKSTORE, IDLE_WAITING, RECALCULATING_PATH, WAITING_FOR_PLAYER }
var current_state = NPCState.GOING_TO_BOOKSTORE

# --- RayCast3D nodes for obstacle detection ---
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

# --- Initialization ---
func _ready():
	print("🚀 NPC INITIALIZING...")
	
	if not grid_system:
		print("❌ ERROR: No grid_system assigned! Drag enhanced Grid node to NPC's grid_system property")
		return
	
	if not bookstore_marker:
		print("❌ ERROR: No bookstore_marker assigned!")
		return
	
	# Find player node
	find_player_node()
	
	# Setup raycasts
	setup_raycasts()
	
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

func find_player_node():
	"""Find the player node in the scene"""
	# Try common player node names/paths
	var possible_paths = [
		"../Player", 
		"../CharacterBody3D", 
		"../../Player",
		"../PlayerCharacter"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is CharacterBody3D:
			player_node = node
			print("👤 Found player node: ", player_node.name)
			break
	
	if not player_node:
		print("⚠️ Player node not found! Player avoidance disabled")
		print("   Expected paths: ", possible_paths)

func setup_raycasts():
	"""Setup raycast properties for obstacle detection"""
	if ray_forward:
		ray_forward.target_position = Vector3(0, 0, -raycast_distance)
		ray_forward.collision_mask = 3  # Layer 1 (Player) + Layer 2 (Obstacles) = 3
		ray_forward.enabled = true
	
	if ray_left:
		ray_left.target_position = Vector3(-raycast_distance, 0, 0)
		ray_left.collision_mask = 3  # Layer 1 (Player) + Layer 2 (Obstacles) = 3
		ray_left.enabled = true
		
	if ray_right:
		ray_right.target_position = Vector3(raycast_distance, 0, 0)
		ray_right.collision_mask = 3  # Layer 1 (Player) + Layer 2 (Obstacles) = 3
		ray_right.enabled = true
		
	if ray_back:
		ray_back.target_position = Vector3(0, 0, raycast_distance)
		ray_back.collision_mask = 3  # Layer 1 (Player) + Layer 2 (Obstacles) = 3
		ray_back.enabled = true

# --- Physics Process ---
func _physics_process(delta: float):
	if not grid_system:
		return
		
	# Update recalculation timer
	recalc_timer += delta
		
	update_state(delta)
	match current_state:
		NPCState.GOING_TO_BOOKSTORE:
			follow_path()
		NPCState.IDLE_WAITING:
			idle_behavior()
		NPCState.RECALCULATING_PATH:
			recalculate_path()
		NPCState.WAITING_FOR_PLAYER:
			wait_for_player_behavior(delta)

	# --- Stuck detection ---
	var moved_distance = global_position.distance_to(last_position)
	var is_trying_to_move = velocity.length() > 0.1
	
	if moved_distance < 0.1 and is_trying_to_move and current_state == NPCState.GOING_TO_BOOKSTORE:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("⚠️ NPC STUCK at world: ", global_position)
			print("⚠️ Triggering path recalculation...")
			current_state = NPCState.RECALCULATING_PATH
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		
	last_position = global_position

# --- State Management ---
func update_state(delta: float):
	# Update player tracking
	if player_node:
		track_player_movement()
	
	match current_state:
		NPCState.GOING_TO_BOOKSTORE:
			# Check for player blocking first
			if is_player_blocking():
				print("👤 Player blocking path, waiting...")
				current_state = NPCState.WAITING_FOR_PLAYER
				player_wait_timer = 0.0
				velocity = Vector3.ZERO
				return
			
			# Check if we need to recalculate due to obstacles ahead
			if recalc_timer >= recalc_interval:
				if should_recalculate_path():
					print("🔄 Obstacle detected, recalculating path...")
					current_state = NPCState.RECALCULATING_PATH
				recalc_timer = 0.0
			
			# Check if we reached the destination
			if current_path.is_empty() or path_index >= current_path.size():
				current_state = NPCState.IDLE_WAITING
				print("✅ Reached bookstore! Switching to idle state")
				grid_system.clear_route()
		
		NPCState.WAITING_FOR_PLAYER:
			player_wait_timer += delta
			if not is_player_blocking():
				print("✅ Player moved, resuming path...")
				current_state = NPCState.GOING_TO_BOOKSTORE
			elif player_wait_timer > player_wait_timeout:
				print("⏰ Player wait timeout, finding alternate route...")
				current_state = NPCState.RECALCULATING_PATH

func track_player_movement():
	"""Track player movement to detect when they move away"""
	if player_node:
		var current_player_pos = player_node.global_position
		var player_moved_significantly = current_player_pos.distance_to(last_known_player_position) > 1.0
		
		if player_moved_significantly:
			last_known_player_position = current_player_pos
			# If player moved and we were waiting, resume pathfinding
			if current_state == NPCState.WAITING_FOR_PLAYER:
				print("👤 Player moved significantly, checking if path is clear...")

func is_player_blocking() -> bool:
	"""Check if the player is blocking the NPC's path"""
	if not player_node:
		return false
	
	# Check direct distance to player
	var distance_to_player = global_position.distance_to(player_node.global_position)
	if distance_to_player > player_avoidance_radius * 2:
		return false  # Player too far to be blocking
	
	# Check if player is in the direction we want to move
	if current_path.is_empty() or path_index >= current_path.size():
		return false
	
	var target = current_path[path_index]
	var direction_to_target = (target - global_position).normalized()
	var direction_to_player = (player_node.global_position - global_position).normalized()
	
	# Check if player is roughly in the direction we want to go
	var dot_product = direction_to_target.dot(direction_to_player)
	var player_in_path = dot_product > 0.7  # Player is roughly ahead
	
	# Use raycast to confirm player is actually blocking
	if player_in_path and ray_forward:
		ray_forward.target_position = to_local(global_position + direction_to_target * raycast_distance) - to_local(global_position)
		ray_forward.force_raycast_update()
		
		if ray_forward.is_colliding():
			var collider = ray_forward.get_collider()
			if collider == player_node:
				player_blocking = true
				return true
	
	player_blocking = false
	return false

func wait_for_player_behavior(delta: float):
	"""Behavior when waiting for player to move"""
	velocity = Vector3.ZERO
	move_and_slide()
	
	# Optional: Look at the player while waiting
	if player_node:
		var look_direction = (player_node.global_position - global_position).normalized()
		if look_direction.length() > 0:
			look_at(global_position + look_direction, Vector3.UP)

func should_recalculate_path() -> bool:
	"""Check if we need to recalculate the path due to obstacles"""
	if current_path.is_empty() or path_index >= current_path.size():
		return false
	
	# Don't recalculate if player is just blocking temporarily
	if player_blocking:
		return false
	
	# Check if direct path to next few waypoints is blocked
	var check_ahead = min(3, current_path.size() - path_index)  # Check next 3 waypoints
	
	for i in range(check_ahead):
		var waypoint_index = path_index + i
		if waypoint_index >= current_path.size():
			break
			
		var target_pos = current_path[waypoint_index]
		var direction_to_waypoint = (target_pos - global_position).normalized()
		
		# Update raycast direction to check toward the waypoint
		if ray_forward:
			var local_dir = to_local(global_position + direction_to_waypoint * raycast_distance) - to_local(global_position)
			ray_forward.target_position = local_dir
			ray_forward.force_raycast_update()
			
			if ray_forward.is_colliding():
				var collider = ray_forward.get_collider()
				# Skip if it's the player (handled separately)
				if collider == player_node:
					continue
					
				var distance_to_collision = ray_forward.get_collision_point().distance_to(global_position)
				var distance_to_waypoint = global_position.distance_to(target_pos)
				
				# If collision is closer than the waypoint, we need to recalculate
				if distance_to_collision < min(distance_to_waypoint, recalc_distance):
					print("🚧 Non-player collision detected ", distance_to_collision, "m ahead, waypoint at ", distance_to_waypoint, "m")
					return true
	
	return false

func recalculate_path():
	"""Recalculate the path when obstacles are detected"""
	print("🧮 Recalculating path from ", global_position, " to ", bookstore_position)
	
	# If player is blocking, temporarily mark player area as blocked for pathfinding
	var temp_blocked_cells: Array[Vector2] = []
	if player_node:
		temp_blocked_cells = temporarily_block_player_area()
	
	# Mark cells as blocked if they have obstacles detected by raycasts
	update_grid_with_raycast_data()
	
	# Find new path
	var path_result = find_path(global_position, bookstore_position)
	current_path = path_result.world_path
	current_grid_path = path_result.grid_path
	path_index = 0
	
	# Restore temporarily blocked cells
	if temp_blocked_cells.size() > 0:
		restore_temp_blocked_cells(temp_blocked_cells)
	
	if current_path.size() > 0:
		print("✅ New path calculated with ", current_path.size(), " waypoints")
		grid_system.set_route(current_grid_path)
		current_state = NPCState.GOING_TO_BOOKSTORE
	else:
		print("❌ Could not find alternative path!")
		current_state = NPCState.IDLE_WAITING
		grid_system.clear_route()

func temporarily_block_player_area() -> Array[Vector2]:
	"""Temporarily mark player area as blocked for pathfinding"""
	var blocked_cells: Array[Vector2] = []
	if not player_node:
		return blocked_cells
	
	var player_grid = grid_system.world_to_grid(player_node.global_position)
	var radius_cells = int(player_avoidance_radius / grid_system.grid_size) + 1
	
	for x in range(-radius_cells, radius_cells + 1):
		for z in range(-radius_cells, radius_cells + 1):
			var check_cell = player_grid + Vector2(x, z)
			if grid_system.is_valid_cell(check_cell) and grid_system.is_walkable(check_cell):
				# Store original state and mark as blocked
				blocked_cells.append(check_cell)
				grid_system.grid[check_cell] = false
	
	print("🚫 Temporarily blocked ", blocked_cells.size(), " cells around player")
	return blocked_cells

func restore_temp_blocked_cells(blocked_cells: Array[Vector2]):
	"""Restore temporarily blocked cells to walkable state"""
	for cell in blocked_cells:
		# Only restore if there's no actual obstacle there
		var world_pos = grid_system.grid_to_world(cell)
		if not grid_system.check_obstacle(world_pos):
			grid_system.grid[cell] = true
	
	print("✅ Restored ", blocked_cells.size(), " temporarily blocked cells")

func update_grid_with_raycast_data():
	"""Update the grid with real-time obstacle data from raycasts"""
	var rays = [ray_forward, ray_left, ray_right, ray_back]
	var ray_names = ["forward", "left", "right", "back"]
	
	for i in range(rays.size()):
		var ray = rays[i]
		if not ray:
			continue
			
		ray.force_raycast_update()
		if ray.is_colliding():
			var collider = ray.get_collider()
			# Skip player collisions (handled separately)
			if collider == player_node:
				continue
				
			var collision_point = ray.get_collision_point()
			var blocked_grid_pos = grid_system.world_to_grid(collision_point)
			
			# Mark this grid cell as blocked temporarily
			if grid_system.is_valid_cell(blocked_grid_pos):
				print("🚫 Raycast ", ray_names[i], " detected obstacle at grid ", blocked_grid_pos)
				grid_system.grid[blocked_grid_pos] = false

# --- Movement Functions ---
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
		print("📍 Reached waypoint ", path_index - 1, "/", current_path.size())
		return

	dir = dir.normalized()

	# Minecraft-style obstacle avoidance using raycasts
	var final_direction = get_safe_direction(dir)
	
	# If no safe direction found, try to recalculate path
	if final_direction == Vector3.ZERO:
		print("🛑 No safe direction found, recalculating path")
		current_state = NPCState.RECALCULATING_PATH
		return

	velocity = final_direction * speed
	move_and_slide()
	
	# Face the movement direction
	if final_direction.length() > 0:
		look_at(global_position + final_direction, Vector3.UP)

func get_safe_direction(desired_direction: Vector3) -> Vector3:
	"""Get a safe direction to move, avoiding obstacles detected by raycasts"""
	
	# First, check if the desired direction is safe
	ray_forward.target_position = to_local(global_position + desired_direction * raycast_distance) - to_local(global_position)
	ray_forward.force_raycast_update()
	
	if not ray_forward.is_colliding():
		return desired_direction
	
	# Check if collision is with player - handle differently
	var forward_collider = ray_forward.get_collider()
	if forward_collider == player_node:
		# Player is in the way, try to go around them politely
		return get_player_avoidance_direction(desired_direction)
	
	print("🚧 Path blocked ahead, seeking alternative...")
	
	# Try alternative directions (Minecraft-style pathfinding)
	var alternatives = []
	
	# Check left direction
	ray_left.force_raycast_update()
	if not ray_left.is_colliding() or ray_left.get_collider() == player_node:
		alternatives.append(-transform.basis.x)  # Left
		
	# Check right direction
	ray_right.force_raycast_update()
	if not ray_right.is_colliding() or ray_right.get_collider() == player_node:
		alternatives.append(transform.basis.x)   # Right
	
	# Check back direction (last resort)
	ray_back.force_raycast_update()
	if not ray_back.is_colliding() or ray_back.get_collider() == player_node:
		alternatives.append(-transform.basis.z)  # Back
	
	# Choose the best alternative (closest to desired direction)
	if alternatives.size() > 0:
		var best_alternative = alternatives[0]
		var best_dot = desired_direction.dot(best_alternative)
		
		for alt in alternatives:
			var dot_product = desired_direction.dot(alt)
			if dot_product > best_dot:
				best_dot = dot_product
				best_alternative = alt
		
		print("✅ Using alternative direction: ", best_alternative)
		return best_alternative
	
	# No safe direction found
	print("❌ All directions blocked!")
	return Vector3.ZERO

func get_player_avoidance_direction(desired_direction: Vector3) -> Vector3:
	"""Get direction to politely avoid the player"""
	if not player_node:
		return desired_direction
	
	var to_player = (player_node.global_position - global_position).normalized()
	var perpendicular = Vector3(-to_player.z, 0, to_player.x)  # Perpendicular to player direction
	
	# Try going around the player (left or right)
	var left_option = perpendicular
	var right_option = -perpendicular
	
	# Choose the side that keeps us closer to our desired direction
	if desired_direction.dot(left_option) > desired_direction.dot(right_option):
		return left_option
	else:
		return right_option

func idle_behavior():
	velocity = Vector3.ZERO
	move_and_slide()

# --- Pathfinding Functions ---
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
		var remaining_route: Array[Vector2] = []
		for i in range(path_index, current_grid_path.size()):
			remaining_route.append(current_grid_path[i])
		grid_system.set_route(remaining_route)

func find_path(start: Vector3, target: Vector3) -> Dictionary:
	var start_grid = grid_system.world_to_grid(start)
	var target_grid = grid_system.world_to_grid(target)
	
	print("🔍 A* Pathfinding from grid ", start_grid, " to ", target_grid)
	
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
	var open_set_lookup: Dictionary = {}  # For faster lookups

	var start_node = PathNode.new(start_grid, grid_system.grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)
	open_set_lookup[start_grid] = start_node

	var iterations = 0
	var max_iterations = 10000  # Increased for larger grids
	
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		# Get node with lowest f_cost
		var current: PathNode = open_set[0]
		var current_index = 0
		
		for i in range(1, open_set.size()):
			if open_set[i].f_cost < current.f_cost:
				current = open_set[i]
				current_index = i
		
		# Move current from open to closed set
		open_set.remove_at(current_index)
		open_set_lookup.erase(current.pos)
		closed_set[current.pos] = current

		# Found target!
		if current.pos == target_grid:
			print("🎯 A* Path found in ", iterations, " iterations")
			var path_result = reconstruct_path(current)
			print("📊 Path stats: ", path_result.grid_path.size(), " cells, ", path_result.world_path.size(), " waypoints")
			return path_result

		# Explore neighbors
		var neighbors = get_valid_neighbors(current.pos)
		for neighbor_pos in neighbors:
			if closed_set.has(neighbor_pos):
				continue

			# Calculate costs (Manhattan distance for grid-based movement)
			var dx = abs(neighbor_pos.x - current.pos.x)
			var dy = abs(neighbor_pos.y - current.pos.y)
			var move_cost = 14 if (dx == 1 and dy == 1) else 10  # diagonal = 14, straight = 10
			var tentative_g = current.g_cost + move_cost

			# Check if this neighbor is already in open set
			var neighbor_node: PathNode = open_set_lookup.get(neighbor_pos, null)
			
			if neighbor_node == null:
				# Add new node to open set
				var neighbor_world = grid_system.grid_to_world(neighbor_pos)
				neighbor_node = PathNode.new(neighbor_pos, neighbor_world)
				neighbor_node.g_cost = tentative_g
				neighbor_node.h_cost = heuristic(neighbor_pos, target_grid)
				neighbor_node.parent = current
				neighbor_node.calculate_f()
				
				open_set.append(neighbor_node)
				open_set_lookup[neighbor_pos] = neighbor_node
			elif tentative_g < neighbor_node.g_cost:
				# Update existing node with better path
				neighbor_node.g_cost = tentative_g
				neighbor_node.parent = current
				neighbor_node.calculate_f()

	print("❌ A* No path found after ", iterations, " iterations")
	var empty_world: Array[Vector3] = []
	var empty_grid: Array[Vector2] = []
	return {"world_path": empty_world, "grid_path": empty_grid}

func get_valid_neighbors(pos: Vector2) -> Array[Vector2]:
	var neighbors: Array[Vector2] = []
	var directions = [
		# Straight movements (prioritized)
		Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0),
		# Diagonal movements
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	
	for dir in directions:
		var neighbor = pos + dir
		if grid_system.is_valid_cell(neighbor) and grid_system.is_walkable(neighbor):
			# For diagonal movement, check if both straight paths are clear (Minecraft style)
			if abs(dir.x) == 1 and abs(dir.y) == 1:
				var check1 = pos + Vector2(dir.x, 0)
				var check2 = pos + Vector2(0, dir.y)
				if grid_system.is_walkable(check1) and grid_system.is_walkable(check2):
					neighbors.append(neighbor)
			else:
				neighbors.append(neighbor)
	
	return neighbors

func heuristic(a: Vector2, b: Vector2) -> float:
	var dx = abs(a.x - b.x)
	var dy = abs(a.y - b.y)
	# Use octile distance for 8-directional movement
	return 10 * max(dx, dy) + 4 * min(dx, dy)

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
	
	# Optimize path by removing unnecessary waypoints (line-of-sight optimization)
	var optimized_world = optimize_path(world_path)
	var optimized_grid: Array[Vector2] = []
	for world_pos in optimized_world:
		optimized_grid.append(grid_system.world_to_grid(world_pos))
	
	return {
		"world_path": optimized_world,
		"grid_path": optimized_grid
	}

func optimize_path(world_path: Array[Vector3]) -> Array[Vector3]:
	"""Optimize path by removing unnecessary waypoints using line-of-sight"""
	if world_path.size() <= 2:
		return world_path
	
	var optimized: Array[Vector3] = []
	optimized.append(world_path[0])  # Always keep start
	
	var current_index = 0
	while current_index < world_path.size() - 1:
		var furthest_visible = current_index + 1
		
		# Find furthest visible waypoint
		for i in range(current_index + 2, world_path.size()):
			if has_line_of_sight(world_path[current_index], world_path[i]):
				furthest_visible = i
			else:
				break
		
		optimized.append(world_path[furthest_visible])
		current_index = furthest_visible
	
	print("🔧 Path optimized: ", world_path.size(), " -> ", optimized.size(), " waypoints")
	return optimized

func has_line_of_sight(start: Vector3, end: Vector3) -> bool:
	"""Check if there's a clear line of sight between two points"""
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var check_distance = grid_system.grid_size * 0.5  # Check every half grid cell
	var steps = int(distance / check_distance)
	
	for i in range(1, steps):
		var check_point = start + direction * (i * check_distance)
		var grid_pos = grid_system.world_to_grid(check_point)
		
		if not grid_system.is_walkable(grid_pos):
			return false
	
	return true

# --- Public Interface ---
func set_target(world_pos: Vector3):
	"""Set a new target position for the NPC to navigate to"""
	bookstore_position = world_pos
	current_state = NPCState.RECALCULATING_PATH

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
		"target_cell_walkable": grid_system.is_walkable(target_grid) if grid_system else false,
		"path_blocked": path_blocked,
		"player_blocking": player_blocking,
		"player_detected": player_node != null,
		"state": NPCState.keys()[current_state]
	}

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
	print("🏃 State: ", info.state)
	print("🚧 Path blocked: ", info.path_blocked)
	print("👤 Player blocking: ", info.player_blocking)
	print("👤 Player detected: ", info.player_detected)
	if player_node:
		print("👤 Player distance: ", global_position.distance_to(player_node.global_position))
	print("🔢 Grid total cells: ", grid_info.total_cells)
	print("🚶 Grid walkable: ", grid_info.walkable_cells)
	print("🚫 Grid blocked: ", grid_info.blocked_cells)
	print("🎯 Raycast Status:")
	print("   Forward blocked: ", ray_forward.is_colliding() if ray_forward else "N/A")
	print("   Left blocked: ", ray_left.is_colliding() if ray_left else "N/A")
	print("   Right blocked: ", ray_right.is_colliding() if ray_right else "N/A")
	print("   Back blocked: ", ray_back.is_colliding() if ray_back else "N/A")
	print("====================")

# --- Player Node Management ---
func set_player_node(node: CharacterBody3D):
	"""Manually set the player node if auto-detection fails"""
	player_node = node
	if player_node:
		print("👤 Player node manually set: ", player_node.name)
		last_known_player_position = player_node.global_position

# --- Legacy Compatibility ---
func is_wall_ahead() -> bool:
	return ray_forward.is_colliding() if ray_forward else false
	
func choose_alternate_direction() -> Vector3:
	return get_safe_direction(transform.basis.z)
