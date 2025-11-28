# res://tests/test_slice_intersection.gd
extends GdUnitTestSuite

## Test suite for line-hyperplane intersection calculations
## Tests edge-plane intersections for mesh slicing

const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")
const GeometricIntersection = preload("res://scripts/4d/geometric_intersection.gd")

func test_line_plane_intersection_3d_perpendicular():
	# Test line perpendicular to plane
	# Line from (0, -1, 0) to (0, 1, 0)
	# Plane at y = 0
	# Should intersect at (0, 0, 0)

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4.ZERO, 3)
	var line_start = Vector4(0, -1, 0, 0)
	var line_end = Vector4(0, 1, 0, 0)

	var result = GeometricIntersection.line_hyperplane_intersection(line_start, line_end, plane)

	assert_that(result.intersects).is_true()
	assert_that(result.intersection_point.x).is_equal_approx(0.0, 0.001)
	assert_that(result.intersection_point.y).is_equal_approx(0.0, 0.001)
	assert_that(result.intersection_point.z).is_equal_approx(0.0, 0.001)
	assert_that(result.t).is_equal_approx(0.5, 0.001)

func test_line_plane_intersection_3d_parallel():
	# Test line parallel to plane (no intersection)
	# Line from (0, 1, 0) to (1, 1, 0)
	# Plane at y = 0
	# Should return null/no intersection

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4.ZERO, 3)
	var line_start = Vector4(0, 1, 0, 0)
	var line_end = Vector4(1, 1, 0, 0)

	var result = GeometricIntersection.line_hyperplane_intersection(line_start, line_end, plane)

	assert_that(result.intersects).is_false()

func test_line_plane_intersection_3d_angled():
	# Test line at angle to plane
	# Line from (-1, -1, 0) to (1, 1, 0)
	# Plane at y = 0
	# Should intersect at (0, 0, 0)

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4.ZERO, 3)
	var line_start = Vector4(-1, -1, 0, 0)
	var line_end = Vector4(1, 1, 0, 0)

	var result = GeometricIntersection.line_hyperplane_intersection(line_start, line_end, plane)

	assert_that(result.intersects).is_true()
	assert_that(result.intersection_point.x).is_equal_approx(0.0, 0.001)
	assert_that(result.intersection_point.y).is_equal_approx(0.0, 0.001)
	assert_that(result.intersection_point.z).is_equal_approx(0.0, 0.001)
	assert_that(result.t).is_equal_approx(0.5, 0.001)

func test_line_hyperplane_intersection_4d():
	# Test 4D line intersecting 4D hyperplane
	# Line from (0, 0, 0, -1) to (0, 0, 0, 1)
	# Hyperplane at w = 0
	# Should intersect at (0, 0, 0, 0)

	var hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, 4)
	var line_start = Vector4(0, 0, 0, -1)
	var line_end = Vector4(0, 0, 0, 1)

	var result = GeometricIntersection.line_hyperplane_intersection(line_start, line_end, hyperplane)

	assert_that(result.intersects).is_true()
	assert_that(result.intersection_point).is_equal(Vector4.ZERO)
	assert_that(result.t).is_equal_approx(0.5, 0.001)

func test_edge_intersection_ratio():
	# Test calculating t-value (0-1) for intersection along edge
	# Important for interpolating vertex attributes at intersection

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4(0, 2, 0, 0), 3)
	var line_start = Vector4(0, 0, 0, 0)
	var line_end = Vector4(0, 10, 0, 0)

	var result = GeometricIntersection.line_hyperplane_intersection(line_start, line_end, plane)

	# Plane at y=2, line from y=0 to y=10, intersection at y=2
	# t should be 0.2 (20% along the line)
	assert_that(result.intersects).is_true()
	assert_that(result.t).is_equal_approx(0.2, 0.001)

func test_sphere_hyperplane_intersection():
	# Test whether a sphere intersects a hyperplane
	# Used for quick rejection testing before detailed mesh slicing

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4(0, 5, 0, 0), 3)

	# Sphere touching the plane
	var sphere_touching = Vector4(0, 8, 0, 0)
	assert_that(GeometricIntersection.sphere_hyperplane_intersection(sphere_touching, 3.0, plane)).is_true()

	# Sphere far from plane
	var sphere_far = Vector4(0, 20, 0, 0)
	assert_that(GeometricIntersection.sphere_hyperplane_intersection(sphere_far, 2.0, plane)).is_false()

	# Sphere intersecting plane
	var sphere_intersecting = Vector4(0, 6, 0, 0)
	assert_that(GeometricIntersection.sphere_hyperplane_intersection(sphere_intersecting, 5.0, plane)).is_true()

func test_hypersphere_hyperplane_intersection_4d():
	# Test whether a 4D hypersphere intersects a 4D hyperplane
	# Returns true if within slice thickness

	var hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 0), 4)

	# Hypersphere centered at w=5 with radius 3 should not intersect hyperplane at w=0
	var center_far = Vector4(0, 0, 0, 10)
	assert_that(GeometricIntersection.sphere_hyperplane_intersection(center_far, 3.0, hyperplane)).is_false()

	# Hypersphere centered at w=2 with radius 3 should intersect hyperplane at w=0
	var center_near = Vector4(0, 0, 0, 2)
	assert_that(GeometricIntersection.sphere_hyperplane_intersection(center_near, 3.0, hyperplane)).is_true()

func test_aabb_hyperplane_intersection():
	# Test whether an axis-aligned bounding box intersects hyperplane
	# Used for spatial culling optimization

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4(0, 0, 0, 0), 3)

	# Box above plane (y from 1 to 3)
	var box_above_min = Vector4(-1, 1, -1, 0)
	var box_above_max = Vector4(1, 3, 1, 0)
	assert_that(GeometricIntersection.aabb_hyperplane_intersection(box_above_min, box_above_max, plane)).is_false()

	# Box intersecting plane (y from -1 to 1)
	var box_intersect_min = Vector4(-1, -1, -1, 0)
	var box_intersect_max = Vector4(1, 1, 1, 0)
	assert_that(GeometricIntersection.aabb_hyperplane_intersection(box_intersect_min, box_intersect_max, plane)).is_true()

func test_intersection_on_edge_endpoints():
	# Test edge cases where intersection occurs exactly at edge endpoints
	# Should handle without numerical instability

	var plane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4.ZERO, 3)

	# Line starting exactly on plane
	var result1 = GeometricIntersection.line_hyperplane_intersection(
		Vector4(0, 0, 0, 0),
		Vector4(0, 5, 0, 0),
		plane
	)
	assert_that(result1.intersects).is_true()
	assert_that(result1.t).is_equal_approx(0.0, 0.001)

	# Line ending exactly on plane
	var result2 = GeometricIntersection.line_hyperplane_intersection(
		Vector4(0, 5, 0, 0),
		Vector4(0, 0, 0, 0),
		plane
	)
	assert_that(result2.intersects).is_true()
	assert_that(result2.t).is_equal_approx(1.0, 0.001)
