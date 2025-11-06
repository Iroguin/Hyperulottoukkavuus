extends Node3D

var mesh_instance: MeshInstance3D
var material: ShaderMaterial

# Rotation angles
var angle_xw = 0.0
var angle_yw = 0.0
var angle_zw = 0.0
var angle_xy = 0.0
var angle_xz = 0.0
var angle_yz = 0.0

# Settings
var auto_rotate = true
var manual_speed = 2.5
var auto_speed_xw = 0.3
var auto_speed_yw = 0.5
var auto_speed_zw = 0.7
var auto_speed_xy = 0.2

func _ready():
	create_tesseract()
	setup_shader()

func create_tesseract():
	var vertices_3d = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Generate 16 vertices (all combinations of ±1 in 4D space)
	for i in range(16):
		var x = 1.0 if (i & 1) else -1.0
		var y = 1.0 if (i & 2) else -1.0
		var z = 1.0 if (i & 4) else -1.0
		var w = 1.0 if (i & 8) else -1.0
		
		vertices_3d.append(Vector3(x, y, z))
		# Store W coordinate in red channel (normalized to 0-1)
		colors.append(Color(w * 0.5 + 0.5, 0, 0, 1))
	
	# Create edges connecting adjacent 4D vertices
	for i in range(16):
		for j in range(i + 1, 16):
			var diff_count = 0
			for bit in range(4):
				if (i & (1 << bit)) != (j & (1 << bit)):
					diff_count += 1
			if diff_count == 1:  # Adjacent in 4D space
				indices.append(i)
				indices.append(j)
	
	# Build mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices_3d
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)

func setup_shader():
	var shader = load("res://shaders/hypercube_4d.gdshader")
	if not shader:
		print("No Shader Found")
	material = ShaderMaterial.new()
	material.shader = shader
	
	# Initialize shader parameters
	material.set_shader_parameter("w_distance", 3.0)
	material.set_shader_parameter("angle_xw", 0.0)
	material.set_shader_parameter("angle_yw", 0.0)
	material.set_shader_parameter("angle_zw", 0.0)
	material.set_shader_parameter("angle_xy", 0.0)
	material.set_shader_parameter("angle_xz", 0.0)
	material.set_shader_parameter("angle_yz", 0.0)
	
	mesh_instance.material_override = material

func _process(delta):
	handle_input(delta)
	
	# Auto-rotation
	if auto_rotate:
		angle_xw += delta * auto_speed_xw
		angle_yw += delta * auto_speed_yw
		angle_zw += delta * auto_speed_zw
		angle_xy += delta * auto_speed_xy
	
	# Update shader with current angles
	update_shader()

func handle_input(delta):
	# Manual rotation controls
	if Input.is_key_pressed(KEY_W):
		angle_xw += delta * manual_speed
	if Input.is_key_pressed(KEY_S):
		angle_xw -= delta * manual_speed
	if Input.is_key_pressed(KEY_A):
		angle_yw += delta * manual_speed
	if Input.is_key_pressed(KEY_D):
		angle_yw -= delta * manual_speed
	if Input.is_key_pressed(KEY_Q):
		angle_zw += delta * manual_speed
	if Input.is_key_pressed(KEY_E):
		angle_zw -= delta * manual_speed
	
	# 3D rotations (Arrow keys)
	if Input.is_key_pressed(KEY_UP):
		angle_xz += delta * manual_speed
	if Input.is_key_pressed(KEY_DOWN):
		angle_xz -= delta * manual_speed
	if Input.is_key_pressed(KEY_LEFT):
		angle_xy += delta * manual_speed
	if Input.is_key_pressed(KEY_RIGHT):
		angle_xy -= delta * manual_speed
	
	# Toggle auto-rotation
	if Input.is_action_just_pressed("ui_accept"):  # Space
		auto_rotate = !auto_rotate
	
	# Reset rotations
	if Input.is_key_pressed(KEY_R):
		angle_xw = 0.0
		angle_yw = 0.0
		angle_zw = 0.0
		angle_xy = 0.0
		angle_xz = 0.0
		angle_yz = 0.0

func update_shader():
	material.set_shader_parameter("angle_xw", angle_xw)
	material.set_shader_parameter("angle_yw", angle_yw)
	material.set_shader_parameter("angle_zw", angle_zw)
	material.set_shader_parameter("angle_xy", angle_xy)
	material.set_shader_parameter("angle_xz", angle_xz)
	material.set_shader_parameter("angle_yz", angle_yz)
