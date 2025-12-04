extends AudioStreamPlayer
var time
var music="res://music/placeholders/placeholder_23dmusiikkijippii.ogg"
func _ready() -> void:
	pass 
func switch():
	time=self.get_playback_position()
	self.play(time)
	self.stream=music
