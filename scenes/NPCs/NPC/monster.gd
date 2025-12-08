extends CharacterBody3D
# Attach this to your NPC (Npc2)

# =========================
# CONFIG
# =========================
@export var move_speed: float = 10.0
@export var acceleration: float = 10.0
@export var rotation_speed: float = 8.0
@export var path_update_rate: float = 0.5
@export var stop_distance: float = 2.0
@export var waypoint_reach_distance: float = 1.5  # Increased for diagonal paths
@export var show_path_debug: bool = true
@export var wall_avoidance_distance: float = 1.0  # New: detect walls ahead

# =========================
# REFERENCES
# =========================
@onready var grid_system = $"../NavigationRegion3D"
@onready var player = $"../Player3d"
@onready var companion_sprite: AnimatedSprite3D = $CompanionSprite

# =========================
# PATHFINDING
# =========================
var current_path: Array = []
var current_waypoint_index: int = 0
var path_update_timer: float = 0.0
var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var stuck_position: Vector3 = Vector3.ZERO

# =========================
# A* ALGORITHM
# =========================
class AStarNode:
	var cell: Vector2
	var g_cost: float = 0.0
	var h_cost: float = 0.0
	var f_cost: float = 0.0
	var parent: AStarNode = null
	
	func _init(p_cell: Vector2):
		cell = p_cell
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

func heuristic(from: Vector2, to: Vector2) -> float:
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
			var is_diagonal = abs(dir.x) + abs(dir.y) > 1
			if is_diagonal:
				# STRICTER diagonal check - both adjacent cells must be walkable
				var check1 = cell + Vector2(dir.x, 0)
				var check2 = cell + Vector2(0, dir.y)
				if grid_system.is_walkable(check1) and grid_system.is_walkable(check2):
					# Additional check: make sure the diagonal neighbor itself is not a corner
					var corner_check1 = neighbor + Vector2(-dir.x, 0)
					var corner_check2 = neighbor + Vector2(0, -dir.y)
					if grid_system.is_walkable(corner_check1) or grid_system.is_walkable(corner_check2):
						neighbors.append(neighbor)
			else:
				neighbors.append(neighbor)
	
	return neighbors

func find_path(start_cell: Vector2, end_cell: Vector2) -> Array:
	if not grid_system.is_walkable(start_cell) or not grid_system.is_walkable(end_cell):
		return []
	
	var open_list: Array = []
	var closed_list: Dictionary = {}
	var all_nodes: Dictionary = {}
	
	var start_node = AStarNode.new(start_cell)
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_cell, end_cell)
	start_node.calculate_f_cost()
	open_list.append(start_node)
	all_nodes[start_cell] = start_node
	
	var iterations = 0
	var max_iterations = 1000
	
	while open_list.size() > 0 and iterations < max_iterations:
		iterations += 1
		
		var current_node: AStarNode = open_list[0]
		var current_index = 0
		
		for i in range(1, open_list.size()):
			if open_list[i].f_cost < current_node.f_cost:
				current_node = open_list[i]
				current_index = i
		
		open_list.remove_at(current_index)
		closed_list[current_node.cell] = true
		
		if current_node.cell == end_cell:
			return reconstruct_path(current_node)
		
		for neighbor_cell in get_neighbors(current_node.cell):
			if closed_list.has(neighbor_cell):
				continue
			
			# Higher cost for diagonal movement to prefer straight paths
			var is_diagonal = abs(neighbor_cell.x - current_node.cell.x) + abs(neighbor_cell.y - current_node.cell.y) > 1
			var movement_cost = 1.5 if is_diagonal else 1.0  # Increased diagonal cost
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			var neighbor_node: AStarNode
			if all_nodes.has(neighbor_cell):
				neighbor_node = all_nodes[neighbor_cell]
			else:
				neighbor_node = AStarNode.new(neighbor_cell)
				neighbor_node.h_cost = heuristic(neighbor_cell, end_cell)
				all_nodes[neighbor_cell] = neighbor_node
			
			var is_in_open = open_list.has(neighbor_node)
			if tentative_g_cost < neighbor_node.g_cost or not is_in_open:
				neighbor_node.g_cost = tentative_g_cost
				neighbor_node.parent = current_node
				neighbor_node.calculate_f_cost()
				
				if not is_in_open:
					open_list.append(neighbor_node)
	
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
	stuck_position = global_position

func _physics_process(delta):
	if not is_instance_valid(grid_system) or not is_instance_valid(player):
		return
	
	check_if_stuck(delta)
	
	path_update_timer -= delta
	if path_update_timer <= 0:
		path_update_timer = path_update_rate
		update_path()
	
	if current_path.size() > 0:
		follow_path(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1
	
	move_and_slide()
	update_animation()
	apply_player_push()

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
	
	if moved_distance < 0.05 and current_path.size() > 0:  # Reduced threshold
		stuck_timer += delta
		if stuck_timer > 1.5:  # Faster reaction time
			print("🚫 NPC stuck, recalculating path")
			# Try to move away from stuck position
			var escape_dir = (global_position - stuck_position).normalized()
			velocity += Vector3(escape_dir.x, 0, escape_dir.z) * move_speed * 0.5
			
			current_path.clear()
			path_update_timer = 0.0
			stuck_timer = 0.0
			stuck_position = global_position
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func update_path():
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= stop_distance:
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()
		return
	
	var start_cell = grid_system.world_to_grid(global_position)
	var end_cell = grid_system.world_to_grid(player.global_position)
	
	if start_cell == end_cell:
		current_path.clear()
		if is_instance_valid(grid_system):
			grid_system.clear_path_visualization()
		return
	
	var new_path = find_path(start_cell, end_cell)
	
	if new_path.size() > 0:
		current_path = new_path
		current_waypoint_index = 0
		
		# Skip waypoints we're already past
		if current_path.size() > 1:
			var first_waypoint = grid_system.grid_to_world(current_path[0])
			if global_position.distance_to(first_waypoint) < waypoint_reach_distance:
				current_waypoint_index = 1
		
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
	
	var target_cell = current_path[current_waypoint_index]
	var target_pos = grid_system.grid_to_world(target_cell)
	
	# Check for walls in movement direction
	var to_target = target_pos - global_position
	to_target.y = 0
	var distance_to_waypoint = to_target.length()
	
	# If there's a wall between us and the waypoint, skip to next waypoint
	if is_wall_between(global_position, target_pos):
		print("🚧 Wall detected, skipping waypoint")
		current_waypoint_index += 1
		if show_path_debug and is_instance_valid(grid_system):
			grid_system.draw_path_visualization(current_path, current_waypoint_index)
		return
	
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
	
	# Smooth rotation
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		var current_rotation = rotation.y
		rotation.y = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)

func is_wall_between(from: Vector3, to: Vector3) -> bool:
	"""Check if there's a wall between two positions using raycast"""
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	
	var ray_params = PhysicsRayQueryParameters3D.create(
		from + Vector3(0, 0.5, 0),  # Start slightly above ground
		to + Vector3(0, 0.5, 0)
	)
	ray_params.collision_mask = 2  # Check obstacles layer only
	ray_params.exclude = [self]  # Don't collide with self
	
	var result = get_world_3d().direct_space_state.intersect_ray(ray_params)
	return not result.is_empty()

func apply_player_push():
	if not is_instance_valid(player):
		return
	
	var player_motion = player.velocity * get_physics_process_delta_time()
	var player_future_pos = player.global_transform.translated(player_motion)
	
	if player.test_move(player.global_transform, player_motion):
		var push_dir = (global_position - player.global_position).normalized()
		var push_strength = player.velocity.length() * 0.3
		
		velocity += push_dir * push_strength
