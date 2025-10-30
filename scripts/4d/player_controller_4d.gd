# res://scripts/4d/player_4d.gd
extends Object4D
class_name Player4D

@export var move_speed := 5.0
@export var rotation_speed := 2.0

var collected_fruits := []

func _ready():
	super._ready()
	collision_radius_4d = 0.5

func _process(delta):
	handle_dimension_switching()
	handle_slice_adjustment()

func _physics_process(delta):
	handle_movement(delta)
	super._physics_process(delta)

func handle_movement(delta):
	var dimension = GameWorld4D.dimension_manager.current_dimension
	var input_vector := Vector4.ZERO

	# Movement based on current dimension
	match dimension:
		1:
			# Only move along X axis
			if Input.is_action_pressed("move_right"):
				input_vector.x = 1.0
			elif Input.is_action_pressed("move_left"):
				input_vector.x = -1.0

		2:
			# Move in XY plane
			input_vector.x = Input.get_axis("move_left", "move_right")
			input_vector.y = Input.get_axis("move_down", "move_up")

		3:
			# Move in XYZ space
			input_vector.x = Input.get_axis("move_left", "move_right")
			input_vector.y = Input.get_axis("move_down", "move_up")
			input_vector.z = Input.get_axis("move_backward", "move_forward")

		4:
			# Move in full 4D space
			input_vector.x = Input.get_axis("move_left", "move_right")
			input_vector.y = Input.get_axis("move_down", "move_up")
			input_vector.z = Input.get_axis("move_backward", "move_forward")
			input_vector.w = Input.get_axis("move_ana", "move_kata")  # 4th dimension

	# Normalize and apply speed
	if input_vector.length_squared() > 0:
		velocity_4d = normalize_vector4(input_vector) * move_speed
	else:
		velocity_4d = Vector4.ZERO

func handle_dimension_switching():
	if Input.is_action_just_pressed("dimension_up"):
		GameWorld4D.dimension_manager.increase_dimension()

	if Input.is_action_just_pressed("dimension_down"):
		GameWorld4D.dimension_manager.decrease_dimension()

func handle_slice_adjustment():
	# Adjust slice position when in lower dimensions
	var dimension = GameWorld4D.dimension_manager.current_dimension

	if dimension < 4 and Input.is_action_pressed("adjust_slice_modifier"):
		var slice_speed = 2.0
		if Input.is_action_pressed("move_forward"):
			match dimension:
				1: GameWorld4D.dimension_manager.slice_z += slice_speed * get_process_delta_time()
				2: GameWorld4D.dimension_manager.slice_z += slice_speed * get_process_delta_time()
				3: GameWorld4D.dimension_manager.slice_x += slice_speed * get_process_delta_time()
		elif Input.is_action_pressed("move_backward"):
			match dimension:
				1: GameWorld4D.dimension_manager.slice_z -= slice_speed * get_process_delta_time()
				2: GameWorld4D.dimension_manager.slice_z -= slice_speed * get_process_delta_time()
				3: GameWorld4D.dimension_manager.slice_x -= slice_speed * get_process_delta_time()

func on_collision(other: Object4D):
	if other is DimensionalFruit:
		try_collect_fruit(other)
	elif other is Obstacle4D:
		# Bounce back
		var normal = GameWorld4D.collision_manager.get_collision_normal(
			self, other, GameWorld4D.dimension_manager.current_dimension
		)
		position_4d -= normal * 0.1  # Push back slightly
		velocity_4d = Vector4.ZERO

func try_collect_fruit(fruit: DimensionalFruit):
	var current_dim = GameWorld4D.dimension_manager.current_dimension

	if fruit.required_dimension == current_dim:
		collected_fruits.append(fruit)
		fruit.collect()
		print("Collected %dD fruit!" % current_dim)
		GameWorld4D.level_manager.on_fruit_collected(fruit)
	else:
		print("Wrong dimension! Need to be in %dD to collect this fruit." % fruit.required_dimension)

func normalize_vector4(v: Vector4) -> Vector4:
	var length = sqrt(v.x*v.x + v.y*v.y + v.z*v.z + v.w*v.w)
	if length > 0:
		return v / length
	return Vector4.ZERO
