# res://scripts/level_manager.gd
extends Node
class_name LevelManager

signal level_completed(time: float, dimension_switches: int)
signal fruit_collected

@export var level_name := "Level 1"
@export var next_level_scene: PackedScene

var player: Player4D
var fruits: Array[DimensionalFruit] = []
var fruits_collected := 0
var total_fruits := 0

var level_start_time := 0.0
var level_time := 0.0
var dimension_switches := 0
var is_level_complete := false

func _ready():
	add_to_group("level_manager")
	print("=== Level Manager Ready ===")
	print("Level: ", level_name)
	
	# Find player
	await get_tree().process_frame  # Wait one frame for everything to initialize
	player = get_tree().get_first_node_in_group("player") as Player4D
	
	if not player:
		push_error("No player found! Make sure player is in 'player' group")
		return
	
	print("Player found: ", player.name)
	
	# Find all fruits in the level
	find_all_fruits()
	
	# Connect to dimension manager to track switches
	if GameWorld4D.dimension_manager:
		# We'll track this manually since dimension_manager doesn't have a signal yet
		pass
	
	# Start timer
	level_start_time = Time.get_ticks_msec() / 1000.0

func _process(delta):
	if is_level_complete:
		return
	
	# Update level time
	level_time = (Time.get_ticks_msec() / 1000.0) - level_start_time

func find_all_fruits():
	fruits.clear()
	fruits_collected = 0
	
	# Find all DimensionalFruit nodes
	for node in get_tree().get_nodes_in_group("4d_objects"):
		if node is DimensionalFruit:
			var fruit = node as DimensionalFruit
			fruits.append(fruit)
			fruit.collected.connect(_on_fruit_collected)
	
	total_fruits = fruits.size()
	print("Found ", total_fruits, " fruits in level")
	
	if total_fruits == 0:
		push_warning("No fruits found in level!")

func _on_fruit_collected(by_player: Player4D):
	fruits_collected += 1
	fruit_collected.emit()
	
	print("Fruits collected: ", fruits_collected, "/", total_fruits)
	
	# Check if level is complete
	if fruits_collected >= total_fruits:
		complete_level()

func complete_level():
	if is_level_complete:
		return
	
	is_level_complete = true
	
	print("🎉 LEVEL COMPLETE! 🎉")
	print("  Time: ", "%.2f" % level_time, " seconds")
	print("  Dimension Switches: ", dimension_switches)
	
	level_completed.emit(level_time, dimension_switches)
	
	# Show completion UI
	show_completion_screen()

func show_completion_screen():
	# Wait a moment before showing screen
	await get_tree().create_timer(1.0).timeout
	
	# You can create a completion UI scene or just load next level
	if next_level_scene:
		load_next_level()
	else:
		print("No next level set. Restarting current level...")
		await get_tree().create_timer(2.0).timeout
		restart_level()

func load_next_level():
	print("Loading next level...")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_packed(next_level_scene)

func restart_level():
	get_tree().reload_current_scene()

func track_dimension_switch():
	dimension_switches += 1
	print("Dimension switches: ", dimension_switches)

func get_completion_percentage() -> float:
	if total_fruits == 0:
		return 0.0
	return (float(fruits_collected) / float(total_fruits)) * 100.0
