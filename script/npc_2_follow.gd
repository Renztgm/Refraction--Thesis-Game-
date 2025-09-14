extends CharacterBody3D

# --- Settings ---
@export var speed: float = 5.0
@export var follow_distance: float = 3.0
@export var obstacle_check_radius: float = 0.5
@export var grid_size: float = 1.0
@export var world_size: Vector2 = Vector2(400, 400)

# --- References ---
var player: CharacterBody3D
var current_path: Array[Vector3] = []
var path_index: int = 0

# --- Path update timer ---
var path_update_timer: float = 0.0
var update_frequency: float = 0.5

# --- Stuck detection ---
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_timeout: float = 1.0

# --- Grid ---
var grid: Dictionary = {}

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

func _ready():
	player = get_tree().get_first_node_in_group("player")
	last_position = global_position
	initialize_grid()

func initialize_grid():
	for x in range(int(-world_size.x/2), int(world_size.x/2)):
		for z in range(int(-world_size.y/2), int(world_size.y/2)):
			var cell = Vector2(x, z)
			var world_pos = grid_to_world(cell)
			grid[cell] = not check_obstacle(world_pos)

func check_obstacle(world_pos: Vector3) -> bool:
	var sphere = SphereShape3D.new()
	sphere.radius = obstacle_check_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = world_pos
	query.collision_mask = 2
	return get_world_3d().direct_space_state.intersect_shape(query, 1).size() > 0

func grid_to_world(grid_pos: Vector2) -> Vector3:
	return Vector3(
		grid_pos.x * grid_size + grid_size * 0.5,
		global_position.y,
		grid_pos.y * grid_size + grid_size * 0.5
	)

func world_to_grid(world_pos: Vector3) -> Vector2:
	return Vector2(
		floor(world_pos.x / grid_size),
		floor(world_pos.z / grid_size)
	)

func is_walkable(grid_pos: Vector2) -> bool:
	return grid.get(grid_pos, false)

func _physics_process(delta: float):
	if not player:
		return

	path_update_timer += delta
	
	# Update path regularly to keep following the player
	if path_update_timer >= update_frequency:
		update_path_to_player()
		path_update_timer = 0.0
	
	# Move along the path
	move_along_path(delta)
	
	# Stuck detection
	if global_position.distance_to(last_position) < 0.1:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			update_path_to_player()
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	
	last_position = global_position

func update_path_to_player():
	if not player:
		return
	
	# Find path directly to the player's position
	current_path = find_path(global_position, player.global_position)
	path_index = 0

func move_along_path(delta: float):
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# If we have no path or finished the path, move directly toward player
	if current_path.is_empty() or path_index >= current_path.size():
		move_toward_player(distance_to_player)
		return
	
	# Get the current target waypoint
	var target = current_path[path_index]
	var direction = (target - global_position)
	var distance_to_waypoint = direction.length()
	
	# If close to waypoint, move to next one
	if distance_to_waypoint < 0.5:
		path_index += 1
		return
	
	# Move toward the waypoint
	direction = direction.normalized()
	var move_speed = calculate_movement_speed(distance_to_player)
	
	velocity = direction * move_speed
	move_and_slide()
	
	# Look in the direction of movement
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

func move_toward_player(distance_to_player: float):
	# Move directly toward player when no path available
	var direction = (player.global_position - global_position).normalized()
	var move_speed = calculate_movement_speed(distance_to_player)
	
	velocity = direction * move_speed
	move_and_slide()
	
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

func calculate_movement_speed(distance_to_player: float) -> float:
	# Adjust speed based on distance to player
	if distance_to_player < 1.0:
		return speed * 0.2  # Very slow when very close
	elif distance_to_player < follow_distance:
		return speed * 0.5  # Half speed when close
	else:
		return speed  # Full speed when far

# --- A* Pathfinding ---
func find_path(start: Vector3, target: Vector3) -> Array[Vector3]:
	var start_grid = world_to_grid(start)
	var target_grid = world_to_grid(target)
	
	if not is_walkable(start_grid) or not is_walkable(target_grid):
		return []

	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start_grid, grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)

	while open_set.size() > 0:
		var current = open_set[0]
		for n in open_set:
			if n.f_cost < current.f_cost:
				current = n
		open_set.erase(current)
		closed_set[current.pos] = current

		if current.pos == target_grid:
			return reconstruct_path(current)

		for neighbor in get_neighbors(current.pos):
			if closed_set.has(neighbor) or not is_walkable(neighbor):
				continue

			var neighbor_node = null
			for n in open_set:
				if n.pos == neighbor:
					neighbor_node = n
					break

			var tentative_g = current.g_cost + (neighbor - current.pos).length()
			var neighbor_world = grid_to_world(neighbor)

			if neighbor_node == null:
				neighbor_node = PathNode.new(neighbor, neighbor_world)
				neighbor_node.g_cost = tentative_g
				neighbor_node.h_cost = heuristic(neighbor, target_grid)
				neighbor_node.parent = current
				neighbor_node.calculate_f()
				open_set.append(neighbor_node)
			elif tentative_g < neighbor_node.g_cost:
				neighbor_node.g_cost = tentative_g
				neighbor_node.parent = current
				neighbor_node.calculate_f()

	return []

func heuristic(a: Vector2, b: Vector2) -> float:
	var dx = abs(a.x - b.x)
	var dz = abs(a.y - b.y)
	return dx + dz - min(dx, dz)

func get_neighbors(pos: Vector2) -> Array[Vector2]:
	var dirs = [
		Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0),
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	var result: Array[Vector2] = []
	for d in dirs:
		var n = pos + d
		if n.x >= -world_size.x/2 and n.x < world_size.x/2 and n.y >= -world_size.y/2 and n.y < world_size.y/2:
			result.append(n)
	return result

func reconstruct_path(node: PathNode) -> Array[Vector3]:
	var path: Array[Vector3] = []
	var current = node
	while current != null:
		path.append(current.world_pos)
		current = current.parent
	path.reverse()
	return path
