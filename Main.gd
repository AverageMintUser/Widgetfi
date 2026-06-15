extends Node2D

onready var crt = $ViewportContainer/Viewport/CRT
onready var music = $ViewportContainer/Viewport/Music/PanelContainer

func _ready():
	music.connect("playback_changed", crt, "set_playing")
