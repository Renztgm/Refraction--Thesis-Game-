extends Area3D

@onready var sky_material: ShaderMaterial = $"../Environment/WorldEnvironment".environment.sky.sky_material
@onready var dir_light: DirectionalLight3D = $"../Environment/DirectionalLight3D"

var has_flickered := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player") and not has_flickered:
		print("Player Detected! Flickering Sky + Light (one time)")
		has_flickered = true
		flicker_burst()

func flicker_burst() -> void:
	var sky_states = [0.0, 1.0]
	var light_colors = [Color("a5ff7a"), Color("808080")]
	
	for i in 20: # number of flickers
		sky_material.set("shader_parameter/flicker", sky_states[i % 2])
		dir_light.light_color = light_colors[i % 2]
		await get_tree().create_timer(0.1).timeout
