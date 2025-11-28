# res://scripts/4d/slice_plane_visualizer.gd
extends MeshInstance3D
class_name SlicePlaneVisualizer

## Visual indicator showing the current slice hyperplane
## Displays a semi-transparent plane to help understand where slicing occurs

@export var plane_size := 20.0  # Size of the visual plane
@export var opacity := 0.15  # How transparent the plane is
@export var color := Color(0.3, 0.7, 1.0)  # Cyan color for the slice

var plane_material: StandardMaterial3D

func _ready():
	create_plane_mesh()
	setup_material()

func create_plane_mesh():
	# This will be replaced dynamically based on dimension
	# Initial mesh is created in update_plane_transform based on current dimension
	pass

func setup_material():
	# Create semi-transparent material
	plane_material = StandardMaterial3D.new()
	plane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plane_material.albedo_color = Color(color.r, color.g, color.b, opacity)
	plane_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
	plane_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting
	plane_material.disable_receive_shadows = true

	set_surface_override_material(0, plane_material)

func _process(_delta):
	update_plane_transform()

func create_slice_mesh_for_dimension(dimension: int):
	"""Create appropriate mesh type based on dimension:
	- 3D mode (4D→3D): BoxMesh (volume)
	- 2D mode (3D→2D): QuadMesh (plane)
	- 1D mode (2D→1D): CylinderMesh (thick line)
	"""
	match dimension:
		3:
			# 4D→3D slicing: Show 3D volume
			var box = BoxMesh.new()
			var thickness = GameWorld4D.dimension_manager.slice_thickness * 2.0
			box.size = Vector3(plane_size, plane_size, thickness)
			mesh = box
		2:
			# 3D→2D slicing: Show 2D plane
			var plane_mesh = QuadMesh.new()
			plane_mesh.size = Vector2(plane_size, plane_size)
			mesh = plane_mesh
		1:
			# 2D→1D slicing: Show thick line (cylinder)
			var cylinder = CylinderMesh.new()
			cylinder.height = plane_size
			cylinder.top_radius = GameWorld4D.dimension_manager.slice_thickness
			cylinder.bottom_radius = GameWorld4D.dimension_manager.slice_thickness
			mesh = cylinder
		_:
			# Default fallback
			var plane_mesh = QuadMesh.new()
			plane_mesh.size = Vector2(plane_size, plane_size)
			mesh = plane_mesh

	# Reapply material to new mesh
	if plane_material:
		set_surface_override_material(0, plane_material)

func update_plane_transform():
	"""Update plane position and orientation based on current slice hyperplane"""
	var dim_manager = GameWorld4D.dimension_manager

	if not dim_manager or not dim_manager.use_geometric_slicing:
		visible = false
		return

	var hyperplane = dim_manager.get_slice_hyperplane()
	if not hyperplane:
		visible = false
		return

	# Only show when slicing is active (dimensions 2-3)
	# In 4D we see the full volume, no slicing
	# In 1D the visualization is not useful (can't see it properly)
	if dim_manager.current_dimension < 2 or dim_manager.current_dimension > 3:
		visible = false
		return

	visible = true

	# Create/update mesh type if dimension changed
	create_slice_mesh_for_dimension(dim_manager.current_dimension)

	# Position the slice at the hyperplane's point
	# For 4D, we project to 3D by ignoring W coordinate
	global_position = Vector3(
		hyperplane.point.x,
		hyperplane.point.y,
		hyperplane.point.z
	)

	# Orient the slice to align with the hyperplane's normal
	var normal_3d = Vector3(hyperplane.normal.x, hyperplane.normal.y, hyperplane.normal.z)

	# Only rotate if we have a meaningful normal
	if normal_3d.length() > 0.01:
		# For different dimensions, orient differently:
		match dim_manager.current_dimension:
			3:
				# Volume: Orient box so its Z-axis aligns with hyperplane normal
				# The box extends along the normal direction (thickness)
				var right = Vector3.UP.cross(normal_3d)
				if right.length() < 0.01:
					right = Vector3.RIGHT
				right = right.normalized()
				var up = normal_3d.cross(right).normalized()
				var new_basis = Basis(right, up, normal_3d)
				global_transform.basis = new_basis
			2:
				# Plane: Orient quad perpendicular to normal
				var up = Vector3.UP
				var right = up.cross(normal_3d)
				if right.length() < 0.01:
					right = Vector3.RIGHT
				right = right.normalized()
				up = normal_3d.cross(right).normalized()
				var new_basis = Basis(right, up, normal_3d)
				global_transform.basis = new_basis
			1:
				# Line: Orient cylinder along the slice direction
				# In 1D mode, the "slice" is perpendicular to X-axis
				# Rotate cylinder to be horizontal (along X)
				global_transform.basis = Basis(Quaternion(Vector3.UP, PI / 2.0))

	# Adjust opacity based on dimension
	if plane_material:
		match dim_manager.current_dimension:
			1:
				plane_material.albedo_color.a = opacity * 0.5  # Medium in 1D
			2:
				plane_material.albedo_color.a = opacity * 0.3  # More transparent in 2D
			3:
				plane_material.albedo_color.a = opacity * 0.5  # Medium in 3D (volume)
