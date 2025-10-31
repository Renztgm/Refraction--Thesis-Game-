extends Node3D

@onready var fade_overlay: ColorRect = $Fade/FadeOverlay
@onready var door_area: Area3D = $Area3D  # Your door collision area

var is_transitioning: bool = false

func _ready():
	# Fade in Scene 7
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 2.0)
	
	# Connect door collision
	if door_area:
		door_area.body_entered.connect(_on_door_entered)

func _on_door_entered(body):
	"""Called when player enters the door"""
	if body.is_in_group("player") and not is_transitioning:
		is_transitioning = true
		go_to_end_chapter()

func go_to_end_chapter():
	# Fade to black
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 0)
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
		await tween.finished

	# ✅ Log scene completion
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "scene_7"
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Scene 7 logged:", scene_path)
		else:
			print("ℹ️ Scene 7 already logged or failed to log.")

		# ✅ Set chapter info for next scene
		SaveManager.set_current_chapter(1)
		SaveManager.set_next_scene_path("res://scenes/Chapter2/Scene1/Chapter2Scene1.tscn")

	# Load end chapter scene
	get_tree().change_scene_to_file("res://scenes/UI/endchapterscene.tscn")
