extends Node
class_name CharData

signal dead
signal play_animation(animation)
signal turn_sprite

#TODO decide what logic code to move over to the PlayerData node rather than in the base CharData

#region STATE MACHINE PARTS
#TODO priority system for animations
#TODO state changes and such still need revision, currently a bit jank

enum HORIZONTAL_STATE{
	L = -1,
	R = 1,
}

enum AIR_STATE{
	GROUNDED,
	IN_AIR,
}

enum CHAR_STATE{
	WAITING_FOR_UPDATE, #Waiting for state input
	STANDING,
	WALKING,
	RUNNING,
	RUN_START,
	RUN_STOP,
	GUARDING,
	FALLING,
	TURNING,
	DASHING,
	BACKDASHING,
	PARRYING,
	ATTACKING,
	JUMPING,
	NORMAL_HIT,
	STAGGERED_HIT,
	COUNTERHIT,
	DEAD,
}

const ACTION_STATES = [CHAR_STATE.TURNING,
						CHAR_STATE.DASHING,
						CHAR_STATE.BACKDASHING,
						CHAR_STATE.PARRYING,
						CHAR_STATE.ATTACKING,]

const DAMAGE_STATES = [CHAR_STATE.NORMAL_HIT, 
						CHAR_STATE.STAGGERED_HIT,
						CHAR_STATE.COUNTERHIT,
						CHAR_STATE.DEAD, ]


var state_animation_dictionary = {
	CHAR_STATE.STANDING   	: "Idle",
	CHAR_STATE.WALKING   	: "Walk",
	CHAR_STATE.RUNNING  	: "Run",
	CHAR_STATE.RUN_START  	: "RunStart",
	CHAR_STATE.RUN_STOP  	: "RunStop",
	CHAR_STATE.FALLING  	: "Fall",
	CHAR_STATE.GUARDING  	: "Guard",
	CHAR_STATE.TURNING  	: "Turn",
	CHAR_STATE.DASHING  	: "Dash",
	CHAR_STATE.BACKDASHING  : "Backdash",
	CHAR_STATE.ATTACKING  	: "",
	CHAR_STATE.PARRYING  	: "Parry",
	CHAR_STATE.JUMPING  	: "Jump",
	CHAR_STATE.NORMAL_HIT  	: "Damage",
	CHAR_STATE.STAGGERED_HIT: "Stagger",
	CHAR_STATE.COUNTERHIT  	: "Stagger",
	CHAR_STATE.DEAD  		: "Death",
}



var waiting_for_animation_completion = false

var cur_state = CHAR_STATE.STANDING

var air_state = AIR_STATE.GROUNDED

var char_name = ""

var horizontal_state_ = HORIZONTAL_STATE.R

var invuln = false
#endregion


#ATTACK DATA
var cur_attack = null

#ANIMATIONS CONTAINED WITHIN CHAR
var sprite_library
var animation_player_library 
var current_animation = "StandIdle"

#CHARACTER HP DATA
var HP = 5
export(int) var max_HP = 5


#TODO revisit how the cancelable attacks work
export(bool) var uncancellable = false

func _ready():
	HP = max_HP
	uncancellable = false

func set_name(name):
	char_name = name

func take_damage(hit_var):
	if not invuln:
		
		HP -= hit_var["dmg"]
		
		if cur_state == CHAR_STATE.ATTACKING or cur_state == CHAR_STATE.COUNTERHIT:
			cur_state = CHAR_STATE.COUNTERHIT
		elif  hit_var["stagger"]:
			cur_state = CHAR_STATE.STAGGERED_HIT
		else:
			cur_state = CHAR_STATE.NORMAL_HIT
		
		if HP <= 0:
			emit_signal("dead")
			cur_state = CHAR_STATE.DEAD

		else:
			#DO THE DAMAGE THINGS
			pass

		#pass in the damage animation
		change_animation()


#Toggle invincibility state
func toggle_invuln():
	invuln = not invuln


#region Attack Processing

#Handles Character Attacking effects. 
#Currently does not do anything
func process_attack():
	return true
	pass

#endregion


#region Change States

func change_state(_new_state):
	var can_change = false
	if _new_state == cur_state and not cur_state == CHAR_STATE.ATTACKING:
		pass
	elif cur_state == CHAR_STATE.WAITING_FOR_UPDATE:
		can_change = true
	else:
		match _new_state:
			CHAR_STATE.STANDING   	: can_change = change_to_standing()
			CHAR_STATE.WALKING   	: can_change = change_to_walking()
			CHAR_STATE.RUNNING  	: can_change = change_to_running()
			CHAR_STATE.RUN_START  	: can_change = change_to_run_start()
			CHAR_STATE.RUN_STOP  	: can_change = change_to_run_stop()
			CHAR_STATE.FALLING  	: can_change = change_to_falling()
			CHAR_STATE.GUARDING  	: can_change = change_to_guarding()
			CHAR_STATE.TURNING  	: can_change = change_to_turning()
			CHAR_STATE.DASHING  	: can_change = change_to_dashing()
			CHAR_STATE.BACKDASHING  : can_change = change_to_backdashing()
			CHAR_STATE.ATTACKING  	: can_change = change_to_attacking()
			CHAR_STATE.PARRYING  	: can_change = change_to_parrying()
			CHAR_STATE.JUMPING  	: can_change = change_to_jumping()
			CHAR_STATE.NORMAL_HIT  	: can_change = change_to_normal_hit()
			CHAR_STATE.STAGGERED_HIT: can_change = change_to_staggered_hit()
			CHAR_STATE.COUNTERHIT  	: can_change = change_to_counterhit()
			CHAR_STATE.DEAD  		: can_change = change_to_dead()
	if can_change:
		cur_state = _new_state
		change_animation()

#region specific change to state checks

#Can state change to CHAR_STATE.STANDING
#Currently: Always can when on ground, except if dead or run_start
func change_to_standing():
	if air_state == AIR_STATE.IN_AIR:
		return false
	elif cur_state == CHAR_STATE.DEAD:
		return false
	elif cur_state == CHAR_STATE.RUN_START:
		return false
	elif cur_state == CHAR_STATE.RUNNING:
		return false
	else:
		if not waiting_for_animation_completion:
			return true
		else:
			return false

#Can state change to CHAR_STATE.WALKING   
#Currently: Can only transition from standing or RunStop while grounded
func change_to_walking():
	if waiting_for_animation_completion:
		return false
	elif air_state == AIR_STATE.IN_AIR:
		return false
	elif cur_state == CHAR_STATE.STANDING:
		return true
	elif cur_state == CHAR_STATE.RUN_STOP:
		return true
	elif cur_state == CHAR_STATE.FALLING:
		return true
	elif cur_state == CHAR_STATE.JUMPING:
		if not waiting_for_animation_completion: #If not in initial frames of the jump
			return true
		return false
	else:
		return false

	
#Can state change to CHAR_STATE.RUNNING  	
#Currently: Can only do so from RunStart or Dashing
func change_to_running():
	if air_state == AIR_STATE.IN_AIR:
		return false	
	elif cur_state == CHAR_STATE.RUN_START:
		if not waiting_for_animation_completion:
			return true
	elif cur_state == CHAR_STATE.DASHING:
		return true
	elif cur_state == CHAR_STATE.FALLING:
		return true
	elif cur_state == CHAR_STATE.JUMPING:
		if not waiting_for_animation_completion: #If not in initial frames of the jump
			return true
		return false
	else:
		change_state(CHAR_STATE.RUN_START)
		return false

#Can state change to CHAR_STATE.JUMPING  	
#Currently: can do so from any lower priority state
func change_to_jumping():

	if cur_state < CHAR_STATE.JUMPING and not uncancellable:
		waiting_for_animation_completion = true
		return true
		
	else:
		return false

#Can state change to CHAR_STATE.FALLING  	
#Currently: can do so from any lower priority state
func change_to_falling():
	if air_state == AIR_STATE.GROUNDED:
		return false
	elif cur_state == CHAR_STATE.JUMPING:
		waiting_for_animation_completion = false
		return true
	elif waiting_for_animation_completion:
		return false
	elif cur_state < CHAR_STATE.FALLING:
		return true
	else:
		return false

#Can state change to CHAR_STATE.GUARDING  	
#Currently: can do so from any lower priority state
#TODO can you guard in the air?
func change_to_guarding():
	if cur_state < CHAR_STATE.GUARDING:
		return true
	else:
		return false


#Can state change to CHAR_STATE.RUN_START  	
#Currently: can do so from walking or running
func change_to_run_start():
	if air_state == AIR_STATE.IN_AIR:
		return false 

	elif cur_state == CHAR_STATE.WALKING:
		waiting_for_animation_completion = true
		return true

	elif cur_state == CHAR_STATE.STANDING:
		waiting_for_animation_completion = true
		return true

	else:
		return false

#Can state change to CHAR_STATE.RUN_STOP  	
#Currently: can only do so from running
func change_to_run_stop():
	if air_state == AIR_STATE.IN_AIR:
		return false 
	elif cur_state == CHAR_STATE.RUNNING:
		waiting_for_animation_completion = true
		return true
	else:
		return false

#Can state change to CHAR_STATE.TURNING  	
#Currently: can do so from walking or standing
#BUG: GIVES STANDING TURN WHEN JUMPING BUT NOT FALLING. DOES KNOW IT IS IN AIR. 
func change_to_turning():
	if cur_state == CHAR_STATE.JUMPING:
		waiting_for_animation_completion = true
		return true
	elif cur_state == CHAR_STATE.FALLING:
		waiting_for_animation_completion = true
		return true
		
	elif cur_state < CHAR_STATE.TURNING:
		waiting_for_animation_completion = true
		return true
	
	else:
		return false

#Can state change to CHAR_STATE.DASHING  	
#Currently: can do so from any lower-priority state, or attacking
func change_to_dashing():
	if cur_state < CHAR_STATE.DASHING:
		return true
	elif cur_state == CHAR_STATE.ATTACKING:
		return true
	elif cur_state == CHAR_STATE.FALLING:
		return true
	elif cur_state == CHAR_STATE.JUMPING:
		return true
	else:
		return false

#Can state change to CHAR_STATE.BACKDASHING  
#Currently: can do so from guarding
#TODO Make this actually work
func change_to_backdashing():
	# if cur_state == CHAR_STATE.GUARDING:
	# 	return true
	# else:
	# 	return false
	return true

#Can state change to CHAR_STATE.ATTACKING  	
#Currently: can do so from any lower-priority state
func change_to_attacking():
	if cur_state < CHAR_STATE.ATTACKING:
		waiting_for_animation_completion = true
		return true
	elif cur_state == CHAR_STATE.ATTACKING:
		waiting_for_animation_completion = true
		return true
	elif cur_state == CHAR_STATE.JUMPING:
		waiting_for_animation_completion = true
		return true
	else:
		return false

#Can state change to CHAR_STATE.PARRYING  	
#Currently: can do so from any lower-priority state
func change_to_parrying():
	if cur_state < CHAR_STATE.PARRYING:
		return true
	else:
		return false

#Can state change to CHAR_STATE.NORMAL_HIT  	
#Currently: can do so from any lower-priority state
func change_to_normal_hit():
	if cur_state < CHAR_STATE.NORMAL_HIT and not invuln:
		return true
	else:
		return false


#Can state change to CHAR_STATE.STAGGERED_HIT	
#Currently: can do so from any lower-priority state
func change_to_staggered_hit():
	if cur_state < CHAR_STATE.STAGGERED_HIT and not invuln:
		return true
	else:
		return false

#Can state change to CHAR_STATE.COUNTERHIT  	
#Currently: can do so from any lower-priority state
func change_to_counterhit():
	if cur_state < CHAR_STATE.COUNTERHIT and not invuln:
		return true
	else:
		return false

#Can state change to CHAR_STATE.DEAD  		
#Currently: can do so from any lower-priority state
func change_to_dead():
	if cur_state < CHAR_STATE.DEAD:
		return true
	else:
		return false

#end region 


#Is the character in the air or not
#is changed directly from Actor based on is_on_floor()
func change_air_state(new_state):
	if air_state != new_state:
		air_state = new_state
		if new_state == AIR_STATE.GROUNDED:
			waiting_for_animation_completion = false
			uncancellable = false

			#TODO decide if thiis is how it should work

			change_state(CHAR_STATE.STANDING)

#endregion

#
func change_animation():
	var new_animation = current_animation

	if cur_state == CHAR_STATE.WAITING_FOR_UPDATE:
		return
	elif cur_state == CHAR_STATE.ATTACKING:
		new_animation = cur_attack.movename
	else:
		new_animation = state_animation_dictionary[cur_state]
	
	var air_prefix = "Stand" if air_state == AIR_STATE.GROUNDED else "Jump"
		#BUG ALL ATTACKS OUT OF DASH ARE REGISTERED AS 

	if air_prefix + new_animation in animation_player_library:
		new_animation = air_prefix + new_animation

	if new_animation in animation_player_library:
		current_animation = new_animation
		
		emit_signal("play_animation", current_animation)

	else:
		if char_name == "player":
			print(char_name  + " could not find "+ new_animation)


# #Handle any state changes that automatically occur on completion of an animation
# #Then call to update state depending on which state was changed 
func animation_completed():
	
	waiting_for_animation_completion = false

	if cur_state == CHAR_STATE.RUN_START:
		change_state(CHAR_STATE.RUNNING)

	elif cur_state == CHAR_STATE.RUN_STOP:
		change_state(CHAR_STATE.STANDING)

	elif cur_state == CHAR_STATE.GUARDING:
		pass
	
	elif cur_state == CHAR_STATE.RUNNING:
		print("run")
		pass	

	elif cur_state == CHAR_STATE.WALKING:
		pass
	
	elif cur_state == CHAR_STATE.JUMPING:
		pass

	elif cur_state == CHAR_STATE.FALLING:
		pass

	#One-shot animations
	else:
		if cur_state == CHAR_STATE.TURNING:
			horizontal_state_*=-1
			emit_signal("turn_sprite")

		cur_state = CHAR_STATE.WAITING_FOR_UPDATE
		
		#HACK

		# if air_state == AIR_STATE.IN_AIR:
		# 	change_state(CHAR_STATE.FALLING)
		# else:
		# 	#TODO double setting state, find why
		# 	change_state(CHAR_STATE.STANDING)

	change_animation()

#endregion

