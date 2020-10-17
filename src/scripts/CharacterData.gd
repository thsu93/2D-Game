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
	BLOCKING,
	DODGING,
	ATTACKING,
	DAMAGED,
	DISABLED, #TODO NECESSARY?
	};

enum DAMAGE_STATE{
	IDLE, #Currently not taking damage
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
#HACK, rewrite this for more complexity later
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
		# 	#STATE.BLOCKING:
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
			return

		else:
			#DO THE DAMAGE THINGS
			pass
			
		update_current_animation()

#TODO: What does this actually do for gameplay?
func toggle_invuln():
	if damage_state_ == DAMAGE_STATE.INVULN:
		damage_state_ = DAMAGE_STATE.IDLE
	else: 
		damage_state_ = DAMAGE_STATE.INVULN


#region change_horiz_state
func change_horiz_state(dir):
	#if trying to turn to the direction already facing
	if not dir == horizontal_state_:
		evaluate_state_change(dir, "HORIZONTAL")
#endregion

#change mvmt state
#TODO should add landing frames
func change_move_state(new_state):
	#if not move_state_ == MOVE_STATE.JUMPING and not move_state_ == MOVE_STATE.FALLING:
	#should be checked in player via on_floor
	#unsure how to handle better

	if not new_state == move_state_:
		evaluate_state_change(new_state, "MOVEMENT")
	else:
		update_current_animation()

#change dmg state 



#change animation state
#HACK should handle this more cleanly
func change_anim_state(new_state):
	if new_state == ANIMATION_STATE.DASHING:
		evaluate_state_change(ANIMATION_STATE.DASHING, "ANIMATION")
	if new_state == ANIMATION_STATE.BACKDASHING:
		evaluate_state_change(ANIMATION_STATE.BACKDASHING, "ANIMATION")
	if new_state == ANIMATION_STATE.ATTACKING:
		evaluate_state_change(ANIMATION_STATE.ATTACKING, "ANIMATION")
	if new_state == ANIMATION_STATE.IDLE:
		anim_state_ = ANIMATION_STATE.IDLE
	
	pass


#See if char is currently able to change state
#region 
func evaluate_state_change(new_state, state_changed):
	#HIGHEST PRIORITY
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

		elif new_state == ANIMATION_STATE.ATTACKING:
			anim_state_ = ANIMATION_STATE.ATTACKING
			process_attack()

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

#region HOW CHARACTER WILL HANDLE ATTACKING
#TODO When Character Attacks
func process_attack():
	pass
#endregion

#region update_current_animation 
func update_current_animation():

	var new_anim = current_animation

	if not damage_state_ == DAMAGE_STATE.IDLE:
		if damage_state_ == DAMAGE_STATE.STAGGERED:
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
	elif anim_state_ == ANIMATION_STATE.BLOCKING:
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

#endregion

#region match the vertical state, if possible
func match_vert_state(new_anim):
	var temp_anim = new_anim
	match move_state_:
		MOVE_STATE.CROUCHING : 	temp_anim = "Crouch" + new_anim
		MOVE_STATE.STANDING : 	temp_anim = "Stand" + new_anim
		MOVE_STATE.JUMPING : 	temp_anim = "Jump" + new_anim
		MOVE_STATE.FALLING : 	temp_anim = "Jump" + new_anim
		MOVE_STATE.WALKING : 	temp_anim = "Walk" + new_anim
		MOVE_STATE.RUNNING : 	temp_anim = "Run" + new_anim

		#BUG? this means dash moves will come out while backdashing as well as forward dashing
		MOVE_STATE.DASHING :	temp_anim = "Dash" + new_anim 


	if temp_anim in sprite_library or temp_anim in animation_player_library:
		return temp_anim
	elif new_anim in sprite_library or new_anim in animation_player_library:
		return new_anim
	else:
		#HACK Decide how to handle
		temp_anim = "Stand" + new_anim
		if temp_anim in sprite_library or temp_anim in animation_player_library:
			return temp_anim
		else: # new_anim in sprite_library or new_anim in animation_player_library
			return new_anim
#endregion


#region animation_completed()
func animation_completed():
	#THE TRANSITIONAL ANIMATIONS
	var move_state_change = false
	#
	if anim_state_ == ANIMATION_STATE.DAMAGED:
		damage_state_ = DAMAGE_STATE.IDLE

	#if turning state, change horizontal state
	if anim_state_ == ANIMATION_STATE.TURNING:
		horizontal_state_ *= -1 #FLIP SIDE
		emit_signal("turn_sprite")

	#RunStart
	else:
		move_state_change = true
		match anim_state_:
			ANIMATION_STATE.RUN_START:		move_state_ = MOVE_STATE.RUNNING
			ANIMATION_STATE.RUN_STOP:		move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.CROUCH_DOWN:	move_state_ = MOVE_STATE.CROUCHING
			ANIMATION_STATE.STAND_UP:		move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.BACKDASHING:	move_state_ = MOVE_STATE.STANDING
			ANIMATION_STATE.DASHING: 		move_state_ = MOVE_STATE.RUNNING #HACK
			ANIMATION_STATE.IDLE: 			move_state_change = MOVE_STATE.STANDING
			_: move_state_change = false

	anim_state_ = ANIMATION_STATE.IDLE


	if move_state_change:
		change_move_state(move_state_)
	else: 
		evaluate_state_change(anim_state_, "ANIMATION")
#endregion

func get_new_animation():
	return current_animation
