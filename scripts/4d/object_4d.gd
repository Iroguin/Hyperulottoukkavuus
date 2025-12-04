# res://scripts/4d/object_4d.gd
extends Node3D
class_name Object4D

# True 4D properties
@export var position_4d := Vector4.ZERO
@export var collision_radius_4d := 1.0
@export var velocity_4d := Vector4.ZERO


# Dimension state
var exists_in_dimensions := [true, true, true, true]  # [1D, 2D, 3D, 4D]
var current_dimension := 4  # What dimension we're viewing in

# Visual representation
var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial

func _ready():
	add_to_group("4d_objects")
	GameWorld4D.register_object(self)

	# Find MeshInstance3D (direct child or nested in imported scenes)
	if has_node("MeshInstance3D"):
		mesh_instance = get_node("MeshInstance3D")
	else:
		mesh_instance = find_mesh_instance_recursive(self)

	setup_shader()

func _physics_process(delta):
	# Update 4D physics
	position_4d += velocity_4d * delta

	apply_dimension_lock()

	var collisions = GameWorld4D.collision_manager.check_collisions(self)
	for collision in collisions:
		on_collision(collision)

	apply_dimension_lock()
	update_visual_projection()

func on_collision(other: Object4D):
	# Override in subclasses
	pass

func apply_dimension_lock():
	"""Lock movement in dimensions higher than current"""
	var current_dim = GameWorld4D.dimension_manager.current_dimension

	match current_dim:
		1:
			velocity_4d.y = 0
			velocity_4d.z = 0
			velocity_4d.w = 0
			lock_position_to_1d()
		2:
			constrain_velocity_to_slice_plane()
		3:
			velocity_4d.w = 0
			lock_position_to_3d()
		4:
			has_locked_w = false

var locked_position_1d := 0.0
var locked_w_position := 0.0
var has_locked_w := false

func lock_position_to_1d():
	var dm = GameWorld4D.dimension_manager

	# Get line direction from slice normal (perpendicular to normal in XZ plane)
	var normal_xz = Vector2(dm.slice_hyperplane.normal.x, dm.slice_hyperplane.normal.z).normalized()
	var line_dir = Vector2(-normal_xz.y, normal_xz.x)  # Perpendicular to normal

	# Project position onto 1D line
	var pos_xz = Vector2(position_4d.x, position_4d.z)
	var projection_length = pos_xz.dot(line_dir)
	var projected = line_dir * projection_length

	position_4d.x = projected.x
	position_4d.y = 0
	position_4d.z = projected.y
	position_4d.w = 0

func lock_position_to_3d():
	if not has_locked_w:
		locked_w_position = position_4d.w
		has_locked_w = true
	position_4d.w = locked_w_position

func constrain_velocity_to_slice_plane():
	var dm = GameWorld4D.dimension_manager
	var slice_normal = dm.slice_plane_normal
	var vel_3d = Vector3(velocity_4d.x, velocity_4d.y, velocity_4d.z)
	var vel_normal_component = vel_3d.dot(slice_normal)
	vel_3d -= slice_normal * vel_normal_component
	velocity_4d.x = vel_3d.x
	velocity_4d.y = vel_3d.y
	velocity_4d.z = vel_3d.z
	velocity_4d.w = 0

func update_visual_projection():
	var dim_manager = GameWorld4D.dimension_manager

	if dim_manager.use_geometric_slicing:
		var in_slice = dim_manager.is_object_in_slice_geometric(position_4d, collision_radius_4d)
		if mesh_instance and not is_in_group("player"):
			mesh_instance.visible = in_slice
		if not in_slice and not is_in_group("player"):
			return

	var projected_pos = dim_manager.project_to_current_dimension(position_4d)
	global_position = projected_pos

	if is_in_group("player"):
		compensate_perspective_scale()

	update_shader_uniforms()

func is_in_dimension(dim: int) -> bool:
	return exists_in_dimensions[dim - 1]

func get_position_in_dimension(dim: int) -> Variant:
	match dim:
		1: return position_4d.x
		2: return Vector2(position_4d.x, position_4d.y)
		3: return Vector3(position_4d.x, position_4d.y, position_4d.z)
		4: return position_4d
	return null

func setup_shader():
	if not mesh_instance:
		return

	if is_in_group("player"):
		var standard_mat = StandardMaterial3D.new()
		standard_mat.albedo_color = Color(0.3, 0.7, 1.0)
		standard_mat.emission_enabled = true
		standard_mat.emission = Color(0.2, 0.4, 0.6)
		standard_mat.metallic = 0.7
		standard_mat.roughness = 0.3
		mesh_instance.set_surface_override_material(0, standard_mat)
		return

	shader_material = mesh_instance.get_surface_override_material(0)
	if shader_material == null and mesh_instance.mesh:
		var mesh_mat = mesh_instance.mesh.surface_get_material(0)
		if mesh_mat is ShaderMaterial:
			shader_material = mesh_mat

	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/4d_projection.gdshader")
		mesh_instance.set_surface_override_material(0, shader_material)

func find_mesh_instance_recursive(node: Node) -> MeshInstance3D:
	"""Recursively find the first MeshInstance3D in the scene tree"""
	if node is MeshInstance3D:
		return node

	for child in node.get_children():
		var result = find_mesh_instance_recursive(child)
		if result:
			return result

	return null

func compensate_perspective_scale():
	scale = Vector3.ONE

func update_shader_uniforms():
	# Player doesn't use shader material, so skip shader updates
	if not shader_material:
		return

	var dm = GameWorld4D.dimension_manager
	shader_material.set_shader_parameter("w_distance", dm.w_distance)
	shader_material.set_shader_parameter("angle_xw", dm.rotation_xw)
	shader_material.set_shader_parameter("angle_yw", dm.rotation_yw)
	shader_material.set_shader_parameter("angle_zw", dm.rotation_zw)
