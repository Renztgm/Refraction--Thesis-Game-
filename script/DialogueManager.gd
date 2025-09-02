extends Control

@onready var npc_name_label = $NPCName
@onready var dialogue_label = $DialogueLabel
@onready var next_button = $NextButton
@onready var options_container = $Options

var dialogue = {}
var current_node = "start"

# Example data (replace with JSON load later)
var dialogue_data = {
	"start": {
		"name": "Old Man",
		"text": "Hello, traveler. What brings you here?",
		"options": [
			{"text": "I'm looking for adventure.", "next": "adventure"},
			{"text": "Just passing by.", "next": "passing"}
		]
	},
	"adventure": {
		"name": "Old Man",
		"text": "Adventure, you say? I may have a quest for you.",
		"options": [
			{"text": "Tell me more.", "next": "quest"},
			{"text": "Not interested.", "next": "end"}
		]
	},
	"passing": {
		"name": "Old Man",
		"text": "Safe travels, then.",
		"options": [
			{"text": "Goodbye.", "next": "end"}
		]
	},
	"quest": {
		"name": "Village Chief",
		"text": "A dragon is troubling the village. Will you help?",
		"options": [
			{"text": "Yes, I'll help!", "next": "accept_quest"},
			{"text": "No, that's too dangerous.", "next": "end"}
		]
	},
	"accept_quest": {
		"name": "Village Chief",
		"text": "Thank you, hero. The village counts on you!",
		"options": []
	},
	"end": {
		"name": "Old Man",
		"text": "Farewell.",
		"options": []
	}
}

func _ready():
	dialogue = dialogue_data
	show_node(current_node)

func show_node(node_name: String):
	if not dialogue.has(node_name):
		return
	current_node = node_name
	var node = dialogue[node_name]

	# Set NPC name and text
	npc_name_label.text = node.get("name", "Unknown")
	dialogue_label.text = node["text"]

	# Clear old options
	for child in options_container.get_children():
		child.queue_free()

	# Show options if any
	var has_options = node["options"].size() > 0
	options_container.visible = has_options
	next_button.visible = not has_options

	if has_options:
		for option in node["options"]:
			var button = Button.new()
			button.text = option["text"]
			button.connect("pressed", Callable(self, "_on_option_selected").bind(option["next"]))
			options_container.add_child(button)

func _on_option_selected(next_node: String):
	if next_node == "end":
		queue_free() # close dialogue box
	else:
		show_node(next_node)

func _on_NextButton_pressed():
	# Auto go to "end" if no next node
	if not dialogue.has(current_node):
		queue_free()
		return
	var node = dialogue[current_node]

	if node["options"].size() == 0:
		show_node("end")
