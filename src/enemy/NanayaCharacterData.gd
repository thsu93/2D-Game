extends "res://src/scripts/CharacterData.gd"
class_name NanayaCharacterData

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var movelist = {
	"Jab": preload("res://src/attacks/enemy1/jab.gd").new()
}

var ATTACK_TIMER = 1.5
var timer = 0
#JAB, LUNGE, UPPER, ELBOW

func _init():
	max_HP = 500

func _ready():
	cur_attack = movelist["Jab"]
	HP = max_HP

func _process(delta):
	timer += delta
	run_ai()

func run_ai():
	if timer > ATTACK_TIMER and not anim_state_ == ANIMATION_STATE.DAMAGED:
		timer = 0
		change_anim_state(ANIMATION_STATE.ATTACKING)
	pass