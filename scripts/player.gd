# res://scripts/player_4d.gd
extends Object4D
class_name Player4D

@export var move_speed := 5.0
@export var drag := 0.95  # Friction/air resistance

func _ready():
	super._ready()  # Call parent's _ready()
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
		velocity_4d += input_4d * move_speed * delta * 10.0
	
	# Apply drag/friction
	velocity_4d *= drag

func on_collision(other: Object4D):
	print("Player collided with: ", other.name)
	# Simple bounce back
	var collision_normal = (position_4d - other.position_4d).normalized()
	velocity_4d += collision_normal * 2.0

func _input(event):
	# Optional: Reset position with R key
	if event.is_action_pressed("ui_cancel"):  # ESC key
		position_4d = Vector4(0, 1, 0, 0)
		velocity_4d = Vector4.ZERO
