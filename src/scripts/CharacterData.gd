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
	GUARDING,
	DODGING,
	PARRYING,
	ATTACKING,
	DAMAGED,
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
	TRANSITIONING,
}

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
		# match (anim_state_):
		# 	ANIMATION_STATE.DASHING:
		# 		pass
		# 	ANIMATION_STATE.ATTACKING:
		# 		HP -= dmg	#Should some sort of multiplier?
		# 		damage_state_ = DAMAGE_STATE.COUNTERHIT
		# 		emit_signal("damage_state_change", damage_state_)
		# 		#multiplied damage
		# 	#STATE.GUARDING:
		# 		#reduced damage
		# 	_:
		# 		HP -= dmg
		# 		damage_state_ = DAMAGE_STATE.HIT
		# 		emit_signal("damage_state_change", damage_state_)
		
		HP -= hit_var["dmg"]
		
		if hit_var["stagger"]:
			damage_state_ = DAMAGE_STATE.STAGGERED
		else:
			damage_state_ = DAMAGE_STATE.HIT
			
		anim_state_ = ANIMATION_STATE.DAMAGED
		
		if HP <= 0:
			emit_signal("dead")
			damage_state_ = DAMAGE_STATE.DEAD

		else:
			#DO THE DAMAGE THINGS
			pass
			
		update_current_animation()

func toggle_invuln():
	if damage_state_ == DAMAGE_STATE.INVULN:
		damage_state_ = DAMAGE_STATE.IDLE
	else: 
		damage_state_ = DAMAGE_STATE.INVULN


#region Attack Processing

#Handles Character Attacking effects. 
func process_attack():
	return true
	pass

#endregion


#region Change States

#given a new horizontal state, attempt to change to that new state
#if is not current direction, flip the character
func change_horiz_state(dir):
	#if trying to turn to the direction already facing
	if not dir == horizontal_state_:
		evaluate_state_change(dir, "HORIZONTAL")

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
	damage_state_ = new_state
	pass


#given a new animation state, attempt to change to that new state
#Currently only checks against Dash/Backdash/Attack/Idle
func change_anim_state(new_state):
	if new_state == ANIMATION_STATE.DASHING:
		evaluate_state_change(ANIMATION_STATE.DASHING, "ANIMATION")
	if new_state == ANIMATION_STATE.BACKDASHING:
		evaluate_state_change(ANIMATION_STATE.BACKDASHING, "ANIMATION")
	if new_state == ANIMATION_STATE.ATTACKING:
		evaluate_state_change(ANIMATION_STATE.ATTACKING, "ANIMATION")
	if new_state == ANIMATION_STATE.PARRYING:
		evaluate_state_change(ANIMATION_STATE.PARRYING, "ANIMATION")
	if new_state == ANIMATION_STATE.GUARDING:
		evaluate_state_change(ANIMATION_STATE.GUARDING, "ANIMATION")
	if new_state == ANIMATION_STATE.IDLE:
		anim_state_ = ANIMATION_STATE.IDLE
	
	pass

#endregion

#region Evaluate State Change

#See if char is currently able to change state
#Prioritizes Damage -> Animation -> Movement state changes.
func evaluate_state_change(new_state, state_changed):
	#HIGHEST PRIORITY
	#Currently does not check this ever, as damage state changes always pass and thus never need to be evaluated
	if state_changed == "DAMAGE":
		pass
		#Should probably change animation state to idle to indicate deferring
	#If not currently animating
	#TODO THIS IS WHERE THE PRIORITY SYSTEM WOULD GO
	
	if state_changed == "ANIMATION":
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
		#start turn
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
func update_current_animation():

	var new_anim = current_animation

	if not damage_state_ == DAMAGE_STATE.IDLE:
		if damage_state_ ==DAMAGE_STATE.DEAD:
			new_anim = "Death"
		elif damage_state_ == DAMAGE_STATE.STAGGERED:
			new_anim = "Stagger"
		else:
			new_anim = "Damage"
		pass #deal with 

	
	elif anim_state_ == ANIMATION_STATE.DASHING:
		# if move_state_ == MOVE_STATE.JUMPING or move_state_ == MOVE_STATE.FALLING:
		# 	new_anim ="JumpDash"
		# else:
		# 	new_anim = "Dash"
		new_anim = "Dash"
	elif anim_state_ == ANIMATION_STATE.BACKDASHING:
		new_anim = "Backdash"
	
	elif anim_state_ == ANIMATION_STATE.ATTACKING:
		new_anim = cur_attack.movename

	elif anim_state_ == ANIMATION_STATE.PARRYING:
		new_anim = "Parry"

	elif anim_state_ == ANIMATION_STATE.TURNING:
		new_anim = "Turn"

	#Transitional Animations
	elif anim_state_ == ANIMATION_STATE.CROUCH_DOWN:
		new_anim = "CrouchDown"
	elif anim_state_ == ANIMATION_STATE.STAND_UP:
		new_anim = "StandUp"
	elif anim_state_ == ANIMATION_STATE.RUN_START:
		new_anim = "RunStart"
	elif anim_state_ == ANIMATION_STATE.RUN_STOP:
		new_anim = "RunStop"

	
	elif anim_state_ == ANIMATION_STATE.ATTACKING:
		new_anim = cur_attack.movename
		pass
		#no attacking animations current
		#should probably defer this call to a more complex function given possible variants
	elif anim_state_ == ANIMATION_STATE.GUARDING:
		new_anim = "Guard"
		pass
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
			MOVE_STATE.FALLING: new_anim = "Falling"
			MOVE_STATE.RUNNING: new_anim = "Run"
			MOVE_STATE.WALKING: new_anim = "Walk"
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
	
	#Variable to track if the move state should change given the animation
	var move_state_change = false

	#Change damage state back at the end of taking damage
	if anim_state_ == ANIMATION_STATE.DAMAGED:
		damage_state_ = DAMAGE_STATE.IDLE

	#if in the turning state, change horizontal state
	if anim_state_ == ANIMATION_STATE.TURNING:
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
#endregion
