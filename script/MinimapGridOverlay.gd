extends Control

@onready var icon_ref: TextureRect = $"../MinimapIcons/PlayerIcon"
@onready var npc_icon_ref: TextureRect = $"../MinimapIcons/NPCIcon"

var grid_ref: NavigationRegion3D = null
var player_ref: CharacterBody3D = null
var npc_refs: Array = []

const CELL_SIZE := Vector2(10, 10)
const PADDING := 0.5

var quest_item_refs: Array = []
var blink_timer := 0.0
var blink_alpha := 1.0

func _ready():
	add_to_group("minimap_overlay")
	print("🗺️ MinimapGridOverlay script active on:", self.name)

	var players = get_tree().get_nodes_in_group("player2")
	var grids = get_tree().get_nodes_in_group("grid")
	var npcs = get_tree().get_nodes_in_group("npc")
	var quest_items = get_tree().get_nodes_in_group("quest_item")
	quest_item_refs = quest_items

	if players.size() > 0:
		player_ref = players[0] as CharacterBody3D
	if grids.size() > 0:
		grid_ref = grids[0] as NavigationRegion3D
	npc_refs = npcs

	if not grid_ref or not player_ref:
		push_warning("MinimapGridOverlay: Could not find 'player' or 'grid' group nodes.")
	else:
		call_deferred("queue_redraw")

func _process(delta):
	if not grid_ref or not player_ref:
		return

	# Clean up freed items
	quest_item_refs = quest_item_refs.filter(func(item):
		return is_instance_valid(item) and item is Node3D
	)

	icon_ref.position = get_rect().size / 2
	icon_ref.rotation = 0

	if npc_refs.size() > 0:
		var npc = npc_refs[0] as Node3D
		var npc_grid = grid_ref.world_to_grid(npc.global_transform.origin)
		var player_grid = grid_ref.world_to_grid(player_ref.global_transform.origin)
		var offset = npc_grid - player_grid
		var minimap_pos = get_rect().size / 2 + offset * CELL_SIZE
		npc_icon_ref.position = npc_icon_ref.position.move_toward(minimap_pos, delta * 100)
		npc_icon_ref.rotation = 0

	blink_timer += delta
	blink_alpha = 0.5 + 0.5 * sin(blink_timer * 5.0)

	queue_redraw()

func remove_quest_item(item: Node3D) -> void:
	if quest_item_refs.has(item):
		print("🧼 Removing item from minimap:", item.name)
		quest_item_refs.erase(item)
		queue_redraw()
	else:
		print("⚠️ Item not found in quest_item_refs:", item.name)

func _draw():
	if not grid_ref or not player_ref:
		return

	var draw_size = get_rect().size
	var center = draw_size / 2
	var player_grid = grid_ref.world_to_grid(player_ref.global_transform.origin)

	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	var visible_cells := []

	for cell in grid_ref.grid.keys():
		var offset = cell - player_grid
		var pos = center + offset * CELL_SIZE

		if pos.x < 0 or pos.x > draw_size.x or pos.y < 0 or pos.y > draw_size.y:
			continue

		min_pos = min_pos.min(pos)
		max_pos = max_pos.max(pos)
		visible_cells.append({ "pos": pos, "cell": cell })

	if visible_cells.size() > 0:
		var grid_rect = Rect2(
			min_pos - CELL_SIZE * PADDING,
			(max_pos - min_pos) + CELL_SIZE * (PADDING * 2 + 1)
		)
		draw_rect(grid_rect, Color(0, 0, 0, 1.0))
		draw_rect(grid_rect, Color(0, 1, 0, 1.0), false)

	for entry in visible_cells:
		var pos = entry["pos"]
		var cell = entry["cell"]
		var walkable = grid_ref.is_walkable(cell)
		var color = Color(0.6, 0.6, 0.6, 1.0) if walkable else Color(0, 0, 0, 1.0)

		draw_rect(Rect2(pos, CELL_SIZE), color)
		draw_rect(Rect2(pos, CELL_SIZE), Color(0.2, 0.2, 0.2, 0.5), false)

	draw_rect(Rect2(center.floor(), CELL_SIZE), Color(0, 1, 0))

	if npc_refs.size() > 0:
		var npc = npc_refs[0] as Node3D
		var npc_grid = grid_ref.world_to_grid(npc.global_transform.origin)
		var offset = npc_grid - player_grid
		var minimap_pos = center + offset * CELL_SIZE

		if minimap_pos.x >= 0 and minimap_pos.x <= draw_size.x and minimap_pos.y >= 0 and minimap_pos.y <= draw_size.y:
			draw_rect(Rect2(minimap_pos.floor(), CELL_SIZE), Color(0.6, 0.0, 0.8))

	for item in quest_item_refs:
		if not is_instance_valid(item) or not item is Node3D:
			continue

		var item_grid = grid_ref.world_to_grid(item.global_transform.origin)
		var offset = item_grid - player_grid
		var minimap_pos = center + offset * CELL_SIZE

		if minimap_pos.x >= 0 and minimap_pos.x <= draw_size.x and minimap_pos.y >= 0 and minimap_pos.y <= draw_size.y:
			var blink_color = Color(1, 1, 0, blink_alpha)
			draw_rect(Rect2(minimap_pos.floor(), CELL_SIZE), blink_color)
