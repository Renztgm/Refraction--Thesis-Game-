extends GutTest

const NPCScene = preload("res://scenes/Npc2_No_sound.tscn")

func test_npc_moves_toward_bookstore():
	var npc = NPCScene.instantiate()
	add_child(npc)
	npc.global_position = Vector3(0, 0, 0)

	var start_pos = npc.global_position

	for i in range(60): # simulate 1 second
		npc._physics_process(1.0 / 60.0)

	var end_pos = npc.global_position
	assert_true(start_pos.distance_to(end_pos) > 0.1, "NPC should move toward bookstore")
