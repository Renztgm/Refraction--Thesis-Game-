extends Node3D

func _ready():
	add_to_group("bookstore")
	print("Bookstore marker ready at: ", global_position)
