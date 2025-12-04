# res://scripts/4d/dimensional_fruit.gd
extends Object4D
class_name DimensionalFruit

signal collected(by_player: Player4D)

@export var required_dimension := 4  # Which dimension must player be in to collect
@export var rotation_speed := 1.0
@export var bob_speed := 2.0
@export var bob_height := 0.3

var is_collected := false
var initial_y: float

func _ready():
	super._ready()
	initial_y = position_4d.y
	
	# Set collision radius smaller for precise collection
	collision_radius_4d = 0.5
	
	print("Dimensional Fruit spawned at: ", position_4d)
	print("  Required dimension: ", required_dimension)

func _process(delta):
	if is_collected:
		return
	
	# Visual effects - rotate and bob
	if mesh_instance:
		mesh_instance.rotate_y(rotation_speed * delta)
		
		# Bob up and down
		var bob_offset = sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_height
		position_4d.y = initial_y + bob_offset

func on_collision(other: Object4D):
	if is_collected:
		return
	
	# Check if it's the player
	if not other is Player4D:
		return
	
	var player = other as Player4D
	
	# Check if player is in the correct dimension
	var current_dim = GameWorld4D.dimension_manager.current_dimension
	
	if current_dim == required_dimension:
		collect(player)
	else:
		print("Fruit requires dimension ", required_dimension, " but player is in dimension ", current_dim)

func collect(player: Player4D):
	if is_collected:
		return
	
	is_collected = true
	print("Fruit collected by ", player.name)
	
	# Visual feedback
	play_collection_effect()
	
	# Emit signal
	collected.emit(player)
	
	# Remove from world after effect
	await get_tree().create_timer(0.5).timeout
	queue_free()

func play_collection_effect():
	# Scale up and fade out effect
	if mesh_instance:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mesh_instance, "scale", Vector3(2, 2, 2), 0.5)
		
		# Optional: Add material fade if you want
		var material = mesh_instance.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
	
	# Play sound effect (if you have one)
	# $AudioStreamPlayer3D.play()

func set_required_dimension(dim: int):
	required_dimension = clamp(dim, 1, 4)
	update_visual_for_dimension()

func update_visual_for_dimension():
	# Optional: Change color based on required dimension
	if mesh_instance:
		var material = mesh_instance.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			match required_dimension:
				1: material.albedo_color = Color.RED
				2: material.albedo_color = Color.GREEN
				3: material.albedo_color = Color.BLUE
				4: material.albedo_color = Color.YELLOW
