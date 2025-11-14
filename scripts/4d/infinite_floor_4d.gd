# res://scripts/4d/infinite_floor_4d.gd
extends Node3D
class_name InfiniteFloor4D

## An infinite floor in 4D space (a 3D hyperplane)
## The floor is at a fixed Y coordinate, infinite in X, Z, and W

@export var floor_y := 0  # Height of the floor in 4D space
@export var floor_size_visual := 100.0  # Size of visual mesh (for display only)

var floor_mesh: MeshInstance3D

func _ready():
	add_to_group("infinite_floor")
	create_visual_mesh()

func create_visual_mesh():
	# Create a large visual plane to represent the floor
	floor_mesh = MeshInstance3D.new()
	add_child(floor_mesh)

	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(floor_size_visual, floor_size_visual)
	floor_mesh.mesh = plane_mesh

	# Create a simple material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	mat.metallic = 0.2
	mat.roughness = 0.8
	floor_mesh.set_surface_override_material(0, mat)

	# Position the visual mesh
	floor_mesh.global_position = Vector3(0, floor_y, 0)

func _process(_delta):
	# Update visual position to follow player in X and Z
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var player_pos = player.global_position
		floor_mesh.global_position = Vector3(player_pos.x, floor_y, player_pos.z)

func check_collision(obj: Object4D) -> bool:
	"""Check if object is colliding with the floor"""
	# Floor collision is simple: object's Y position minus radius
	var obj_bottom_y = obj.position_4d.y - obj.collision_radius_4d
	return obj_bottom_y <= floor_y

func get_collision_response(obj: Object4D) -> Vector4:
	"""Get the collision response to push object out of floor"""
	var penetration_depth = floor_y - (obj.position_4d.y - obj.collision_radius_4d)

	if penetration_depth > 0:
		# Push object up by penetration depth
		return Vector4(0, penetration_depth, 0, 0)

	return Vector4.ZERO

func get_floor_normal() -> Vector4:
	"""Get the floor's normal vector (always pointing up in Y)"""
	return Vector4(0, 1, 0, 0)
