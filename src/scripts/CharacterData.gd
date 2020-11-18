extends Node
class_name CharData

signal dead
signal play_animation(animation)
signal new_sprite_animation(animation)
signal turn_sprite

#TODO decide what logic code to move over to the PlayerData node rather than in the base CharData

#region STATE MACHINE PARTS
#TODO priority system for animations
#TODO state changes and such still need revision, currently a bit jank

enum ANIMATION_STATE{
	IDLE, #DEFERRING TO OTHER STATE CHECKS
	DASHING,
	BACKDASHING,
	CROUCH_DOWN,
	STAND_UP,
	RUN_START,
	RUN_STOP,
	TURNING,
	DODGING,
	PARRYING,
	ATTACKING,
	DAMAGED,
	GUARDING,
	DISABLED, #TODO NECESSARY?
	};

enum DAMAGE_STATE{
	IDLE, #Currently not taking damage
	GUARDING, #Currently reducing damage
	DAMAGED, #Normal Damage State
	STAGGERED, #Special Damage State
	HIT, #Normal Hit, no special modifiers
	COUNTERHIT, #Hit during an attack animation, special modifiers
	INVULN, #Immune to damage
	DEAD, 
}

enum HORIZONTAL_STATE{
	L = -1,
	R = 1,
}

#TODO ADD TRANSITIONAL STATES?
enum MOVE_STATE{
	CROUCHING,
	STANDING,
	JUMPING,
	FALLING,
	WALKING,
	RUNNING,
	DASHING,
	BACKDASHING,
	GUARDING,
	TRANSITIONING,
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

enum AIR_STATE{
	GROUNDED,
	IN_AIR,
}

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


var anim_name_dictionary = {
	ANIMATION_STATE.DASHING : "Dash",
	ANIMATION_STATE.BACKDASHING : "Backdash",
	ANIMATION_STATE.PARRYING : "Parry",
	ANIMATION_STATE.TURNING : "Turn", 
	ANIMATION_STATE.RUN_START : "RunStart",
	ANIMATION_STATE.RUN_STOP : "RunStop",
}

var waiting_for_animation_completion = false

var cur_state = CHAR_STATE.STANDING

var air_state = AIR_STATE.GROUNDED

var char_name = ""

var anim_state_ = ANIMATION_STATE.IDLE

var damage_state_ = DAMAGE_STATE.IDLE

var horizontal_state_ = HORIZONTAL_STATE.R

var move_state_ = MOVE_STATE.STANDING
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
	if not damage_state_ == DAMAGE_STATE.INVULN:
		
		HP -= hit_var["dmg"]
		
		var new_anim = null

		if hit_var["stagger"]:
			new_anim = "Stagger"
		else:
			new_anim = "Damage"

		if anim_state_ == ANIMATION_STATE.ATTACKING or damage_state_ == DAMAGE_STATE.COUNTERHIT:
			damage_state_ = DAMAGE_STATE.COUNTERHIT
		else:
			damage_state_ = DAMAGE_STATE.DAMAGED

		anim_state_ = ANIMATION_STATE.DAMAGED
		move_state_ = MOVE_STATE.STANDING
		
		if HP <= 0:
			emit_signal("dead")
			damage_state_ = DAMAGE_STATE.DEAD
			new_anim = "Death"

		else:
			#DO THE DAMAGE THINGS
			pass

		#pass in the damage animation
		update_current_animation(new_anim)


#Toggle invincibility state
func toggle_invuln():
	if damage_state_ == DAMAGE_STATE.INVULN:
		damage_state_ = DAMAGE_STATE.IDLE
	else: 
		damage_state_ = DAMAGE_STATE.INVULN


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
	if cur_state < CHAR_STATE.NORMAL_HIT:
		return true
	else:
		return false


#Can state change to CHAR_STATE.STAGGERED_HIT	
#Currently: can do so from any lower-priority state
func change_to_staggered_hit():
	if cur_state < CHAR_STATE.STAGGERED_HIT:
		return true
	else:
		return false

#Can state change to CHAR_STATE.COUNTERHIT  	
#Currently: can do so from any lower-priority state
func change_to_counterhit():
	if cur_state < CHAR_STATE.COUNTERHIT:
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

#given a new horizontal state, attempt to change to that new state
#if is not current direction, flip the character
#No longer called from char directly, just called after 
func change_horiz_state(dir):
	#if trying to turn to the direction already facing
	if not dir == horizontal_state_:
		evaluate_state_change(dir, "HORIZONTAL")

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

	else:
		if char_name == "player":
			print(char_name  + " could not find "+ new_animation)

	emit_signal("play_animation", current_animation)


#endregion

#given a new movement state, attempt to change to that new state
#if new state is the same as current state, simply refreshes the animation
func change_move_state(new_state):
	if not new_state == move_state_:
		evaluate_state_change(new_state, "MOVEMENT")
	else:
		update_current_animation()

#given a new damage state, attempt to change to that new state 
#currently does nothing at all, never called.
func change_damage_state(new_state):
	if damage_state_ == DAMAGE_STATE.IDLE:
		damage_state_ = new_state
	pass


#given a new animation state, attempt to change to that new state
#Currently only checks against Dash/Backdash/Attack/Idle
func change_anim_state(new_state):
		
	if new_state == ANIMATION_STATE.IDLE:
		anim_state_ = ANIMATION_STATE.IDLE
	else:
		evaluate_state_change(new_state, "ANIMATION")
	pass

#endregion

#region Evaluate State Change

#See if char is currently able to change state
#Prioritizes Damage -> Animation -> Movement state changes.
#TODO this has gotta be better somehow, it's a convoluted mess
func evaluate_state_change(new_state, state_changed):
	#HIGHEST PRIORITY
	#Currently does not check this ever, as damage state changes always pass and thus never need to be evaluated
	if state_changed == "DAMAGE":
		pass
		#Should probably change animation state to idle to indicate deferring


	#If not currently animating
	#TODO THIS IS WHERE THE PRIORITY SYSTEM WOULD GO
	#This is a mess
	if state_changed == "ANIMATION":
		if not anim_state_ == ANIMATION_STATE.TURNING:
			if new_state == ANIMATION_STATE.DASHING:
				anim_state_ = ANIMATION_STATE.DASHING
				move_state_ = MOVE_STATE.DASHING
			
			elif new_state == ANIMATION_STATE.BACKDASHING:
				anim_state_ = ANIMATION_STATE.BACKDASHING
				move_state_ = MOVE_STATE.BACKDASHING

			elif new_state == ANIMATION_STATE.PARRYING:
				anim_state_ = ANIMATION_STATE.PARRYING
			
			elif new_state == ANIMATION_STATE.ATTACKING:
				if process_attack():
					anim_state_ = ANIMATION_STATE.ATTACKING

			elif new_state == ANIMATION_STATE.GUARDING:
				anim_state_ = ANIMATION_STATE.GUARDING


	if anim_state_ == ANIMATION_STATE.IDLE:
		#start turning
		if state_changed == "HORIZONTAL":
			anim_state_ = ANIMATION_STATE.TURNING
				
		if state_changed == "MOVEMENT":
			
			#HIGHEST PRIORITY CHANGE 
			if new_state == MOVE_STATE.JUMPING:
				move_state_ = MOVE_STATE.JUMPING
				pass #Should not require any changes to the animation state


			if new_state == MOVE_STATE.CROUCHING:
				anim_state_ = ANIMATION_STATE.CROUCH_DOWN

			#IF ANY CHANGES OUT OF CROUCHING, EXCEPTING JUMPING
			if move_state_ == MOVE_STATE.CROUCHING:
				if new_state != MOVE_STATE.CROUCHING:
					anim_state_ = ANIMATION_STATE.STAND_UP
			
			if new_state == MOVE_STATE.STANDING:

				if move_state_ == MOVE_STATE.RUNNING:
					anim_state_ = ANIMATION_STATE.RUN_STOP

				else:
					move_state_ = MOVE_STATE.STANDING

			
			if new_state == MOVE_STATE.FALLING:
				move_state_ = MOVE_STATE.FALLING
				pass #should not require any changes to the animation state
			
			if new_state == MOVE_STATE.WALKING:

				if move_state_ == MOVE_STATE.RUNNING:
					anim_state_ = ANIMATION_STATE.RUN_STOP
				else:
					move_state_ = MOVE_STATE.WALKING
		
			if new_state == MOVE_STATE.RUNNING:
				if not move_state_ == MOVE_STATE.JUMPING:
					anim_state_ = ANIMATION_STATE.RUN_START
				pass

	else: #If playing another animation right now
		pass #Do not update anything
	
	update_current_animation()
#endregion


#region Animation Changes

#Updates the actor's animation to fit the current state of the state machine
#prioritizes damage, then animations, then movement
func update_current_animation(new_anim = null):

	if not new_anim:
		new_anim = current_animation

	if not damage_state_ == DAMAGE_STATE.IDLE:
		if damage_state_ == DAMAGE_STATE.GUARDING:
			new_anim = "Guard"
		#DAMAGE ANIMATIONS HANDLED WITHIN TAKE_DAMAGE

		pass #deal with 

	if anim_name_dictionary.has(anim_state_ ):
		new_anim = anim_name_dictionary[anim_state_]
	
	# elif anim_state_ == ANIMATION_STATE.DASHING:
	# 	# if move_state_ == MOVE_STATE.JUMPING or move_state_ == MOVE_STATE.FALLING:
	# 	# 	new_anim ="JumpDash"
	# 	# else:
	# 	# 	new_anim = "Dash"
	# 	new_anim = "Dash"
	# elif anim_state_ == ANIMATION_STATE.BACKDASHING:
	# 	new_anim = "Backdash"
	
	# elif anim_state_ == ANIMATION_STATE.PARRYING:
	# 	new_anim = "Parry"

	# elif anim_state_ == ANIMATION_STATE.TURNING:
	# 	new_anim = "Turn"

	# #Transitional Animations
	# elif anim_state_ == ANIMATION_STATE.CROUCH_DOWN:
	# 	new_anim = "CrouchDown"
	# elif anim_state_ == ANIMATION_STATE.STAND_UP:
	# 	new_anim = "StandUp"
	# elif anim_state_ == ANIMATION_STATE.RUN_START:
	# 	new_anim = "RunStart"
	# elif anim_state_ == ANIMATION_STATE.RUN_STOP:
	# 	new_anim = "RunStop"

	
	elif anim_state_ == ANIMATION_STATE.ATTACKING:
		new_anim = cur_attack.movename
		pass
		#no attacking animations current
		#should probably defer this call to a more complex function given possible variants
		#no attacking animations current
		#have jumping/crouching/standing variants to consider as well 
	elif anim_state_ == ANIMATION_STATE.DODGING:
		pass
		#no attacking animations current

	elif anim_state_ == ANIMATION_STATE.IDLE:
		#defer to the movement-controlled animations
		match move_state_:
			MOVE_STATE.CROUCHING: new_anim = "CrouchIdle"
			MOVE_STATE.JUMPING: new_anim = "Jump" 
			MOVE_STATE.FALLING: new_anim = "Fall"
			MOVE_STATE.RUNNING: new_anim = "Run"
			MOVE_STATE.WALKING: new_anim = "Walk"
			MOVE_STATE.GUARDING: new_anim = "Guard"
			_: new_anim = "StandIdle"
		pass

	new_anim = match_vert_state(new_anim)
	
	# if not new_anim == current_animation: #probably redundant check
# 		print(new_anim)
	if new_anim in animation_player_library:
		emit_signal("play_animation", new_anim)
		current_animation = new_anim
	elif new_anim in sprite_library:
		emit_signal("new_sprite_animation", new_anim)
		current_animation = new_anim
	else:
		print("ERROR ANIMATION NOT IN LIBRARY: ", new_anim)



#Fixes the animation to match the movestate of the character, if possible
#IE will correct for running/in-air/crouching/dashing animations
func match_vert_state(new_anim):
	
	#Create a placeholder animation name, and then append the movestate descriptor to the front
	var temp_anim = new_anim
	match move_state_:
		MOVE_STATE.CROUCHING : 	temp_anim = "Crouch" + new_anim
		MOVE_STATE.STANDING : 	temp_anim = "Stand" + new_anim
		MOVE_STATE.JUMPING : 	temp_anim = "Jump" + new_anim
		MOVE_STATE.FALLING : 	temp_anim = "Jump" + new_anim
		MOVE_STATE.WALKING : 	temp_anim = "Walk" + new_anim
		MOVE_STATE.RUNNING : 	temp_anim = "Run" + new_anim
		MOVE_STATE.DASHING :	temp_anim = "Dash" + new_anim

	#If movestate+anim exists in the sprite or animation player, 
	#or if the animation exists on its own without a descriptor,
	#return the animation value
	if temp_anim in sprite_library or temp_anim in animation_player_library:
		return temp_anim
	elif new_anim in sprite_library or new_anim in animation_player_library:
		return new_anim

	#Otherwise, check if a standing version exists but the player is not in a matching state
	#and no movestate-generic animation exists
	#HACK Probably not the best practice
	else:
		
		temp_anim = "Stand" + new_anim
		if temp_anim in sprite_library or temp_anim in animation_player_library:
			return temp_anim
		else: # new_anim in sprite_library or new_anim in animation_player_library
			return new_anim #This seems like it should never be called


#Handle any state changes that automatically occur on completion of an animation
#Then call to update state depending on which state was changed 
func animation_completed():
	
	waiting_for_animation_completion = false

	#Variable to track if the move state should change given the animation
	var move_state_change = false

	#Change damage state back at the end of taking damage
	if anim_state_ == ANIMATION_STATE.DAMAGED:
		damage_state_ = DAMAGE_STATE.IDLE

	#if in the turning state, change horizontal state
	if anim_state_ == ANIMATION_STATE.TURNING:
		if char_name != "player":
			horizontal_state_ *= -1 #FLIP SIDE
			emit_signal("turn_sprite")

	#Check if the animation_state was a transitional animation
	else:
		move_state_change = true
		match anim_state_:
			ANIMATION_STATE.RUN_START:		move_state_ = MOVE_STATE.RUNNING
			ANIMATION_STATE.RUN_STOP:		move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.CROUCH_DOWN:	move_state_ = MOVE_STATE.CROUCHING
			ANIMATION_STATE.STAND_UP:		move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.BACKDASHING:	move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.DASHING: 		move_state_ = MOVE_STATE.RUNNING #Forces player into run post-dash if fowrward dashing
			ANIMATION_STATE.IDLE: 			move_state_change = MOVE_STATE.STANDING
			_: move_state_change = false

	anim_state_ = ANIMATION_STATE.IDLE

	if move_state_change:
		change_move_state(move_state_)
	else: 
		evaluate_state_change(anim_state_, "ANIMATION")


	if cur_state == CHAR_STATE.RUN_START:
		change_state(CHAR_STATE.RUNNING)

	elif cur_state == CHAR_STATE.RUN_STOP:
		change_state(CHAR_STATE.STANDING)

	elif cur_state == CHAR_STATE.GUARDING:
		pass
	
	elif cur_state == CHAR_STATE.RUNNING:
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
		# if air_state == AIR_STATE.IN_AIR:
		# 	change_state(CHAR_STATE.FALLING)
		# else:
		# 	#TODO double setting state, find why
		# 	change_state(CHAR_STATE.STANDING)

	change_animation()

#endregion
