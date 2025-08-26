# awakening_camera_controller.gd - Camera system for Scene 1
extends Node3D

@onready var camera = $Camera3D
@onready var animator = $CameraAnimator

func _ready():
	setup_initial_camera()

func setup_initial_camera():
	# Start with camera looking down at the lying player
	camera.position = Vector3(2, 8, 5)
	camera.look_at(Vector3(0, 0, 0), Vector3.UP)

func position_for_awakening():
	# Close shot of player lying down
	move_camera_smooth(Vector3(1, 2, 3), Vector3(0, 0, 0), 0.1)

func adjust_for_standing():
	# Adjust camera when player stands up
	move_camera_smooth(Vector3(2, 3, 5), Vector3(0, 1, 0), 2.0)

func focus_on_environment():
	# Pan to show the overgrown environment
	move_camera_smooth(Vector3(0, 4, 8), Vector3(0, 2, -5), 3.0)

func close_up_hands():
	# Close up shot for looking at hands
	move_camera_smooth(Vector3(0.5, 1.5, 1), Vector3(0, 1, 0), 1.5)

func wide_lonely_shot():
	# Wide shot to emphasize isolation
	move_camera_smooth(Vector3(0, 6, 12), Vector3(0, 1, 0), 3.0)

func move_camera_smooth(target_pos: Vector3, look_at_pos: Vector3, duration: float):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move position
	tween.tween_property(camera, "position", target_pos, duration)
	
	# Smooth rotation towards look_at point
	var look_transform = camera.global_transform.looking_at(look_at_pos, Vector3.UP)
	tween.tween_property(camera, "global_transform", look_transform, duration)

# Alternative method using AnimationPlayer for more complex camera movements
func create_camera_animations():
	if animator:
		# Create awakening sequence animation
		var awakening_anim = Animation.new()
		awakening_anim.length = 5.0
		
		# Position track
		var pos_track = awakening_anim.add_track(Animation.TYPE_POSITION_3D)
		awakening_anim.track_set_path(pos_track, NodePath("Camera3D"))
		awakening_anim.track_insert_key(pos_track, 0.0, Vector3(1, 2, 3))
		awakening_anim.track_insert_key(pos_track, 3.0, Vector3(2, 3, 5))
		awakening_anim.track_insert_key(pos_track, 5.0, Vector3(0, 6, 12))
		
		# Rotation track for smooth looking
		var rot_track = awakening_anim.add_track(Animation.TYPE_ROTATION_3D)
		awakening_anim.track_set_path(rot_track, NodePath("Camera3D"))
		
		var library = AnimationLibrary.new()
		library.add_animation("awakening_sequence", awakening_anim)
		animator.add_animation_library("default", library)
