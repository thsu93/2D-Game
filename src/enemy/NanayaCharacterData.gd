extends "res://src/scripts/CharacterData.gd"
class_name NanayaCharacterData

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var regen_rate = 5

var movelist = {
	"Jab": preload("res://src/attacks/enemy1/jab.gd").new(), 
	"Elbow": preload("res://src/attacks/enemy1/elbow.gd").new(),
}


func _init():
	max_HP = 50

func _process(delta):
	if HP < max_HP:
		HP += regen_rate * delta
	else:
		HP = max_HP

func _ready():
	cur_attack = movelist["Jab"]
	HP = max_HP	

func next_move():
	cur_attack = movelist["Elbow"]

func base_move():
	cur_attack = movelist["Jab"]
