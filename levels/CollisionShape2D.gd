extends CharacterBody2D
 
@onready var player = get_parent().find_child("Player")
@onready var sprite = $Sprite2D

 
var direction : Vector2

func _ready():
	set_physics_process(false)
 
func _process(_delta):
	direction = player.position - position
 
