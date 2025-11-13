# res://scripts/4d/dimension_manager.gd
extends Node
class_name DimensionManager

# Current viewing dimension (1-4)
var current_dimension := 4

# W-axis distance/position for 4D slicing
var w_distance := 0.0  # The W coordinate of the current slice

# Slice thickness - objects within this range of w_distance are visible
var slice_thickness := 2.0

# Rotation angles for 4D rotations (XW, YW, ZW planes)
var rotation_xw := 0.0
var rotation_yw := 0.0
var rotation_zw := 0.0

# Projection parameters
var projection_distance := 2.0  # Distance from 4D "camera" to projection hyperplane

func _process(_delta):
	# Note: W-slice movement is now handled by camera_4d_follow.gd
	# to maintain consistent player perspective
	pass

func is_object_in_current_slice(pos_4d: Vector4) -> bool:
	"""Check if object is within the current W-slice"""
	if current_dimension < 4:
		# In lower dimensions, we don't slice by W
		return true
	
	# Check if object's W coordinate is within slice thickness
	var w_diff = abs(pos_4d.w - w_distance)
	return w_diff <= slice_thickness

func project_to_current_dimension(pos_4d: Vector4) -> Vector3:
	match current_dimension:
		1: return project_to_1d(pos_4d)
		2: return project_to_2d(pos_4d)
		3: return project_to_3d(pos_4d)
		4: return project_4d_to_3d(pos_4d)
	return Vector3.ZERO

func project_to_1d(pos_4d: Vector4) -> Vector3:
	# Show only X axis (side view, Y=0 fixed)
	return Vector3(pos_4d.x, 0, 0)

func project_to_2d(pos_4d: Vector4) -> Vector3:
	# Show X and Y as side view (XY plane viewed from the side)
	# Z is always 0 to keep it flat against the "screen"
	return Vector3(pos_4d.x, pos_4d.y, 0)

func project_to_3d(pos_4d: Vector4) -> Vector3:
	# Show X, Y, Z normally (ignoring W)
	return Vector3(pos_4d.x, pos_4d.y, pos_4d.z)

func project_4d_to_3d(pos_4d: Vector4) -> Vector3:
	# Apply 4D rotations first
	var rotated = apply_4d_rotations(pos_4d)

	# Perspective projection from 4D to 3D
	# Similar to 3D to 2D perspective: divide by distance
	var w_offset = rotated.w - w_distance

	# Clamp w_offset to prevent objects from going "behind" the 4D camera
	# This is analogous to near-plane clipping in 3D graphics
	# Objects closer than 0.1 units in W-space are clamped
	var min_w_offset = -projection_distance + 0.1
	w_offset = max(w_offset, min_w_offset)

	var w_factor = projection_distance / (projection_distance + w_offset)

	return Vector3(
		rotated.x * w_factor,
		rotated.y * w_factor,
		rotated.z * w_factor
	)

func apply_4d_rotations(pos: Vector4) -> Vector4:
	var result = pos
	
	# XW rotation
	if rotation_xw != 0:
		result = rotate_xw(result, rotation_xw)
	
	# YW rotation
	if rotation_yw != 0:
		result = rotate_yw(result, rotation_yw)
	
	# ZW rotation
	if rotation_zw != 0:
		result = rotate_zw(result, rotation_zw)
	
	return result

func rotate_xw(pos: Vector4, angle: float) -> Vector4:
	var c = cos(angle)
	var s = sin(angle)
	return Vector4(
		pos.x * c - pos.w * s,
		pos.y,
		pos.z,
		pos.x * s + pos.w * c
	)

func rotate_yw(pos: Vector4, angle: float) -> Vector4:
	var c = cos(angle)
	var s = sin(angle)
	return Vector4(
		pos.x,
		pos.y * c - pos.w * s,
		pos.z,
		pos.y * s + pos.w * c
	)

func rotate_zw(pos: Vector4, angle: float) -> Vector4:
	var c = cos(angle)
	var s = sin(angle)
	return Vector4(
		pos.x,
		pos.y,
		pos.z * c - pos.w * s,
		pos.z * s + pos.w * c
	)

func set_dimension(dim: int):
	current_dimension = clamp(dim, 1, 4)
	print("Switched to dimension: ", current_dimension)

func get_slice_position() -> float:
	"""Get current W-slice position"""
	return w_distance

func set_slice_position(w: float):
	"""Set the W-slice position"""
	w_distance = w
