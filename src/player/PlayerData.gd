extends "res://src/scripts/CharacterData.gd"
class_name PlayerData

#TODO How to handle modifications of abilities, if occurring>
#Does the move dict need anything other than hit data? 
#HACK directly loaded in moves, cleaner way to do this?
#Dictionary containing all actor attack_data scripts.
var MOVE_DICTIONARY = {
	"Jab": preload("res://src/attacks/player/jab.gd").new(),
	"Hook": preload("res://src/attacks/player/hook.gd").new(),
	"Overhead" : preload("res://src/attacks/player/overhead.gd").new(),
	"Shoryuken" : preload("res://src/attacks/player/shoryuken.gd").new(),
	"Corkscrew" : preload("res://src/attacks/player/corkscrew.gd").new(),
	"Combo (Light)" : preload("res://src/attacks/player/combolight.gd").new(),
	"Combo (Heavy)": preload("res://src/attacks/player/comboheavy.gd").new(),
}

#TODO evaluate this
#List of the different moves the player has equipped.
#Array of X by 2-elem array (first elem for L, 2nd R click)
var normal_movelist = [	MOVE_DICTIONARY["Jab"], 
						MOVE_DICTIONARY["Hook"],
						MOVE_DICTIONARY["Combo (Light)"], 
					]

var special_movelist = [MOVE_DICTIONARY["Corkscrew"],
						MOVE_DICTIONARY["Overhead"],
						MOVE_DICTIONARY["Combo (Heavy)"],
					]

#The current position within the movelist.
var cur_move_num = 0
var max_move_num = 3

#How fast the player's HP returns.
var regen_rate = 5


func _ready():
	cur_attack = normal_movelist[cur_move_num]
	max_HP = 100
	HP = max_HP

#Slowly regen player health over time	
func _physics_process(delta):
	HP = 100 if HP + regen_rate * delta > 100 else HP + regen_rate * delta

#Check for the existence of a move against the player's MOVE_DICTIONARY
#Should not ever fail.
func is_move(move_name):
	if move_name in MOVE_DICTIONARY:
		return true
	else:
		print("ERROR: ", move_name , " IS NOT AN EXISTING MOVE")
		return false


#Overloaded fxn of character_data
#Handles any player-sided effects resulting from a player attack action. 
#Currently only subtracts the HP cost from the player
func process_attack():
	if cur_attack.cost == 0 or HP - cur_attack.cost > 0:
		HP -= cur_attack.cost
		return true
	else:
		return false


#region GETTERS

#Returns the attack_data script for the player's currently active move
func get_move_data():
	return cur_attack

func get_movelist_names():
	var temp_normal_list = []
	var temp_special_list = []

	for move in normal_movelist:
		temp_normal_list.append(move.movename)
	for move in special_movelist:
		temp_special_list.append(move.movename)

	return [temp_normal_list, temp_special_list]

#endregion

#region SETTERS

func set_movelist(movenames):
	normal_movelist = []
	for movename in movenames[0]:
		normal_movelist.append(MOVE_DICTIONARY[movename])

	special_movelist = []
	for movename in movenames[1]:
		special_movelist.append(MOVE_DICTIONARY[movename])



#Increases the selected location on the movelist forward if possible. Otherwise stays at movelist index max.
#Called when player scrolls down
func select_next_move():
	cur_move_num = cur_move_num + 1 if cur_move_num < max_move_num -1 else max_move_num-1
	# cur_attack = movelist[cur_move_num]

#Decreases the selected location on the movelist forward if possible. Otherwise stays at movelist index 0.
#Called when player scrolls up	
func select_prev_move():
	cur_move_num = cur_move_num -1 if cur_move_num > 0 else 0
	# cur_attack = movelist[cur_move_num]

#Determines if the player's current attack is a special (right click) or normal (left click) attack.
#Called when player clicks either mouse button
func select_attack(special = false):
	cur_attack = normal_movelist[cur_move_num] if not special else special_movelist[cur_move_num]



#endregion
