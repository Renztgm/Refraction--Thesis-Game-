extends Area3D

@onready var next_scene: String = ""
@onready var label: Label3D	= $Label3D
@onready var player = get_tree().get_nodes_in_group("player")
@onready var player_in_area: Node
func _ready() -> void:
	label.visible = false

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		_interact()

func _interact():
		# ✅ If both conditions pass → open workbench
		var ui = preload("res://scenes/Chapter3/Straight/Scene2/WorkingBenchCylinderStructure.tscn").instantiate()
		get_tree().root.add_child(ui)
		
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = body
		label.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		label.visible = false
