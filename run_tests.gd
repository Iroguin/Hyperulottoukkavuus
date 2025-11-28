extends SceneTree

# Simple test runner script
# Usage: godot --headless --script run_tests.gd

func _init():
	print("Running GDUnit4 tests...")

	# Check if GDUnit4 is available
	if not FileAccess.file_exists("res://addons/gdUnit4/bin/GdUnitCmdTool.gd"):
		print("ERROR: GDUnit4 not found at res://addons/gdUnit4/")
		quit(1)
		return

	# Load the GDUnit4 command tool
	var GdUnitCmdTool = load("res://addons/gdUnit4/bin/GdUnitCmdTool.gd")

	if GdUnitCmdTool:
		print("GDUnit4 loaded successfully")
		# Run tests
		var cmd_tool = GdUnitCmdTool.new()
		# The actual test running happens in the GdUnitCmdTool script
	else:
		print("ERROR: Could not load GdUnitCmdTool")
		quit(1)

	quit()
