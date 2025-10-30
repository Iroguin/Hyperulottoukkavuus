# res://scripts/level_manager.gd
extends Node
class_name LevelManager

signal level_completed
signal level_failed
signal fruit_collected(fruit_number: int, total_fruits: int)

var current_level: Node3D  # Changed from Level4D to Node3D
var fruits_in_level := 0
var fruits_collected := 0
var max_dimension_switches := 10

func load_level(level_scene: PackedScene):
	# Clear previous level
	if current_level:
		current_level.queue_free()
		fruits_collected = 0
	
	# Load new level
	current_level = level_scene.instantiate()
	get_tree().current_scene.add_child(current_level)
	
	# Try to find Fruits container
	var fruits_node = current_level.get_node_or_null("Fruits")
	if fruits_node:
		fruits_in_level = fruits_node.get_child_count()
	else:
		fruits_in_level = 0
		push_warning("No 'Fruits' node found in level!")
	
	# Get level settings from metadata if available
	if current_level.has_meta("max_dimension_switches"):
		max_dimension_switches = current_level.get_meta("max_dimension_switches")
	else:
		max_dimension_switches = 10  # Default
	
	# Reset dimension switches
	GameWorld4D.dimension_manager.remaining_switches = max_dimension_switches
	GameWorld4D.dimension_manager.max_dimension_switches = max_dimension_switches
	GameWorld4D.dimension_manager.current_dimension = 4  # Start in 4D
	
	print("Level loaded with %d fruits and %d dimension switches" % [fruits_in_level, max_dimension_switches])

func on_fruit_collected(fruit: DimensionalFruit):
	fruits_collected += 1
	fruit_collected.emit(fruits_collected, fruits_in_level)
	
	print("Fruit collected: %d/%d" % [fruits_collected, fruits_in_level])
	
	if fruits_collected >= fruits_in_level:
		level_completed.emit()
		print("🎉 Level Complete! All fruits collected!")
	elif GameWorld4D.dimension_manager.remaining_switches <= 0:
		level_failed.emit()
		print("❌ Out of dimension switches! Level failed.")

func restart_level():
	if current_level and current_level.scene_file_path:
		var level_path = current_level.scene_file_path
		load_level(load(level_path))
