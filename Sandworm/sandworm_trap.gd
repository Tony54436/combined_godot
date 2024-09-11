extends CharacterBody2D

@onready var player = get_parent().find_child("player")
@onready var sprite = $Sprite2D
@onready var FiniteStateMachine = $".."
var direction : Vector2

func _ready():
	set_physics_process(false)

func _process(delta):
	direction = player.position - position

func _physics_process(delta):
	pass
