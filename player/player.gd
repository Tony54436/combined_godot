extends CharacterBody2D

# Constants for movement and gameplay
const ACCELERATION = 800
const FRICTION = 500
const MAX_SPEED = 120
const JUMP_VELOCITY = -500
const ROLL_VELOCITY = 100
const ATTACK_DAMAGE = 20
const HURT_ANIMATION = "hurt"
const HURT_TIME = 0.5
const INVINCIBILITY_TIME = 0.5  # Duration of invincibility during roll

# Define states
enum {IDLE, RUN, JUMP, BLOCK, ROLL, HURT}
var state = IDLE
var player_alive = true

# On ready variables
@onready var animation = $AnimationPlayer
@onready var sword_hit_area = $SwordHit  # Reference to the SwordHit area
@onready var collision_shape = $CollisionShape2D  # Reference to the main collision shape

# Player attributes
var health = 100
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var isAttacking = false
var facing_right = true  # Variable to track the facing direction
var is_rolling = false  # To track if the character is rolling
var invincible = false  # To track if the character is invincible


func _ready():
	# Disable the SwordHit area initially
	sword_hit_area.set_deferred("monitoring", false)
	# Connect the body_entered signal to detect when enemies are hit
	sword_hit_area.connect("body_entered", Callable(self, "_on_sword_hit_body_entered"))

	# Start in idle animation
	animation.play("idle")

func _physics_process(delta):
	move(delta)
	update_health()
	
	if health <= 0:
		player_alive = false
		health = 0
		print("Player has been killed")
		self.queue_free()
		
	if not is_on_floor() and state != ROLL:
		velocity.y += gravity * delta
		if state != JUMP:
			state = JUMP
			animation.play("jump")
	elif state == JUMP and is_on_floor():
		state = IDLE
		animation.play("idle")

func move(delta):
	var input_vector = Input.get_vector("move_left", "move_right", "ui_up", "ui_down")
		
	if input_vector == Vector2.ZERO and state != ROLL and state != BLOCK and state != HURT:
		if state != IDLE:
			state = IDLE
			animation.play("idle")
		apply_friction(FRICTION * delta)
	elif is_on_floor() and state != ROLL and state != BLOCK and state != HURT:
		if state != RUN:
			state = RUN
			animation.play("run")
		apply_movement(input_vector * ACCELERATION * delta)
	
	if input_vector.x > 0 and not facing_right:
		facing_right = true
		flip_character()
	elif input_vector.x < 0 and facing_right:
		facing_right = false
		flip_character()
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and state != ROLL:
		velocity.y = JUMP_VELOCITY
		state = JUMP
		animation.play("jump")
	
	if Input.is_action_just_pressed("block") and is_on_floor() and state != ROLL:
		start_block()

	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling:
		start_roll()

	if Input.is_action_just_pressed("attack1") and is_on_floor() and state != BLOCK and state != ROLL and state != HURT:
		start_attack()
		
	move_and_slide()

func apply_friction(amount) -> void:
	if velocity.length() > amount:
		velocity -= velocity.normalized() * amount
	else:
		velocity = Vector2.ZERO

func apply_movement(amount) -> void:
	velocity += amount
	velocity = velocity.limit_length(MAX_SPEED)

func update_health():
	var healthbar = $healthBar
	healthbar.value = health

func flip_character():
	scale.x *= -1  # Flips the character horizontally

func start_block():
	state = BLOCK
	animation.play("block")
	animation.disconnect("animation_finished", Callable(self, "_on_block_finished"))
	animation.connect("animation_finished", Callable(self, "_on_block_finished"))

func _on_block_finished(anim_name):
	if anim_name == "block":
		state = IDLE  # Return to idle state after blocking
		animation.play("idle")
		animation.disconnect("animation_finished", Callable(self, "_on_block_finished"))

func start_roll():
	is_rolling = true
	invincible = true  # Set player to be invincible during the roll
	state = ROLL
	velocity.x = ROLL_VELOCITY if facing_right else -ROLL_VELOCITY  # Roll in the facing direction
	animation.play("roll")
	collision_shape.disabled = true  # Disable the collision shape to allow passing through enemies

	# Re-enable the collision shape after the roll ends
	animation.disconnect("animation_finished", Callable(self, "_on_roll_finished"))
	animation.connect("animation_finished", Callable(self, "_on_roll_finished"))

func _on_roll_finished(anim_name):
	if anim_name == "roll":
		is_rolling = false
		invincible = false  # Remove invincibility after the roll
		state = IDLE
		animation.play("idle")
		collision_shape.disabled = false  # Re-enable the collision shape
		animation.disconnect("animation_finished", Callable(self, "_on_roll_finished"))

func start_attack():
	isAttacking = true
	state = IDLE  # Prevent movement during attack
	animation.play("attack1")
	sword_hit_area.set_deferred("monitoring", true)  # Enable the SwordHit area for the attack

	# Ensure that the SwordHit area is disabled after the attack animation
	animation.disconnect("animation_finished", Callable(self, "_on_attack_finished"))
	animation.connect("animation_finished", Callable(self, "_on_attack_finished"))

func _on_attack_finished(anim_name):
	if anim_name == "attack1":
		isAttacking = false
		sword_hit_area.set_deferred("monitoring", false)  # Disable the SwordHit area after the attack
		state = IDLE
		animation.play("idle")
		animation.disconnect("animation_finished", Callable(self, "_on_attack_finished"))

func _on_sword_hit_body_entered(body):
	# Apply damage to the enemy when it enters the SwordHit area
	if body.is_in_group("enemies"):  # Assuming enemies are in a group named "enemies"
		body.take_damage(ATTACK_DAMAGE)  # Call a take_damage method on the enemy

# Method to handle taking damage and playing the hurt animation
func take_damage(amount):
	if state == HURT or invincible:
		return  # Prevent taking damage while already hurt or invincible
	health -= amount
	if health <= 0:
		health = 0
		die()  # Handle player death
	else:
		state = HURT
		animation.play(HURT_ANIMATION)
		await get_tree().create_timer(HURT_TIME).timeout  # Wait for the hurt state to end
		state = IDLE
		animation.play("idle")

# Method to handle player death
func die():
	player_alive = false
	print("Player has died")
	self.queue_free()

# Optional function for interacting with hurt areas
func _on_sword_hit_area_entered(area):
	if area.is_in_group("hurtbox"):
		area.take_damage()
