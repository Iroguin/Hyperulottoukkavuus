# res://scripts/4d/hyperplane_nd.gd
extends RefCounted
class_name HyperplaneND

## N-Dimensional Hyperplane
##
## Represents an (N-1)-dimensional hyperplane in N-dimensional space
## Defined by: normal · (x - point) = 0
## Where normal is perpendicular to the hyperplane and point is any point on the hyperplane

var normal: Vector4  # Normal vector (must be unit length)
var point: Vector4   # A point on the hyperplane
var dimension: int   # Dimensionality (3 for 3D plane, 4 for 4D hyperplane, etc.)

func _init(p_normal: Vector4 = Vector4(0, 0, 0, 1), p_point: Vector4 = Vector4.ZERO, p_dimension: int = 4):
	"""Initialize hyperplane with normal vector and a point on the plane"""
	dimension = p_dimension
	point = p_point

	# Normalize the normal vector
	var length = _vector_length(p_normal)
	if length > 0.0001:
		normal = _vector_divide(p_normal, length)
	else:
		# Default to W-axis normal if zero vector provided
		normal = Vector4(0, 0, 0, 1)

func signed_distance_to_point(p: Vector4) -> float:
	"""Calculate signed distance from point to hyperplane

	Positive distance: point is on the side the normal points to
	Negative distance: point is on the opposite side
	Zero: point is on the hyperplane
	"""
	var diff = _vector_subtract(p, point)
	return _dot_product(normal, diff)

func is_point_on_plane(p: Vector4, epsilon: float = 0.0001) -> bool:
	"""Check if point lies on the hyperplane within tolerance"""
	return abs(signed_distance_to_point(p)) < epsilon

func project_point_to_plane(p: Vector4) -> Vector4:
	"""Project a point onto the hyperplane (closest point on plane to p)"""
	var dist = signed_distance_to_point(p)
	return _vector_subtract(p, _vector_multiply(normal, dist))

func rotate_around_y_axis(angle: float) -> HyperplaneND:
	"""Rotate hyperplane around Y-axis (preserves Y component of normal)

	This is used for camera-aligned slicing where gravity must remain consistent.
	The Y-axis always points up, so rotating around it keeps gravity downward.

	For 4D: Rotates in the XZW space, preserving Y
	For 3D: Rotates in the XZ space, preserving Y
	"""
	var c = cos(angle)
	var s = sin(angle)

	var rotated_normal: Vector4

	if dimension == 4:
		# 4D rotation around Y-axis (affects X, Z, W)
		# This is a composite rotation preserving Y
		rotated_normal = Vector4(
			normal.x * c + normal.w * s,  # X component rotates with W
			normal.y,                      # Y preserved
			normal.z * c - normal.w * s,  # Z component affected by W rotation
			-normal.x * s + normal.w * c  # W component rotates with X
		)
	elif dimension == 3:
		# 3D rotation around Y-axis (affects X, Z only)
		rotated_normal = Vector4(
			normal.x * c - normal.z * s,
			normal.y,
			normal.x * s + normal.z * c,
			0
		)
	else:
		# For lower dimensions, no rotation needed
		rotated_normal = normal

	# Create new hyperplane with rotated normal, same point
	return HyperplaneND.new(rotated_normal, point, dimension)

func offset_by_distance(distance: float) -> HyperplaneND:
	"""Create parallel hyperplane offset by distance along normal"""
	var new_point = _vector_add(point, _vector_multiply(normal, distance))
	return HyperplaneND.new(normal, new_point, dimension)

## Helper functions for N-dimensional vector operations
## These work with Vector4 but respect the dimension parameter

func _dot_product(a: Vector4, b: Vector4) -> float:
	"""N-dimensional dot product"""
	match dimension:
		1: return a.x * b.x
		2: return a.x * b.x + a.y * b.y
		3: return a.x * b.x + a.y * b.y + a.z * b.z
		4: return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
	return 0.0

func _vector_length(v: Vector4) -> float:
	"""N-dimensional vector length"""
	return sqrt(_dot_product(v, v))

func _vector_add(a: Vector4, b: Vector4) -> Vector4:
	"""N-dimensional vector addition"""
	return Vector4(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)

func _vector_subtract(a: Vector4, b: Vector4) -> Vector4:
	"""N-dimensional vector subtraction"""
	return Vector4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)

func _vector_multiply(v: Vector4, scalar: float) -> Vector4:
	"""N-dimensional scalar multiplication"""
	return Vector4(v.x * scalar, v.y * scalar, v.z * scalar, v.w * scalar)

func _vector_divide(v: Vector4, scalar: float) -> Vector4:
	"""N-dimensional scalar division"""
	if abs(scalar) < 0.0001:
		return Vector4.ZERO
	return Vector4(v.x / scalar, v.y / scalar, v.z / scalar, v.w / scalar)

## Utility functions

static func from_camera_and_player(camera: Camera3D, player_pos: Vector3, dimension: int = 4) -> HyperplaneND:
	"""Create hyperplane from camera forward vector and player position

	The hyperplane:
	- Is perpendicular to camera's forward direction (in XZ plane components)
	- Passes through the player position
	- Preserves Y-axis for consistent gravity
	"""
	if not camera:
		# Default: W-axis aligned hyperplane
		return HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, dimension)

	# Get camera forward vector (negative Z in camera space)
	var cam_forward = -camera.global_transform.basis.z

	# Project to XZ plane (remove Y component for pure horizontal rotation)
	var forward_xz = Vector3(cam_forward.x, 0, cam_forward.z).normalized()

	# Create normal vector from camera forward
	# For 4D: the normal has X and Z components from camera, W component for depth
	# We'll use a default W component that can be adjusted by rotation
	var normal_4d = Vector4(forward_xz.x, 0, forward_xz.z, 0)

	# If the normal is too close to zero (camera pointing straight up/down)
	if normal_4d.length() < 0.01:
		normal_4d = Vector4(0, 0, 1, 0)  # Default to Z-axis

	# Convert player position to 4D
	var point_4d = Vector4(player_pos.x, player_pos.y, player_pos.z, 0)

	return HyperplaneND.new(normal_4d, point_4d, dimension)

func get_debug_string() -> String:
	"""Get human-readable representation of hyperplane"""
	return "Hyperplane%dD: normal=%s, point=%s" % [
		dimension,
		_vector_to_string(normal),
		_vector_to_string(point)
	]

func _vector_to_string(v: Vector4) -> String:
	"""Format vector based on dimension"""
	match dimension:
		1: return "(%.2f)" % v.x
		2: return "(%.2f, %.2f)" % [v.x, v.y]
		3: return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
		4: return "(%.2f, %.2f, %.2f, %.2f)" % [v.x, v.y, v.z, v.w]
	return str(v)
