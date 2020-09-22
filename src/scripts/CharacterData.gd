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
	TURNING,
	CROUCH_DOWN,
	STAND_UP,
	RUN_START,
	RUN_STOP,
	ATTACKING,
	BLOCKING,
	DODGING,
	DISABLED, #TODO NECESSARY?
	};

enum DAMAGE_STATE{
	IDLE,
	HIT,
	COUNTERHIT,
	INVULN,
}

enum HORIZONTAL_STATE{
	L = 1,
	R = -1,
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
	TRANSITIONING,
}

var anim_state_ = ANIMATION_STATE.IDLE
var cur_anim_state = anim_state_

var damage_state_ = DAMAGE_STATE.IDLE
var cur_damage_state_ = damage_state_

var horizontal_state_ = HORIZONTAL_STATE.R
var cur_horizontal_state_ = horizontal_state_

var move_state_ = MOVE_STATE.STANDING
var cur_move_state_ = move_state_
#endregion


#ATTACK DATA
#HACK, rewrite this for more complexity later
var cur_attack = null
var cur_attack_name = "Jab"

#ANIMATIONS CONTAINED WITHIN CHAR
var sprite_library
var animation_player_library
var current_animation = "StandIdle"

#CHARACTER HP DATA
var HP = 5
export(int) var max_HP = 5


#HACK perhaps not needed
export(bool) var cancellable = false



func _ready():
	HP = max_HP

# func _process(_delta):
# 	#TODO MAKE A STATE PRIORITIZATION FUNCTION
# 	#DEPRECATED?
# 	# if not anim_state_ == cur_anim_state:
# 	# 	emit_signal("anim_state_change", anim_state_)
# 	# 	cur_anim_state = anim_state_

# 	# if not horizontal_state_ == cur_horizontal_state_ :
# 	# 	emit_signal("horizontal_state_change", horizontal_state_)
# 	# 	cur_horizontal_state_ = horizontal_state_

# 	# if not move_state_ == cur_move_state_  :
# 	# 	emit_signal("move_state_change", move_state_ )
# 	# 	cur_move_state_ = move_state_ 

# 	# if not damage_state_ == cur_damage_state_:
# 	# 	emit_signal("damage_state_change", damage_state_)
# 	# 	cur_damage_state_ = damage_state_



func take_damage(dmg):
	if not damage_state_ == DAMAGE_STATE.INVULN:
		match (anim_state_):
			ANIMATION_STATE.DASHING:
				pass
			ANIMATION_STATE.ATTACKING:
				HP -= dmg	#Should some sort of multiplier?
				damage_state_ = DAMAGE_STATE.COUNTERHIT
				emit_signal("damage_state_change", damage_state_)
				#multiplied damage
			#STATE.BLOCKING:
				#reduced damage
			_:
				HP -= dmg
				damage_state_ = DAMAGE_STATE.HIT
				emit_signal("damage_state_change", damage_state_)
		if HP <= 0:
			emit_signal("dead")
			

#TODO: What does this do?
func toggle_invuln():
	if damage_state_ == DAMAGE_STATE.INVULN:
		damage_state_ = DAMAGE_STATE.IDLE
	else: 
		damage_state_ = DAMAGE_STATE.INVULN


#region change_horiz_state
func change_horiz_state(dir):
	#if trying to turn to the direction already facing
	if (dir == "L" and horizontal_state_ == 1) or (dir == "R" and horizontal_state_ == -1):
		#ignore 
		pass
	else:
		#try to start turn animation
		var new_state = HORIZONTAL_STATE.R
		if dir == "L":
			new_state = HORIZONTAL_STATE.L
		elif dir == "R":
			new_state = HORIZONTAL_STATE.R
		evaluate_state_change(new_state, "HORIZONTAL")
		#anim_state_ = ANIMATION_STATE.TURNING
		update_current_animation()
#endregion

#change mvmt state
#TODO should add landing frames
func change_move_state(new_state):
	#if not move_state_ == MOVE_STATE.JUMPING and not move_state_ == MOVE_STATE.FALLING:
	#should be checked in player via on_floor
	#unsure how to handle better

	# if new_state == "Crouch":
	# 	if move_state_ == MOVE_STATE.CROUCHING:
	# 		pass
	# 	else:
	# 		anim_state_=ANIMATION_STATE.CROUCH_DOWN
	# elif new_state == "Run":
	# 	if not move_state_ == MOVE_STATE.RUNNING:

	match new_state:
		"Crouch" : new_state = MOVE_STATE.CROUCHING
		"StandIdle": new_state = MOVE_STATE.STANDING
		"Jump" : new_state = MOVE_STATE.JUMPING
		"Fall" : new_state = MOVE_STATE.FALLING
		"Walk" : new_state = MOVE_STATE.WALKING
		"Run" : new_state = MOVE_STATE.RUNNING

	if not new_state == move_state_:
		evaluate_state_change(new_state, "MOVEMENT")

#change dmg state 

#change animation state
#HACK should handle this more cleanly
func change_anim_state(new_state, move_name = ""):
	if new_state == "Dash":
		evaluate_state_change(ANIMATION_STATE.DASHING, "ANIMATION")
	if new_state == "Backdash":
		evaluate_state_change(ANIMATION_STATE.BACKDASHING, "ANIMATION")
	if new_state == "Attack":
		cur_attack_name = move_name
		evaluate_state_change(ANIMATION_STATE.ATTACKING, "ANIMATION")
		
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
			move_state_ = MOVE_STATE.DASHING

		elif new_state == ANIMATION_STATE.ATTACKING:
			anim_state_ = ANIMATION_STATE.ATTACKING
			print("Attacking")
			print(cur_attack_name)

	if anim_state_ == ANIMATION_STATE.IDLE:
		#start turn
		if state_changed == "HORIZONTAL":
			anim_state_ = ANIMATION_STATE.TURNING
				
		if state_changed == "MOVEMENT":
			
			if new_state == MOVE_STATE.CROUCHING:
				#TODO Check if this will crouch in midair, possibly needs more complex checks
				anim_state_ = ANIMATION_STATE.CROUCH_DOWN

			if new_state == MOVE_STATE.STANDING:

				if move_state_ == MOVE_STATE.CROUCHING:
					anim_state_ = ANIMATION_STATE.STAND_UP

				elif move_state_ == MOVE_STATE.RUNNING:
					anim_state_ = ANIMATION_STATE.RUN_STOP

				else:
					move_state_ = MOVE_STATE.STANDING

			if new_state == MOVE_STATE.JUMPING:
				move_state_ = MOVE_STATE.JUMPING
				pass #Should not require any changes to the animation state
			
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


#region update_current_animation 
func update_current_animation():

	var new_anim = current_animation

	if not damage_state_ == DAMAGE_STATE.IDLE:
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
		new_anim = cur_attack_name

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
		new_anim = cur_attack_name
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
	
	if not new_anim == current_animation: #probably redundant check
		print(new_anim)
		if new_anim in animation_player_library:
			emit_signal("play_animation", new_anim)
			current_animation = new_anim
		elif new_anim in sprite_library:
			emit_signal("new_sprite_animation", new_anim)
			current_animation = new_anim
		else:
			print("ERROR ANIMATION NOT IN LIBRARY: ", new_anim)

#endregion

func match_vert_state(new_anim):
	var temp_anim = new_anim
	match move_state_:
		MOVE_STATE.CROUCHING : temp_anim = "Crouch" + new_anim
		MOVE_STATE.STANDING : temp_anim = "Stand" + new_anim
		MOVE_STATE.JUMPING : temp_anim = "Jump" + new_anim
		MOVE_STATE.FALLING : temp_anim = "Fall" + new_anim
		MOVE_STATE.WALKING : temp_anim = "Walk" + new_anim
		MOVE_STATE.RUNNING : temp_anim = "Run" + new_anim
		MOVE_STATE.DASHING : temp_anim = "Dash" + new_anim

	if temp_anim in sprite_library or temp_anim in animation_player_library:
		return temp_anim
	elif new_anim in sprite_library or new_anim in animation_player_library:
		return new_anim
	else:
		#HACK Decide how to handle
		temp_anim = "Stand" + new_anim
		if temp_anim in sprite_library or temp_anim in animation_player_library:
			return temp_anim
		elif new_anim in sprite_library or new_anim in animation_player_library:
			return new_anim
		else:
			return new_anim


#region animation_completed()
func animation_completed():
	#THE TRANSITIONAL ANIMATIONS
	#if turning state, change horizontal state
	if anim_state_ == ANIMATION_STATE.TURNING:
		horizontal_state_ *= -1 #FLIP SIDE
		emit_signal("turn_sprite")

	#RunStart
	if anim_state_ == ANIMATION_STATE.RUN_START:
		move_state_ = MOVE_STATE.RUNNING

	#RunStop
	if anim_state_ == ANIMATION_STATE.RUN_STOP:
		move_state_ = MOVE_STATE.STANDING

	#CrouchDown
	if anim_state_ == ANIMATION_STATE.CROUCH_DOWN:
		move_state_ = MOVE_STATE.CROUCHING

	#StandUp
	if anim_state_ == ANIMATION_STATE.STAND_UP:
		move_state_ = MOVE_STATE.STANDING

	if anim_state_ == ANIMATION_STATE.BACKDASHING:
		move_state_ = MOVE_STATE.STANDING

	anim_state_ = ANIMATION_STATE.IDLE
	evaluate_state_change(anim_state_, "ANIMATION")
#endregion

func get_new_animation():
	return current_animation
