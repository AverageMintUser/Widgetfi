extends PanelContainer
signal playback_changed(is_playing)
# --- CONFIGURATION ---
const LASTFM_USERNAME = "CrestOfTheMoon"
const LASTFM_API_KEY = "2a5549b476db8e3c8c1c26c25ae32af9"

# --- ONREADY VARIABLES ---
onready var album_art = get_node("/root/Main/CanvasLayer/AlbumArt")
onready var track_label = get_node("/root/Main/CanvasLayer/TrackLabel")
onready var artist_label = get_node("/root/Main/CanvasLayer/ArtistLabel")
onready var poll_request = HTTPRequest.new()

var _hue_shift = 0.0
var _showing_placeholder = false
var _last_img_url = ""
var _placeholder_texture : Texture

func _ready():
	if album_art:
		_placeholder_texture = album_art.texture
	else:
		print("album_art node not found at: ", album_art)
	add_child(poll_request)
	poll_request.connect("request_completed", self, "_on_data_received")

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5.0
	timer.connect("timeout", self, "_check_status")
	timer.start()

	set_process(true)
	_clear_art()
	_check_status()

func _process(delta):
	if _showing_placeholder:
		_hue_shift += delta * 0.3
		if _hue_shift > 1.0:
			_hue_shift -= 1.0
		album_art.material.set_shader_param("hue_shift", _hue_shift)

func _check_status():
	var url = "https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=" \
		+ LASTFM_USERNAME \
		+ "&api_key=" + LASTFM_API_KEY \
		+ "&format=json&limit=1"
	var empty_headers = PoolStringArray([])
	poll_request.request(url, empty_headers, false, HTTPClient.METHOD_GET, "")

func _on_data_received(_result, response_code, _headers, body):
	if response_code != 200:
		track_label.text = "Offline"
		artist_label.text = "HTTP Code: " + str(response_code)
		_clear_art()
		return

	var json_result = JSON.parse(body.get_string_from_utf8())
	if json_result.error != OK:
		track_label.text = "Parse error"
		artist_label.text = ""
		_clear_art()
		return

	var payload = json_result.result
	if not (payload and payload.has("recenttracks") and payload["recenttracks"].has("track")):
		_set_idle()
		return

	var tracks = payload["recenttracks"]["track"]
	var current_track = null

	if typeof(tracks) == TYPE_ARRAY and tracks.size() > 0:
		current_track = tracks[0]
	elif typeof(tracks) == TYPE_DICTIONARY:
		current_track = tracks

	if current_track == null:
		_set_idle()
		return

	var is_playing = current_track.has("@attr") \
		and current_track["@attr"].has("nowplaying") \
		and current_track["@attr"]["nowplaying"] == "true"

	if is_playing:
		_set_track_label(str(current_track["name"]))
		_set_artist_label(str(current_track["artist"]["#text"]))
		emit_signal("playback_changed", true) 		
		var found_url = ""
		if current_track.has("image") and typeof(current_track["image"]) == TYPE_ARRAY:
			var img_obj = current_track["image"][2]
			if img_obj.has("#text"):
				var candidate = str(img_obj["#text"])
				if candidate != "" and candidate.find("2a96cbd8b46e442fc41c2b86b821562f") == -1:
					found_url = candidate

		if found_url != "":
			if found_url != _last_img_url:
				_download_image(found_url)
		else:
			# No valid track image — go straight to placeholder
			_clear_art()
	else:
		_set_idle()

func _set_idle():
	_set_track_label("No track playing")
	_set_artist_label("<Last.fm idle>")
	_clear_art()
	emit_signal("playback_changed", false)
func _clear_art():
	_showing_placeholder = true
	_last_img_url = ""
	album_art.texture = _placeholder_texture
	album_art.material.set_shader_param("cycling", true)
func _download_image(img_url):
	var img_req = HTTPRequest.new()
	add_child(img_req)
	img_req.connect("request_completed", self, "_on_image_downloaded", [img_req, img_url])
	var empty_headers = PoolStringArray([])
	img_req.request(img_url, empty_headers, false, HTTPClient.METHOD_GET, "")

func _on_image_downloaded(_result, _code, _headers, body, node_to_free, img_url):
	node_to_free.queue_free()
	if body.size() == 0:
		_clear_art()
		return
	var image = Image.new()
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_png_from_buffer(body)
	if error == OK:
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		album_art.texture = texture
		_last_img_url = img_url
		_showing_placeholder = false
		_hue_shift = 0.0
		album_art.material.set_shader_param("hue_shift", 0.0)
		album_art.material.set_shader_param("cycling", false)
		album_art.material.set_shader_param("hue_shift", 0.0)
		_hue_shift = 0.0
	else:
		_clear_art()
func _set_track_label(text: String):
	var max_width = track_label.rect_size.x
	var min_size = 11
	var size = 16

	var template_font = track_label.get_font("font") # Get your original font settings

	var dyn_font = DynamicFont.new()
	dyn_font.font_data = template_font.font_data
	
	# --- COPY OUTLINE SETTINGS HERE ---
	dyn_font.outline_size = template_font.outline_size
	dyn_font.outline_color = template_font.outline_color
	# ----------------------------------

	dyn_font.size = size


	while size >= min_size:
		dyn_font.size = size
		# Count wrapped lines at this font size
		var line_count = 0
		var words = text.split(" ")
		var current_line = ""
		for word in words:
			var test = current_line + (" " if current_line != "" else "") + word
			if dyn_font.get_string_size(test).x > max_width:
				line_count += 1
				current_line = word
			else:
				current_line = test
		if current_line != "":
			line_count += 1

		if line_count <= 3:
			break
		size -= 1

	# Still doesn't fit in 3 lines at min size — truncate
	if size < min_size:
		size = min_size
		dyn_font.size = size
		var truncated = text
		while truncated.length() > 0:
			var wrapped = ""
			var line_count = 0
			var words = truncated.split(" ")
			var current_line = ""
			for word in words:
				var test = current_line + (" " if current_line != "" else "") + word
				if dyn_font.get_string_size(test).x > max_width:
					line_count += 1
					current_line = word
				else:
					current_line = test
			if current_line != "":
				line_count += 1
			if line_count <= 3:
				break
			# Trim last word and add ellipsis
			truncated = truncated.rsplit(" ", true, 1)[0]
		text = truncated + "..."

	track_label.text = text
	track_label.add_font_override("font", dyn_font)

func _set_artist_label(text: String):
	artist_label.text = text
	var font = artist_label.get_font("font")
	var max_width = artist_label.rect_size.x
	var size = 14
	var min_size = 9

	var fits = false
	while size >= min_size:
		if font.get_string_size(text).x * (size / float(font.size)) <= max_width:
			fits = true
			break
		size -= 1

	if not fits:
		var truncated = text
		while font.get_string_size(truncated + "...").x * (min_size / float(font.size)) > max_width and truncated.length() > 0:
			truncated = truncated.substr(0, truncated.length() - 1)
		artist_label.text = truncated + "..."

	var dyn_font = DynamicFont.new()
	dyn_font.font_data = font.get_data() if font.has_method("get_data") else font.font_data
	dyn_font.size = size
	artist_label.add_font_override("font", dyn_font)
