# res://scripts/level_ui.gd
extends CanvasLayer

@onready var level_name_label: Label = $MarginContainer/VBoxContainer/LevelNameLabel
@onready var fruits_label: Label = $MarginContainer/VBoxContainer/FruitsLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var dimension_label: Label = $MarginContainer/VBoxContainer/DimensionLabel
@onready var completion: Label = $MarginContainer/completion

var level_manager: LevelManager

func _ready():
	# Find level manager
	level_manager = get_tree().get_first_node_in_group("level_manager")
	
	if level_manager:
		level_name_label.text = level_manager.level_name
		level_manager.fruit_collected.connect(update_fruits)
		level_manager.level_completed.connect(_on_level_complete)

func _process(_delta):
	if level_manager:
		# Update fruits
		fruits_label.text = "Fruits: %d/%d" % [level_manager.fruits_collected, level_manager.total_fruits]
		
		# Update time
		time_label.text = "Time: %.1f s" % level_manager.level_time
	
	# Update dimension
	if GameWorld4D.dimension_manager:
		dimension_label.text = "Dimension: %dD" % GameWorld4D.dimension_manager.current_dimension

func update_fruits():
	# Already updated in _process
	pass

func _on_level_complete(time: float, switches: int):
	# Show completion message
	completion.text = "LEVEL COMPLETE!\nTime: %.2f s\nSwitches: %d" % [time, switches]
	completion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	completion.add_theme_font_size_override("font_size", 48)
	add_child(completion)
