extends GutTest

const SCENE3 = preload("res://scenes/NarativeScenes/Scene3.tscn")

# Helper: simulate physics frames
func simulate_physics(node: Node, frames: int, delta: float = 1.0 / 60.0) -> void:
	for i in range(frames):
		if node.has_method("_physics_process"):
			node._physics_process(delta)

# --- Test 1: NPC moves in Scene3 ---
func test_npc_in_scene3_moves():
	var scene = SCENE3.instantiate()
	add_child_autofree(scene)

	# ⚠️ Adjust this path to match your NPC node name inside Scene3
	var npc = scene.get_node("Npc2")

	var start_pos = npc.global_position
	simulate_physics(npc, 120)  # ~2 seconds at 60fps
	var end_pos = npc.global_position

	assert_true(
		start_pos.distance_to(end_pos) > 0.1,
		"NPC in Scene3 should move toward the bookstore"
	)
