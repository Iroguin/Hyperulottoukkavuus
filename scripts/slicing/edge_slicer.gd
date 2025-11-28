# res://scripts/slicing/edge_slicer.gd
class_name EdgeSlicer

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")
const GeometricIntersection = preload("res://scripts/4d/geometric_intersection.gd")

## Edge slicing algorithm for N-dimensional meshes
## Calculates intersection points where edges cross a hyperplane

class EdgeIntersection:
	"""Result of slicing an edge with a hyperplane"""
	var intersects: bool = false
	var intersection_point: Vector4 = Vector4.ZERO
	var t: float = 0.0  # Parameter along edge (0 = start, 1 = end)
	var edge_index: int = -1  # Which edge in the face

	func _init(intersects_: bool = false, point: Vector4 = Vector4.ZERO, t_: float = 0.0, edge_idx: int = -1):
		intersects = intersects_
		intersection_point = point
		t = t_
		edge_index = edge_idx

static func slice_edge(start: Vector4, end: Vector4, hyperplane: HyperplaneND) -> EdgeIntersection:
	"""Calculate where an edge crosses a hyperplane

	Args:
		start: Start vertex of edge (4D)
		end: End vertex of edge (4D)
		hyperplane: The slicing hyperplane

	Returns:
		EdgeIntersection with intersection point and parameter t
	"""
	var result = GeometricIntersection.line_hyperplane_intersection(start, end, hyperplane)

	if not result.intersects:
		return EdgeIntersection.new(false)

	# Check if intersection is within the edge (0 <= t <= 1)
	if result.t < 0.0 or result.t > 1.0:
		return EdgeIntersection.new(false)

	return EdgeIntersection.new(true, result.intersection_point, result.t)

static func slice_triangle(v0: Vector4, v1: Vector4, v2: Vector4, hyperplane: HyperplaneND) -> Array[EdgeIntersection]:
	"""Slice a triangle with a hyperplane, returning 0-2 intersection points

	A plane can intersect a triangle in:
	- 0 points: Triangle entirely on one side
	- 1 point: Plane touches exactly one vertex (degenerate case, we skip)
	- 2 points: Plane crosses through triangle (typical case)

	Args:
		v0, v1, v2: Triangle vertices in 4D
		hyperplane: The slicing hyperplane

	Returns:
		Array of EdgeIntersection (0-2 elements)
	"""
	var intersections: Array[EdgeIntersection] = []

	# Check each edge
	var edges = [
		[v0, v1, 0],  # Edge 0: v0->v1
		[v1, v2, 1],  # Edge 1: v1->v2
		[v2, v0, 2]   # Edge 2: v2->v0
	]

	for edge_data in edges:
		var start = edge_data[0]
		var end = edge_data[1]
		var edge_idx = edge_data[2]

		var intersection = slice_edge(start, end, hyperplane)

		if intersection.intersects:
			intersection.edge_index = edge_idx
			intersections.append(intersection)

			# Early exit if we have 2 intersections (max for a triangle)
			if intersections.size() >= 2:
				break

	return intersections

static func slice_quad(v0: Vector4, v1: Vector4, v2: Vector4, v3: Vector4, hyperplane: HyperplaneND) -> Array[EdgeIntersection]:
	"""Slice a quad (4-sided polygon) with a hyperplane

	A plane can intersect a quad in:
	- 0 points: Quad entirely on one side
	- 2 points: Plane crosses through quad (typical case)
	- 4 points: Plane aligned with quad edges (rare, degenerate)

	Args:
		v0, v1, v2, v3: Quad vertices in 4D (counter-clockwise order)
		hyperplane: The slicing hyperplane

	Returns:
		Array of EdgeIntersection (0-4 elements)
	"""
	var intersections: Array[EdgeIntersection] = []

	# Check each edge
	var edges = [
		[v0, v1, 0],  # Edge 0: v0->v1
		[v1, v2, 1],  # Edge 1: v1->v2
		[v2, v3, 2],  # Edge 2: v2->v3
		[v3, v0, 3]   # Edge 3: v3->v0
	]

	for edge_data in edges:
		var start = edge_data[0]
		var end = edge_data[1]
		var edge_idx = edge_data[2]

		var intersection = slice_edge(start, end, hyperplane)

		if intersection.intersects:
			intersection.edge_index = edge_idx
			intersections.append(intersection)

	return intersections

static func classify_vertex(vertex: Vector4, hyperplane: HyperplaneND, epsilon: float = 0.001) -> int:
	"""Classify vertex relative to hyperplane

	Returns:
		-1: Behind hyperplane (negative side)
		 0: On hyperplane (within epsilon)
		+1: In front of hyperplane (positive side)
	"""
	var distance = hyperplane.signed_distance_to_point(vertex)

	if abs(distance) < epsilon:
		return 0  # On plane
	elif distance < 0:
		return -1  # Behind
	else:
		return 1  # In front

static func does_edge_cross_hyperplane(start: Vector4, end: Vector4, hyperplane: HyperplaneND) -> bool:
	"""Quick test if an edge crosses a hyperplane without computing intersection

	An edge crosses if its endpoints are on opposite sides of the hyperplane.
	"""
	var start_side = classify_vertex(start, hyperplane)
	var end_side = classify_vertex(end, hyperplane)

	# Edge crosses if vertices are on opposite sides (one positive, one negative)
	# We don't count vertices exactly on the plane as crossing
	return (start_side > 0 and end_side < 0) or (start_side < 0 and end_side > 0)

static func project_to_slice_space(point_4d: Vector4, hyperplane: HyperplaneND) -> Vector3:
	"""Project a 4D point to 3D space of the slice hyperplane

	This creates a local coordinate system on the hyperplane:
	- Origin: hyperplane.point
	- Normal: perpendicular to slice (removed dimension)
	- Tangent plane: the (N-1)D slice space

	For 4D->3D slicing, we want XYZ coordinates on the slice plane.
	The W component is effectively "flattened" onto the slice.

	Args:
		point_4d: Point on or near the hyperplane
		hyperplane: The slice hyperplane

	Returns:
		Vector3 representing the point's position in slice space
	"""
	# For now, simple implementation: just drop the component most aligned with normal
	# More sophisticated version would create proper tangent space

	# Find which axis is most aligned with the normal
	var normal = hyperplane.normal
	var abs_normal = Vector4(abs(normal.x), abs(normal.y), abs(normal.z), abs(normal.w))

	# Simple projection: drop the dimension with largest normal component
	if abs_normal.w > abs_normal.x and abs_normal.w > abs_normal.y and abs_normal.w > abs_normal.z:
		# W is dominant, project to XYZ
		return Vector3(point_4d.x, point_4d.y, point_4d.z)
	elif abs_normal.z > abs_normal.x and abs_normal.z > abs_normal.y:
		# Z is dominant, project to XYW -> XYZ representation
		return Vector3(point_4d.x, point_4d.y, point_4d.w)
	elif abs_normal.y > abs_normal.x:
		# Y is dominant, project to XZW -> XYZ representation
		return Vector3(point_4d.x, point_4d.z, point_4d.w)
	else:
		# X is dominant, project to YZW -> XYZ representation
		return Vector3(point_4d.y, point_4d.z, point_4d.w)
