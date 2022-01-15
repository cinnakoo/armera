extends Control

# Singletons
onready var apm = get_node("/root/Apm")
onready var options = get_node("/root/Options")

# User Interface
onready var home = get_node("Vbox/Footer/Hbox/Homebox/Home")
onready var cog = get_node("Vbox/Footer/Hbox/Optionbox/Options")

# Pages
onready var searcher = $Vbox/Searcher
onready var inspector = $Vbox/AlbumViewer
onready var settings = $Vbox/Options

# Result Containers
onready var searcher_results = searcher.get_node("Scroller/List")
onready var inspector_results = inspector.get_node("Scroller/List")

# User Input
onready var searchbar = searcher.get_node("Searchbox/Line")
onready var searchbtn = searcher.get_node("Searchbox/Search")

# Prefabs
onready var row = preload("res://scenes/gui/Row.tscn")

# Others
onready var audio = get_node("Audio")

var currentlyPlayingTrack: String

func _ready():
	apm.connect("json_obtained", self, "on_apm_json_obtained")
	apm.connect("mp3_obtained", self, "on_apm_mp3_obtained")

	home.connect("pressed", self, "on_home_pressed")
	cog.connect("pressed", self, "on_cog_pressed")

	searchbar.connect("text_entered", self, "on_searchbar_text_entered")
	searchbtn.connect("pressed", self, "on_searchbtn_pressed")

# Flips to the searcher page, to perform search requests.
func search(term: String):
	searcher.clear()

	apm.get_csrf()
	yield(apm, "csrf_obtained")

	apm.search_tracks(term, options.limit)


# Flips to the album inspector page, to view the album.
func inspect_album(metadata: Dictionary):
	inspector.clear()

	apm.get_csrf()
	yield(apm, "csrf_obtained")

	inspector.set_title(metadata["albumTitle"])

	apm.get_jpg(metadata["albumArtLargeUrl"])
	var art = yield(apm, "jpg_obtained")
	inspector.set_album_art(art)

	flip_to_page(inspector)

	apm.get_album_tracks(metadata["albumCode"])
	

# Flips to the correct page of the application.
func flip_to_page(target_page: Container):
	var pages = [searcher, inspector, settings]

	for page in pages:
		if page == target_page:
			page.visible = true
			continue
		
		page.visible = false

# Returns true if the metadata belongs to an album.
func is_album(metadata: Dictionary) -> bool:
	# Track objects don't hold the "title" key.
	if metadata.has("title"):
		return true
	
	# Metadata has "albumTitle" therefore it isn't an album.
	return false

# Returns true if the metadata belongs to a track.
func is_track(metadata: Dictionary) -> bool:
	# Album objects don't hold the "albumTitle" key.
	if metadata.has("albumTitle"):
		return true
	
	# Metadata has "title" therefore it isn't a track.
	return false

func connect_all_pressed_signals(element, metadata: Dictionary):
	element.get_node("Play").connect("pressed", self, "on_row_played", [metadata])
	element.get_node("Pause").connect("pressed", self, "on_row_pause", [metadata])
	element.get_node("Flip").connect("pressed", self, "on_row_inspected", [metadata])


func on_home_pressed():
	flip_to_page(searcher)

func on_cog_pressed():
	flip_to_page(settings)

func on_searchbar_text_entered(text: String):
	search(text)

func on_searchbtn_pressed():
	search(searchbar.text)

func on_row_played(metadata: Dictionary):
	if not is_track(metadata):
		return

	if currentlyPlayingTrack == metadata["trackTitle"]:
		return
	
	currentlyPlayingTrack = metadata["trackTitle"]

	apm.get_mp3(metadata["audioUrl"])


func on_row_paused(metadata: Dictionary):
	if not is_track(metadata):
		return

	if not currentlyPlayingTrack == metadata["trackTitle"]:
		return
	
	audio.stop()

func on_row_inspected(metadata: Dictionary):
	inspect_album(metadata)


func on_apm_mp3_obtained(mp3):
	audio.stream = mp3
	audio.play()

func on_apm_json_obtained(content):
	# If content is Dictionary, that means we obtained the JSON of a search request.
	# The request stores the search results in content["rows"], therefore it's a search.
	if content is Dictionary:
		for metadata in content["rows"]:
			var element = row.instance()
			var title: String

			if is_album(metadata):
				title = metadata["title"]

				row.get_node("Play").disabled = true
				row.get_node("Pause").disabled = true
			elif is_track(metadata):
				title = metadata["trackTitle"]

			element.set("metadata", metadata)
			element.set_title(title)
			element.set_flip_visibility(true)
			
			connect_all_pressed_signals(element, metadata)

			searcher_results.add_child(element) # Append to search results.
	
	# If content is Array, that means we obtained the JSON of an album GET request.
	# The GET request is sent when we're looking to get the tracks of an album.
	if content is Array:
		for metadata in content:
			var element = row.instance()
			var title = metadata["trackTitle"]

			element.set("metadata", metadata)
			element.set_title(title)
			element.set_flip_visibility(false)
	
			connect_all_pressed_signals(element, metadata)

			inspector_results.add_child(element) # Append to album inspector.
