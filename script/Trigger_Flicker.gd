extends Area3D

@onready var sky_material: ShaderMaterial = $"../Environment/WorldEnvironment".environment.sky.sky_material
@onready var dir_light: DirectionalLight3D = $"../Environment/DirectionalLight3D"
@onready var player: CharacterBody3D = $"../Player3d"
@onready var shadow: CharacterBody3D = $"../shadow"
@onready var static_audio: AudioStreamPlayer = $"../StaticAudio"
@onready var dialogue_manager: Control = $"../DialogueManager"
@onready var screen_warp: Control = $"../ScreenWarp"

var has_triggered := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Ensure ScreenWarp is OFF at start
	if screen_warp:
		screen_warp.visible = false
		screen_warp.mouse_filter = Control.MOUSE_FILTER_IGNORE  # avoid blocking clicks

func _on_body_entered(body):
	if body.is_in_group("player") and not has_triggered:
		has_triggered = true
		_trigger_event()

func _trigger_event() -> void:
	print("Player Detected! Initiating shadow encounter.")
	
	# 1. Freeze player
	if player and player.has_method("freeze_player"):
		player.freeze_player()

	# 2. Static + warp ON
	if static_audio:
		static_audio.play()
	if screen_warp:
		screen_warp.visible = true
	
	# 3. Shadow + flicker
	if shadow:
		shadow.visible = true
	await flicker_burst()
	
	# 4. Start dialogue
	dialogue_manager.load_dialogue("res://dialogues/shadow_event.json", "shadow_event")
	
	# 🔄 No early disappearance here – shadow stays during dialogue
	
	# 5. Wait until dialogue fully ends
	await dialogue_manager.dialogue_finished
	
	# 6. Shadow vanishes + silence + warp OFF + unfreeze
	if shadow:
		shadow.visible = false
	if static_audio:
		static_audio.stop()
	if screen_warp:
		screen_warp.visible = false
	if player and player.has_method("unfreeze_player"):
		player.unfreeze_player()

	print("Shadow vanished after dialogue finished.")

func flicker_burst() -> void:
	var sky_states = [0.0, 1.0]
	var light_colors = [Color("a5ff7a"), Color("808080")]
	
	for i in 20:
		sky_material.set("shader_parameter/flicker", sky_states[i % 2])
		dir_light.light_color = light_colors[i % 2]
		await get_tree().create_timer(0.1).timeout
