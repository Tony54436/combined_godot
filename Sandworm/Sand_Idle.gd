extends Sand_State

@onready var collision = $"../../PlayerDetection/CollisionShape2D"

# Called when the node enters the scene tree for the first time.

var player_entered: bool = false:
	set(value):
		player_entered = value
		collision.set_deferred("disabled", value)
 
func transition():
	print("Player entered Sand Trap: ", player_entered)
	if player_entered:
		get_parent().change_state("Sand_Attack")

func _on_player_detection_body_entered(body):
	if body.is_in_group("Player"):
		player_entered = true
		print("Player detected: ", body.name)
