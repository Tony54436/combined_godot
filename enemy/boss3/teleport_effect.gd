extends Node2D

signal teleport_finished
signal show_boss
signal hide_boss

func _ready():
	$AnimationPlayer.play("teleport_effect")
	$AnimationPlayer.connect("animation_finished", Callable(self, "_on_animation_finished"))
	$AnimationPlayer.connect("animation_step", Callable(self, "_on_animation_step"))

func _on_animation_step():
	var frame = $AnimationPlayer.current_animation_position
	
	if frame >= 2 and frame < 3:
		emit_signal("hide_boss")
	elif frame >= 3:
		emit_signal("show_boss")

func _on_animation_finished(animation_name):
	if animation_name == "teleport_effect":
		emit_signal("teleport_finished")
		queue_free()  # Remove the teleport effect after it's done
