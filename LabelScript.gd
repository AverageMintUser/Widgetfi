extends Label

# Hardcoded month array to avoid complex system lookups
const MONTHS = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

# Finds the sibling DateLabel dynamically without changing its positioning properties
onready var date_label = get_node_or_null("../DateLabel") as Label

func _ready() -> void:
	_update_clock()

func _process(_delta: float) -> void:
	_update_clock()

func _update_clock() -> void:
	# Get the system time dict
	var dt = OS.get_datetime()
	
	# Convert 24h to 12h: (dt.hour - 1) % 12 + 1 keeps the hour from 1 to 12
	var hour_12 = ((dt.hour - 1) % 12) + 1
	
	# Process time format from your original code layout
	var raw_hour = "%02d" % hour_12
	var formatted_hour = raw_hour.substr(0, 1) + "" + raw_hour.substr(1, 1)
	var formatted_minute = "%02d" % dt.minute
	
	# Update your main time label text without AM/PM
	text = formatted_hour + ":" + formatted_minute
	
	# Only update the date label if it is found in the scene tree
	if date_label:
		var month_str = MONTHS[dt.month]
		var day_str = "%02d" % dt.day
		var year_str = "%04d" % dt.year
		
		# Update your date label text exactly where you placed it in the editor
		date_label.text = month_str + "" + day_str + " " + year_str
