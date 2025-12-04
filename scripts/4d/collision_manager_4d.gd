# res://scripts/4d/collision_manager_4d.gd
extends Node
class_name CollisionManager4D

## Hypersphere collision aka based on distance in 4d between objects

const GeometricIntersection = preload("res://scripts/4d/geometric_intersection.gd")

func check_collisions(obj: Object4D) -> Array[Object4D]:
	var collisions: Array[Object4D] = []
	var dimension = GameWorld4D.dimension_manager.current_dimension
	var dim_manager = GameWorld4D.dimension_manager

	# Check floor collision first
	var grounded_from_planes = check_plane_collisions(obj)

	var grounded_from_objects = false

	for other in get_tree().get_nodes_in_group("4d_objects"):
		if other == obj:
			continue

		# Skip if object doesn't exist in current dimension
		if not other.is_in_dimension(dimension):
			continue

		# NEW: Use geometric slice intersection if enabled
		if dim_manager.use_geometric_slicing:
			# Skip if object doesn't intersect current slice hyperplane
			if not is_object_in_slice_geometric(other):
				continue
		else:
			# OLD: Skip if object is outside current slice (simple W-distance check)
			if not dim_manager.is_object_in_current_slice(other.position_4d):
				continue

		# Perform hypersphere collision in active dimensions only
		if check_hypersphere_collision(obj, other, dimension):
			collisions.append(other)

			# Handle collision response and ground detection
			var is_ground = resolve_object_collision(obj, other, dimension)
			if is_ground:
				grounded_from_objects = true

	# Update player grounded state (grounded if on plane OR on object)
	if obj.is_in_group("player") and "is_on_ground" in obj:
		obj.is_on_ground = grounded_from_planes or grounded_from_objects

	return collisions
func check_plane_collisions(obj: Object4D) -> bool:
	"""
	Check and resolve collision with ALL generic collision planes.
	Handles Floors, Walls, and 4D barriers using vector reflection.
	Returns true if object is grounded on a plane.
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

	return is_grounded_this_frame

func is_object_in_slice_geometric(obj: Object4D) -> bool:
	"""Check if object intersects the current slice hyperplane using geometric intersection"""
	var dim_manager = GameWorld4D.dimension_manager
	var hyperplane = dim_manager.get_slice_hyperplane()

	if not hyperplane:
		return true

	# Use sphere-hyperplane intersection
	var result = GeometricIntersection.sphere_hyperplane_intersection(
		obj.position_4d,
		obj.collision_radius_4d,
		hyperplane
	)

	# Debug: Log when objects are culled
	if not result and Time.get_ticks_msec() % 1000 < 50:  # Log occasionally
		print("Object '", obj.name, "' outside slice at pos: ", obj.position_4d)

	return result

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

func resolve_object_collision(obj: Object4D, other: Object4D, dimension: int) -> bool:
	"""
	Resolve collision between two 4D objects.
	Returns true if this collision makes obj grounded (standing on top of other).
	"""
	# Calculate collision normal (from other to obj)
	var normal = get_collision_normal(other, obj, dimension)

	# Calculate penetration depth
	var distance = distance_4d(obj.position_4d, other.position_4d, dimension)
	var min_dist = obj.collision_radius_4d + other.collision_radius_4d
	var penetration = min_dist - distance

	if penetration <= 0:
		return false  # No collision

	# 1. Position correction - push objects apart
	# Push obj away from other along the normal
	var correction = normal * (penetration * 0.5)
	obj.position_4d += correction

	# If other is movable, push it the opposite way
	if not other.is_in_group("static") and "velocity_4d" in other:
		other.position_4d -= correction

	# 2. Velocity response - bounce and friction
	var vel_into_collision = obj.velocity_4d.dot(normal)

	if vel_into_collision < 0:  # Moving into the collision
		apply_plane_physics_response(obj, normal, vel_into_collision)

	# 3. Ground detection
	# Check if obj is standing on top of other
	# Normal should point upward (Y component positive)
	# and obj should be above other in Y
	var is_ground = false

	if dimension >= 2:  # Need at least 2D for ground detection
		# Check if normal points upward (Y component > 0.7 means ~45 degree slope or flatter)
		if normal.dot(Vector4(0, 1, 0, 0)) > 0.7:
			# Check if obj is above other
			if obj.position_4d.y > other.position_4d.y:
				is_ground = true

	return is_ground

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
