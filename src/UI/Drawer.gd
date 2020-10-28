#DEPRECATED currently

extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const L_CLICK_RESET_LOCKOUT = 1

var move_lockout = .5


onready var root = get_tree().get_root().get_node("World")
onready var player = get_parent()

var projectResolution
var origin

var rheld = false

var lclicked = false

var sword

var select = 0

var l_click_timer = 0
var r_click_timer = 0

var disabled = false

var current_r_action

var sword_actions = [
	{
		"name": "Swing 1",
		"anim": "SwordSwing1",
		"window": .5
	},
	{
		"name": "Swing 2",
		"anim": "SwordSwing2",
		"window": .5
	},
	{
		"name": "Swing 3",
		"anim": "SwordSwing3",
		"window": .75
	},
]

var current_sword_action = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	projectResolution = get_viewport().size
	origin = projectResolution/2

func _process(delta):
	
	if not disabled:
		
		var offset = player.get_position()
		l_click_timer += delta
		r_click_timer += delta
		
		projectResolution = get_viewport().size
		origin = projectResolution/2
		var mouseloc = get_viewport().get_mouse_position()-origin
		
		
#		RIGHT CLICK 
		if Input.is_action_just_pressed("rclick"):
			r_click_action(mouseloc, offset)
			
		# 	rheld = true
			
		# if rheld:
		# 	r_click_action(mouseloc, offset)
				
		# if Input.is_action_just_released("rclick"):
		# 	rheld = false
			
			
#		LEFT CLICK
		if Input.is_action_just_pressed("click"):
			lclicked = true
			
		if lclicked:
			if l_click_timer > move_lockout:
				l_click_action(mouseloc, offset)
				l_click_timer = 0
			
		if Input.is_action_just_released("click"):
			lclicked = false
		
		if l_click_timer > L_CLICK_RESET_LOCKOUT:
			current_sword_action = 0


func set_selection(a):
	select = a
	
func set_player(a):
	player = a
	
func disable():
	disabled = true
	
func enable():
	disabled = false
	
func l_click_action(mouseloc, offset):
#	root.spawn($Shooter.shoot(BULLET, mouseloc+offset, offset))
	# var dir = ((mouseloc+offset)-offset).normalized()
	# sword.rotation_degrees = rad2deg(dir.angle())
	# sword.play(sword_actions[current_sword_action]["anim"])
	# move_lockout = sword_actions[current_sword_action]["window"]
	# current_sword_action += 1
	# if (current_sword_action>=sword_actions.size()):
	# 	current_sword_action = 0
	# 	move_lockout = 1
	mouse_click_to_cardinal(mouseloc, offset)
	player.char_data.action_state_ = player.char_data.ACTION_STATE.ATTACKING
	pass

func mouse_click_to_cardinal(mouseloc, offset):
	var dir = ((mouseloc+offset)-offset).normalized()
	var rads = atan2(dir.y, dir.x)
	var tempx = 0
	var tempy = 0
	if abs(rads) > (3.14/8) and abs(rads) < (3.14*7/8):
		tempy = -1 if rads < 0 else 1
	if abs(rads) < (3.14*3/8):
		tempx = 1
	elif abs(rads) > (3.14*5/8):
		tempx = -1
	player.change_dir_state(Vector2(tempx, tempy))
	pass

#
#	var spawn
#	match select:
#		0: spawn = R_SPAWN.instance()
#		1: spawn  = R_SPAWN2.instance()
#		_: spawn = $Shooter.shoot(R_SPAWN3, mouseloc+offset, offset)
#	if not spawn.get_type() == "projectile":
#		spawn.position = mouseloc+offset
#	root.spawn(spawn)

#CURRENTLY PLACEHOLDER
func set_sword(obj):
	sword = obj

func r_click_action(mouseloc, offset):
	var move = player.get_move()
	if not move.on_cooldown:
		move.activate()
		if move.get_type() == "Scene":
			var spawn = move.get_instance()
			if not spawn == null:
				if not spawn.get_type() == "projectile":
					spawn.position = mouseloc+offset
				else:
					$Shooter.shoot(spawn, mouseloc+offset, offset)
				root.spawn(spawn)
		else:
			#melee
			pass
		if move.get_anim_time() > 0:
			#play animation
			var dir = ((mouseloc+offset)-offset).normalized()
			player.force_movement(dir, move.get_speed(), move.get_anim_time())



	# if not player.special_on_lockout():
	# 	if (player.check_type() == "Scene"):
	# 		var spawn = player.instance_scene()
	# 		if not spawn == null:
	# 			if not spawn.get_type() == "projectile":
	# 				spawn.position = mouseloc+offset
	# 			else:
	# 				$Shooter.shoot(spawn, mouseloc+offset, offset)
	# 			root.spawn(spawn)
	# 	else:
	# 		#melee functionality
	# 		pass

