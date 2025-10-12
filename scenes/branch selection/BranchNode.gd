# BranchNode.gd
extends Resource
class_name BranchNode

@export var title: String
@export var description: String
@export var scene_path: String = ""
@export var children: Array[BranchNode] = []

# Behavior flags
@export var triggers_event: bool = false
@export var event_name: String = ""
@export var is_ending: bool = false
@export var music_track: String = ""
