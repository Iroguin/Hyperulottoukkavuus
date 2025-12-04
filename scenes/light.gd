extends DirectionalLight3D


func _on_player_4d_light(light, _a) -> void:
	if light:
		self.light_color = Color.WHITE
	else:
		self.light_color = Color.BLACK
