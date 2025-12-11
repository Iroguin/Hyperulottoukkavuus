# res://scripts/4d/camera_4d_follow.gd
extends Camera3D

@export var target: Object4D
@export var follow_speed := 100.0
@export var offset := Vector3(0, 3, 8)
@export var follow_w_axis := true  # Whether to follow player in W dimension
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 80.0

var yaw := 0.0  # Horizontal rotation
var pitch := 0.0  # Vertical rotation
var mouse_captured := false
var middle_mouse_pressed := false
var p_key_pressed := false  # Alternative to middle mouse for 4D rotation

# 4D rotation angles (ana/kata are 4D rotation terms)
var rotation_ana := 0.0  # Up/down mouse = rotate around X into W (XW plane)
var rotation_kata := 0.0  # Left/right mouse = rotate around Y into W (YW plane)

func _ready():
	# Capture mouse on start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _input(event):
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true

	# Track middle mouse button
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			middle_mouse_pressed = event.pressed

	# Track P key for 4D rotation
	if event is InputEventKey:
		if event.keycode == KEY_P:
			p_key_pressed = event.pressed

	# Mouse look (only in 3D/4D)
	if event is InputEventMouseMotion and mouse_captured:
		var dim_manager = GameWorld4D.dimension_manager
		if dim_manager and dim_manager.current_dimension >= 3:
			if middle_mouse_pressed or p_key_pressed:
				# Middle mouse or P key: 4D rotation (ana/kata)
				rotation_kata -= event.relative.x * mouse_sensitivity  # Left/right = YW rotation
				rotation_ana -= event.relative.y * mouse_sensitivity  # Up/down = XW rotation
			else:
				# Regular mouse: 3D rotation
				yaw -= event.relative.x * mouse_sensitivity
				pitch -= event.relative.y * mouse_sensitivity
				pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _process(delta):
	if not target:
		return

	# Get dimension manager once
	var dim_manager = GameWorld4D.dimension_manager

	# Set rotation center to player's 4D position
	# This makes ana/kata rotations happen around the player instead of world origin
	dim_manager.rotation_center_4d = target.position_4d

	# Apply 4D rotation angles to dimension manager
	# This rotates the entire 4D space based on camera controls
	dim_manager.rotation_xw = rotation_ana  # Up/down middle mouse
	dim_manager.rotation_yw = rotation_kata  # Left/right middle mouse

	# Follow player's W position to maintain consistent perspective
	if follow_w_axis:
		var current_w = dim_manager.get_slice_position()
		var target_w = target.position_4d.w

		# Smoothly adjust w_distance to follow player
		var new_w = lerp(current_w, target_w, follow_speed * delta)
		dim_manager.set_slice_position(new_w)

	# Get target's 3D projected position
	var target_pos = target.global_position

	# Update 4D projection origin to player's XYZ position
	# This makes 4D perspective converge toward the player instead of world origin
	dim_manager.projection_origin_3d = target_pos

	# Check current dimension for camera behavior
	var current_dim = dim_manager.current_dimension

	var desired_pos: Vector3

	if current_dim <= 2:
		# Lock camera to side view for 1D and 2D
		# Camera looks directly at the XY plane from the side (positive Z)
		desired_pos = target_pos + Vector3(0, 0, 10)
		global_position = global_position.lerp(desired_pos, follow_speed * delta)
		look_at(target_pos)

		# Use orthogonal (parallel) projection for 1D/2D
		projection = PROJECTION_ORTHOGONAL
		size = 10.0  # Orthogonal view size
	else:
		# 3D and 4D: Free mouse look with perspective projection
		projection = PROJECTION_PERSPECTIVE
		fov = 75.0  # Field of view for perspective mode

		# Calculate camera position with mouse look
		# Start with base offset, then rotate it
		var rotated_offset = offset.rotated(Vector3.UP, yaw)
		# Apply pitch by rotating around the right vector
		var right = Vector3.UP.cross(rotated_offset.normalized()).normalized()
		rotated_offset = rotated_offset.rotated(right, pitch)

		# Calculate desired camera position
		desired_pos = target_pos + rotated_offset

		# Smooth follow
		global_position = global_position.lerp(desired_pos, follow_speed * delta)

		# Look at target
		look_at(target_pos)
