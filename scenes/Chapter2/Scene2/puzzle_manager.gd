extends Node2D

@onready var fragments: Array[Sprite2D] = [
	$"../FragmentsContainer/Fragment1",
	$"../FragmentsContainer/Fragment2",
	$"../FragmentsContainer/Fragment3",
	$"../FragmentsContainer/Fragment4"
]

@onready var completion_label: Label = $"../CompletionLabel"

var puzzle_solved: bool = false
var puzzle_locked: bool = false   # NEW FLAG

func _ready():
	completion_label.text = ""  
	disassemble_picture()  

func _process(delta):
	if not puzzle_solved and is_puzzle_complete():
		puzzle_solved = true
		puzzle_locked = true   # lock puzzle once solved
		completion_label.text = ""
		ItemPopUp.show_message("Picture Obtained!")

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
