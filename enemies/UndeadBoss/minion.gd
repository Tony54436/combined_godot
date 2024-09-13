extends CharacterBody2D
 
@onready var player = get_parent().find_child("player")

@onready var animation = $AnimatedSprite2D

var damage = 1
 
func _ready():
	set_physics_process(false)
	await animation.animation_finished
	set_physics_process(true)
	animation.play("idle")
 
func _physics_process(_delta):
	var direction = player.position - position
	velocity = direction.normalized() * 60
	move_and_slide()
	
	if position.distance_to(player.position) < 20:  # Replace 20 with the appropriate collision threshold
		player.take_damage(damage)
		queue_free()

func take_damage(damage):
	queue_free()
