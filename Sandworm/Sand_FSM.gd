extends Node2D

var current_state: Sand_State
var previous_state: Sand_State

func _ready():
	current_state = get_child(0) as Sand_State
	previous_state = current_state
	current_state.enter()

func change_state(state):
	current_state = find_child(state) as Sand_State
	current_state.enter()
	
	previous_state.exit()
	previous_state = current_state

func set_initial_state(state):
	current_state = state
	current_state.enter()
