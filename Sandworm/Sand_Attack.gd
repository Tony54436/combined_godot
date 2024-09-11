extends Sand_State


func enter():
	super.enter()
	owner.set_physics_process(true)
	animation_player.play("Sand_Attack")

func exit():
	super.exit()
	owner.set_physics_process(false)

func transition():
	var distance = owner.distance_to(player)
	print("Sandworm: ", distance)
	if distance == 0:
		get_parent().change_state("Sand_Attack")
