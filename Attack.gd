extends SandwormState

@onready var sandworm = preload('res://sandworm_trap.tscn')

func enter():
	super.enter()
	owner.set_physics_process(true)
	animation_player.play("Attack")
 
func exit():
	super.exit()
	owner.set_physics_process(false)

func transition():
	var distance = player.distance_tosandworm.position)
	print('distance ', distance)
	if distance < 1:
		get_parent().change_state("Attack")
