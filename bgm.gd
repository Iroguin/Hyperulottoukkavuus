extends AudioStreamPlayer
var time
var music=[0,"res://music/12Dmusa.ogg",
		"res://music/12Dmusa.ogg",
"res://music/34Dmusa.ogg",
  "res://music/34Dmusa.ogg"]
func _ready() -> void:
	pass 
func _on_player_4d_light(_a, dim) -> void:

	time=self.get_playback_position()+AudioServer.get_time_since_last_mix()
	self.stream=load(music[dim])
	self.play(time)
