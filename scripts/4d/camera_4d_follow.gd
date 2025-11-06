# res://scripts/4d/camera_4d_follow.gd
extends Camera3D

@export var target: Object4D
@export var follow_speed := 5.0
@export var offset := Vector3(0, 3, 8)

func _process(delta):
	if not target:
		return
	
	# Get target's 3D projected position
	var target_pos = target.global_position
	
	# Calculate desired camera position
	var desired_pos = target_pos + offset
	
	# Smooth follow
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
	# Look at target
	look_at(target_pos)
