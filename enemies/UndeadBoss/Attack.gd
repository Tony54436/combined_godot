extends State




var player_in_range = false


 
func enter():
	super.enter()
	combo()
 
func attack(move):
	
	
	animation_player.play("attack_" + move)
	await animation_player.animation_finished
	
	if player_in_range:
		player.take_damage(2)

 
 
func combo():
	var move_set = ["1","1","2"]
	for i in move_set:
		await attack(i)
 
	combo()
 
func transition():
	if owner.direction.length() > 40:
		get_parent().change_state("Follow")

func _on_hitbox_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		

func _on_hitbox_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
