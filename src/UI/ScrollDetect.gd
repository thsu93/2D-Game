extends PanelContainer


const INITIAL = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var length = 0
var selected = INITIAL
var nodes = []
var current_pos = 0
onready var grid = $Grid

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in grid.get_children():
		if child.get_class() == "TextureProgress":
			nodes.append(child)
	length = nodes.size()
	reset_all_nodes()
	nodes[0].set_selected()


# func change_selection(dir):
# 	var temp_pos = current_pos
# 	if dir == "down":
# 		while (temp_pos < nodes.size()):
# 			temp_pos += 1 
# 			if temp_pos == nodes.size():
# 				return false
# 			elif nodes[temp_pos].active:
# 				nodes[current_pos].set_unselected()
# 				current_pos = temp_pos
# 				nodes[current_pos].set_selected()
# 				return true

# 	if dir == "up":
# 		while (temp_pos >= 0):
# 			temp_pos -= 1 
# 			if temp_pos < 0:
# 				return false
# 			elif nodes[temp_pos].active:
# 				nodes[current_pos].set_unselected()
# 				current_pos = temp_pos
# 				nodes[current_pos].set_selected()
# 				return true

func reset_all_nodes():
	for node in nodes:
		node.set_unselected()

func change_selection(num):
	reset_all_nodes()
	nodes[num].set_selected()
	current_pos = num

func set_movelist(movelist):
	for i in nodes.size():
		nodes[i].set_name(movelist[0][i] + " \n" + "x" + "\n" + movelist[1][i])
	reset_all_nodes()
	nodes[current_pos].set_selected()
	

# func get_selected_special():
# 	return current_pos
	
# #take in a list of abilitynodes
# #set ability node children to said nodes

# func set_movelist(movelist):
# 	for i in nodes.size():
# 		nodes[i].set_ability(movelist[i])
# 	nodes[current_pos].set_selected()










#DEPRECATED
#func check_damage():
#	if nodes[current_pos].selectable:
#		nodes[current_pos].activate()
#		return false
#	else:
#		nodes[current_pos].break_node()
#
#		#move to next-closest active node upwards first, if possible
#		var moved = change_selection("up")
#		if not moved:
#			moved = change_selection("down")
#		return true 

#func lock_selection(pos):
#	nodes[pos].modulate = Color.black
