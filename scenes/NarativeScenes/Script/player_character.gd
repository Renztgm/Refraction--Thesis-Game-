# player_character.gd
extends CharacterBody3D

var mesh_instance: MeshInstance3D
var animation_player: AnimationPlayer
var is_lying_down = true

func _ready():
	# Ensure MeshInstance3D exists
	if not has_node("MeshInstance3D"):
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
	else:
		mesh_instance = $MeshInstance3D

	# Ensure AnimationPlayer exists
	if not has_node("AnimationPlayer"):
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	else:
		animation_player = $AnimationPlayer

	setup_player_appearance()

	# Start lying down
	rotation_degrees.z = 90  # Lying on side
	position.y = 0.2


func setup_player_appearance():
	# Create a simple capsule for the player
	var capsule = CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.3
	mesh_instance.mesh = capsule

	# Player material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.3, 0.6)  # Dark clothing
	material.roughness = 0.6
	mesh_instance.set_surface_override_material(0, material)

	# Create animations
	create_animations()


func create_animations():
	if not animation_player.has_animation("stand_up"):
		var animation = Animation.new()
		animation.length = 2.0

		# Rotation track
		var rot_track = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(rot_track, NodePath("."))
		animation.track_insert_key(rot_track, 0.0, Quaternion.from_euler(Vector3(0, 0, deg_to_rad(90))))
		animation.track_insert_key(rot_track, 2.0, Quaternion.from_euler(Vector3(0, 0, 0)))

		# Position track
		var pos_track = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(pos_track, NodePath("."))
		animation.track_insert_key(pos_track, 0.0, Vector3(0, 0.2, 0))
		animation.track_insert_key(pos_track, 2.0, Vector3(0, 0.9, 0))

		var library = AnimationLibrary.new()
		library.add_animation("stand_up", animation)
		animation_player.add_animation_library("default", library)


func stand_up():
	is_lying_down = false
	animation_player.play("stand_up")


func look_at_hands():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation_degrees:x", -15, 1.0)
	tween.tween_delay(2.0)
	tween.tween_property(self, "rotation_degrees:x", 0, 1.0)
