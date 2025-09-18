extends Node3D

var astar := AStar3D.new()

func _ready():
	# Add points for AStar
	astar.add_point(0, Vector3(0,0,0))
	astar.add_point(1, Vector3(10,0,0))
	astar.add_point(2, Vector3(10,0,10))
	astar.add_point(3, Vector3(0,0,10))

	# Connect points
	astar.connect_points(0, 1)
	astar.connect_points(1, 2)
	astar.connect_points(2, 3)
	astar.connect_points(3, 0)
