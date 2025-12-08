extends Control

var guide_instance: Node = null # ahhh may nagadd ng child

func _ready() -> void:
	pass # Replace with function body.

func _on_button_mouse_entered() -> void:
	if guide_instance == null: 
		guide_instance = preload("res://scenes/UI/legends.tscn").instantiate()
		get_tree().root.add_child(guide_instance)


func _on_button_mouse_exited() -> void:
	if guide_instance and guide_instance.is_inside_tree():
		guide_instance.queue_free()
		guide_instance = null
