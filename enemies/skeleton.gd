extends RigidBody2D

# Constants
const ATTACK_DAMAGE = 20
const ATTACK_DISTANCE = 10
const ATTACK_COOLDOWN = 1.0

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
var is_attacking = false
var time_since_last_attack = 0.0

# Animation states
enum State {
	IDLE,
	WALK,
	ATTACK,
	HURT,
	DIE
}

var state = State.WALK

# Nodes
@onready var sword_hit = $SwordHit
@onready var raycast = $RayCast2D
@onready var animation_player = $AnimationPlayer
@onready var health_bar = $HealthBar
@onready var attack_detector = $attackDetector  # New for attack detection

# Called when the node enters the scene tree for the first time
func _ready():
	player = get_parent().get_node("player")
	start_position = global_position
	health_bar.max_value = max_health
	health_bar.value = health
	animation_player.play("walk")

func _integrate_forces(physics_state):
	if state != State.DIE:
		apply_gravity()
		physics_state.set_linear_velocity(velocity)
		physics_state.set_angular_velocity(0)
		set_rotation_degrees(0)
	else:
		stop_movement(physics_state)

# Apply gravity if the enemy is not on the ground
func apply_gravity():
	if not on_ground:
		velocity.y += gravity * get_physics_process_delta_time()
	else:
		velocity.y = 0

# Stop all movement when the enemy dies
func stop_movement(physics_state):
	physics_state.set_linear_velocity(Vector2.ZERO)
	physics_state.set_angular_velocity(0)
	set_rotation_degrees(0)

func _process(delta):
	if animation_player.current_animation == "attack1":
		return
	
	on_ground = raycast.is_colliding()
	time_since_last_attack += delta
	
	match state:
		State.WALK:
			if is_chasing:
				move_towards_player(delta)
			else:
				patrol(delta)
		State.ATTACK:
			attack_player(delta)
		State.HURT:
			play_hurt_animation()
		State.DIE:
			play_die_animation()

# Move towards the player if chasing
func move_towards_player(delta):
	if player and state != State.DIE:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * speed
		flip_mob(direction.x)
		
		if is_in_attack_range():
			velocity.x = 0
			state = State.ATTACK

# Patrol between left and right bounds
func patrol(delta):
	if state != State.DIE:
		var left_bound = start_position.x - patrol_distance
		var right_bound = start_position.x + patrol_distance

		if facing_right:
			velocity.x = speed
		else:
			velocity.x = -speed

		if global_position.x <= left_bound and not facing_right:
			flip_mob_right()
		elif global_position.x >= right_bound and facing_right:
			flip_mob_left()

# Check if the player is within the attack range
func is_in_attack_range() -> bool:
	return global_position.distance_to(player.global_position) <= ATTACK_DISTANCE

# Attack the player if in range and not on cooldown
func attack_player(delta):
	if time_since_last_attack >= ATTACK_COOLDOWN and state != State.DIE:
		if is_in_attack_range():
			if not is_attacking:
				start_attack()
		else:
			state = State.WALK

# Start the attack
func start_attack():
	is_attacking = true
	animation_player.play("attack1")
	hit()  # Start monitoring collisions
	animation_player.connect("animation_finished", Callable(self, "_on_attack_finished"), CONNECT_ONE_SHOT)

# Callback when the attack animation finishes
func _on_attack_finished(anim_name):
	if anim_name == "attack1":
		is_attacking = false
		end_of_hit()  # Stop monitoring collisions
		if state != State.DIE:
			state = State.WALK

# Enable collision monitoring for the attack
func hit():
	attack_detector.monitoring = true  # Turn on attack detection

# Disable collision monitoring after the attack
func end_of_hit():
	attack_detector.monitoring = false  # Turn off attack detection

# Handle hurt animation and transition back to WALK state
func play_hurt_animation():
	if state != State.DIE:
		animation_player.play("hurt")
		state = State.WALK

# Handle die animation and remove the enemy after it finishes
func play_die_animation():
	if state == State.DIE:
		velocity = Vector2.ZERO
		animation_player.play("die")
		await get_tree().create_timer(3.0).timeout
		queue_free()

# Flip the mob's direction based on movement
func flip_mob(direction_x):
	if direction_x < 0 and facing_right:
		flip_mob_left()
	elif direction_x > 0 and not facing_right:
		flip_mob_right()

# Flip mob left
func flip_mob_left():
	facing_right = false
	$AnimatedSprite2D.scale.x = -1

# Flip mob right
func flip_mob_right():
	facing_right = true
	$AnimatedSprite2D.scale.x = 1

# Handle detection of player entering and exiting the detection area
func _on_detection_area_body_entered(body):
	if body.is_in_group("player") and state != State.DIE:
		is_chasing = true
		state = State.ATTACK

func _on_detection_area_body_exited(body):
	if body.is_in_group("player") and state != State.DIE:
		is_chasing = false
		state = State.WALK

# Handle taking damage and playing hurt or die animations
func take_damage(damage):
	health -= damage
	update_health_bar()
	if health <= 0:
		state = State.DIE
		play_die_animation()
	else:
		state = State.HURT
		play_hurt_animation()

# Update the health bar
func update_health_bar():
	health_bar.value = health

