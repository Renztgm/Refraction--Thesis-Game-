# awakening_environment.gd - Attach to Environment node
extends Node3D

@onready var world_env = $WorldEnvironment
@onready var light = $DirectionalLight3D
@onready var background = $Background

func _ready():
	setup_awakening_environment()

func setup_awakening_environment():
	# Create the emerald sky environment
	if not world_env.environment:
		var env = Environment.new()
		
		# Emerald/green sky setup
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.2, 0.7, 0.4)  # Emerald green
		
		# Ambient light with greenish tint
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.6, 0.9, 0.7)  # Soft green ambient
		env.ambient_light_energy = 0.4
		
		# Add some fog for mystery
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.02
		env.volumetric_fog_albedo = Color(0.7, 0.9, 0.8)
		
		world_env.environment = env

	# Setup lighting - soft, mysterious
	light.light_energy = 0.8
	light.light_color = Color(0.9, 1.0, 0.8)  # Slightly green-tinted light
	light.rotation_degrees = Vector3(-30, 45, 0)
	light.shadow_enabled = true
	
	# Create overgrown ground with streetlamps
	setup_overgrown_scene()

func setup_overgrown_scene():
	# Ground plane
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(100, 100)
	background.mesh = ground_mesh
	background.position = Vector3(0, 0, 0)
	
	# Ground material - overgrown grass
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.6, 0.2)  # Dark green grass
	ground_material.roughness = 0.8
	background.set_surface_override_material(0, ground_material)
	
	# Add some streetlamps with ivy (we'll create these as simple objects)
	create_overgrown_streetlamps()

func create_overgrown_streetlamps():
	# Create a few streetlamps around the scene
	var lamp_positions = [
		Vector3(-5, 0, -3),
		Vector3(7, 0, -8),
		Vector3(-12, 0, 5),
		Vector3(4, 0, 12)
	]
	
	for pos in lamp_positions:
		create_streetlamp_with_ivy(pos)

func create_streetlamp_with_ivy(pos: Vector3):
	var lamp = Node3D.new()
	lamp.position = pos
	background.add_child(lamp)
	
	# Lamp post (cylinder)
	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.height = 8.0
	post_mesh.top_radius = 0.2
	post_mesh.bottom_radius = 0.3
	post.mesh = post_mesh
	post.position.y = 4.0
	
	# Metal material for post
	var metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.3, 0.3, 0.2)  # Rusty metal
	metal_material.roughness = 0.7
	post.set_surface_override_material(0, metal_material)
	
	lamp.add_child(post)
	
	# Lamp head (sphere)
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.8
	head.mesh = head_mesh
	head.position.y = 8.5
	
	# Glass material for lamp head
	var glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.9, 0.9, 0.7, 0.6)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	head.set_surface_override_material(0, glass_material)
	
	lamp.add_child(head)
	
	# Add ivy effect (green ribbons around the post)
	#add_ivy_to_lamp(lamp)
