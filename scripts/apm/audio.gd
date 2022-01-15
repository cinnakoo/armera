extends AudioStreamPlayer

onready var apm = get_node("/root/Apm")

var url: String

func _ready():
	apm.connect("mp3_obtained", self, "on_mp3_obtained")

func set_track(trackUrl: String):
	url = trackUrl
	apm.get_mp3(trackUrl)

func on_mp3_obtained(stream: AudioStreamMP3):
	stream = stream
