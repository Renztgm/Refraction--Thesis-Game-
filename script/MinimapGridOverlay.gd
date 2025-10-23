extends Control

@onready var icon_ref: TextureRect = $"../MinimapIcons/PlayerIcon"
@onready var npc_icon_ref: TextureRect = $"../MinimapIcons/NPCIcon"

var grid_ref: NavigationRegion3D = null
var player_ref: CharacterBody3D = null
var npc_refs: Array = []

const ZOOM_RADIUS := 10
const CELL_SIZE := Vector2(10, 10)

func _ready():
	var players = get_tree().get_nodes_in_group("player2")
	var grids = get_tree().get_nodes_in_group("grid")
	var npcs = get_tree().get_nodes_in_group("npc")

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
	if not grid_ref or not player_ref or not icon_ref:
		return

	# Rotate the minimap to match player facing
	var facing_angle = player_ref.global_transform.basis.get_euler().y
	rotation = -facing_angle

	# Keep player icon centered and upright
	icon_ref.position = size / 2
	icon_ref.rotation = 0

	# Position NPC icon relative to player
	if npc_refs.size() > 0:
		var npc = npc_refs[0] as Node3D
		var npc_grid = grid_ref.world_to_grid(npc.global_transform.origin)
		var player_grid = grid_ref.world_to_grid(player_ref.global_transform.origin)
		var offset = npc_grid - player_grid
		var minimap_pos = size / 2 + offset * CELL_SIZE
		npc_icon_ref.position = npc_icon_ref.position.lerp(minimap_pos, 0.2)
		npc_icon_ref.rotation = 0

	queue_redraw()

func _draw():
	if not grid_ref or not player_ref:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.1, 0.2))

	var player_grid = grid_ref.world_to_grid(player_ref.global_transform.origin)

	for cell in grid_ref.grid.keys():
		var offset = cell - player_grid
		if abs(offset.x) > ZOOM_RADIUS or abs(offset.y) > ZOOM_RADIUS:
			continue

		var walkable = grid_ref.is_walkable(cell)
		var pos = size / 2 + offset * CELL_SIZE
		var rect = Rect2(pos, CELL_SIZE)
		var color = Color(0.2, 0.8, 0.2, 1.0) if walkable else Color(0.8, 0.2, 0.2, 1.0)
		draw_rect(rect, color)
		draw_rect(rect, Color(0, 0, 0, 0.2), false)

	# Fallback player triangle (always pointing up)
	var center = size / 2
	var radius = 6.0
	var p1 = center + Vector2(0, -radius)
	var p2 = center + Vector2(-radius * 0.6, radius)
	var p3 = center + Vector2(radius * 0.6, radius)
	draw_polygon([p1, p2, p3], [Color(1, 1, 1)])

	# Fallback NPC dot
	if npc_refs.size() > 0:
		var npc = npc_refs[0] as Node3D
		var npc_grid = grid_ref.world_to_grid(npc.global_transform.origin)
		var offset = npc_grid - player_grid
		var minimap_pos = size / 2 + offset * CELL_SIZE
		var clamped_pos = minimap_pos.clamp(Vector2.ZERO, size)
		draw_circle(clamped_pos, 4, Color(1, 1, 0))
