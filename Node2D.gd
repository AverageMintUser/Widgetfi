extends Node2D

onready var sprite = $AnimatedSprite
onready var equalizer = $Equalizer

var _was_playing = false

func set_playing(playing: bool):
	if playing and not _was_playing:
		sprite.play("Turn On")
		equalizer.set_playing(true)
	elif not playing and _was_playing:
		sprite.play("Idle")
		equalizer.set_playing(false)
	_was_playing = playing

func _ready():
	sprite.connect("animation_finished", self, "_on_animation_finished")
	sprite.play("Idle")

func _on_animation_finished():
	if sprite.animation == "Turn On":
		sprite.stop()
