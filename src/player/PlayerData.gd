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
var movelist = [[MOVE_DICTIONARY["Jab"], MOVE_DICTIONARY["Hook"]], 
				[MOVE_DICTIONARY["Corkscrew"], MOVE_DICTIONARY["Overhead"]], 
				[MOVE_DICTIONARY["Combo (Light)"], MOVE_DICTIONARY["Combo (Heavy)"]], 
			]

#The current position within the movelist.
var cur_move_num = 0


#How fast the player's HP returns.
var regen_rate = 5


func _ready():
	cur_attack = movelist[cur_move_num]
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
	HP -= cur_attack.cost


#region GETTERS

#Returns the attack_data script for the player's currently active move
func get_move_data():
	return cur_attack

#endregion

#region SETTERS

#Increases the selected location on the movelist forward if possible. Otherwise stays at movelist index max.
#Called when player scrolls down
func select_next_move():
	cur_move_num = cur_move_num + 1 if cur_move_num + 1 < movelist.size() else movelist.size()-1
	# cur_attack = movelist[cur_move_num]

#Decreases the selected location on the movelist forward if possible. Otherwise stays at movelist index 0.
#Called when player scrolls up	
func select_prev_move():
	cur_move_num = cur_move_num -1 if cur_move_num > 0 else 0
	# cur_attack = movelist[cur_move_num]


#Determines if the player's current attack is a special (right click) or normal (left click) attack.
#Called when player clicks either mouse button
func select_attack(special = false):
	cur_attack = movelist[cur_move_num][0] if not special else movelist[cur_move_num][1]



#endregion
