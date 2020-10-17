extends "res://src/scripts/CharacterData.gd"
class_name PlayerData

#TODO
#Attach move list
#Does the move dict need anything other than hit data? 
#HACK directly loaded in moves, cleaner way to do this?
var MOVE_DICTIONARY = {
	"Jab": preload("res://src/attacks/player/jab.gd").new(),
	"Hook": preload("res://src/attacks/player/hook.gd").new(),
	"Overhead" : preload("res://src/attacks/player/overhead.gd").new(),
	"Shoryuken" : preload("res://src/attacks/player/shoryuken.gd").new(),
	"Corkscrew" : preload("res://src/attacks/player/corkscrew.gd").new(),
	"Combo (Light)" : preload("res://src/attacks/player/combolight.gd").new(),
	"Combo (Heavy)": preload("res://src/attacks/player/comboheavy.gd").new(),
}

#TODO improve this
var movelist = [[MOVE_DICTIONARY["Jab"], MOVE_DICTIONARY["Hook"]], 
				[MOVE_DICTIONARY["Corkscrew"], MOVE_DICTIONARY["Overhead"]], 
				[MOVE_DICTIONARY["Combo (Light)"], MOVE_DICTIONARY["Combo (Heavy)"]], 
			]

var regen_rate = 15

var cur_move_num = 0

func _ready():
	cur_attack = movelist[cur_move_num]
	max_HP = 100
	HP = max_HP

func _physics_process(delta):
	HP = 100 if HP + regen_rate * delta > 100 else HP + regen_rate * delta

func is_move(move_name):
	if move_name in MOVE_DICTIONARY:
		return true
	else:
		print("ERROR: ", move_name , " IS NOT AN EXISTING MOVE")
		return false

func process_attack():
	HP -= MOVE_DICTIONARY[cur_attack.movename].cost


#TODO double using variables to track, kinda gross
#How do you want to handle attakc combinations
func get_move_data():
	return MOVE_DICTIONARY[cur_attack.movename]

func select_next_move():
	cur_move_num = cur_move_num + 1 if cur_move_num + 1 < movelist.size() else movelist.size()-1
	# cur_attack = movelist[cur_move_num]

func select_prev_move():
	cur_move_num = cur_move_num -1 if cur_move_num > 0 else 0
	# cur_attack = movelist[cur_move_num]

func select_attack(special = false):
	cur_attack = movelist[cur_move_num][0] if not special else movelist[cur_move_num][1]


	
