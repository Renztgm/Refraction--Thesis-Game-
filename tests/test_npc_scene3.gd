extends GutTest

const SCENE3 = preload("res://scenes/Scene3/Scene3.tscn")

# Helper: simulate physics frames
func simulate_physics(node: Node, frames: int, delta: float = 1.0 / 60.0) -> void:
	for i in range(frames):
		if node.has_method("_physics_process"):
			node._physics_process(delta)

# --- Test: NPC moves in Scene3 ---
func test_npc_in_scene3_moves():
	var scene = SCENE3.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame  # allow _ready() to run

	var npc = scene.get_node_or_null("Npc3")
	assert_not_null(npc, "Npc2 should exist in Scene3")

	var start_pos = npc.global_position
	simulate_physics(npc, 120)  # ~2 seconds at 60fps
	var end_pos = npc.global_position

	assert_true(
		start_pos.distance_to(end_pos) > 0.1,
		"NPC in Scene3 should move toward the bookstore"
	)
