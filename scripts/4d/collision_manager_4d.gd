# res://scripts/4d/collision_manager_4d.gd
extends Node
class_name CollisionManager4D

## Hypersphere collision aka based on distance in 4d between objects

func check_collisions(obj: Object4D) -> Array[Object4D]:
	var collisions: Array[Object4D] = []
	var dimension = GameWorld4D.dimension_manager.current_dimension

	# Check floor collision first
	check_floor_collision(obj)

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

func check_floor_collision(obj: Object4D):
	"""Check and resolve collision with infinite floor"""
	var floors = get_tree().get_nodes_in_group("infinite_floor")
	if floors.size() == 0:
		return

	var floor_obj = floors[0]  # Assume only one floor for now

	if floor_obj.check_collision(obj):
		# Push object out of floor
		var response = floor_obj.get_collision_response(obj)
		obj.position_4d += response

		# Set is_on_ground flag for player
		if obj.is_in_group("player") and "is_on_ground" in obj:
			obj.is_on_ground = true

		# Dampen Y velocity (bounce/friction)
		if obj.velocity_4d.y < 0:
			obj.velocity_4d.y *= -0.3  # Bounce with energy loss
			# Apply friction to horizontal movement
			obj.velocity_4d.x *= 0.95
			obj.velocity_4d.z *= 0.95
			obj.velocity_4d.w *= 0.95
	else:
		# Not on ground
		if obj.is_in_group("player") and "is_on_ground" in obj:
			obj.is_on_ground = false

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
