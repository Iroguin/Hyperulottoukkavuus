extends AudioStreamPlayer
var time
var music
func _ready() -> void:
	pass 
func switch():
	time=self.get_playback_position()
	self.play(time)
	self.stream=music
