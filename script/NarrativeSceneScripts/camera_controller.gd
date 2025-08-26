extends Node3D

@onready var camera: Camera3D = $"../Camera3D"
@onready var animator: AnimationPlayer = $"../CameraAnimator"

var camera_shots = {
	"wide": {"position": Vector3(0, 2, 8), "rotation": Vector3(0, 0, 0)},
	"close_char1": {"position": Vector3(-1, 1.5, 3), "rotation": Vector3(0, 15, 0)},
	"close_char2": {"position": Vector3(1, 1.5, 3), "rotation": Vector3(0, -15, 0)},
	"awakening": {"position": Vector3(0, 4.5, 4.5), "rotation": Vector3(-30, 0, 0)},
	"standing": {"position": Vector3(0, 6.0, 6.5), "rotation": Vector3(-25, 0, 0)},
	"environment": {"position": Vector3(0, 8.0, 10.0), "rotation": Vector3(-20, 0, 0)},
	"hands": {"position": Vector3(0.3, 1.5, 1.2), "rotation": Vector3(-10, 15, 0)},
	"lonely": {"position": Vector3(0, 14.0, 18.0), "rotation": Vector3(-30, 0, 0)}
}

func move_to_shot(shot_name: String, duration: float = 1.0):
	if shot_name in camera_shots:
		var target = camera_shots[shot_name]
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(camera, "position", target.position, duration)
		tween.tween_property(camera, "rotation_degrees", target.rotation, duration)

# --- Narrative-specific wrappers ---
func position_for_awakening():
	move_to_shot("awakening", 0.0)

func adjust_for_standing():
	move_to_shot("standing", 1.5)

func focus_on_environment():
	move_to_shot("environment", 2.0)

func close_up_hands():
	move_to_shot("hands", 1.2)

func wide_lonely_shot():
	move_to_shot("lonely", 2.5)

func _ready():
	move_to_shot("wide", 0.0)  # Start with wide shot
