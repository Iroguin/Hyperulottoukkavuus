extends Node3D
class_name CollisionPlane4D

## A generic infinite collision hyperplane in 4D space.
## Defined by a normal vector (direction) and a position (anchor).

# The "Up" direction of the floor in 4D. 
# (0,1,0,0) is a standard floor. (0,0,0,1) would be a "W-wall".
@export var plane_normal := Vector4(0, 1, 0, 0)

# A point in 4D space that the plane passes through.
@export var position_4d := Vector4(0, 0, 0, 0)

# Visual settings
@export var visual_size := 100.0
@export var visual_thickness := 1.0 # Thickness of the floor visually
@export var color := Color(0.3, 0.3, 0.3)

var floor_mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial

func _ready():
	add_to_group("collision_plane_4d")
	
	# Normalize normal to ensure math works
	plane_normal = plane_normal.normalized()
	
	setup_visuals()

func setup_visuals():
	floor_mesh_instance = MeshInstance3D.new()
	add_child(floor_mesh_instance)
	
	# Load your specific shader
	var shader = load("res://shaders/4d_projection.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Apply basic styling uniforms if they exist in your shader or use albedo
	# Note: Your provided shader uses COLOR for W-coord, so we mix albedo logic
	# usually via a uniform or vertex color manipulation.
	
	floor_mesh_instance.material_override = shader_material
	
	# Generate a mesh compatible with the 4D shader
	generate_hyperplane_mesh()

func generate_hyperplane_mesh():
	# We need to generate a 3D Box (Volume) that represents this plane.
	# The shader expects X,Y,Z in VERTEX and W in COLOR.r.
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 1. Create a Basis for the plane. 
	# We need 3 vectors orthogonal to plane_normal to span the surface.
	var basis_4d = get_orthonormal_basis(plane_normal)
	var right = basis_4d[0] * visual_size
	var forward = basis_4d[1] * visual_size
	var ana = basis_4d[2] * visual_thickness # The "depth" or "w-thickness"
	
	# We will build a simple cube grid manually to ensure W is encoded correctly.
	# A simple quad is insufficient for 4D depth perception, so we draw a box.
	
	# Define the 8 corners of a cube relative to 0,0,0,0
	var corners = [
		-right - forward - ana, # 0
		 right - forward - ana, # 1
		 right + forward - ana, # 2
		-right + forward - ana, # 3
		-right - forward + ana, # 4
		 right - forward + ana, # 5
		 right + forward + ana, # 6
		-right + forward + ana  # 7
	]
	
	# Helper to add vertex
	var add_v = func(idx):
		var v4 = corners[idx]
		# Add global offset
		v4 += position_4d 
		
		# Encode W in Color.r (range -1 to 1 usually, assuming shader handles generic floats?
		# The provided shader does: vec4 pos_4d = vec4(VERTEX.xyz, COLOR.r * 2.0 - 1.0);
		# We must remap W to 0.0-1.0 range for the Color struct.
		var w_normalized = (v4.w * 0.5) + 0.5 
		st.set_color(Color(w_normalized, 0.5, 1.0 - w_normalized, 1.0))
		st.set_normal(Vector3(plane_normal.x, plane_normal.y, plane_normal.z)) # Approx normal
		
		# The shader takes VERTEX as the XYZ slice
		st.add_vertex(Vector3(v4.x, v4.y, v4.z))

	# Build triangles (Standard Cube indices)
	var indices = [
		0, 1, 2, 0, 2, 3, # Bottom
		4, 6, 5, 4, 7, 6, # Top
		0, 4, 1, 1, 4, 5, # Front
		2, 6, 3, 3, 6, 7, # Back
		0, 3, 4, 4, 3, 7, # Left
		1, 5, 2, 2, 5, 6  # Right
	]
	
	for i in indices:
		add_v.call(i)

	st.generate_normals()
	floor_mesh_instance.mesh = st.commit()

func _process(_delta):
	# Update shader uniforms to match global 4D camera rotation
	# Assuming you have a global singleton or group for the 4D camera
	var camera_group = get_tree().get_nodes_in_group("camera_4d")
	if camera_group.size() > 0:
		var cam = camera_group[0]
		# Pass the rotation angles from your camera script to the material
		if "angle_xw" in cam: shader_material.set_shader_parameter("angle_xw", cam.angle_xw)
		if "angle_yw" in cam: shader_material.set_shader_parameter("angle_yw", cam.angle_yw)
		if "angle_zw" in cam: shader_material.set_shader_parameter("angle_zw", cam.angle_zw)
		if "angle_xy" in cam: shader_material.set_shader_parameter("angle_xy", cam.angle_xy)
		if "angle_xz" in cam: shader_material.set_shader_parameter("angle_xz", cam.angle_xz)
		if "angle_yz" in cam: shader_material.set_shader_parameter("angle_yz", cam.angle_yz)

	# Infinite Floor Logic:
	# Move visual mesh to follow player, projected onto the plane
	var player = get_tree().get_first_node_in_group("player")
	if player and "position_4d" in player:
		# Project player position onto the plane
		# P_proj = P - ( (P - PlaneOrigin) . Normal ) * Normal
		var v = player.position_4d - position_4d
		var dist = v.dot(plane_normal)
		var projected_pos = player.position_4d - (plane_normal * dist)
		#fix here snap apua auttakaa
		
		# We update the visual mesh node's 3D position to match the projected XYZ
		# The Shader handles the W, but since we baked W into vertices, 
		# "infinite" movement requires regenerating the mesh or using UV offsets.
		# For simplicity/performance: We just move the 3D transform container.
		floor_mesh_instance.global_position = Vector3(projected_pos.x, projected_pos.y, projected_pos.z)


# --- COLLISION LOGIC ---

func check_collision(obj: Object4D) -> bool:
	"""Check if object is colliding with the generic hyperplane"""
	# Distance from point to plane: (P_obj - P_plane_origin) dot Normal
	var vec_to_obj = obj.position_4d - position_4d
	var signed_distance = vec_to_obj.dot(plane_normal)
	
	# If distance is less than radius (and we assume one-sided floor), it's a collision
	# Note: This treats the 'back' of the plane as solid infinite earth.
	return signed_distance <= obj.collision_radius_4d

func get_collision_response(obj: Object4D) -> Vector4:
	"""Push object out along the normal vector"""
	var vec_to_obj = obj.position_4d - position_4d
	var signed_distance = vec_to_obj.dot(plane_normal)
	
	var penetration = obj.collision_radius_4d - signed_distance
	
	if penetration > 0:
		# Push along the normal
		return plane_normal * penetration
		
	return Vector4.ZERO

func get_floor_normal() -> Vector4:
	return plane_normal

# --- MATH HELPER ---

func get_orthonormal_basis(n: Vector4) -> Array:
	# Returns 3 vectors orthogonal to n and each other
	# Simple Gram-Schmidt or arbitrary axis selection
	
	# Pick an arbitrary vector that isn't n
	var v1 = Vector4(1,0,0,0)
	if abs(n.dot(v1)) > 0.9: v1 = Vector4(0,1,0,0)
	
	var tangent1 = (v1 - n * v1.dot(n)).normalized()
	
	# Pick another
	var v2 = Vector4(0,0,1,0)
	if abs(n.dot(v2)) > 0.9 or abs(tangent1.dot(v2)) > 0.9: v2 = Vector4(0,0,0,1)
	
	# Gram-Schmidt for v2
	var t2 = v2 - n * v2.dot(n)
	t2 = t2 - tangent1 * t2.dot(tangent1)
	var tangent2 = t2.normalized()
	
	# Pick last
	var v3 = Vector4(0,0,0,1)
	if abs(n.dot(v3)) > 0.9: v3 = Vector4(1,0,0,0) # Fallback
	
	var t3 = v3 - n * v3.dot(n)
	t3 = t3 - tangent1 * t3.dot(tangent1)
	t3 = t3 - tangent2 * t3.dot(tangent2)
	var tangent3 = t3.normalized()
	
	return [tangent1, tangent2, tangent3]
