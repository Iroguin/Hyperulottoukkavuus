# res://scripts/4d/collision_manager_4d.gd
extends Node
class_name CollisionManager4D

## Hypersphere collision aka based on distance in 4d between objects

func check_collisions(obj: Object4D) -> Array[Object4D]:
	var collisions: Array[Object4D] = []
	var dimension = GameWorld4D.dimension_manager.current_dimension

	# Check floor collision first
	check_plane_collisions(obj)

	for other in get_tree().get_nodes_in_group("4d_objects"):
		if other == obj:
			continue

		# Skip if object doesn't exist in current dimension
		if not other.is_in_dimension(dimension):
			continue

		# Skip if object is outside current slice
		if not GameWorld4D.dimension_manager.is_object_in_current_slice(other.position_4d):
			continue

		# Perform hypersphere collision in active dimensions only
		if check_hypersphere_collision(obj, other, dimension):
			collisions.append(other)

	return collisions
func check_plane_collisions(obj: Object4D):
	"""
	Check and resolve collision with ALL generic collision planes.
	Handles Floors, Walls, and 4D barriers using vector reflection.
	"""
	# Match the group name from the new CollisionPlane4D script
	var planes = get_tree().get_nodes_in_group("collision_plane_4d")
	
	var is_grounded_this_frame = false
	
	for plane in planes:
		# Does the plane script exist and have the method?
		if not plane.has_method("check_collision"): continue
		
		if plane.check_collision(obj):
			# 1. Position Correction: Push object out of the plane
			var response_vec = plane.get_collision_response(obj)
			obj.position_4d += response_vec
			
			# 2. Velocity Response: Bounce and Friction
			var normal = plane.get_floor_normal()
			
			# Calculate velocity relative to the normal
			# Dot product tells us how fast we are moving INTO the wall
			var vel_into_plane = obj.velocity_4d.dot(normal)
			
			# Only bounce if we are actually moving INTO the plane (negative dot product)
			# If dot > 0, we are moving away, so don't interfere.
			if vel_into_plane < 0:
				apply_plane_physics_response(obj, normal, vel_into_plane)

			# 3. Ground Detection
			# If the normal points somewhat "UP" in Y, we consider it ground.
			# Dot product of Normal and Up Vector (0,1,0,0).
			# If result > 0.7 (approx 45 degrees), it's floor. Less is a slope/wall.
			if normal.dot(Vector4(0, 1, 0, 0)) > 0.7:
				is_grounded_this_frame = true

	# Update player state
	if obj.is_in_group("player") and "is_on_ground" in obj:
		obj.is_on_ground = is_grounded_this_frame

func apply_plane_physics_response(obj: Object4D, normal: Vector4, vel_into_plane: float):
	"""
	Calculates generic slide and bounce logic for 4D vectors.
	"""
	var bounciness = 0.3 # Energy retained on bounce (0.0 = no bounce, 1.0 = superball)
	var friction = 0.05  # Drag applied to the sliding surface
	
	# 1. Isolate the "Normal Velocity" (The part going straight into the wall)
	# formula: v_normal = normal * (v . normal)
	var v_normal = normal * vel_into_plane
	
	# 2. Isolate the "Tangent Velocity" (The sliding part)
	# formula: v_tangent = v_total - v_normal
	var v_tangent = obj.velocity_4d - v_normal
	
	# 3. Apply changes
	
	# Response A: Bounce the normal velocity
	# Multiply by negative restitution to flip direction
	var v_normal_response = v_normal * -bounciness
	
	# Response B: Friction on the tangent velocity
	# Reduce the sliding speed
	var v_tangent_response = v_tangent * (1.0 - friction)
	
	# 4. Recombine
	obj.velocity_4d = v_normal_response + v_tangent_response

func check_hypersphere_collision(a: Object4D, b: Object4D, dimensions: int) -> bool:
	"""Check collision in N dimensions (1D, 2D, 3D, or 4D)"""
	var dist_squared := 0.0

	match dimensions:
		1:
			# Only check X axis
			var dx = a.position_4d.x - b.position_4d.x
			dist_squared = dx * dx

		2:
			# Check X and Y
			var dx = a.position_4d.x - b.position_4d.x
			var dy = a.position_4d.y - b.position_4d.y
			dist_squared = dx*dx + dy*dy

		3:
			# Check X, Y, and Z
			var dx = a.position_4d.x - b.position_4d.x
			var dy = a.position_4d.y - b.position_4d.y
			var dz = a.position_4d.z - b.position_4d.z
			dist_squared = dx*dx + dy*dy + dz*dz

		4:
			# Check all four dimensions
			var dx = a.position_4d.x - b.position_4d.x
			var dy = a.position_4d.y - b.position_4d.y
			var dz = a.position_4d.z - b.position_4d.z
			var dw = a.position_4d.w - b.position_4d.w
			dist_squared = dx*dx + dy*dy + dz*dz + dw*dw

	var min_dist = a.collision_radius_4d + b.collision_radius_4d
	return dist_squared < min_dist * min_dist

func distance_4d(a: Vector4, b: Vector4, dimensions: int) -> float:
	"""Calculate distance in N dimensions"""
	var dist_squared := 0.0

	if dimensions >= 1:
		var dx = a.x - b.x
		dist_squared += dx * dx
	if dimensions >= 2:
		var dy = a.y - b.y
		dist_squared += dy * dy
	if dimensions >= 3:
		var dz = a.z - b.z
		dist_squared += dz * dz
	if dimensions >= 4:
		var dw = a.w - b.w
		dist_squared += dw * dw

	return sqrt(dist_squared)

func get_collision_normal(a: Object4D, b: Object4D, dimensions: int) -> Vector4:
	"""Get collision normal in N dimensions"""
	var diff = b.position_4d - a.position_4d

	match dimensions:
		1:
			return Vector4(sign(diff.x), 0, 0, 0)
		2:
			var norm_2d = Vector2(diff.x, diff.y).normalized()
			return Vector4(norm_2d.x, norm_2d.y, 0, 0)
		3:
			var norm_3d = Vector3(diff.x, diff.y, diff.z).normalized()
			return Vector4(norm_3d.x, norm_3d.y, norm_3d.z, 0)
		4:
			var length = sqrt(diff.x*diff.x + diff.y*diff.y + diff.z*diff.z + diff.w*diff.w)
			if length > 0:
				return diff / length
			return Vector4.ZERO

	return Vector4.ZERO
