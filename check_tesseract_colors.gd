extends Node

# Quick script to check if tesseract_red_test_5.glb has vertex colors
func _ready():
	var scene = load("res://blender_tests/tesseract_red_test_5.glb")
	if not scene:
		print("ERROR: Could not load tesseract_red_test_5.glb")
		return

	var instance = scene.instantiate()
	add_child(instance)

	print("=== TESSERACT VERTEX COLOR CHECK ===")
	print("Scene loaded successfully")
	print("")

	# Find all MeshInstance3D nodes
	var mesh_instances = find_mesh_instances(instance)
	print("Found %d MeshInstance3D nodes" % mesh_instances.size())
	print("")

	for mesh_inst in mesh_instances:
		print("--- MeshInstance: %s ---" % mesh_inst.name)
		var mesh = mesh_inst.mesh

		if not mesh:
			print("  No mesh attached")
			continue

		print("  Mesh type: %s" % mesh.get_class())
		print("  Surface count: %d" % mesh.get_surface_count())

		# Check each surface for vertex colors
		for surface_idx in range(mesh.get_surface_count()):
			print("")
			print("  Surface %d:" % surface_idx)

			# Get mesh data arrays
			var arrays = mesh.surface_get_arrays(surface_idx)

			if arrays.size() <= Mesh.ARRAY_COLOR:
				print("    Arrays size too small for COLOR data")
				continue

			var colors = arrays[Mesh.ARRAY_COLOR]

			if colors == null:
				print("    ❌ NO VERTEX COLORS FOUND")
				print("    The mesh was imported without vertex color data.")
				print("    Blender export may not have included vertex colors,")
				print("    or Godot import settings need adjustment.")
			else:
				print("    ✅ VERTEX COLORS PRESENT")
				print("    Color array type: PackedColorArray")
				print("    Color count: %d" % colors.size())

				if colors.size() > 0:
					# Check first few colors to see if red channel has varied values
					var sample_size = min(72, colors.size())
					print("")
					print("    Sample of first %d vertex colors:" % sample_size)
					var has_varying_red = false
					var first_red = colors[0].r if colors.size() > 0 else 0.0

					for i in range(sample_size):
						var color = colors[i]
						print("      [%d] R:%.3f G:%.3f B:%.3f A:%.3f" % [i, color.r, color.g, color.b, color.a])
						if abs(color.r - first_red) > 0.01:
							has_varying_red = true

					print("")
					if has_varying_red:
						print("    ✅ RED CHANNEL HAS VARYING VALUES")
						print("    This suggests W coordinates are encoded in COLOR.r")
					else:
						print("    ⚠️  RED CHANNEL APPEARS CONSTANT")
						print("    Expected varying values for W coordinate encoding")
						print("    All red values are approximately %.3f" % first_red)

			# Check vertex count
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			if vertices:
				print("")
				print("    Vertex count: %d" % vertices.size())
				print("    Expected: 16 vertices for a tesseract")
				if vertices.size() == 16:
					print("    ✅ Correct vertex count for tesseract")
				else:
					print("    ⚠️  Unexpected vertex count")

	print("")
	print("=== CHECK COMPLETE ===")
	print("")
	print("Expected behavior:")
	print("- Should have 16 vertices (tesseract in 4D)")
	print("- Should have vertex colors (COLOR array)")
	print("- Red channel should vary from 0.0 to 1.0 (encoding W from -1 to 1)")
	print("- Shader reads: vec4 pos_4d = vec4(VERTEX.xyz, COLOR.r * 2.0 - 1.0)")

	# Clean up
	await get_tree().create_timer(0.1).timeout
	queue_free()

func find_mesh_instances(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(find_mesh_instances(child))
	return result
