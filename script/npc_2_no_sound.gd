extends CharacterBody3D

# --- Settings ---
@export var speed: float = 5.0
@export var idle_threshold: float = 0.1
@export var grid_size: float = 1.0
@export var world_size: Vector2 = Vector2(400, 400) # bigger so bookstore fits
@export var obstacle_check_radius: float = 0.5

# --- References ---
@onready var bookstore_marker: Node3D = $"../Structures/Building/Bookstore/BookstoreMarker"

var bookstore_position: Vector3
var current_path: Array[Vector3] = []
var path_index: int = 0

# --- Debug helpers ---
var debug_parent: Node3D
var debug_meshes: Array = []

# --- Stuck detection ---
var last_position: Vector3
var stuck_timer: float = 0.0
var stuck_timeout: float = 2.0

# --- Grid ---
var grid: Dictionary = {} # Vector2 -> walkable (true/false)

# --- States ---
enum NPCState { GOING_TO_BOOKSTORE, IDLE_WAITING }
var current_state = NPCState.GOING_TO_BOOKSTORE

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

# --- Ready ---
func _ready():
	if bookstore_marker:
		bookstore_position = bookstore_marker.global_position
		print("📍 Bookstore grid: ", world_to_grid(bookstore_position))

	debug_parent = Node3D.new()
	add_child(debug_parent)

	initialize_grid()
	go_to_bookstore()
	last_position = global_position

# --- Grid initialization ---
func initialize_grid():
	for x in range(int(-world_size.x/2), int(world_size.x/2)):
		for z in range(int(-world_size.y/2), int(world_size.y/2)):
			var cell = Vector2(x, z)
			var world_pos = grid_to_world(cell)
			grid[cell] = not check_obstacle(world_pos)
			if not grid[cell]:
				draw_debug_marker(world_pos, Color.RED)

func check_obstacle(world_pos: Vector3) -> bool:
	var sphere = SphereShape3D.new()
	sphere.radius = obstacle_check_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = world_pos
	query.collision_mask = 2 # obstacle layer
	return get_world_3d().direct_space_state.intersect_shape(query, 1).size() > 0

# --- Conversion ---
func grid_to_world(grid_pos: Vector2) -> Vector3:
	return Vector3(
		grid_pos.x * grid_size + grid_size * 0.5,
		global_position.y,
		grid_pos.y * grid_size + grid_size * 0.5
	)

func world_to_grid(world_pos: Vector3) -> Vector2:
	return Vector2(
		floori(world_pos.x / grid_size),
		floori(world_pos.z / grid_size)
	)

func is_walkable(grid_pos: Vector2) -> bool:
	return grid.get(grid_pos, false)

# --- Physics Process ---
func _physics_process(delta: float):
	update_state()
	match current_state:
		NPCState.GOING_TO_BOOKSTORE:
			follow_path()
		NPCState.IDLE_WAITING:
			idle_behavior()

	# Stuck detection
	if global_position.distance_to(last_position) < 0.05 and velocity.length() < 0.1:
		stuck_timer += delta
		if stuck_timer > stuck_timeout:
			print("⚠️ NPC STUCK at ", global_position, " | Recalculating path...")
			if current_state == NPCState.GOING_TO_BOOKSTORE:
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

# --- Movement ---
func follow_path():
	if current_path.is_empty() or path_index >= current_path.size():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target = current_path[path_index]
	var dir = (target - global_position)
	var distance = dir.length()
	if distance < 0.5:
		path_index += 1
		return

	dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	if dir.length() > 0:
		look_at(global_position + dir, Vector3.UP)

func idle_behavior():
	velocity = Vector3.ZERO
	move_and_slide()

# --- Path Updates ---
func go_to_bookstore():
	current_path = find_path(global_position, bookstore_position)
	path_index = 0
	draw_debug_path(current_path)

# --- A* Pathfinding (Minecraft style) ---
func find_path(start: Vector3, target: Vector3) -> Array[Vector3]:
	var start_grid = world_to_grid(start)
	var target_grid = world_to_grid(target)
	if not is_walkable(start_grid) or not is_walkable(target_grid):
		print("⚠️ Target not walkable, fallback direct.")
		return [target]

	var open_set: Array[PathNode] = []
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start_grid, grid_to_world(start_grid))
	start_node.g_cost = 0
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)

	while open_set.size() > 0:
		# Pick lowest f_cost
		open_set.sort_custom(func(a, b): return a.f_cost < b.f_cost)
		var current: PathNode = open_set[0]
		open_set.remove_at(0)
		closed_set[current.pos] = current

		if current.pos == target_grid:
			return reconstruct_path(current)

		for neighbor in get_neighbors(current.pos):
			if closed_set.has(neighbor) or not is_walkable(neighbor):
				continue

			# Movement cost: 10 straight, 14 diagonal
			var move_cost = 10
			if abs(neighbor.x - current.pos.x) == 1 and abs(neighbor.y - current.pos.y) == 1:
				# Diagonal, prevent cutting corners
				if not (is_walkable(Vector2(neighbor.x, current.pos.y)) and is_walkable(Vector2(current.pos.x, neighbor.y))):
					continue
				move_cost = 14

			var tentative_g = current.g_cost + move_cost
			var neighbor_world = grid_to_world(neighbor)

			var neighbor_node: PathNode = null
			for n in open_set:
				if n.pos == neighbor:
					neighbor_node = n
					break

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

	return [target]

# Manhattan heuristic (like Minecraft)
func heuristic(a: Vector2, b: Vector2) -> float:
	var dx = abs(a.x - b.x)
	var dz = abs(a.y - b.y)
	return (dx + dz) * 10

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

# --- Debug ---
func ensure_debug_parent():
	if debug_parent == null or not debug_parent.is_inside_tree():
		debug_parent = Node3D.new()
		add_child(debug_parent)

func clear_debug():
	ensure_debug_parent()
	for m in debug_meshes:
		if m.is_inside_tree():
			m.queue_free()
	debug_meshes.clear()

func draw_debug_marker(pos: Vector3, color: Color = Color.RED):
	ensure_debug_parent()
	var mesh = SphereMesh.new()
	mesh.radius = 0.2
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	debug_parent.add_child(mi)
	debug_meshes.append(mi)

func draw_debug_path(path: Array[Vector3]):
	clear_debug()
	if path.size() < 2:
		return
	
	# Create a MultiMesh for dots
	var multimesh := MultiMesh.new()
	multimesh.mesh = SphereMesh.new()
	multimesh.mesh.radius = 0.1
	multimesh.instance_count = 0
	
	var multimesh_instance := MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	
	# Material (red for path, blue for bookstore)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	multimesh_instance.material_override = mat
	
	debug_parent.add_child(multimesh_instance)
	debug_meshes.append(multimesh_instance)
	
	# Place dots along each segment
	var dot_spacing := 0.5
	var transforms: Array[Transform3D] = []
	
	for i in range(path.size() - 1):
		var start := path[i]
		var end := path[i + 1]
		var segment_length := start.distance_to(end)
		var steps := int(segment_length / dot_spacing)
		
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var pos := start.lerp(end, t)
			var xform := Transform3D(Basis(), pos)
			transforms.append(xform)
	
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
	
	# Mark bookstore with a big blue dot
	if bookstore_position != Vector3.ZERO:
		draw_debug_marker(bookstore_position, Color.BLUE)
