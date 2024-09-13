extends CharacterBody2D
 
@onready var player = get_parent().find_child("player")
@onready var animated_sprite = $AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var hitbox = $Hitbox
 
var direction : Vector2
 
var health: = 100:
	set(value):
		health = value
		progress_bar.value = value
		if value <= 0:
			progress_bar.visible = false
			find_child("FiniteStateMachine").change_state("Death")
 
func _ready():
	set_physics_process(false)
 
 
func _process(_delta):
	direction = player.position - position
 
	if direction.x < 0:
		animated_sprite.flip_h = true
		hitbox.scale.x =-1
	else:
		animated_sprite.flip_h = false
		hitbox.scale.x =1
	
	

 
func _physics_process(delta):
	velocity = direction.normalized() * 40
	move_and_collide(velocity * delta)
 
func take_damage(damage):
	health -= damage
