extends Area2D

# Reference to the TileMap node
@export var tilemap: TileMap
# Position of the tile in the TileMap grid
@export var tile_position: Vector2

func _on_player_detection_body_entered(body) -> void:
	if body is get_parent().:  # Replace with your player character's type
		# Remove the tile at the trap location
		tilemap.set_cellv(tile_position, -1)
		# Optionally make the player fall
		body.fall()  # This assumes you have a fall method on your player

func _on_body_entered(body):
	pass # Replace with function body.
