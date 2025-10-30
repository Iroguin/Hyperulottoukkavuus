# res://scripts/4d/dimensional_fruit.gd
extends Object4D
class_name DimensionalFruit

@export var required_dimension := 2  # Which dimension player must be in to collect
@export var fruit_color := Color.GREEN

var is_collected := false

func _ready():
	super._ready()
	collision_radius_4d = 0.3
	setup_appearance()

func setup_appearance():
	# Visual feedback based on dimension
	if mesh_instance:
		var mat = mesh_instance.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = fruit_color
			mat.emission_enabled = true
			mat.emission = fruit_color
			mat.emission_energy = 2.0

func _physics_process(delta):
	# Rotate fruit for visual appeal
	if not is_collected:
		GameWorld4D.dimension_manager.rotation_xw += delta * 0.5
		GameWorld4D.dimension_manager.rotation_yw += delta * 0.3

	super._physics_process(delta)

func collect():
	is_collected = true
	# Play collection effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)

func is_in_dimension(dim: int) -> bool:
	# Fruit only exists in its required dimension
	return dim == required_dimension

func update_visual_projection():
	super.update_visual_projection()

	# Pulsate effect
	if not is_collected:
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.2
		scale = Vector3.ONE * pulse
