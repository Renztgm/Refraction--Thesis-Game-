extends CanvasLayer
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/name
@onready var position_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/position
var names = ["Jhon Lorenz Bacon", "Justine Zyrie Dungao", "Timothy Jhon Enriquez", "Shane Laure"]
var positions = ["Programmer", "Writer/Project Manager", "Artist", "Researcher"]

func _ready() -> void:
	name_label.modulate = 0
	position_label.modulate = 0
	credits()

func credits():
	for i in range(names.size()):
		name_label.text = names[i]
		position_label.text = positions[i]
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(name_label, "modulate:a", 1, 0.5)
		tween.tween_property(position_label, "modulate:a", 1, 0.5)
		await tween.finished
		
		await get_tree().create_timer(2.0).timeout
		
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(name_label, "modulate:a", 0.0, 0.5)
		tween.tween_property(position_label, "modulate:a", 0.0, 0.5)
		await tween.finished
