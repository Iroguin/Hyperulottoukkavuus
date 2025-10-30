# res://scripts/4d/game_world_4d.gd (Set as Autoload: GameWorld4D)
extends Node

var dimension_manager: DimensionManager
var collision_manager: CollisionManager4D
var level_manager: LevelManager

var registered_objects: Array[Object4D] = []

func _ready():
	dimension_manager = DimensionManager.new()
	add_child(dimension_manager)
	
	collision_manager = CollisionManager4D.new()
	add_child(collision_manager)
	
	level_manager = LevelManager.new()
	add_child(level_manager)

func register_object(obj: Object4D):
	if obj not in registered_objects:
		registered_objects.append(obj)

func unregister_object(obj: Object4D):
	registered_objects.erase(obj)
