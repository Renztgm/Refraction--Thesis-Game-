extends Node3D

var dialogue_active: bool = false
var dialogue_triggered: bool = false

@export var dialogue_file_path: String = "res://dialogues/Chapter3Scene2.json"
@export var npc_id: String = "Companion"

@export var dialogue_area_path: NodePath
@export var interact_label_path: NodePath

@onready var dialogue_area: Area3D = get_node_or_null(dialogue_area_path)
@onready var interact_label: Node = get_node_or_null(interact_label_path)

var player: Node = null

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	#if dialogue_area:
		#dialogue_area.body_entered.connect(_on_area_3d_body_entered)
##
#func start_dialogue():
	#if dialogue_active or dialogue_triggered:
		#return
#
	#dialogue_active = true
	#dialogue_triggered = true
#
	#if player and player.has_method("freeze_player"):
		#player.freeze_player()
#
	#if interact_label:
		#interact_label.visible = false
#
	#var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	#get_tree().current_scene.add_child(dialogue_box)
#
	#dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	#dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
#
#func _on_dialogue_finished():
	#dialogue_active = false
	#if player and player.has_method("unfreeze_player"):
		#player.unfreeze_player()
		#FadeOutCanvas.fade_out(1)
		#get_tree().change_scene_to_file("res://scenes/Chapter3/Straight/Scene2/Chapter3Scene2.tscn")
#
##func _on_area_3d_body_entered(body: Node3D) -> void:
	##if body.is_in_group("player"):
		##start_dialogue()
		##print(player)
