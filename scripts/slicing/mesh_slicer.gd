# res://scripts/slicing/mesh_slicer.gd
class_name MeshSlicer

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")
const EdgeSlicer = preload("res://scripts/slicing/edge_slicer.gd")

## Mesh slicing core algorithm
## Generates (N-1)-dimensional polygons from N-dimensional mesh intersections

class SliceContour:
	"""A closed contour (polygon) formed by slicing a mesh"""
	var points_4d: Array[Vector4] = []  # Points in 4D space
	var points_3d: Array[Vector3] = []  # Projected to 3D slice space
	var face_indices: Array[int] = []   # Which faces contributed points

	func _init():
		points_4d = []
		points_3d = []
		face_indices = []

	func add_point(point_4d: Vector4, point_3d: Vector3, face_idx: int = -1):
		points_4d.append(point_4d)
		points_3d.append(point_3d)
		face_indices.append(face_idx)

	func is_valid() -> bool:
		"""Check if contour forms a valid polygon (at least 3 points)"""
		return points_3d.size() >= 3

	func is_closed() -> bool:
		"""Check if first and last points are close (closed loop)"""
		if points_3d.size() < 2:
			return false

		var first = points_3d[0]
		var last = points_3d[points_3d.size() - 1]
		return first.distance_to(last) < 0.001

class Mesh4D:
	"""Represents a 4D mesh with vertices and triangular faces"""
	var vertices: Array[Vector4] = []
	var triangles: Array[Array] = []  # Each element is [v0_idx, v1_idx, v2_idx]

	func _init():
		vertices = []
		triangles = []

	func add_vertex(v: Vector4) -> int:
		vertices.append(v)
		return vertices.size() - 1

	func add_triangle(v0_idx: int, v1_idx: int, v2_idx: int):
		triangles.append([v0_idx, v1_idx, v2_idx])

	func get_triangle_vertices(tri_idx: int) -> Array[Vector4]:
		"""Get the three vertices of a triangle"""
		var tri = triangles[tri_idx]
		var result: Array[Vector4] = []
		result.append(vertices[tri[0]])
		result.append(vertices[tri[1]])
		result.append(vertices[tri[2]])
		return result

	## Factory methods for common shapes

	static func create_hypercube(size: float = 1.0) -> Mesh4D:
		"""Create a 4D hypercube (tesseract) with triangulated faces"""
		var mesh = Mesh4D.new()
		var half = size * 0.5

		# Generate 16 vertices (2^4 for 4D cube)
		for w in [- half, half]:
			for z in [-half, half]:
				for y in [-half, half]:
					for x in [-half, half]:
						mesh.add_vertex(Vector4(x, y, z, w))

		# Tesseract has 8 cubic cells, each with 6 quad faces
		# For simplicity, we'll triangulate the 6 faces of the "front" W-cell (W = -half)
		# This gives us a 3D cube embedded in 4D space

		# Front face (Z = -half, W = -half): indices 0,1,2,3
		mesh.add_triangle(0, 1, 2)  # Triangle 1
		mesh.add_triangle(0, 2, 3)  # Triangle 2

		# Back face (Z = half, W = -half): indices 4,5,6,7
		mesh.add_triangle(4, 6, 5)
		mesh.add_triangle(4, 7, 6)

		# Left face (X = -half, W = -half): indices 0,2,4,6
		mesh.add_triangle(0, 4, 2)
		mesh.add_triangle(2, 4, 6)

		# Right face (X = half, W = -half): indices 1,3,5,7
		mesh.add_triangle(1, 3, 7)
		mesh.add_triangle(1, 7, 5)

		# Bottom face (Y = -half, W = -half): indices 0,1,4,5
		mesh.add_triangle(0, 4, 1)
		mesh.add_triangle(1, 4, 5)

		# Top face (Y = half, W = -half): indices 2,3,6,7
		mesh.add_triangle(2, 3, 6)
		mesh.add_triangle(3, 7, 6)

		# TODO: Add the other 7 cubic cells for a complete tesseract
		# For now, this is sufficient for testing slicing

		return mesh

	static func create_4d_pyramid(base_size: float = 1.0, height: float = 1.0) -> Mesh4D:
		"""Create a 4D pyramid (5-cell simplex) - simplest 4D polyhedron"""
		var mesh = Mesh4D.new()

		# 5 vertices: 4 at base, 1 at apex
		var half = base_size * 0.5

		# Base vertices (W = 0, forming tetrahedron in XYZ)
		mesh.add_vertex(Vector4(0, -half, -half, 0))     # 0: front-bottom
		mesh.add_vertex(Vector4(-half, -half, half, 0))  # 1: left-back
		mesh.add_vertex(Vector4(half, -half, half, 0))   # 2: right-back
		mesh.add_vertex(Vector4(0, half, 0, 0))          # 3: top

		# Apex vertex (W = height)
		mesh.add_vertex(Vector4(0, 0, 0, height))        # 4: apex in W direction

		# Base tetrahedron faces (4 triangular faces)
		mesh.add_triangle(0, 1, 2)  # Bottom
		mesh.add_triangle(0, 3, 1)  # Front-left face
		mesh.add_triangle(1, 3, 2)  # Back face
		mesh.add_triangle(2, 3, 0)  # Front-right face

		# Pyramid faces connecting base to apex (4 triangular faces)
		mesh.add_triangle(0, 2, 4)  # Bottom face to apex
		mesh.add_triangle(0, 4, 1)  # Front face to apex
		mesh.add_triangle(1, 4, 2)  # Back face to apex
		mesh.add_triangle(2, 4, 3)  # Right face to apex
		mesh.add_triangle(3, 4, 0)  # Top to apex (closes the pyramid)

		return mesh

static func slice_mesh(mesh: Mesh4D, hyperplane: HyperplaneND) -> Array[SliceContour]:
	"""Slice a 4D mesh with a hyperplane, returning slice contours

	Algorithm:
	1. For each triangle in the mesh:
	   - Find which edges cross the hyperplane
	   - Collect intersection points
	2. Connect intersection points into closed contours
	3. Return array of contours (polygons)

	Args:
		mesh: The 4D mesh to slice
		hyperplane: The slicing hyperplane

	Returns:
		Array of SliceContour objects representing the (N-1)D cross-section
	"""
	var all_intersections: Array = []  # [face_idx, intersection_point_4d, edge_idx]

	# Step 1: Find all edge-hyperplane intersections
	for face_idx in range(mesh.triangles.size()):
		var tri = mesh.get_triangle_vertices(face_idx)
		var v0 = tri[0]
		var v1 = tri[1]
		var v2 = tri[2]

		var intersections = EdgeSlicer.slice_triangle(v0, v1, v2, hyperplane)

		for intersection in intersections:
			all_intersections.append({
				"face_idx": face_idx,
				"point_4d": intersection.intersection_point,
				"edge_idx": intersection.edge_index
			})

	# If no intersections, mesh doesn't cross hyperplane
	if all_intersections.size() == 0:
		return []

	# Step 2: Group intersection points into contours
	# For simple convex meshes, all points form a single contour
	# For complex meshes, need edge connectivity analysis

	var contour = SliceContour.new()

	for intersection in all_intersections:
		var point_4d = intersection["point_4d"]
		var point_3d = EdgeSlicer.project_to_slice_space(point_4d, hyperplane)
		var face_idx = intersection["face_idx"]

		contour.add_point(point_4d, point_3d, face_idx)

	# Step 3: Sort points to form a coherent polygon
	# Use convex hull or angle-based sorting for now
	if contour.points_3d.size() >= 3:
		_sort_contour_points_by_angle(contour)

	var result: Array[SliceContour] = []
	if contour.is_valid():
		result.append(contour)

	return result

static func _sort_contour_points_by_angle(contour: SliceContour):
	"""Sort contour points in counter-clockwise order around their centroid

	This creates a proper polygon from an unordered set of points.
	Works well for convex polygons; may need more sophisticated algorithm for concave.
	"""
	if contour.points_3d.size() < 3:
		return

	# Calculate centroid
	var centroid = Vector3.ZERO
	for point in contour.points_3d:
		centroid += point
	centroid /= contour.points_3d.size()

	# Calculate angles from centroid to each point
	var point_angles: Array = []
	for i in range(contour.points_3d.size()):
		var point = contour.points_3d[i]
		var direction = point - centroid
		var angle = atan2(direction.y, direction.x)
		point_angles.append({"index": i, "angle": angle})

	# Sort by angle
	point_angles.sort_custom(func(a, b): return a["angle"] < b["angle"])

	# Reorder points based on sorted angles
	var sorted_points_3d: Array[Vector3] = []
	var sorted_points_4d: Array[Vector4] = []
	var sorted_face_indices: Array[int] = []

	for item in point_angles:
		var idx = item["index"]
		sorted_points_3d.append(contour.points_3d[idx])
		sorted_points_4d.append(contour.points_4d[idx])
		sorted_face_indices.append(contour.face_indices[idx])

	contour.points_3d = sorted_points_3d
	contour.points_4d = sorted_points_4d
	contour.face_indices = sorted_face_indices

static func calculate_contour_normal(contour: SliceContour) -> Vector3:
	"""Calculate the normal vector for a contour polygon using Newell's method

	This works for both convex and concave polygons.
	"""
	if contour.points_3d.size() < 3:
		return Vector3.UP

	var normal = Vector3.ZERO
	var num_points = contour.points_3d.size()

	for i in range(num_points):
		var current = contour.points_3d[i]
		var next = contour.points_3d[(i + 1) % num_points]

		normal.x += (current.y - next.y) * (current.z + next.z)
		normal.y += (current.z - next.z) * (current.x + next.x)
		normal.z += (current.x - next.x) * (current.y + next.y)

	return normal.normalized()
