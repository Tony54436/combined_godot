extends State

func enter():
	super.enter()
	owner.set_physics_process(true)
	animation_player.play("Boss_Idle")

func exit():
	super.exit()
	owner.set_physics_process(false)

func transition():
	var distance = owner.direction.length()
	if distance < 30:
		get_parent().change_state("Boss_MeleeAttack")
	elif distance > 130:
		var chance = randi() % 2
		match chance:
			0:
				get_parent().change_state("Boss_HomingMissile")
			1:
				get_parent().change_state("Boss_LaserBeam")
