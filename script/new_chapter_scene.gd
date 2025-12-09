extends CanvasLayer

var NextChapter : int = 0
var player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
func transfer_scene(chapter_num: int) -> void:
	self.visible = true
	var tween = create_tween()
	tween.tween_property($Panel, "modulate:a", 1.0, 0.0)
	NextChapter = chapter_num
	$Label.text = "New Chapter " + str(NextChapter)

func close_panel():
	var tween = create_tween()
	tween.tween_property($Panel, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	self.visible = false

	
func _on_button_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	
	close_panel()
