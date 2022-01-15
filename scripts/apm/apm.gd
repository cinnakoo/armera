extends Node

signal csrf_obtained()
signal json_obtained(content)
signal jpg_obtained(texture)
signal mp3_obtained(stream)

var payload = {
	"limit":25,
	"offset":0,
	"sort":"relevancy_suggested",
	"terms":[
	   {
		  "type":"text",
		  "field":["tags", "track_title", "track_description", "album_title", "album_description", "sound_alikes", "lyrics", "library","composer"],
		  "value":"Hijacked",
		  "operation":"must"
	   }
	]
}
var headers = [
	"x-sundrop-token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.W3sidHlwZSI6ImNvbXBvc2l0ZSIsImZpZWxkIjoidXNlcmluZm8iLCJ2YWx1ZSI6W3sidHlwZSI6InRleHQiLCJ2YWx1ZSI6IjAiLCJmaWVsZCI6InVzZXJpZCIsIm9wZXJhdGlvbiI6ImluY2x1ZGUifV0sIm9wZXJhdGlvbiI6ImluY2x1ZGUifSx7InR5cGUiOiJ0YWciLCJ2YWx1ZSI6IlVTIiwiZmllbGQiOlsicmVzdHJpY3RlZF90byJdLCJvcGVyYXRpb24iOiJtdXN0In1d.N4wYVgW8VnoKSZApYYjGqS2T3Tud_f4oHDCcKrBqPqg",
	"x-csrf-token: "
]

# Send a GET|POST request.
func request(url: String, callback: String, method: int = HTTPClient.METHOD_GET, query: String = ""):
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)

	http.connect("request_completed", self, callback)
	http.request(url, headers, true, method, query)


func set_search_term(term: String):
	payload["terms"][0]["value"] = term

func set_amount_of_tracks(limit: int):
	payload["limit"] = limit


func search_tracks(term: String, limit: int):
	set_search_term(term)
	set_amount_of_tracks(limit)

	var query = JSON.print(payload)

	request("https://api.apmmusic.com/search/tracks", "on_json_request_completed", HTTPClient.METHOD_POST, query)

func search_albums(term: String, limit: int):
	set_search_term(term)
	set_amount_of_tracks(limit)

	var query = JSON.print(payload)

	request("https://api.apmmusic.com/search/albums", "on_json_request_completed", HTTPClient.METHOD_POST, query)

func get_album_tracks(code: String):
	request("https://api.apmmusic.com/search/albums/%s/tracks" % code, "on_json_request_completed")


# Obtains a parsed JSON for usage.
func get_json(url: String):
	request(url, "on_json_request_completed")

# Obtains an ImageTexture for a TextureRect.
func get_jpg(url: String):
	request(url, "on_jpg_request_completed")

# Obtains an AudioStreamMP3 for an AudioStreamPlayer.
func get_mp3(url: String):
	request(url, "on_mp3_request_completed")

# Obtains a CSRF token for authorization, emits `csrf_obtained` if successful.
func get_csrf():
	request("https://www.apmmusic.com/services/session/token", "on_csrf_request_completed")


func on_json_request_completed(_result: int, _code: int, _headers: PoolStringArray, body: PoolByteArray):
	var json: String = body.get_string_from_utf8()
	var content: JSONParseResult = JSON.parse(json)

	emit_signal("json_obtained", content.result)

func on_jpg_request_completed(_result: int, _code: int, _headers: PoolStringArray, body: PoolByteArray):
	yield(get_tree(), "idle_frame")
	
	var image: Image = Image.new()
	image.load_jpg_from_buffer(body)

	var texture: ImageTexture = ImageTexture.new()
	texture.create_from_image(image, 0)

	emit_signal("jpg_obtained", texture)

func on_mp3_request_completed(_result: int, _code: int, _headers: PoolStringArray, body: PoolByteArray):
	var mp3: AudioStreamMP3 = AudioStreamMP3.new()
	mp3.data = body

	emit_signal("mp3_obtained", mp3)

func on_csrf_request_completed(_result: int, _code: int, _headers: PoolStringArray, body: PoolByteArray):
	var token: String = "x-csrf-token: " + body.get_string_from_utf8()
	headers[1] = token

	emit_signal("csrf_obtained")
