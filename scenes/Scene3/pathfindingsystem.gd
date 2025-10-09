# pathfinding_system.gd
# A* pathfinding tailored to your 2D grid.gd (Minecraft-style: 4-dir, no diagonals)
class_name PathfindingSystem
extends Node3D

# --- Path Node ---
class PathNode:
	var pos: Vector2
	var g_cost: float
	var h_cost: float
	var f_cost: float
	var parent: PathNode = null

	func _init(p: Vector2):
		pos = p
		g_cost = 0.0
		h_cost = 0.0
		f_cost = 0.0
		parent = null

	func calculate_f():
		f_cost = g_cost + h_cost

	func is_better_than(other: PathNode) -> bool:
		return f_cost < other.f_cost or (f_cost == other.f_cost and h_cost < other.h_cost)

# --- Public API ---
static func find_path(grid_system: Node, start_world: Vector3, target_world: Vector3, options: Dictionary = {}) -> Dictionary:
	"""
	Find path using A* compatible with your grid.gd.
	Options:
		allow_diagonal (ignored — forced false to match Minecraft behavior)
		optimize_path: bool (default true)  -> line-of-sight pruning
		max_iterations: int (default 10000)
		avoid_cells: Array[Vector2] (temporarily mark as blocked)
		debug: bool (default false)
	Returns: { "world_path": Array[Vector3], "grid_path": Array[Vector2], "success": bool, "iterations": int }
	"""
	var optimize = options.get("optimize_path", true)
	var max_iterations = options.get("max_iterations", 10000)
	var avoid_cells: Array = options.get("avoid_cells", [])
	var debug: bool = options.get("debug", false)
	# Explicitly ignore allow_diagonal
	if options.has("allow_diagonal") and options.allow_diagonal:
		if debug:
			print("⚠️ Diagonal movement is disabled in this pathfinding system.")

	# Temporarily block avoid_cells, store original values
	var original_states := {}
	for cell in avoid_cells:
		if grid_system.is_valid_cell(cell):
			original_states[cell] = grid_system.grid.get(cell, false)
			grid_system.grid[cell] = false

	# Convert world -> grid (Vector2)
	var start_grid: Vector2 = grid_system.world_to_grid(start_world)
	var target_grid: Vector2 = grid_system.world_to_grid(target_world)

	if debug:
		print("🔍 find_path: start=", start_grid, " target=", target_grid)
		print("Start grid:", start_grid, "walkable:", grid_system.is_walkable(start_grid))
		print("Target grid:", target_grid, "walkable:", grid_system.is_walkable(target_grid))

	# If start/target not walkable, find nearest walkable
	if not grid_system.is_walkable(start_grid):
		var old_start = start_grid
		start_grid = grid_system.find_nearest_walkable(start_grid)
		if debug:
			print("⚠️ start not walkable:", old_start, " -> nearest:", start_grid)

	if not grid_system.is_walkable(target_grid):
		var old_target = target_grid
		target_grid = grid_system.find_nearest_walkable(target_grid)
		if debug:
			print("⚠️ target not walkable:", old_target, " -> nearest:", target_grid)

	# If equal, return single waypoint
	if start_grid == target_grid:
		_restore_avoided_cells(grid_system, original_states)
		return {
			"world_path": [grid_system.grid_to_world(target_grid)],
			"grid_path": [target_grid],
			"success": true,
			"iterations": 0
		}

	# A* containers
	var open_set: Array = []
	var open_lookup: Dictionary = {}
	var closed_set: Dictionary = {}

	var start_node = PathNode.new(start_grid)
	start_node.h_cost = heuristic(start_grid, target_grid)
	start_node.calculate_f()
	open_set.append(start_node)
	open_lookup[start_grid] = start_node

	var iterations = 0
	while open_set.size() > 0 and iterations < max_iterations:
		iterations += 1

		# get best node from open_set
		var current: PathNode = _get_best_node(open_set)
		if current == null:
			break
		# remove current from open
		open_set.erase(current)
		open_lookup.erase(current.pos)
		closed_set[current.pos] = current

		# reached target
		if current.pos == target_grid:
			if debug:
				print("🎯 Path found in", iterations, "iterations")
			var result = reconstruct_path(current, grid_system, optimize, debug)
			result["iterations"] = iterations
			_restore_avoided_cells(grid_system, original_states)
			return result

		# explore 4 neighbors (N,S,E,W) -- Minecraft-style (no diagonal)
		var neighbors = _get_cardinal_neighbors(current.pos, grid_system)
		for npos in neighbors:
			if closed_set.has(npos):
				continue

			var tentative_g = current.g_cost + 10.0  # uniform cost per step
			var neighbor_node: PathNode = open_lookup.get(npos, null)

			if neighbor_node == null:
				neighbor_node = PathNode.new(npos)
				neighbor_node.g_cost = tentative_g
				neighbor_node.h_cost = heuristic(npos, target_grid)
				neighbor_node.parent = current
				neighbor_node.calculate_f()

				open_set.append(neighbor_node)
				open_lookup[npos] = neighbor_node
			elif tentative_g < neighbor_node.g_cost:
				neighbor_node.g_cost = tentative_g
				neighbor_node.parent = current
				neighbor_node.calculate_f()

	# no path found
	_restore_avoided_cells(grid_system, original_states)
	if debug:
		print("❌ No path found after", iterations, "iterations")
		print("   open_set:", open_set.size(), " closed_set:", closed_set.size())
	return {"world_path": [], "grid_path": [], "success": false, "iterations": iterations}


# --- Helpers ---

static func _get_best_node(open_set: Array) -> PathNode:
	if open_set.is_empty():
		return null
	var best: PathNode = open_set[0]
	for i in range(1, open_set.size()):
		if open_set[i].is_better_than(best):
			best = open_set[i]
	return best

static func _get_cardinal_neighbors(pos: Vector2, grid_system: Node) -> Array:
	var dirs = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]
	var out: Array = []
	for d in dirs:
		var n = pos + d
		if grid_system.is_valid_cell(n) and grid_system.is_walkable(n):
			out.append(n)
	return out

static func heuristic(a: Vector2, b: Vector2) -> float:
	return 10.0 * (abs(a.x - b.x) + abs(a.y - b.y))

static func reconstruct_path(end_node: PathNode, grid_system: Node, optimize: bool, debug: bool) -> Dictionary:
	var grid_path: Array = []
	var world_path: Array = []
	var cur: PathNode = end_node
	while cur != null:
		grid_path.append(cur.pos)
		world_path.append(grid_system.grid_to_world(cur.pos))
		cur = cur.parent
	grid_path.reverse()
	world_path.reverse()

	if debug:
		print("🔍 Raw path has", grid_path.size(), "cells")

	if optimize and world_path.size() > 2:
		var optimized_world = optimize_path(world_path, grid_system, debug)
		var optimized_grid: Array = []
		for w in optimized_world:
			optimized_grid.append(grid_system.world_to_grid(w))
		if debug:
			print("🔧 Optimized path:", world_path.size(), "->", optimized_world.size(), "waypoints")
		return {"world_path": optimized_world, "grid_path": optimized_grid, "success": true}
	else:
		return {"world_path": world_path, "grid_path": grid_path, "success": true}

static func optimize_path(world_path: Array, grid_system: Node, debug: bool) -> Array:
	if world_path.size() <= 2:
		return world_path

	var optimized: Array = []
	optimized.append(world_path[0])
	var idx = 0
	while idx < world_path.size() - 1:
		var furthest = idx + 1
		for j in range(idx + 2, world_path.size()):
			if _has_line_of_sight(world_path[idx], world_path[j], grid_system):
				furthest = j
			else:
				break
		optimized.append(world_path[furthest])
		idx = furthest
	return optimized

static func _has_line_of_sight(a: Vector3, b: Vector3, grid_system: Node) -> bool:
	var dir = b - a
	var dist = a.distance_to(b)
	if dist < 0.001:
		return true
	dir = dir.normalized()
	var step = grid_system.grid_size * 0.5
	var steps = max(1, int(dist / step))
	for i in range(1, steps):
		var p = a + dir * (i * step)
		var g = grid_system.world_to_grid(p)
		if not grid_system.is_valid_cell(g) or not grid_system.is_walkable(g):
			return false
	var endg = grid_system.world_to_grid(b)
	return grid_system.is_valid_cell(endg) and grid_system.is_walkable(endg)

static func _restore_avoided_cells(grid_system: Node, original_states: Dictionary) -> void:
	for cell in original_states.keys():
		grid_system.grid[cell] = original_states[cell]

# --- Utility Functions ---

static func get_path_length(world_path: Array) -> float:
	"""Returns the total length of a path in meters (sum of segment distances)."""
	if world_path.size() < 2:
		return 0.0
	var length = 0.0
	for i in range(world_path.size() - 1):
		length += world_path[i].distance_to(world_path[i + 1])
	return length

static func smooth_path_safe(world_path: Array, grid_system: Node, step_size: float = 0.5) -> Array:
	"""
	Returns a smoothed path by interpolating between waypoints,
	only including points that are walkable.
	"""
	if world_path.size() <= 2:
		return world_path.duplicate()
	var smoothed: Array = []
	smoothed.append(world_path[0])
	for i in range(1, world_path.size()):
		var prev = smoothed[-1]
		var next = world_path[i]
		var dir = (next - prev).normalized()
		var dist = prev.distance_to(next)
		var steps = int(dist / step_size)
		var valid = true
		for s in range(1, steps + 1):
			var p = prev + dir * (s * step_size)
			var g = grid_system.world_to_grid(p)
			if not grid_system.is_valid_cell(g) or not grid_system.is_walkable(g):
				valid = false
				break
		if valid:
			smoothed.append(next)
		else:
			smoothed.append(world_path[i - 1])
			smoothed.append(next)
	return smoothed
