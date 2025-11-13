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
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var shader_material: ShaderMaterial

func _ready():
	add_to_group("4d_objects")
	GameWorld4D.register_object(self)
	setup_shader()
	# DEBUG:
	print("Object4D spawned: ", name)
	print("  Position 4D: ", position_4d)
	print("  3D Position: ", global_position)

func _physics_process(delta):
	# Update 4D physics
	position_4d += velocity_4d * delta

	# Check collisions in current dimension
	var collisions = GameWorld4D.collision_manager.check_collisions(self)
	for collision in collisions:
		on_collision(collision)
	
	# Update visual representation
	update_visual_projection()

func on_collision(other: Object4D):
	# Override in subclasses
	pass

func update_visual_projection():
	# Project based on current dimension
	var projected_pos = GameWorld4D.dimension_manager.project_to_current_dimension(position_4d)
	global_position = projected_pos

	# Compensate for perspective scaling if this is the player
	# to maintain consistent size regardless of W position
	if is_in_group("player"):
		compensate_perspective_scale()

	update_shader_uniforms()

func is_in_dimension(dim: int) -> bool:
	return exists_in_dimensions[dim - 1]

func get_position_in_dimension(dim: int) -> Variant:
	match dim:
		1: return position_4d.x  # Just X coordinate
		2: return Vector2(position_4d.x, position_4d.y)
		3: return Vector3(position_4d.x, position_4d.y, position_4d.z)
		4: return position_4d
	return null

func setup_shader():
	if mesh_instance:
		# Players don't need the 4D projection shader since camera follows them
		if is_in_group("player"):
			# Use a simple standard material for consistent appearance
			var standard_mat = StandardMaterial3D.new()
			standard_mat.albedo_color = Color(0.3, 0.7, 1.0)  # Blue color for player
			standard_mat.emission_enabled = true
			standard_mat.emission = Color(0.2, 0.4, 0.6)
			standard_mat.metallic = 0.7
			standard_mat.roughness = 0.3
			mesh_instance.set_surface_override_material(0, standard_mat)
			return

		# Try to get existing shader material from override or mesh
		shader_material = mesh_instance.get_surface_override_material(0)
		if shader_material == null and mesh_instance.mesh:
			# Check if mesh has a material (must be ShaderMaterial)
			var mesh_mat = mesh_instance.mesh.surface_get_material(0)
			if mesh_mat is ShaderMaterial:
				shader_material = mesh_mat

		# If still no shader material, create one
		if shader_material == null:
			shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/4d_projection.gdshader")
			mesh_instance.set_surface_override_material(0, shader_material)

func compensate_perspective_scale():
	# For the player, ensure scale stays at 1.0 since camera follows them
	# and they use a standard material without 4D projection shader
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
