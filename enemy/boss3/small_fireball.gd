extends Area2D

# Speed of the fireball
@export var speed = 250
# Direction in which the fireball is moving
var velocity = Vector2.ZERO

func _ready():
	# Set a timer to destroy the fireball after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_timeout"))
	add_child(timer)
	timer.start()

func _process(delta):
	# Move the fireball
	position += velocity * delta

func _on_timeout():
	# Destroy the fireball after the timer ends
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		# Handle logic when fireball hits the player
		body.take_damage(10)  # Adjust damage value
		queue_free()  # Destroy the fireball upon collision

func set_direction(direction):
	velocity = direction.normalized() * speed
