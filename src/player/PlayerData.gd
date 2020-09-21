extends "res://src/scripts/CharacterData.gd"
class_name PlayerData



#TODO
#Attach move list
#Does the move dict need anything other than hit data? 
#HACK directly loaded in moves
var MOVE_DICTIONARY = {
	"Jab": preload("res://src/attacks/jab.gd").new(),
	"Hook": preload("res://src/attacks/hook.gd").new(),
	"Overhead" : preload("res://src/attacks/overhead.gd").new(),
	"Shoryuken" : preload("res://src/attacks/shoryuken.gd").new(),
}

func _ready():
	cur_attack = MOVE_DICTIONARY[cur_attack_name]

func is_move(move_name):
	if move_name in MOVE_DICTIONARY:
		return true
	else:
		print("ERROR: ", move_name , " IS NOT AN EXISTING MOVE")
		return false

func get_move_data():
	MOVE_DICTIONARY[cur_attack_name].print_data()
	return MOVE_DICTIONARY[cur_attack_name]

# var special_node = preload("res://src/Scenes/Attacks/AbilityInfo.gd")
# var FULL MOVE DICTIONARY
# var 

# var selected_move_nums = [1,2,3,4,5,]
# var specials = []
# var current_move = 0

# func _ready():
# 	max_HP = 5
# 	HP = max_HP
# 	for move in selected_move_nums:
# 		var child = Node.new()
# 		child.name = "Move" + String(move)
# 		child.script = special_node
# 		add_child(child)
# 		child.set_current_ability(move)
# 		specials.append(child)

# func _process(_delta):
# 	var total_cd = 0
# 	for node in specials:
# 		total_cd += node.current_cd_time
# 	HP = max_HP - total_cd

# func set_HP(total_cd_amt):
# 	HP = max_HP - total_cd_amt

# func get_HP():
# 	return HP

# func get_movelist():
# 	return specials

# func get_selected_type():
# 	return specials[current_move].get_type()

# func instance_scene():
# 	specials[current_move].activate()
# 	return specials[current_move].get_instance()

# func get_move():
# 	return specials[current_move]
					
#Currently copy of TakeDamage for CharData
#Here for possible overloading.
# func take_damage(dmg):
# 	if not damage_state_ == DAMAGE_STATE.INVULN:
# 		match (action_state_):
# 			ACTION_STATE.DASHING:
# 				pass
# 			ACTION_STATE.ATTACKING:
# 				HP -= dmg	#Should some sort of multiplier?
# 				specials[current_move].take_damage(dmg)
# 				damage_state_ = DAMAGE_STATE.COUNTERHIT
# 				emit_signal("damage_state_change", damage_state_)
# 				#multiplied damage
# 			#STATE.BLOCKING:
# 				#reduced damage
# 			_:
# 				HP -= dmg
# 				specials[current_move].take_damage(dmg)
# 				damage_state_ = DAMAGE_STATE.HIT
# 				emit_signal("damage_state_change", damage_state_)
# 		if HP <= 0:
# 			emit_signal("dead")


# func heal(amt):
# 	specials[current_move].current_cd_time -= amt

# func special_on_lockout():
# 	return specials[current_move].on_cooldown
