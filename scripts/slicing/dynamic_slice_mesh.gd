# res://scripts/slicing/dynamic_slice_mesh.gd
class_name DynamicSliceMesh
extends MeshInstance3D

const MeshSlicer = preload("res://scripts/slicing/mesh_slicer.gd")

## Dynamic mesh builder for slice visualization
## Converts slice contours to Godot MeshInstance3D with proper normals, UVs, indices

@export var slice_material: StandardMaterial3D

# Cache for performance
var _cached_mesh: ArrayMesh = null
var _cache_valid: bool = false

func _ready():
	if not slice_material:
		# Create default material
		slice_material = StandardMaterial3D.new()
		slice_material.albedo_color = Color(0.7, 0.8, 1.0)  # Light blue
		slice_material.metallic = 0.3
		slice_material.roughness = 0.7
		slice_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides

func build_mesh_from_contours(contours: Array[MeshSlicer.SliceContour]) -> bool:
	"""Build a Godot mesh from slice contours

	Args:
		contours: Array of SliceContour objects

	Returns:
		true if mesh was successfully built, false otherwise
	"""
	if contours.size() == 0:
		# No contours, hide mesh
		visible = false
		return false

	var array_mesh = ArrayMesh.new()

	for contour in contours:
		if not contour.is_valid():
			continue

		# Build mesh for this contour
		var surface_array = _build_surface_array_from_contour(contour)

		if surface_array != null:
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)

	if array_mesh.get_surface_count() > 0:
		mesh = array_mesh

		# Apply material to all surfaces
		for i in range(array_mesh.get_surface_count()):
			set_surface_override_material(i, slice_material)

		visible = true
		_cached_mesh = array_mesh
		_cache_valid = true
		return true
	else:
		visible = false
		return false

func _build_surface_array_from_contour(contour: MeshSlicer.SliceContour) -> Array:
	"""Build Godot surface arrays from a single contour

	Creates vertices, normals, UVs, and indices for a triangulated polygon.
	"""
	var points = contour.points_3d

	if points.size() < 3:
		return []

	# Arrays for mesh data
	var vertices: PackedVector3Array = []
	var normals: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var indices: PackedInt32Array = []

	# Calculate normal for the entire contour
	var contour_normal = MeshSlicer.calculate_contour_normal(contour)

	# Triangulate polygon using fan triangulation
	# Works for convex polygons; more complex method needed for concave
	var num_points = points.size()

	# Add all vertices
	for point in points:
		vertices.append(point)
		normals.append(contour_normal)

	# Generate UVs based on XY projection
	var bounds_min = Vector2(INF, INF)
	var bounds_max = Vector2(-INF, -INF)

	for point in points:
		bounds_min.x = min(bounds_min.x, point.x)
		bounds_min.y = min(bounds_min.y, point.y)
		bounds_max.x = max(bounds_max.x, point.x)
		bounds_max.y = max(bounds_max.y, point.y)

	var bounds_size = bounds_max - bounds_min
	if bounds_size.x < 0.001:
		bounds_size.x = 1.0
	if bounds_size.y < 0.001:
		bounds_size.y = 1.0

	for point in points:
		var uv = Vector2(
			(point.x - bounds_min.x) / bounds_size.x,
			(point.y - bounds_min.y) / bounds_size.y
		)
		uvs.append(uv)

	# Fan triangulation: connect all triangles to vertex 0
	for i in range(1, num_points - 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)

	# Build surface array
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	return arrays

func clear_mesh():
	"""Clear the current mesh and hide"""
	mesh = null
	visible = false
	_cache_valid = false

func invalidate_cache():
	"""Mark cache as invalid, forcing rebuild on next update"""
	_cache_valid = false

func is_cache_valid() -> bool:
	return _cache_valid
