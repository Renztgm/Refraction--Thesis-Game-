extends CanvasLayer


func _ready() -> void:
	$Panel.visible = false

func show_quest(quest: String) -> void:
	$Panel.visible = true
	var tween = create_tween()
	tween.tween_property($Panel, "modulate:a", 1.0, 0.3)
	var quest_name_label = $Panel/QuestName
	quest_name_label.text = quest
	
	await get_tree().create_timer(3).timeout
	fading_out()
func fading_out():
	var tween = create_tween()
	tween.tween_property($Panel, "modulate:a", 0.0, 0.3)
	await get_tree().create_timer(0.3).timeout
	$Panel.visible = false
