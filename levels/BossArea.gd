extends Area2D

@export var boss_node: PackedScene
@export var boss_spawn_node: NodePath

func _ready():
	# Connect the signal to detect when the player enters the area
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	# Check if the entering body is the player
	if body.is_in_group("player"):
		# Check if boss_node and boss_spawn_node are set
		if boss_node and boss_spawn_node:
			var boss = boss_node.instantiate()
			var boss_spawn = get_node(boss_spawn_node) as Node2D
			if boss_spawn:
				# Set the boss position to the spawn point position
				boss.position = boss_spawn.position
				# Add the boss instance to the current scene
				get_tree().current_scene.add_child(boss)
				# Optionally, remove or hide the trigger area if you don't need it anymore
				queue_free()
			else:
				print("Error: Boss spawn node not found or is not a Node2D.")
		else:
			print("Error: Boss node or boss spawn node path is not set.")
