extends Node2D

@onready var fragments: Array[Sprite2D] = [
	$"../FragmentsContainer/Fragment1",
	$"../FragmentsContainer/Fragment2",
	$"../FragmentsContainer/Fragment3",
	$"../FragmentsContainer/Fragment4"
]

@onready var completion_label: Label = $"../CompletionLabel"
@export var objective_id: String = "assemble_picture"

var puzzle_solved: bool = false
var puzzle_locked: bool = false   # NEW FLAG

func _ready():
	completion_label.text = ""  
	disassemble_picture()  

func _process(delta):
	if not puzzle_solved and is_puzzle_complete():
		puzzle_solved = true
		puzzle_locked = true
		completion_label.text = ""
		ItemPopUp.show_message("Picture Obtained!")
		QuestManager.complete_objective("complete_picture", str(objective_id))

		var workbench_root = get_parent()  # PuzzleManager is child of Workingbench
		if workbench_root:
			# Wait 10 seconds before starting fade
			await get_tree().create_timer(3.0).timeout

			# Fade out over 3 seconds
			FadeOutCanvas.fade_out(3.0)

			# Wait for fade to finish
			await get_tree().create_timer(3.0).timeout

			# Now free the UI
			workbench_root.queue_free()

			# Optional: fade back in if you want to return to gameplay
			FadeOutCanvas.fade_in(1.0)

			

func disassemble_picture():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for frag in fragments:
		if frag == null:
			continue
		frag.position = Vector2(
			rng.randf_range(0, 512),   # scatter within puzzle area
			rng.randf_range(0, 512)
		)
		print("Scattered", frag.name, "to", frag.position)

func is_puzzle_complete() -> bool:
	for frag in fragments:
		if frag == null:
			continue
		# Compare against each fragment’s own correct_position
		if frag.position.distance_to(frag.correct_position) > 1.0:
			return false
	return true
