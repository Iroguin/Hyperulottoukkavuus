extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float):
	if Input.is_action_pressed("forw_3d"):
		linear_velocity.z = -1
	else:
		linear_velocity.z =0
