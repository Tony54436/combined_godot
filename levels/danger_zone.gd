extends Area2D

@export var damage = 2


func _on_body_entered(body):
	if body.name == "Player":
		body.take_damage(damage)
