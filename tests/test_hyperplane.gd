# res://tests/test_hyperplane.gd
extends GdUnitTestSuite

## Test suite for N-dimensional hyperplane mathematics
## Tests hyperplane representation, point-plane distance, and plane equations

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")

func test_hyperplane_creation_3d():
	# Test creating a 3D plane (2D hyperplane in 3D space)
	# Plane through origin with normal pointing up
	var normal = Vector4(0, 1, 0, 0)
	var point = Vector4(0, 0, 0, 0)

	var plane = HyperplaneND.new(normal, point, 3)

	assert_that(plane.dimension).is_equal(3)
	assert_that(plane.normal.y).is_equal(1.0)
	assert_that(plane.point).is_equal(Vector4.ZERO)

func test_hyperplane_creation_4d():
	# Test creating a 4D hyperplane (3D hyperplane in 4D space)
	# Hyperplane through origin with normal pointing in W direction
	var normal = Vector4(0, 0, 0, 1)
	var point = Vector4(0, 0, 0, 0)

	var hyperplane = HyperplaneND.new(normal, point, 4)

	assert_that(hyperplane.dimension).is_equal(4)
	assert_that(hyperplane.normal.w).is_equal(1.0)
	assert_that(hyperplane.point).is_equal(Vector4.ZERO)

func test_point_to_hyperplane_distance_3d():
	# Test calculating signed distance from point to plane in 3D
	# Plane: y = 0 (XZ plane)
	# Point above plane should have positive distance
	# Point below plane should have negative distance

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4.ZERO, 3)

	var point_above = Vector4(0, 5, 0, 0)
	var point_below = Vector4(0, -3, 0, 0)
	var point_on_plane = Vector4(10, 0, -5, 0)

	assert_that(plane.signed_distance_to_point(point_above)).is_equal(5.0)
	assert_that(plane.signed_distance_to_point(point_below)).is_equal(-3.0)
	assert_that(plane.signed_distance_to_point(point_on_plane)).is_equal_approx(0.0, 0.001)

func test_point_to_hyperplane_distance_4d():
	# Test calculating signed distance from point to hyperplane in 4D
	# Hyperplane: w = 0 (XYZ hyperplane)

	var hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, 4)

	var point_forward = Vector4(1, 2, 3, 7)
	var point_backward = Vector4(5, -2, 1, -4)
	var point_on_plane = Vector4(100, -50, 25, 0)

	assert_that(hyperplane.signed_distance_to_point(point_forward)).is_equal(7.0)
	assert_that(hyperplane.signed_distance_to_point(point_backward)).is_equal(-4.0)
	assert_that(hyperplane.signed_distance_to_point(point_on_plane)).is_equal_approx(0.0, 0.001)

func test_hyperplane_rotation_around_y_axis():
	# Test rotating a hyperplane around Y-axis
	# This is critical for camera-aligned slicing
	# Y-axis rotation preserves gravity direction

	# Start with hyperplane normal pointing in +Z direction
	var hyperplane = HyperplaneND.new(Vector4(0, 0, 1, 0), Vector4.ZERO, 3)

	# Rotate 90 degrees around Y-axis (should point in -X direction)
	var rotated = hyperplane.rotate_around_y_axis(PI / 2.0)

	# Check that Y component is preserved
	assert_that(rotated.normal.y).is_equal_approx(0.0, 0.001)

	# Check that rotation occurred in XZ plane
	assert_that(rotated.normal.x).is_equal_approx(-1.0, 0.001)
	assert_that(rotated.normal.z).is_equal_approx(0.0, 0.001)

func test_hyperplane_through_point():
	# Test creating hyperplane that passes through a specific point
	# Used for player-centered slicing

	var player_pos = Vector4(10, 5, -3, 2)
	var normal = Vector4(0, 0, 0, 1)

	var hyperplane = HyperplaneND.new(normal, player_pos, 4)

	# Hyperplane should pass through player position
	assert_that(hyperplane.is_point_on_plane(player_pos)).is_true()

	# Distance from player to hyperplane should be zero
	assert_that(hyperplane.signed_distance_to_point(player_pos)).is_equal_approx(0.0, 0.001)

func test_hyperplane_normal_normalization():
	# Test that hyperplane normals are properly normalized
	# Non-unit normals should be automatically normalized

	# Create hyperplane with non-unit normal
	var non_unit_normal = Vector4(3, 0, 4, 0)  # Length = 5
	var hyperplane = HyperplaneND.new(non_unit_normal, Vector4.ZERO, 3)

	# Normal should be normalized to unit length
	var length = sqrt(hyperplane.normal.x * hyperplane.normal.x +
	                  hyperplane.normal.y * hyperplane.normal.y +
	                  hyperplane.normal.z * hyperplane.normal.z)

	assert_that(length).is_equal_approx(1.0, 0.001)
	assert_that(hyperplane.normal.x).is_equal_approx(0.6, 0.001)  # 3/5
	assert_that(hyperplane.normal.z).is_equal_approx(0.8, 0.001)  # 4/5
