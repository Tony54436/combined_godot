extends CharacterBody2D

enum State { IDLE, WALK, MELEE_ATTACK, RANGED_ATTACK, TAKE_HIT, DIE, TELEPORT }

var current_state = State.IDLE
var health = 100
var speed = 100
var melee_range = 50
var attack_range = 100
var attack_damage = 20
var attack_cooldown = 1.5  # Time between attacks in seconds
var can_attack = true
var attack_timer = Timer
var range_attack_cooldown = 7.5
var can_ranged_attack = true
var ranged_attack_timer = Timer
var facing_right = true  # Track the direction the boss is facing
var teleporting = false
var target_position = null
var teleport_locations = []  # List of teleport locations
var teleport_cooldown = 15
var teleport_timer: Timer
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
signal teleport_finished
signal show_boss
signal hide_boss

@onready var player = get_node("../Player")

@export var medium_fireball: PackedScene
@export var small_fireball: PackedScene
@export var teleport_effect: PackedScene
@export var teleport_location1: Node2D 
@export var teleport_location2: Node2D 
@export var teleport_location3: Node2D 
@export var teleport_location4: Node2D 
@export var teleport_location5: Node2D 

@onready var hitbox = $Hitbox
@onready var hurtbox = $Hurtbox
@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")  # Reference to the state machine
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_tree.active = true
	animation_player.play("teleport_effect")
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))
	set_state(State.IDLE)
	
	# Initialize teleport locations
	teleport_locations = [
		teleport_location1.position,
		teleport_location2.position,
		teleport_location3.position,
		teleport_location4.position,
		teleport_location5.position
	]
	
	hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
	hurtbox.connect("body_entered", Callable(self, "_on_hurtbox_body_entered"))
	
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	add_child(attack_timer)
	attack_timer.connect("timeout", Callable(self, "_on_attack_cooldown_timeout"))
	
	ranged_attack_timer = Timer.new()
	ranged_attack_timer.wait_time = range_attack_cooldown
	ranged_attack_timer.one_shot = true
	add_child(ranged_attack_timer)
	ranged_attack_timer.connect("timeout", Callable(self, "_on_ranged_attack_cooldown_timeout"))

	
	teleport_timer = Timer.new()
	teleport_timer.wait_time = teleport_cooldown
	teleport_timer.one_shot = true
	add_child(teleport_timer)
	teleport_timer.connect("timeout", Callable(self, "_on_teleport_timer_timeout"))
	teleport_timer.start()  # Start the teleport timer when the game starts



func set_state(new_state):
	if current_state == new_state:
		return
	
	current_state = new_state
	match current_state:
		State.IDLE:
			play_animation("Idle")
		State.WALK:
			play_animation("Walk")
		State.MELEE_ATTACK:
			melee_attack()
		State.RANGED_ATTACK:
			ranged_attack()
		State.TAKE_HIT:
			play_animation("TakeHit")
			take_damage(attack_damage)
		State.DIE:
			play_animation("Die")
			queue_free()  # Destroy the boss when the animation ends
		State.TELEPORT:
			start_teleportation()
	print("State changed to:", current_state)  # Debugging line to track state changes


func _process(delta):
	if current_state in [State.IDLE, State.WALK]:
		decide_action()

func decide_action():
	var distance_to_player = position.distance_to(player.position)
	
	if distance_to_player <= melee_range:
		set_state(State.MELEE_ATTACK)
	elif distance_to_player <= attack_range:
		set_state(State.RANGED_ATTACK)
	else:
		walk_towards_player()

func walk_towards_player():
	# Calculate the direction from the boss to the player
	var direction = (player.position - position).normalized()
	
	# Determine if the boss is facing right based on the direction
	facing_right = direction.x > 0
	
	# Apply horizontal movement based on the direction and speed
	velocity.x = direction.x * speed
	
	# Apply gravity to the vertical velocity
	velocity.y += gravity * get_process_delta_time()  # Update the Y velocity with gravity

	# Debug prints to check direction and velocity
	print("Direction:", direction, "Velocity:", velocity)
	
	# Move the boss using move_and_slide, which handles collisions and gravity
	move_and_slide() 
	
	# Play the walking animation if the state is not changing to attack
	play_animation("Walk")
	
	# Check proximity to the player to decide the next action
	var distance_to_player = position.distance_to(player.position)
	
	# Switch to melee attack if in melee range
	if distance_to_player <= melee_range:
		if current_state != State.MELEE_ATTACK:
			set_state(State.MELEE_ATTACK)
	
	# Switch to ranged attack if in attack range but outside melee range
	elif distance_to_player <= attack_range:
		if current_state != State.RANGED_ATTACK:
			set_state(State.RANGED_ATTACK)



func melee_attack():
	if not can_attack:
		return
		
	if player and position.distance_to(player.position) <= melee_range:
		# Trigger attack animation
		play_animation("MeleeAttack")  # Replace "attack" with your actual attack animation name

		# Apply damage to the player
		#player.take_damage(attack_damage)

		# Set can_attack to false and start the attack cooldown timer
		can_attack = false
		attack_timer.start()
		
		# Optionally, add some knockback effect on the player here
		# var knockback_direction = (player.position - position).normalized()
		# player.apply_knockback(knockback_direction)
		
		set_state(State.IDLE)

func _on_attack_cooldown_timeout():
	can_attack = true

func ranged_attack():
	if not can_ranged_attack:
		return  # Prevent attack if cooldown is active

	# Choose which fireball to summon
	if randi() % 2 == 0:
		summon_medium_fireball()
	else:
		summon_three_small_fireballs()
	
	# Set can_ranged_attack to false and start the cooldown timer
	can_ranged_attack = false
	ranged_attack_timer.start()

	# After attacking, set state back to WALK or IDLE to reset behavior
	set_state(State.IDLE)

# Called when the ranged attack cooldown timer times out
func _on_ranged_attack_cooldown_timeout():
	can_ranged_attack = true  # Allow the boss to perform ranged attacks again

func summon_medium_fireball():
	var fireball = medium_fireball.instantiate()

	# Get the player's position
	var direction_to_player = (player.position - position).normalized()

	# Set the fireball's starting position and direction
	fireball.position = position + Vector2(0, -50)
	fireball.scale = Vector2(0.5, 0.5)
	fireball.set_direction(direction_to_player)
	
	get_parent().add_child(fireball)
	
func summon_three_small_fireballs():
	for i in range(3):
		var fireball = small_fireball.instantiate()
		
		# Get the player's position
		var direction_to_player = (player.position - position).normalized()
		
		# Adjust the direction slightly for each fireball
		var offset_angle = deg_to_rad(-15 + (15 * i))  # -15, 0, 15 degrees
		
		# Set the fireball's starting position and direction
		fireball.position = (position + Vector2(0, -50)).rotated(offset_angle)
		fireball.scale = Vector2(0.5, 0.5)
		fireball.set_direction(direction_to_player)
		
		get_parent().add_child(fireball)

func play_animation(animation_name):
	if animation_state is AnimationNodeStateMachinePlayback:
		print("Playing animation:", animation_name)  # Debugging line to track animation changes
		animation_state.travel(animation_name)  # Trigger the animation transition
	else:
		print("Invalid Animation State Machine setup")  # Error handling if the setup is incorrect


func _on_animation_finished(animation_name):
	if animation_name == "teleport_effect":
		emit_signal("teleport_finished")
		queue_free()  # Remove the teleport effect after it's done

# Called when the teleport timer times out
func _on_teleport_timer_timeout():
	# Check if the player is outside of the attack range before teleporting
	if position.distance_to(player.position) > attack_range:
		set_state(State.TELEPORT)  # Initiate teleportation if the player is outside attack range
	teleport_timer.start()  # Restart the timer for the next teleport attempt

# Initiates the teleportation process
func start_teleportation():
	teleporting = true
	# Select a random target position from available locations
	target_position = teleport_locations[randi() % teleport_locations.size()]
	
	# Create the initial teleport effect at the current position
	var initial_effect = create_teleport_effect(position)
	initial_effect.connect("teleport_finished", Callable(self, "_on_teleport_disappeared"))
	initial_effect.connect("hide_boss", Callable(self, "_on_hide_boss"))
	initial_effect.connect("show_boss", Callable(self, "_on_show_boss"))
	
	# Hide the boss to simulate disappearance
	emit_signal("hide_boss")
	add_child(initial_effect)

# Creates the teleport effect at a given position
func create_teleport_effect(effect_position: Vector2) -> Node2D:
	var effect_instance = teleport_effect.instantiate()
	effect_instance.position = effect_position
	return effect_instance

# Called when the first teleport effect finishes (after the boss disappears)
func _on_teleport_disappeared():
	# Move the boss to the new location
	position = target_position
	
	# Create the second teleport effect at the target position
	var reappear_effect = create_teleport_effect(position)
	reappear_effect.connect("teleport_finished", Callable(self, "_on_teleport_finished"))
	reappear_effect.connect("show_boss", Callable(self, "_on_show_boss"))
	
	add_child(reappear_effect)

# Signal handler to hide the boss during teleportation
func _on_hide_boss():
	if teleporting:
		visible = false

# Signal handler to show the boss when teleportation is complete
func _on_show_boss():
	if teleporting:
		visible = true

# Called after the second teleport effect finishes (after the boss reappears)
func _on_teleport_finished():
	teleporting = false
	set_state(State.IDLE)


func take_damage(amount):
	# Reduce the boss's health
	health -= amount
	if health <= 0:
		set_state(State.DIE)
	else:
		set_state(State.IDLE)

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		set_state(State.WALK)
