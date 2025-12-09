extends Control

@export var shard_name: String = "default"
@export var shard_text: String = "default"
@export var shard_texture: Texture2D = preload("res://addons/pngs/shard.png")
var time = 10.0

@onready var shard_texture_node: TextureRect = $Panel/VBoxContainer/shard_texture_node
@onready var shard_name_node: Label = $Panel/VBoxContainer/shard_name_node
@onready var shard_text_node: Label = $Panel/VBoxContainer/shard_text_node

func _ready() -> void:
	shard_name_node.text = shard_name
	shard_text_node.text = shard_text
	shard_texture_node.texture = shard_texture
	countdown()

func countdown():
	await get_tree().create_timer(time).timeout
	get_tree().paused = false
	queue_free()

func _on_close_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
