extends CharacterBody3D

@export var speed := 5.0
var path: Array = []
var target_index := 0
var astar_node: AStar3D
var destination_marker: Marker3D

func _ready():
	var navigation = get_parent().get_node("Navigation")
	astar_node = navigation.astar

	# Get the destination marker
	destination_marker = get_parent().get_node("DestinationMarker")

	# Set initial path to destination
	set_target(destination_marker.global_position)

func _physics_process(delta):
	if path.is_empty() or target_index >= path.size():
		return

	var target_pos = path[target_index]
	var dir = (target_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	if global_position.distance_to(target_pos) < 0.2:
		target_index += 1

# Compute path to a target position
func set_target(target_pos: Vector3):
	if astar_node == null:
		push_error("AStar3D is null!")
		return

	var start_id = astar_node.get_closest_point(global_position)
	var end_id = astar_node.get_closest_point(target_pos)
	path = astar_node.get_point_path(start_id, end_id)
	target_index = 0
