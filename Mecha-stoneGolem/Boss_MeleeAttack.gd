extends State

func enter():
	super.enter()
	animation_player.play("Boss_Melee_Attack")
 
func transition():
	if owner.direction.length() > 30:
		get_parent().change_state("Boss_Follow")
