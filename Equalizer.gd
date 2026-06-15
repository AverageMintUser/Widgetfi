extends Node2D

const BAR_COUNT = 8
const BAR_COLOR = Color(0.4, 0.8, 1.0)
const GAP = 1

# The 4 corners of the screen hole in local sprite coordinates
const TOP_LEFT = Vector2(8, 20)
const TOP_RIGHT = Vector2(69, 22)
const BOTTOM_LEFT = Vector2(8, 79)
const BOTTOM_RIGHT = Vector2(69, 101)

var _time = 0.0
var _bar_phases = []
var _bar_speeds = []
var _bar_wave2_phases = []
var _bar_wave2_speeds = []
var _is_playing = false
var _heights = []

func _ready():
	randomize()
	for i in range(BAR_COUNT):
		_bar_phases.append(rand_range(0.0, TAU))
		_bar_speeds.append(rand_range(1.8, 3.5))
		_bar_wave2_phases.append(rand_range(0.0, TAU))
		_bar_wave2_speeds.append(rand_range(0.8, 1.6))
		_heights.append(0.0)
	set_process(true)

func set_playing(playing: bool):
	_is_playing = playing

func _process(delta):
	if _is_playing:
		_time += delta
	update()

func _draw():
	for i in range(BAR_COUNT):
		# t goes 0.0 to 1.0 across the width, offset by half a bar so bars are centered
		var t_left = (float(i) + 0.1) / float(BAR_COUNT)
		var t_right = (float(i) + 0.9) / float(BAR_COUNT)

		# Interpolate along the top and bottom edges to get perspective-correct positions
		var top_left_pos = TOP_LEFT.linear_interpolate(TOP_RIGHT, t_left)
		var top_right_pos = TOP_LEFT.linear_interpolate(TOP_RIGHT, t_right)
		var bottom_left_pos = BOTTOM_LEFT.linear_interpolate(BOTTOM_RIGHT, t_left)
		var bottom_right_pos = BOTTOM_LEFT.linear_interpolate(BOTTOM_RIGHT, t_right)

		# Bar height as a 0.0-1.0 fraction of the screen height
		var height_frac = 0.05  # min height
		if _is_playing:
			var wave1 = (sin(_time * _bar_speeds[i] + _bar_phases[i]) + 1.0) / 2.0
			var wave2 = (sin(_time * _bar_wave2_speeds[i] + _bar_wave2_phases[i]) + 1.0) / 2.0
			height_frac = 0.05 + (wave1 * 0.7 + wave2 * 0.3) * 0.95

		# Interpolate bottom up toward top by height_frac
		var bar_top_left = bottom_left_pos.linear_interpolate(top_left_pos, height_frac)
		var bar_top_right = bottom_right_pos.linear_interpolate(top_right_pos, height_frac)

		# Draw the bar as a quadrilateral using two triangles
		var points = PoolVector2Array([
			bar_top_left,
			bar_top_right,
			bottom_right_pos,
			bottom_left_pos
		])
		var colors = PoolColorArray([BAR_COLOR, BAR_COLOR, BAR_COLOR, BAR_COLOR])
		draw_primitive(points, colors, PoolVector2Array())
