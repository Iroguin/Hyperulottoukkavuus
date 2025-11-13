# res://scripts/4d/camera_4d_follow.gd
extends Camera3D

@export var target: Object4D
@export var follow_speed := 5.0
@export var offset := Vector3(0, 3, 8)
@export var follow_w_axis := true  # Whether to follow player in W dimension

func _process(delta):
	if not target:
		return

	# Follow player's W position to maintain consistent perspective
	if follow_w_axis:
		var dim_manager = GameWorld4D.dimension_manager
		var current_w = dim_manager.get_slice_position()
		var target_w = target.position_4d.w

		# Smoothly adjust w_distance to follow player
		var new_w = lerp(current_w, target_w, follow_speed * delta)
		dim_manager.set_slice_position(new_w)

	# Get target's 3D projected position
	var target_pos = target.global_position

	# Calculate desired camera position
	var desired_pos = target_pos + offset

	# Smooth follow
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Look at target
	look_at(target_pos)
