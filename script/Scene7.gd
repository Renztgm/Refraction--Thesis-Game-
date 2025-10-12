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
	"""Transition to end chapter scene with fade"""
	
	# Fade to black (or white)
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 0)  # Start transparent
		var tween = create_tween()
		
		# Choose one:
		# Black fade:
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
		
		# White fade (uncomment if you prefer white):
		# tween.tween_property(fade_overlay, "color", Color(1, 1, 1, 1), 1.5)
		
		await tween.finished
	
	# Load end chapter scene
	var end_scene = preload("res://scenes/UI/endchapterscene.tscn").instantiate()
	end_scene.setup_end_chapter_from_db(1, "res://scenes/chapter_2.tscn")
	get_tree().root.add_child(end_scene)
	
	# Remove Scene 7
	queue_free()
