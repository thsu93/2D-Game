extends Node

const SCENEDICTIONARY = {
	"BULLET": preload("res://src/Scenes/Attacks/Bullet.tscn"),
	"BARREL": preload("res://src/Scenes/GameWorld/barrel_E.tscn"),
	"LIGHTNING": preload("res://src/Scenes/Attacks/LightningStrike.tscn"),
	"FIREBALL": preload("res://src/Scenes/Attacks/Fireball.tscn"),
};

#TODO: Can likely delete Movement and AnimTime sections when Animations are finished
# Look for "has_animation("

const ABILITYDICTIONARY = {
	0: {
		"Name": "NULL",
		"Scene": null,
		"Color": null,
		"Lockout" : null,
		"Type" : "Scene",		
		"Animation" : "None",
		"AnimTime" : 0,
		"Movement" : 0,
	},
	1: {
		"Name": "Bullet",
		"Scene": SCENEDICTIONARY["BULLET"],
		"Color": Color.purple,
		"Lockout" : .4,
		"Type" : "Scene",
		"Animation" : "None",
		"AnimTime" : 0,
		"Movement" : 0,
	},
	2: {
		"Name": "Barrel",
		"Scene": SCENEDICTIONARY["BARREL"],
		"Color": Color.brown,
		"Lockout" : .5,
		"Type" : "Scene",
		"Animation" : "None",
		"AnimTime" : 0,
		"Movement" : 0,
	},
	3: {
		"Name": "Lightning",
		"Scene": SCENEDICTIONARY["LIGHTNING"],
		"Color": Color.blue,
		"Lockout" : 2,
		"Type" : "Scene",
		"Animation" : "None",
		"AnimTime" : 0,
		"Movement" : 0,
	},
	4: {
		"Name": "Fireball",
		"Scene": SCENEDICTIONARY["FIREBALL"],
		"Color": Color.red,
		"Lockout" : 3,
		"Type" : "Scene",
		"Animation" : "None",
		"AnimTime" : .25,
		"Movement" : -.3,
	},
	5: {
		"Name": "DashPunch",
		"Scene": null,
		"Color": Color.black,
		"Lockout" : 3,
		"Type" : "Melee",
		"Animation" : "None",
		"AnimTime" : .25,
		"Movement" : .75,
	},
};

var current_cd_time = 0
var max_cd_time = 0
var active = true
var on_cooldown = false
var selectable = true


var moveName = "NewMove"
var moveColor = Color.green
var cooldownTime = 1
var moveType = ""
var animName = ""
var animTime = 0
var moveAmt = 0

var current_ability

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_current_ability(num):
	current_ability = ABILITYDICTIONARY[num]
	moveName = current_ability["Name"]
	cooldownTime = current_ability["Lockout"]
	moveColor = current_ability["Color"]
	moveType = current_ability["Type"]
	animName = current_ability["Animation"]
	animTime = current_ability["AnimTime"]
	moveAmt = current_ability["Movement"]

func get_image():
	return current_ability["Color"]

func get_instance():
	return current_ability["Scene"].instance()

func get_type():
	return moveType

func get_anim_time():
	return animTime

func get_speed():
	return moveAmt

func _process(delta):

	selectable = active and not on_cooldown

	if active:
		if current_cd_time > 0:
			on_cooldown = true
			current_cd_time -= delta
			
			#TODO: What to do if value is < step (huge CDs)
			#Probably save value up to step, subtract step from value, add step.
			#currently just have step set to ~delta value, but probably poor workaround

		if on_cooldown and current_cd_time < 0:
			current_cd_time = 0
			max_cd_time = 0
			on_cooldown = false


func take_damage(dmg):
	on_cooldown = true
	#TODO: Decide how to handle max_cd_time
	current_cd_time += dmg
	max_cd_time += dmg

func activate():
	current_cd_time = cooldownTime
	max_cd_time = cooldownTime
