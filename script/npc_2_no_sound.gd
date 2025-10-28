extends CharacterBody3D
# Attach this to your NPC (Npc2)

# =========================
# CONFIG
# =========================
@export var move_speed: float = 3.0
@export var acceleration: float = 10.0  # Smooth acceleration
@export var rotation_speed: float = 8.0  # Smooth rotation
@export var path_update_rate: float = 0.5  # Update path every 0.5 seconds
@export var stop_distance: float = 2.0  # Stop when this close to player
@export var waypoint_reach_distance: float = 1.0  # Distance to consider waypoint reached
@export var show_path_debug: bool = true  # Show path visualization

# =========================
# REFERENCES
# =========================
@onready var grid_system = $"../NavigationRegion3D"  # Adjust path to your grid system
@onready var player = $"../Structures/Building/Bookstore/BookstoreMarker"
@onready var companion_sprite: AnimatedSprite3D = $CompanionSprite

# =========================
# PATHFINDING
# =========================
var current_path: Array = []  # Array of Vector2 grid cells
var current_waypoint_index: int = 0
var path_update_timer: float = 0.0
var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO

# =========================
# A* ALGORITHM
# =========================
class AStarNode:
	var cell: Vector2
	var g_cost: float = 0.0  # Distance from start
	var h_cost: float = 0.0  # Heuristic distance to end
	var f_cost: float = 0.0  # Total cost (g + h)
	var parent: AStarNode = null
	
	func _init(p_cell: Vector2):
		cell = p_cell
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

func heuristic(from: Vector2, to: Vector2) -> float:
	# Euclidean distance for better diagonal movement
	var dx = to.x - from.x
	var dy = to.y - from.y
	return sqrt(dx * dx + dy * dy)

func get_neighbors(cell: Vector2) -> Array:
	var neighbors = []
	var directions = [
		Vector2(1, 0),   # Right
		Vector2(-1, 0),  # Left
		Vector2(0, 1),   # Down
		Vector2(0, -1),  # Up
		Vector2(1, 1),   # Diagonal: Down-Right
		Vector2(-1, 1),  # Diagonal: Down-Left
		Vector2(1, -1),  # Diagonal: Up-Right
		Vector2(-1, -1)  # Diagonal: Up-Left
	]
	
	for dir in directions:
		var neighbor = cell + dir
		if grid_system.is_walkable(neighbor):
			# For diagonal movement, check if both adjacent cells are walkable
			var is_diagonal = abs(dir.x) + abs(dir.y) > 1
			if is_diagonal:
				var check1 = cell + Vector2(dir.x, 0)
				var check2 = cell + Vector2(0, dir.y)
				if grid_system.is_walkable(check1) and grid_system.is_walkable(check2):
					neighbors.append(neighbor)
			else:
				neighbors.append(neighbor)
	
	return neighbors

func find_path(start_cell: Vector2, end_cell: Vector2) -> Array:
	if not grid_system.is_walkable(start_cell) or not grid_system.is_walkable(end_cell):
		return []
	
	var open_list: Array = []
	var closed_list: Dictionary = {}  # Vector2 -> bool
	var all_nodes: Dictionary = {}  # Vector2 -> AStarNode
	
	# Create start node
	var start_node = AStarNode.new(start_cell)
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_cell, end_cell)
	start_node.calculate_f_cost()
	open_list.append(start_node)
	all_nodes[start_cell] = start_node
	
	var iterations = 0
	var max_iterations = 1000  # Prevent infinite loops
	
	while open_list.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		# Find node with lowest f_cost
		var current_node: AStarNode = open_list[0]
		var current_index = 0
		
		for i in range(1, open_list.size()):
			if open_list[i].f_cost < current_node.f_cost:
				current_node = open_list[i]
				current_index = i
		
		# Remove current from open list
		open_list.remove_at(current_index)
		closed_list[current_node.cell] = true
		
		# Check if we reached the goal
		if current_node.cell == end_cell:
			return reconstruct_path(current_node)
		
		# Check neighbors
		for neighbor_cell in get_neighbors(current_node.cell):
			if closed_list.has(neighbor_cell):
				continue
			
			# Calculate movement cost (diagonal = 1.414, straight = 1)
			var is_diagonal = abs(neighbor_cell.x - current_node.cell.x) + abs(neighbor_cell.y - current_node.cell.y) > 1
			var movement_cost = 1.414 if is_diagonal else 1.0
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			# Get or create neighbor node
			var neighbor_node: AStarNode
			if all_nodes.has(neighbor_cell):
				neighbor_node = all_nodes[neighbor_cell]
			else:
				neighbor_node = AStarNode.new(neighbor_cell)
				neighbor_node.h_cost = heuristic(neighbor_cell, end_cell)
				all_nodes[neighbor_cell] = neighbor_node
			
			# Check if this path is better
			var is_in_open = open_list.has(neighbor_node)
			if tentative_g_cost < neighbor_node.g_cost or not is_in_open:
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.parent = current_node
				neighbor_node.calculate_f_cost()
				
				if not is_in_open:
					open_list.append(neighbor_node)
	
	# No path found
	return []

func reconstruct_path(end_node: AStarNode) -> Array:
	var path = []
	var current = end_node
	
	while current != null:
		path.insert(0, current.cell)
		current = current.parent
	
	return path

# =========================
# MOVEMENT
# =========================
func _ready():
	if not is_instance_valid(grid_system):
		push_error("Grid system not found! Check the path.")
	if not is_instance_valid(player):
		push_error("Player not found! Check the path.")
	last_position = global_position

func _physics_process(delta):
	if not is_instance_valid(grid_system) or not is_instance_valid(player):
		return
	
	# Check if stuck
	check_if_stuck(delta)
	
	# Update path periodically
	path_update_timer -= delta
	if path_update_timer <= 0:
		path_update_timer = path_update_rate
		update_path()
	
	# Follow path
	if current_path.size() > 0:
		follow_path(delta)
	else:
		# No path, slow down smoothly
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1  # Small downward force to stay grounded
	
	move_and_slide()
	update_animation()


func update_animation():
	var movement = Vector2(velocity.x, velocity.z)
	
	if movement.length() < 0.1:
		companion_sprite.play("idle")
		return
	
	var angle = atan2(movement.y, movement.x)
	
	if angle > -PI/4 and angle <= PI/4:
		companion_sprite.play("walk_right")
	elif angle > PI/4 and angle <= 3*PI/4:
		companion_sprite.play("walk_backward")
	elif angle <= -PI/4 and angle > -3*PI/4:
		companion_sprite.play("walk_forward")
	else:
		companion_sprite.play("walk_left")


func check_if_stuck(delta):
	var moved_distance = global_position.distance_to(last_position)
	
	if moved_distance < 0.1 and current_path.size() > 0:
		stuck_timer += delta
		if stuck_timer > 2.0:  # Stuck for 2 seconds
			print("🚫 NPC appears stuck, forcing path recalculation")
			current_path.clear()
			path_update_timer = 0.0  # Force immediate path update
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func update_path():
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Don't pathfind if already close enough
	if distance_to_player <= stop_distance:
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()
		return
	
	# Get grid cells
	var start_cell = grid_system.world_to_grid(global_position)
	var end_cell = grid_system.world_to_grid(player.global_position)
	
	# Skip if we're on the same cell as player
	if start_cell == end_cell:
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()
		return
	
	# Find path
	var new_path = find_path(start_cell, end_cell)
	
	if new_path.size() > 0:
		current_path = new_path
		current_waypoint_index = 0
		
		# Skip first waypoint if we're already close to it
		if current_path.size() > 1:
			var first_waypoint = grid_system.grid_to_world(current_path[0])
			if global_position.distance_to(first_waypoint) < waypoint_reach_distance:
				current_waypoint_index = 1
		
		# Update path visualization
		if show_path_debug and is_instance_valid(grid_system):
			grid_system.draw_path_visualization(current_path, current_waypoint_index)
	else:
		print("⚠️ No path found from NPC to Player")
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()

func follow_path(delta):
	if current_waypoint_index >= current_path.size():
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()
		return
	
	# Get target waypoint
	var target_cell = current_path[current_waypoint_index]
	var target_pos = grid_system.grid_to_world(target_cell)
	
	# Move towards waypoint (only XZ plane)
	var to_target = target_pos - global_position
	to_target.y = 0  # Ignore vertical difference
	var distance_to_waypoint = to_target.length()
	
	# Check if reached waypoint
	if distance_to_waypoint <= waypoint_reach_distance:
		current_waypoint_index += 1
		if show_path_debug and is_instance_valid(grid_system):
			grid_system.draw_path_visualization(current_path, current_waypoint_index)
		return
	
	var direction = to_target.normalized()
	
	# Smooth acceleration
	var target_velocity_x = direction.x * move_speed
	var target_velocity_z = direction.z * move_speed
	velocity.x = lerp(velocity.x, target_velocity_x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity_z, acceleration * delta)
	
	# Smooth rotation towards movement direction
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		var current_rotation = rotation.y
		rotation.y = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
