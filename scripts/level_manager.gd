# res://scripts/level_manager.gd
extends Node
class_name LevelManager

signal level_completed
signal level_failed

var current_level: Level4D
var fruits_in_level := 0
var fruits_collected := 0

func load_level(level_scene: PackedScene):
	# Clear previous level
	if current_level:
		current_level.queue_free()
	
	# Load new level
	current_level = level_scene.instantiate()
	add_child(current_level)
	
	# Count fruits
	fruits_in_level = current_level.get_node("Fruits").get_child_count()
	fruits_collected = 0
	
	# Reset dimension switches
	GameWorld4D.dimension_manager.remaining_switches = current_level.max_dimension_switches
	GameWorld4D.dimension_manager.max_dimension_switches = current_level.max_dimension_switches

func on_fruit_collected(fruit: DimensionalFruit):
	fruits_collected += 1
	
	if fruits_collected >= fruits_in_level:
		level_completed.emit()
		print("Level Complete!")
	
	# Check if out of switches
	if GameWorld4D.dimension_manager.remaining_switches <= 0 and fruits_collected < fruits_in_level:
		level_failed.emit()
		print("Out of dimension switches! Level failed.")
