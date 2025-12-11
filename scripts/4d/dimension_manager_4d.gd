# res://scripts/4d/dimension_manager.gd
extends Node
class_name DimensionManager

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")
const GeometricIntersection = preload("res://scripts/4d/geometric_intersection.gd")

# Current viewing dimension (1-4)
var current_dimension := 4

# W-axis distance/position for 4D slicing
var w_distance := 0.0  # The W coordinate of the current slice

# Slice thickness - objects within this range of the hyperplane are visible/collidable
# This represents the "depth" of the slice in the perpendicular dimension
@export var slice_thickness := 8.0

# geometric hyperplane for slicing
var slice_hyperplane: HyperplaneND = null
var use_geometric_slicing := true

#OLD
# Keeping these for backward compatibility
var slice_plane_offset := Vector3.ZERO  # XYZ offset of the slice plane
var slice_plane_normal := Vector3(0, 0, 1)  # Normal vector of the slice plane in 3D

# Rotation angles for 4D rotations (XW, YW, ZW planes)
var rotation_xw := 0.0
var rotation_yw := 0.0
var rotation_zw := 0.0

# Manual slice rotation for 1D/2D modes (radians)
var slice_rotation_angle := 0.0

# Projection parameters
var projection_distance := 2.0  # Distance from 4D "camera" to projection hyperplane
var projection_origin_3d := Vector3.ZERO  # XYZ point that 4D objects converge toward (updated to player position)

# Rotation center for 4D rotations (ana/kata)
var rotation_center_4d := Vector4.ZERO  # 4D point to rotate around (updated to player position)

func _ready():
	# Initialize with default hyperplane
	slice_hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, 4)

func _process(_delta):
	# Note: W-slice movement is now handled by camera_4d_follow.gd
	# to maintain consistent player perspective
	pass

## NEW: Geometric slicing functions

func is_object_in_slice_geometric(pos_4d: Vector4, radius: float = 0.0) -> bool:
	"""Check if object intersects current slice hyperplane using geometric intersection

	IMPORTANT: Slicing only happens when viewing a LOWER dimension than the object exists in:
	- 4D mode: No slicing (show full 4D volume)
	- 3D mode: Slice 4D objects to 3D
	- 2D mode: Slice 3D/4D objects to 2D
	- 1D mode: Slice 2D/3D/4D objects to 1D
	"""
	if not slice_hyperplane:
		return true

	# In 4D mode, don't slice - show everything
	if current_dimension == 4:
		return true

	# Use sphere-hyperplane intersection test for lower dimensions
	return GeometricIntersection.sphere_hyperplane_intersection(pos_4d, radius + slice_thickness, slice_hyperplane)

func get_slice_hyperplane() -> HyperplaneND:
	"""Get the current slice hyperplane"""
	return slice_hyperplane

func update_slice_hyperplane(camera: Camera3D, player_pos: Vector3):
	"""Manually update the slice hyperplane based on current camera and player position

	Useful for repositioning/reorienting the slice without changing dimensions.
	Press U key to update slice to current camera angle and player position.
	"""
	if not use_geometric_slicing:
		return

	if camera:
		slice_hyperplane = create_hyperplane_from_camera(camera, player_pos, current_dimension)
		print("=== SLICE HYPERPLANE UPDATED ===")
		print("Hyperplane: ", slice_hyperplane.get_debug_string())
		print("Camera angle: ", atan2(-camera.global_transform.basis.z.x, -camera.global_transform.basis.z.z))
		print("Player position: ", player_pos)

	# Also update old system for compatibility
	update_slice_from_camera(camera, player_pos)

func create_hyperplane_from_camera(camera: Camera3D, player_pos: Vector3, dimension: int = 4) -> HyperplaneND:
	"""Create a hyperplane for slicing, passing through player position

	Dimension-specific behavior:
	- 4D: No slicing (default W-aligned hyperplane)
	- 3D: Slices 4D→3D, perpendicular to W-axis (all objects at same W visible)
	- 2D: Slices 3D→2D, rotates with camera (Y-axis only, preserves gravity)
	- 1D: Slices 2D→1D, perpendicular to X-axis
	"""
	if not camera:
		return HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, dimension)

	var cam_forward = -camera.global_transform.basis.z
	var forward_xz = Vector3(cam_forward.x, 0, cam_forward.z).normalized()
	var angle_y = atan2(forward_xz.x, forward_xz.z)

	var normal_4d: Vector4

	match dimension:
		4:
			normal_4d = Vector4(0, 0, 0, 1)
		3:
			# 4D→3D: Pure W-axis normal (flat 3D slice at specific W coordinate)
			# All objects at player's W are visible regardless of camera rotation
			normal_4d = Vector4(0, 0, 0, 1)
		2:
			# 3D→2D: Rotates around Y-axis based on manual rotation
			var c = cos(slice_rotation_angle)
			var s = sin(slice_rotation_angle)
			normal_4d = Vector4(s, 0, c, 0).normalized()
		1:
			# 2D→1D: Rotates around Y-axis based on manual rotation
			var c = cos(slice_rotation_angle)
			var s = sin(slice_rotation_angle)
			normal_4d = Vector4(s, 0, c, 0).normalized()
		_:
			normal_4d = Vector4(0, 0, 0, 1)

	var point_4d = Vector4(player_pos.x, player_pos.y, player_pos.z, w_distance)
	return HyperplaneND.new(normal_4d, point_4d, dimension)

## OLD: Original projection-based functions (kept for compatibility)

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

	# Use absolute distance for symmetric "pass by" behavior
	# Objects are largest when at the same W coordinate, smaller when far in W
	var w_distance_from_player = abs(rotated.w - w_distance)

	# Prevent division issues when very close
	w_distance_from_player = max(w_distance_from_player, 0.01)

	# Inverted formula: objects expand outward as they get further in W
	# This makes objects far in W appear to diverge away from the player
	var w_factor = (projection_distance + w_distance_from_player) / projection_distance

	# Clamp to prevent unbounded growth
	w_factor = min(w_factor, 3.0)

	# Project away from projection_origin_3d based on W distance
	# Objects at same W appear normal size, objects far in W appear larger and further away
	var relative_pos = Vector3(rotated.x, rotated.y, rotated.z) - projection_origin_3d
	return projection_origin_3d + (relative_pos * w_factor)

func apply_4d_rotations(pos: Vector4) -> Vector4:
	# Translate to rotation center (rotate around player instead of world origin)
	var relative_pos = pos - rotation_center_4d
	var result = relative_pos

	# XW rotation
	if rotation_xw != 0:
		result = rotate_xw(result, rotation_xw)

	# YW rotation
	if rotation_yw != 0:
		result = rotate_yw(result, rotation_yw)

	# ZW rotation
	if rotation_zw != 0:
		result = rotate_zw(result, rotation_zw)

	# Translate back
	return result + rotation_center_4d

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

func set_dimension(dim: int, camera: Camera3D = null, player_pos: Vector3 = Vector3.ZERO):
	"""Set dimension and optionally set slice plane based on camera orientation"""
	current_dimension = clamp(dim, 1, 4)
	print("Switched to dimension: ", current_dimension)

	# Initialize slice rotation when entering 1D or 2D
	if current_dimension <= 2:
		if camera:
			# Use camera angle for initial rotation in 2D
			var cam_forward = -camera.global_transform.basis.z
			var forward_xz = Vector3(cam_forward.x, 0, cam_forward.z).normalized()
			slice_rotation_angle = atan2(forward_xz.x, forward_xz.z)
		else:
			# Default to 0 if no camera provided
			slice_rotation_angle = 0.0

	# Update geometric slice hyperplane
	if use_geometric_slicing:
		if camera:
			slice_hyperplane = create_hyperplane_from_camera(camera, player_pos, current_dimension)
			print("=== GEOMETRIC SLICING ACTIVE ===")
			print("Slice hyperplane updated: ", slice_hyperplane.get_debug_string())
			print("Camera angle: ", atan2(-camera.global_transform.basis.z.x, -camera.global_transform.basis.z.z))
		else:
			# Default hyperplane for each dimension
			match current_dimension:
				4: slice_hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, 4)
				3: slice_hyperplane = HyperplaneND.new(Vector4(0, 0, 1, 0), Vector4.ZERO, 3)
				2: slice_hyperplane = HyperplaneND.new(Vector4(0, 0, 1, 0), Vector4.ZERO, 2)
				1: slice_hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4.ZERO, 1)
			print("=== GEOMETRIC SLICING ACTIVE (default hyperplane) ===")

	# If camera is provided, align slice plane with camera view (OLD system)
	if camera and player_pos:
		update_slice_from_camera(camera, player_pos)

func update_slice_from_camera(camera: Camera3D, player_pos: Vector3):
	"""Update slice plane to align with camera's viewing direction"""
	if not camera:
		return

	# Get camera's forward vector (the direction it's looking)
	var cam_forward = -camera.global_transform.basis.z

	# Store the slice plane normal (perpendicular to camera view)
	slice_plane_normal = cam_forward.normalized()

	# Store the slice plane offset (goes through player position)
	slice_plane_offset = player_pos

	print("Slice plane set: normal=", slice_plane_normal, " offset=", slice_plane_offset)

func get_slice_position() -> float:
	"""Get current W-slice position"""
	return w_distance

func set_slice_position(w: float):
	"""Set the W-slice position"""
	w_distance = w
