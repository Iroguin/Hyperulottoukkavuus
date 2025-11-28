extends Node3D

## Controller for 4D tesseract rotation demo
## Applies the 4D projection shader and handles rotation

@export var auto_rotate := true
@export var rotation_speed_xw := 0.3
@export var rotation_speed_yw := 0.5
@export var rotation_speed_zw := 0.4
@export var rotation_speed_xy := 0.2
@export var manual_rotation_speed := 2.0

# Rotation angles (radians)
var angle_xw := 0.0
var angle_yw := 0.0
var angle_zw := 0.0
var angle_xy := 0.0
var angle_xz := 0.0
var angle_yz := 0.0

var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial

func _ready():
	print("=== 4D TESSERACT DEMO ===")
	print("Controls:")
	print("  SPACE - Toggle auto-rotation")
	print("  R - Reset all rotations")
	print("  W/S - Rotate XW plane")
	print("  A/D - Rotate YW plane")
	print("  Q/E - Rotate ZW plane")
	print("  Arrow Keys - 3D rotations (XY, XZ)")
	print("")

	# Find the tesseract mesh
	await get_tree().process_frame  # Wait for scene to be ready

	mesh_instance = find_mesh_instance(self)
	if not mesh_instance:
		push_error("Could not find MeshInstance3D in tesseract!")
		return

	print("Found mesh: ", mesh_instance.name)
	setup_shader()

func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null

func setup_shader():
	# Load the 4D projection shader
	var shader = load("res://shaders/4d_projection.gdshader")
	if not shader:
		push_error("Could not load 4d_projection.gdshader!")
		return

	# Create shader material
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Set initial parameters
	shader_material.set_shader_parameter("w_distance", 3.0)
	update_shader_parameters()

	# Apply to mesh
	mesh_instance.material_override = shader_material

	print("✅ 4D shader applied successfully!")
	print("The tesseract should now show red (W=+1) and black (W=-1) vertices")
	print("")

func _process(delta):
	if not shader_material:
		return

	handle_input(delta)

	# Auto-rotation
	if auto_rotate:
		angle_xw += delta * rotation_speed_xw
		angle_yw += delta * rotation_speed_yw
		angle_zw += delta * rotation_speed_zw
		angle_xy += delta * rotation_speed_xy

	# Update shader with current angles
	update_shader_parameters()

func handle_input(delta):
	# Toggle auto-rotation
	if Input.is_action_just_pressed("ui_accept"):  # SPACE
		auto_rotate = !auto_rotate
		print("Auto-rotation: ", "ON" if auto_rotate else "OFF")

	# Reset rotations
	if Input.is_key_pressed(KEY_R):
		angle_xw = 0.0
		angle_yw = 0.0
		angle_zw = 0.0
		angle_xy = 0.0
		angle_xz = 0.0
		angle_yz = 0.0
		print("Rotations reset")

	# Manual 4D rotations
	if Input.is_key_pressed(KEY_W):
		angle_xw += delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_S):
		angle_xw -= delta * manual_rotation_speed

	if Input.is_key_pressed(KEY_A):
		angle_yw += delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_D):
		angle_yw -= delta * manual_rotation_speed

	if Input.is_key_pressed(KEY_Q):
		angle_zw += delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_E):
		angle_zw -= delta * manual_rotation_speed

	# 3D rotations (arrow keys)
	if Input.is_key_pressed(KEY_UP):
		angle_xz += delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_DOWN):
		angle_xz -= delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_LEFT):
		angle_xy += delta * manual_rotation_speed
	if Input.is_key_pressed(KEY_RIGHT):
		angle_xy -= delta * manual_rotation_speed

func update_shader_parameters():
	shader_material.set_shader_parameter("angle_xw", angle_xw)
	shader_material.set_shader_parameter("angle_yw", angle_yw)
	shader_material.set_shader_parameter("angle_zw", angle_zw)
	shader_material.set_shader_parameter("angle_xy", angle_xy)
	shader_material.set_shader_parameter("angle_xz", angle_xz)
	shader_material.set_shader_parameter("angle_yz", angle_yz)
