extends RigidBody2D

# Variables for the mob
var health = 100
var max_health = 100
var speed = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_chasing = false
var player = null
var patrol_distance = 100
var start_position = Vector2.ZERO
var velocity = Vector2.ZERO
var on_ground = false
var facing_right = true
var health_bar = null
var attack_range_collision_shape = null
var is_attacking = false
const ATTACK_DAMAGE = 20

# Define the animation states
enum State {
	IDLE,
	WALK,
	ATTACK,
	HURT,
	DIE
}

var state = State.WALK
var attack_cooldown = 1.0
var time_since_last_attack = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_parent().get_node("Player")
	attack_range_collision_shape = $attackDetector  # Your collision shape node
	start_position = global_position
	health_bar = $HealthBar
	health_bar.max_value = max_health
	health_bar.value = health



	$AnimationPlayer.play("walk")

func _integrate_forces(physics_state):
	if state != State.DIE:
		if not on_ground:
			velocity.y += gravity * get_physics_process_delta_time()
		else:
			velocity.y = 0
		
		physics_state.set_linear_velocity(velocity)
		physics_state.set_angular_velocity(0)
		set_rotation_degrees(0)
	else:
		# Stop all forces and ensure no rotation during death
		physics_state.set_linear_velocity(Vector2.ZERO)
		physics_state.set_angular_velocity(0)
		set_rotation_degrees(0)

func _process(delta):
	# Ensure attack cooldown accumulates over time
	time_since_last_attack += delta

	if $AnimationPlayer.current_animation == "attack1":
		return

	on_ground = is_on_floor()

	match state:
		State.WALK:
			if is_chasing:
				move_towards_player(delta)
			else:
				patrol(delta)
		State.ATTACK:
			attack_player(delta)  # Try attacking in ATTACK state
		State.HURT:
			hurt_animation()
		State.DIE:
			die_animation()

func move_towards_player(_delta):
	if player and state != State.DIE:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		
		if direction.x < 0 and facing_right:
			flip_mob_left()
		elif direction.x > 0 and not facing_right:
			flip_mob_right()

		# No need to manually check the attack range, the AttackDetector will handle it
		if state != State.ATTACK:
			velocity.x = direction.x * speed

func patrol(_delta):
	if state != State.DIE:
		var left_bound = start_position.x - patrol_distance
		var right_bound = start_position.x + patrol_distance

		if global_position.x <= left_bound and not facing_right:
			flip_mob_right()
		elif global_position.x >= right_bound and facing_right:
			flip_mob_left()

		velocity.x = speed if facing_right else -speed

func attack_player(_delta):
	if time_since_last_attack >= attack_cooldown and state == State.ATTACK:
		if not is_attacking:
			start_attack()

func start_attack():
	if not is_attacking:
		is_attacking = true
		$AnimationPlayer.play("attack1")
		$HammerHit.set_deferred("monitoring", true)  # Enable hitbox for attack

		$AnimationPlayer.disconnect("animation_finished", Callable(self, "_on_attack_finished"))
		$AnimationPlayer.connect("animation_finished", Callable(self, "_on_attack_finished"))
		
		# Reset the attack cooldown timer
		time_since_last_attack = 0.0

func _on_attack_finished(anim_name):
	if anim_name == "attack1":
		is_attacking = false
		$HammerHit.set_deferred("monitoring", false)
		if state != State.DIE:
			state = State.WALK  # Go back to walk or chasing after attacking

func hurt_animation():
	if state != State.DIE:
		$AnimationPlayer.play("hurt")
		state = State.WALK

func die_animation():
	if state == State.DIE:
		velocity = Vector2.ZERO  # Stop all movement
		$AnimationPlayer.play("die")
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _on_VisibleOnScreenNotifier2D_screen_exited():
	queue_free()

func take_damage(damage):
	health -= damage
	update_health_bar()
	if health <= 0:
		state = State.DIE
		die_animation()
	else:
		state = State.HURT
		hurt_animation()

func update_health_bar():
	health_bar.value = health

func _on_player_detection_body_entered(body):
	if body.is_in_group("player") and state != State.DIE:
		print("Player detected")
		is_chasing = true
		state = State.WALK

func _on_player_detection_body_exited(body):
	if body.is_in_group("player") and state != State.DIE:
		print("Player exited detection area")
		is_chasing = false
		state = State.WALK

func flip_mob_left():
	if state != State.DIE:
		facing_right = false
		$AnimatedSprite2D.scale.x = -1

func flip_mob_right():
	if state != State.DIE:
		facing_right = true
		$AnimatedSprite2D.scale.x = 1

func is_on_floor() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = global_position + Vector2(0, 10)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result != null

func _on_hammer_hit_body_entered(body):
	if body.is_in_group("player") and is_attacking and state != State.DIE:
		print("Player hit")
		body.take_damage(ATTACK_DAMAGE)

func _on_attack_detector_body_entered(body):
	if body.is_in_group("player") and state != State.DIE:
		print("Player within attack range")
		state = State.ATTACK
		attack_player(0)  # Start attacking immediately when in range

func _on_attack_detector_body_exited(body):
	if body.is_in_group("player") and state != State.DIE:
		print("Player exited attack range")
		state = State.WALK  # Go back to walking or chasing when the player leaves attack range
