extends Node

@onready var player_ref: CharacterBody3D = null
@onready var npc_ref: Node3D = null
@onready var minimap_camera: Camera3D = $MinimapViewport/MinimapCamera
@onready var minimap_display: TextureRect = $MinimapDisplay
@onready var minimap_viewport: SubViewport = $MinimapViewport
@onready var player_dot: TextureRect = $PlayerDot
@onready var npc_dot: TextureRect = $NPCDot

# 🔧 Manual offset to nudge dot position (in pixels)
const DOT_OFFSET := Vector2(-8, -12)  # top-left nudge

func _ready():
	var players = get_tree().get_nodes_in_group("player2")
	var npcs = get_tree().get_nodes_in_group("npc")

	if players.size() > 0:
		player_ref = players[0] as CharacterBody3D
		print("✅ Player found:", player_ref.name)
	else:
		push_warning("❌ No player found in group 'player2'")

	if npcs.size() > 0:
		npc_ref = npcs[0] as Node3D
		print("✅ NPC found:", npc_ref.name)
	else:
		push_warning("❌ No NPC found in group 'npc'")

	minimap_display.texture = minimap_viewport.get_texture()
	print("✅ Minimap texture assigned")

	_setup_dot(player_dot, Vector2(8, 8))  # assuming 16x16 texture
	_setup_dot(npc_dot, Vector2(8, 8))

func _setup_dot(dot: TextureRect, pivot: Vector2):
	if dot:
		dot.anchor_left = 0.5
		dot.anchor_top = 0.5
		dot.anchor_right = 0.5
		dot.anchor_bottom = 0.5
		dot.pivot_offset = pivot
		dot.z_index = 1
		dot.visible = true

func _process(delta):
	if not player_ref or not minimap_camera:
		return

	var player_pos = player_ref.global_transform.origin
	var cam_pos = minimap_camera.global_transform.origin
	cam_pos.x = player_pos.x
	cam_pos.z = player_pos.z
	minimap_camera.global_transform.origin = cam_pos

	var screen_pos_player = minimap_camera.unproject_position(player_pos)
	var screen_pos_npc = Vector2.ZERO
	if npc_ref:
		screen_pos_npc = minimap_camera.unproject_position(npc_ref.global_transform.origin)

	var minimap_offset = minimap_display.get_global_transform().origin

	# ✅ Apply offset to dot positions
	player_dot.global_position = minimap_offset + screen_pos_player + DOT_OFFSET
	player_dot.modulate = Color(1, 1, 1)

	if npc_ref:
		npc_dot.global_position = minimap_offset + screen_pos_npc + DOT_OFFSET
		npc_dot.modulate = Color(0.895, 0.728, 0.288, 1.0)

	# Debug prints
	print("🎮 Player world:", player_pos, "→ screen:", screen_pos_player)
	print("🧭 Minimap top-left:", minimap_offset)
	print("📍 PlayerDot global:", player_dot.global_position)
	if npc_ref:
		print("🤖 NPC world:", npc_ref.global_transform.origin, "→ screen:", screen_pos_npc)
		print("📍 NPCDot global:", npc_dot.global_position)
