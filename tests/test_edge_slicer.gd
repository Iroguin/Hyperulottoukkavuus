# GdUnit generated TestSuite
class_name TestEdgeSlicer
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const EdgeSlicer = preload("res://scripts/slicing/edge_slicer.gd")
const HyperplaneND = preload("res://scripts/4d/hyperplane_nd.gd")

func test_slice_edge_crossing_hyperplane():
	# Edge from (0,0,0,0) to (2,0,0,0) crosses hyperplane at X=1
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var start = Vector4(0, 0, 0, 0)
	var end = Vector4(2, 0, 0, 0)

	var result = EdgeSlicer.slice_edge(start, end, hyperplane)

	assert_bool(result.intersects).is_true()
	assert_float(result.intersection_point.x).is_equal_approx(1.0, 0.01)
	assert_float(result.t).is_equal_approx(0.5, 0.01)

func test_slice_edge_parallel_to_hyperplane():
	# Edge parallel to hyperplane but NOT on it should not intersect
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(0, 0, 0, 0), 4)
	var start = Vector4(1, 1, 0, 0)  # Both points at X=1, away from hyperplane at X=0
	var end = Vector4(1, 2, 0, 0)

	var result = EdgeSlicer.slice_edge(start, end, hyperplane)

	assert_bool(result.intersects).is_false()

func test_slice_edge_outside_segment():
	# Intersection point exists on line but outside [start, end] segment
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(3, 0, 0, 0), 4)
	var start = Vector4(0, 0, 0, 0)
	var end = Vector4(1, 0, 0, 0)

	var result = EdgeSlicer.slice_edge(start, end, hyperplane)

	# Should not intersect because t > 1
	assert_bool(result.intersects).is_false()

func test_slice_triangle_through_middle():
	# Triangle with vertices at Y=0, Y=1, Y=2, sliced at Y=1
	var hyperplane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4(0, 1, 0, 0), 4)
	var v0 = Vector4(0, 0, 0, 0)
	var v1 = Vector4(1, 2, 0, 0)
	var v2 = Vector4(2, 0, 0, 0)

	var intersections = EdgeSlicer.slice_triangle(v0, v1, v2, hyperplane)

	# Should have 2 intersection points
	assert_int(intersections.size()).is_equal(2)

	# Both intersections should be at Y=1
	for intersection in intersections:
		assert_float(intersection.intersection_point.y).is_equal_approx(1.0, 0.01)

func test_slice_triangle_no_intersection():
	# Triangle entirely below the hyperplane
	var hyperplane = HyperplaneND.new(Vector4(0, 1, 0, 0), Vector4(0, 5, 0, 0), 4)
	var v0 = Vector4(0, 0, 0, 0)
	var v1 = Vector4(1, 1, 0, 0)
	var v2 = Vector4(2, 0, 0, 0)

	var intersections = EdgeSlicer.slice_triangle(v0, v1, v2, hyperplane)

	# Should have no intersections
	assert_int(intersections.size()).is_equal(0)

func test_slice_quad_through_middle():
	# Square quad at Z=0 to Z=2, sliced at Z=1
	var hyperplane = HyperplaneND.new(Vector4(0, 0, 1, 0), Vector4(0, 0, 1, 0), 4)
	var v0 = Vector4(0, 0, 0, 0)
	var v1 = Vector4(1, 0, 0, 0)
	var v2 = Vector4(1, 0, 2, 0)
	var v3 = Vector4(0, 0, 2, 0)

	var intersections = EdgeSlicer.slice_quad(v0, v1, v2, v3, hyperplane)

	# Should have 2 intersection points (crosses through quad)
	assert_int(intersections.size()).is_equal(2)

	# Both intersections should be at Z=1
	for intersection in intersections:
		assert_float(intersection.intersection_point.z).is_equal_approx(1.0, 0.01)

func test_classify_vertex_behind():
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var vertex = Vector4(0, 0, 0, 0)  # Behind plane at X=1

	var classification = EdgeSlicer.classify_vertex(vertex, hyperplane)

	assert_int(classification).is_equal(-1)

func test_classify_vertex_on_plane():
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var vertex = Vector4(1, 5, 3, 2)  # On plane at X=1

	var classification = EdgeSlicer.classify_vertex(vertex, hyperplane)

	assert_int(classification).is_equal(0)

func test_classify_vertex_in_front():
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var vertex = Vector4(2, 0, 0, 0)  # In front of plane at X=1

	var classification = EdgeSlicer.classify_vertex(vertex, hyperplane)

	assert_int(classification).is_equal(1)

func test_does_edge_cross_hyperplane_yes():
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var start = Vector4(0, 0, 0, 0)  # Behind
	var end = Vector4(2, 0, 0, 0)    # In front

	var crosses = EdgeSlicer.does_edge_cross_hyperplane(start, end, hyperplane)

	assert_bool(crosses).is_true()

func test_does_edge_cross_hyperplane_no():
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4(1, 0, 0, 0), 4)
	var start = Vector4(0, 0, 0, 0)  # Behind
	var end = Vector4(0.5, 0, 0, 0)  # Also behind

	var crosses = EdgeSlicer.does_edge_cross_hyperplane(start, end, hyperplane)

	assert_bool(crosses).is_false()

func test_project_to_slice_space_drop_w():
	# Hyperplane with W-dominant normal
	var hyperplane = HyperplaneND.new(Vector4(0, 0, 0, 1), Vector4.ZERO, 4)
	var point = Vector4(1, 2, 3, 5)

	var projected = EdgeSlicer.project_to_slice_space(point, hyperplane)

	# Should drop W, keep XYZ
	assert_float(projected.x).is_equal_approx(1.0, 0.01)
	assert_float(projected.y).is_equal_approx(2.0, 0.01)
	assert_float(projected.z).is_equal_approx(3.0, 0.01)

func test_project_to_slice_space_drop_x():
	# Hyperplane with X-dominant normal
	var hyperplane = HyperplaneND.new(Vector4(1, 0, 0, 0), Vector4.ZERO, 4)
	var point = Vector4(5, 1, 2, 3)

	var projected = EdgeSlicer.project_to_slice_space(point, hyperplane)

	# Should drop X, keep YZW as XYZ
	assert_float(projected.x).is_equal_approx(1.0, 0.01)
	assert_float(projected.y).is_equal_approx(2.0, 0.01)
	assert_float(projected.z).is_equal_approx(3.0, 0.01)
