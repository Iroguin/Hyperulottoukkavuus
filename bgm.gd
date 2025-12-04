extends AudioStreamPlayer
var time
var music=[0,"res://music/placeholders/placeholder_1dmusiikkieihyva.ogg", "res://music/placeholders/placeholder_23dmusiikkijippii.ogg","res://music/placeholders/placeholder_23dmusiikkijippii.ogg", "res://music/placeholders/placeholder_23dmusiikkijippii.ogg"]
func _ready() -> void:
	pass 
func _on_player_4d_light(_a, dim) -> void:
	print("musa",dim)
	time=self.get_playback_position()+AudioServer.get_time_since_last_mix()
	self.stream=load(music[dim])
	self.play(time)
