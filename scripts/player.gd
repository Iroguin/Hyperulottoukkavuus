# res://scripts/player_4d.gd
extends Object4D
class_name Player4D
signal dimension_switch
signal light
@export var move_speed := 10.0
@export var drag := 0.95  # Friction/air resistance
@export var gravity := 20.0  # Gravity acceleration (downward Y)
@export var jump_force := 10.0  # Jump velocity

var is_on_ground := false

func _ready():
	super._ready()  # Call parent's _ready()
	add_to_group("player")
	print("Player4D initialized at: ", position_4d)

func _process(delta):
	apply_gravity(delta)
	handle_movement(delta)

func apply_gravity(delta):
	# Apply gravity in the negative Y direction
	velocity_4d.y -= gravity * delta

func handle_movement(delta):
	var dim_manager = GameWorld4D.dimension_manager
	var current_dim = dim_manager.current_dimension

	# Get input in local (camera-relative) coordinates
	var input_local = Vector3.ZERO

	# WASD movement
	if Input.is_key_pressed(KEY_W):
		input_local.z += 1
	if Input.is_key_pressed(KEY_S):
		input_local.z -= 1
	if Input.is_key_pressed(KEY_A):
		input_local.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_local.x += 1

	# Convert camera-relative movement to world space (only in 3D/4D)
	var input_4d = Vector4.ZERO

	if current_dim >= 3:
		# Get camera to calculate forward/right directions
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Get camera's forward and right vectors (ignoring Y to keep movement horizontal)
			var cam_forward = -camera.global_transform.basis.z
			var cam_right = camera.global_transform.basis.x

			# Flatten to XZ plane for horizontal movement
			cam_forward.y = 0
			cam_right.y = 0
			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()

			# Combine input with camera directions
			var move_dir = cam_forward * input_local.z + cam_right * input_local.x
			input_4d.x = move_dir.x
			input_4d.z = move_dir.z
	else:
		# In 1D/2D, use absolute movement (no camera rotation)
		input_4d.x = input_local.x
		input_4d.z = input_local.z

	# Jump (only when on ground)
	if Input.is_key_pressed(KEY_SPACE) and is_on_ground:
		velocity_4d.y = jump_force
		is_on_ground = false

	# Manual down movement (Shift)
	if Input.is_key_pressed(KEY_SHIFT):
		input_4d.y -= 1

	# 4D Movement (Q/E for W-axis)
	if Input.is_key_pressed(KEY_I) or Input.is_key_pressed(KEY_E):
		input_4d.w += 1
	if Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_Q):
		input_4d.w -= 1

	# Apply movement
	if input_4d.length() > 0:
		input_4d = input_4d.normalized()
		velocity_4d += input_4d * move_speed * delta

	# Apply drag/friction
	velocity_4d *= drag

func on_collision(other: Object4D):
	print("Player collided with: ", other.name)
	# Simple bounce back
	var collision_normal = (position_4d - other.position_4d).normalized()
	velocity_4d += collision_normal * 2.0

func _input(event):
	# Dimension switching with mouse buttons
	if event is InputEventMouseButton and event.pressed:
		var dim_manager = GameWorld4D.dimension_manager
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Decrease dimension (4D -> 3D -> 2D -> 1D)
			if dim_manager.current_dimension != 1:
				emit_signal("dimension_switch")
			var new_dim = max(1, dim_manager.current_dimension - 1)
			dim_manager.set_dimension(new_dim)
			if new_dim == 2:
				emit_signal("light", false)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Increase dimension (1D -> 2D -> 3D -> 4D)
			if dim_manager.current_dimension != 4:
				emit_signal("dimension_switch")
			var new_dim = min(4, dim_manager.current_dimension + 1)
			dim_manager.set_dimension(new_dim)
			if new_dim == 3:
				emit_signal("light", true)

	# Optional: Reset position with R key
	if event.is_action_pressed("ui_text_backspace"):  # R key
		position_4d = Vector4(0, 1, 0, 0)
		velocity_4d = Vector4.ZERO
