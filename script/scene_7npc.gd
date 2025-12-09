extends Area3D

@export var dialogue_file: String = "res://dialogues/Scene7.json"
@export var npc_id: String = "npc_1"

var dialogue_manager: Node = null
var dialogue_triggered: bool = false
var dialogue_active: bool = false       # Track if dialogue is currently active
var can_move: bool = true                # Optional: NPC movement lock
var player_node: Node = null             # Reference to the player                # NPC ID in dialogue JSON

func _ready():	
	player_node = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)
	# Optionally connect body_exited if you want to reset the trigger
	# body_exited.connect(_on_body_exited)

	# Get the DialogueManager node
	dialogue_manager = get_node("/root/Scene7/DialogueManager") # Adjust path

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not dialogue_triggered:
		_start_dialogue()
	

# Optional: reset trigger when player leaves
# func _on_body_exited(body):
#     if body.name == "Player":
#         dialogue_triggered = false

func _start_dialogue():
	# Prevent retriggering
	if dialogue_active or dialogue_triggered:
		return

	dialogue_active = true
	dialogue_triggered = true
	can_move = false

	# Freeze the player safely
	if player_node and player_node.has_method("freeze_player"):
		player_node.freeze_player()

	# Load dialogue via DialogueManager
	if dialogue_manager:
		dialogue_manager.load_dialogue(dialogue_file, npc_id)
		# Connect to signal to unfreeze player when dialogue ends
		dialogue_manager.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	can_move = true
	
	var target_script_node = get_tree().current_scene
	if target_script_node.has_method("go_to_end_chapter"):
		target_script_node.go_to_end_chapter()
	else: 
		push_error("There is no go_to_end_chapter")

	# Unfreeze the player
	if player_node and player_node.has_method("unfreeze_player"):
		player_node.unfreeze_player()
	
