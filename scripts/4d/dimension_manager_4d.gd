# res://scripts/4d/dimension_manager.gd
extends Node
class_name DimensionManager

signal dimension_changed(old_dim: int, new_dim: int)
signal slice_position_changed(axis: String, value: float)
signal dimension_switches_changed(remaining: int)

# Current viewing dimension
var current_dimension := 4

# Slice positions for lower dimensions
var slice_x := 0.0  # For viewing 3D slice of 4D
var slice_y := 0.0  # For viewing 2D slice of 3D
var slice_z := 0.0  # For viewing 1D slice of 2D

# Dimension switch limits
var max_dimension_switches := 10
var remaining_switches := 10

# Projection parameters
var w_distance := 3.0
var rotation_xw := 0.0
var rotation_yw := 0.0
var rotation_zw := 0.0

# Slice thickness (objects within this range are visible)
var slice_thickness := 0.5

func _ready():
	pass

## DIMENSION SWITCHING

func can_switch_dimension() -> bool:
	return remaining_switches > 0

func switch_to_dimension(target_dim: int) -> bool:
	# Check if switch is valid
	if not can_switch_dimension():
		push_error("No dimension switches remaining!")
		return false

	if target_dim < 1 or target_dim > 4:
		push_error("Invalid dimension: %d" % target_dim)
		return false

	# Can only switch one dimension at a time
	var dimension_diff = abs(target_dim - current_dimension)
	if dimension_diff != 1:
		push_error("Can only switch one dimension at a time!")
		return false

	var old_dim = current_dimension
	current_dimension = target_dim
	remaining_switches -= 1

	dimension_changed.emit(old_dim, current_dimension)
	dimension_switches_changed.emit(remaining_switches)

	print("Switched from %dD to %dD. Switches remaining: %d" % [old_dim, current_dimension, remaining_switches])

	return true

func increase_dimension() -> bool:
	if current_dimension >= 4:
		return false
	return switch_to_dimension(current_dimension + 1)

func decrease_dimension() -> bool:
	if current_dimension <= 1:
		return false
	return switch_to_dimension(current_dimension - 1)

## SLICING MECHANICS

func set_slice_position(axis: String, value: float):
	"""Set where we're slicing when viewing lower dimensions"""
	match axis:
		"x":
			slice_x = value
		"y":
			slice_y = value
		"z":
			slice_z = value
		_:
			push_error("Invalid slice axis: %s" % axis)
			return

	slice_position_changed.emit(axis, value)

func is_object_in_current_slice(pos_4d: Vector4) -> bool:
	"""Check if an object is visible in the current dimensional slice"""
	match current_dimension:
		1:
			# Viewing 1D: check if object is within Y and Z slice
			return (abs(pos_4d.y - slice_y) < slice_thickness and
					abs(pos_4d.z - slice_z) < slice_thickness and
					abs(pos_4d.w - slice_x) < slice_thickness)
		2:
			# Viewing 2D: check if object is within Z slice
			return (abs(pos_4d.z - slice_z) < slice_thickness and
					abs(pos_4d.w - slice_x) < slice_thickness)
		3:
			# Viewing 3D: check if object is within W slice
			return abs(pos_4d.w - slice_x) < slice_thickness
		4:
			# Viewing 4D: all objects visible
			return true
	return false

## PROJECTION

func project_to_current_dimension(pos_4d: Vector4) -> Vector3:
	"""Project 4D position to 3D visualization based on current dimension"""
	match current_dimension:
		1:
			# Show as point on X axis
			return Vector3(pos_4d.x, 0, 0)

		2:
			# Show XY plane
			return Vector3(pos_4d.x, pos_4d.y, 0)

		3:
			# Show XYZ space
			return Vector3(pos_4d.x, pos_4d.y, pos_4d.z)

		4:
			# Project 4D to 3D using perspective projection
			var w_factor = 1.0 / (w_distance - pos_4d.w)
			return Vector3(
				pos_4d.x * w_factor,
				pos_4d.y * w_factor,
				pos_4d.z * w_factor
			)
	
	return Vector3.ZERO

func get_collision_dimensions() -> int:
	"""How many dimensions to check for collision"""
	return current_dimension

## UTILITY

func reset_switches():
	remaining_switches = max_dimension_switches
	dimension_switches_changed.emit(remaining_switches)

func get_dimensional_description() -> String:
	match current_dimension:
		1: return "1D - Line World"
		2: return "2D - Flatland"
		3: return "3D - Normal Space"
		4: return "4D - Hyperspace"
	return "Unknown"
