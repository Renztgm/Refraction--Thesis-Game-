extends Control

@onready var map_root = $ScrollContainer/MapRoot
@onready var title_label = $TitleLabel
@onready var description_label = $DescriptionLabel

var node_spacing_x := 250
var node_spacing_y := 120

func _ready():
	var root = load("res://scenes/branch selection/ch1_sn1.tres") as BranchNode
	if root:
		render_node(root, Vector2(0, 0))
	else:
		push_error("❌ Failed to load root node")

func render_node(node: BranchNode, position: Vector2):
	# Create button for this node
	var btn = Button.new()
	btn.text = node.title
	btn.tooltip_text = node.description
	btn.rect_position = position
	btn.pressed.connect(func():
		title_label.text = node.title
		description_label.text = node.description
	)
	map_root.add_child(btn)

	# Render children horizontally below this node
	for i in node.children.size():
		var child = node.children[i]
		var child_pos = position + Vector2((i - node.children.size() / 2.0) * node_spacing_x, node_spacing_y)
		render_node(child, child_pos)
