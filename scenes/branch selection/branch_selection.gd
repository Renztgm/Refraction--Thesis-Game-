extends Node2D

@onready var map_root = $MapRoot
@onready var title_label = $TitleLabel
@onready var description_label = $DescriptionLabel
@onready var line_layer: Node2D = $LineLayer

var dragging := false
var drag_origin := Vector2()

var node_spacing_x := 250
var node_spacing_y := 150

func _ready():
	var root = load("res://scenes/branch selection/ch1_sn1.tres") as BranchNode
	if root:
		render_node(root, Vector2(0, 0))
	else:
		push_error("❌ Failed to load root node")

func render_node(node: BranchNode, position: Vector2):
	# Create button
	var btn = Button.new()
	btn.text = node.title
	btn.tooltip_text = node.description
	btn.position = position
	btn.connect("pressed", func():
		title_label.text = node.title
		description_label.text = node.description
	)
	map_root.add_child(btn)

	# Store this button’s position for line drawing
	var parent_pos = position + btn.size / 2  # center of button

	# Render children and draw lines
	for i in node.children.size():
		var child = node.children[i]
		var offset_x = (i - node.children.size() / 2.0) * node_spacing_x
		var child_pos = position + Vector2(offset_x, node_spacing_y)
		render_node(child, child_pos)

		# Draw line from parent to child
		var line = Line2D.new()
		line.width = 2
		line.default_color = Color.SKY_BLUE
		line.add_point(parent_pos)
		line.add_point(child_pos + btn.size / 2)
		line_layer.add_child(line)





func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_origin = event.position
			else:
				dragging = false

	elif event is InputEventMouseMotion and dragging:
		var delta = drag_origin - event.position
		$Camera2D.position += delta
		drag_origin = event.position
	
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$Camera2D.zoom *= 0.9
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$Camera2D.zoom *= 1.1
