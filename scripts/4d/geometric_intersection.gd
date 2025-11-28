# res://scripts/4d/geometric_intersection.gd
extends RefCounted
class_name GeometricIntersection

## Geometric Intersection Utilities
##
## Provides functions for calculating intersections between various geometric primitives
## and hyperplanes in N-dimensional space. Core functionality for mesh slicing.

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")

## Result structure for line-hyperplane intersection
class LineIntersectionResult:
	var intersects: bool = false
	var intersection_point: Vector4 = Vector4.ZERO
	var t: float = 0.0  # Parameter along line (0 = start, 1 = end)

	func _init(p_intersects: bool = false, p_point: Vector4 = Vector4.ZERO, p_t: float = 0.0):
		intersects = p_intersects
		intersection_point = p_point
		t = p_t

## Calculate intersection between a line segment and a hyperplane
static func line_hyperplane_intersection(
	line_start: Vector4,
	line_end: Vector4,
	hyperplane: HyperplaneND,
	epsilon: float = 0.0001
) -> LineIntersectionResult:
	"""
	Find intersection point between line segment and hyperplane.

	Returns:
	- intersects: true if intersection exists within segment
	- intersection_point: the point of intersection
	- t: parameter along line (0 = start, 1 = end)

	Mathematics:
	Line: P(t) = start + t * (end - start), where t ∈ [0, 1]
	Hyperplane: normal · (P - point) = 0

	Substituting:
	normal · (start + t * direction - point) = 0
	normal · (start - point) + t * (normal · direction) = 0
	t = -normal · (start - point) / (normal · direction)
	"""

	var direction = _vector_subtract(line_end, line_start, hyperplane.dimension)
	var start_to_plane = _vector_subtract(line_start, hyperplane.point, hyperplane.dimension)

	var denominator = _dot_product(hyperplane.normal, direction, hyperplane.dimension)
	var numerator = -_dot_product(hyperplane.normal, start_to_plane, hyperplane.dimension)

	# Check if line is parallel to hyperplane
	if abs(denominator) < epsilon:
		# Line is parallel - either entirely on plane or never intersects
		if abs(numerator) < epsilon:
			# Line is on the plane - return start point
			return LineIntersectionResult.new(true, line_start, 0.0)
		else:
			# Line is parallel but not on plane - no intersection
			return LineIntersectionResult.new(false)

	# Calculate t parameter
	var t = numerator / denominator

	# Check if intersection is within line segment [0, 1]
	if t < -epsilon or t > 1.0 + epsilon:
		# Intersection exists on infinite line, but not on this segment
		return LineIntersectionResult.new(false)

	# Clamp t to [0, 1] to handle floating point precision
	t = clamp(t, 0.0, 1.0)

	# Calculate intersection point
	var intersection = _vector_add(
		line_start,
		_vector_multiply(direction, t, hyperplane.dimension),
		hyperplane.dimension
	)

	return LineIntersectionResult.new(true, intersection, t)

## Check if a sphere/hypersphere intersects a hyperplane
static func sphere_hyperplane_intersection(
	sphere_center: Vector4,
	sphere_radius: float,
	hyperplane: HyperplaneND
) -> bool:
	"""
	Check if sphere intersects hyperplane.
	Returns true if any part of the sphere touches or crosses the hyperplane.
	"""
	var distance = hyperplane.signed_distance_to_point(sphere_center)
	return abs(distance) <= sphere_radius

## Check if an axis-aligned bounding box intersects a hyperplane
static func aabb_hyperplane_intersection(
	aabb_min: Vector4,
	aabb_max: Vector4,
	hyperplane: HyperplaneND
) -> bool:
	"""
	Check if AABB intersects hyperplane using separating axis test.
	Returns true if any part of the box touches or crosses the hyperplane.
	"""

	# Get AABB center and half-extents
	var center = _vector_multiply(
		_vector_add(aabb_min, aabb_max, hyperplane.dimension),
		0.5,
		hyperplane.dimension
	)
	var half_extents = _vector_multiply(
		_vector_subtract(aabb_max, aabb_min, hyperplane.dimension),
		0.5,
		hyperplane.dimension
	)

	# Calculate distance from center to plane
	var distance = hyperplane.signed_distance_to_point(center)

	# Calculate projected radius (maximum distance any corner can be from center along normal)
	var projected_radius = (
		abs(hyperplane.normal.x) * half_extents.x +
		abs(hyperplane.normal.y) * half_extents.y +
		abs(hyperplane.normal.z) * half_extents.z +
		abs(hyperplane.normal.w) * half_extents.w
	)

	return abs(distance) <= projected_radius

## Project a point onto a line segment (closest point on segment to point)
static func project_point_to_line_segment(
	point: Vector4,
	line_start: Vector4,
	line_end: Vector4,
	dimension: int
) -> Vector4:
	"""
	Find the closest point on line segment to given point.
	"""
	var direction = _vector_subtract(line_end, line_start, dimension)
	var point_to_start = _vector_subtract(point, line_start, dimension)

	var direction_length_sq = _dot_product(direction, direction, dimension)

	if direction_length_sq < 0.0001:
		# Line segment is essentially a point
		return line_start

	var t = _dot_product(point_to_start, direction, dimension) / direction_length_sq
	t = clamp(t, 0.0, 1.0)

	return _vector_add(line_start, _vector_multiply(direction, t, dimension), dimension)

## Determine which side of hyperplane a point is on
static func point_side_of_hyperplane(point: Vector4, hyperplane: HyperplaneND, epsilon: float = 0.0001) -> int:
	"""
	Returns:
	 1 if point is on positive side (direction of normal)
	 0 if point is on the hyperplane
	-1 if point is on negative side
	"""
	var distance = hyperplane.signed_distance_to_point(point)

	if abs(distance) < epsilon:
		return 0
	elif distance > 0:
		return 1
	else:
		return -1

## Helper functions for N-dimensional vector operations

static func _dot_product(a: Vector4, b: Vector4, dimension: int) -> float:
	match dimension:
		1: return a.x * b.x
		2: return a.x * b.x + a.y * b.y
		3: return a.x * b.x + a.y * b.y + a.z * b.z
		4: return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
	return 0.0

static func _vector_add(a: Vector4, b: Vector4, dimension: int) -> Vector4:
	return Vector4(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)

static func _vector_subtract(a: Vector4, b: Vector4, dimension: int) -> Vector4:
	return Vector4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)

static func _vector_multiply(v: Vector4, scalar: float, dimension: int) -> Vector4:
	return Vector4(v.x * scalar, v.y * scalar, v.z * scalar, v.w * scalar)

static func _vector_length(v: Vector4, dimension: int) -> float:
	return sqrt(_dot_product(v, v, dimension))
