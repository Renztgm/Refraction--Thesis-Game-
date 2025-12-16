extends CharacterBody3D

@export var npc_id: String = "Guardian"	
@export var dialogue_path: String = "res://dialogues/guardian.json"

var dialogue_active: bool = false
var dialogue_triggered: bool = false
var player: Node = null

var array = [
"res://scenes/Chapter5/EndingC.tscn",
"res://scenes/Chapter5/EndingB.tscn",
"res://scenes/Chapter5/EndingA.tscn",
"res://scenes/Chapter5/EndingD.tscn",
"res://scenes/Chapter5/EndingE.tscn"
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	float_object_up()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func float_object_up():
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector3(0,0.5,0), 5)
	tween.tween_callback(float_object_down)

func float_object_down(): 
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector3(0,-0.5,0), 5)
	tween.tween_callback(float_object_up)

func start_dialogue():
	if dialogue_active or dialogue_triggered:
		return

	dialogue_active = true
	dialogue_triggered = true

	if player and player.has_method("freeze_player"):
		player.freeze_player()

	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.load_dialogue(dialogue_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	if player and player.has_method("unfreeze_player"):
		player.unfreeze_player()
	var scene_log = "res://scenes/Chapter4/Scene2/Chapter4Scene2MemoryCoreRoom.tscn"
	if SaveManager:
		var saved := SaveManager.save_game()
		if saved:
			print("💾 Game state saved successfully")
		else:
			print("❌ Failed to save game state")

	# ✅ Log scene completion for branching system
	if SaveManager:
		var scene_path = scene_log
		var branch_id = "chapter_4_scene_2"
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("logged:", scene_path)
		else:
			print(scene_log, " already logged or failed to log.")
	narative_progression()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		start_dialogue()
		print("is player",player)
		
func narative_progression():
	var shards_obtained = InventoryManager.get_memory_shard_count()
	match shards_obtained:
		1: 
			print("Obtained shards: ", shards_obtained, "| Case 1 ", array[0])
			transition_sys(0)
			#get_tree().change_scene_to_file(array[0])
		2:
			print("Obtained shards: ", shards_obtained, "| Case 2", array[1])
			transition_sys(1)
			#get_tree().change_scene_to_file(array[1])
		3: 
			print("Obtained shards: ", shards_obtained, "| Case 3", array[2])
			transition_sys(2)
			#get_tree().change_scene_to_file(array[2])
		4:
			print("Obtained shards: ", shards_obtained, "| Case 4", array[3])
			transition_sys(3)
			#get_tree().change_scene_to_file(array[3])
		_: 
			print("Obtained shards: ", shards_obtained, "| Case default", array[4])
			transition_sys(4)
			#get_tree().change_scene_to_file(array[4])


func transition_sys(goto:int):
	
	FadeOutCanvas.fade_out(3)
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file(array[goto])
	
