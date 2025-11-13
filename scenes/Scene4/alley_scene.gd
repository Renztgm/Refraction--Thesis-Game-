extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FadeOutCanvas.fade_in(1.0)
	ItemPopUp.show_message("📦 Shard Number 1 Collected! ", 2.0, Color.GREEN)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
