extends "res://src/scripts/CharacterData.gd"
class_name NanayaCharacterData

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var movelist = {
	"Jab": preload("res://src/attacks/enemy1/jab.gd").new(), 
	"Elbow": preload("res://src/attacks/enemy1/elbow.gd").new(),
}


func _init():
	max_HP = 50

func _ready():
	cur_attack = movelist["Jab"]
	HP = max_HP

func next_move():
	cur_attack = movelist["Elbow"]

func base_move():
	cur_attack = movelist["Jab"]