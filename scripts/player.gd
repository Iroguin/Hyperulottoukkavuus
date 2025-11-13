# res://scripts/player_4d.gd
extends Object4D
class_name Player4D

@export var move_speed := 5.0
@export var drag := 0.95  # Friction/air resistance

func _ready():
	super._ready()  # Call parent's _ready()
	add_to_group("player")
	print("Player4D initialized at: ", position_4d)

func _process(delta):
	handle_movement(delta)

func handle_movement(delta):
	var input_4d = Vector4.ZERO
	
	# 3D Movement (WASD + Space/Ctrl)
	if Input.is_key_pressed(KEY_W):
		input_4d.z -= 1
	if Input.is_key_pressed(KEY_S):
		input_4d.z += 1
	if Input.is_key_pressed(KEY_A):
		input_4d.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_4d.x += 1
	if Input.is_key_pressed(KEY_SPACE):
		input_4d.y += 1
	if Input.is_key_pressed(KEY_SHIFT):
		input_4d.y -= 1
	
	# 4D Movement (I/K for W-axis)
	if Input.is_key_pressed(KEY_I):
		input_4d.w += 1
	if Input.is_key_pressed(KEY_K):
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
			var new_dim = max(1, dim_manager.current_dimension - 1)
			dim_manager.set_dimension(new_dim)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Increase dimension (1D -> 2D -> 3D -> 4D)
			var new_dim = min(4, dim_manager.current_dimension + 1)
			dim_manager.set_dimension(new_dim)

	# Optional: Reset position with R key
	if event.is_action_pressed("ui_text_backspace"):  # R key
		position_4d = Vector4(0, 1, 0, 0)
		velocity_4d = Vector4.ZERO
