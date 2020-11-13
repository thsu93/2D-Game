class_name Player
extends Actor

#If scrolled, tell the UI element to scroll via a signal to the game manager
signal selected_move_changed(cur_move_num)

#Inform the game manager that the player has died
#Currently unused, as no death behavior.
signal player_died


signal time_slowed
signal time_unslowed


const WALK_ACCEL = 450.0
const WALK_DECEL = 700.0
const WALK_VELOCITY = 125.0
const MAX_VELOCITY = 200.0

const JUMP_VELOCITY = 450
const STOP_JUMP_FORCE = 450.0


const DASH_SPEED = 300
const DASH_MAX = 2


const GUARD_SPEED_MODIFIER = .25 


const FLOOR_DETECT_DISTANCE = 20.0

const MAX_BUFFER_SIZE = 10

const SWAP_SLOW_TIME = .25
const BASE_TIME_SLOW = .4

#Tracks when player lets go of jump button
var stopping_jump = false

#Counter that counts how long player is off the ground
var airborne_time = 0


#links to nodes
onready var camera = $Camera
onready var platform_detector = $PlatformDetector
onready var parry_box = $Sprite/ParryBox




#movement buffer of size MAX_BUFFER_SIZE
#Movement is represented with numpad notation (1-9)
var mvmt_buffer = []

#command buffer of size MAX_BUFFER_SIZE
#Commands are represented as 1:Dash, 2:R Click, 3:L Click, 4:Parry
var cmd_buffer = []

#Length of the current mvmt_buffer
var buffer_length = 0

#Holds whether the player has started their run animation
#Used to track that player is still in running once the running input in the buffer has been emptied
#Questionable implementation
var held_run = false

#Use to track how many dashes the player has used
#Resets when on ground
#Maximum value is DASH_MAX
var dash_count = 0


#Timer of how much timeslow remains
var slow_time = 0

#Set player actor type before Actor class calculates it
func _init():
	actor_type = "player"


func _ready():

	self.scale.x = -1
	sprite.speed_scale = 3
	animation_player.playback_speed = 1.5


	#HACK
	char_data.select_attack(false)
	attack_data = char_data.get_move_data()


#TODO: Idea of Time Freeze as Roman Cancel

#Priority in animation calculations:
#If in locked animations (dash, attacks, dodges)
#If turning
#If in air, calculate jump/fall
#If not, crouching?
#If not crouch, calculate walk or run

#PROCESS INPUT + CALCULATE PHYSICS
#region 
#TODO Refactor code to use input mvmt_buffer rather than repeat move checks
func _physics_process(delta):

	if not char_data.damage_state_ == char_data.DAMAGE_STATE.DEAD:
		#TODO Remove this when finished with 
		if Input.is_action_pressed("slow_time_debug"):
			slow_time += delta

		#ROMAN CANCEL, ESSENTIALLY
		#HACK PLACEHOLDER 
		if Input.is_action_just_pressed("slow_time_command") and slow_time == 0:
			slow_time = .5
			char_data.HP -= 10
			char_data.uncancellable = false 
			reset_all_hitboxes()
			#OH BOY THATS GONNA CAUSE BUGS

		elif Input.is_action_just_pressed("slow_time_command") and slow_time > 0:
			char_data.HP += 10*slow_time
			slow_time = 0

		#if there is any slowed-down time, add delta to the slow timer
		time_slow(delta)

		var jump = Input.is_action_pressed("move_up")

		check_swap_move()

		#ATTACKING

		#TODO How to get immediate moves out (e.g. dashing moves to come out immediately)
		#TODO mvmt_buffer move inputs
		#Currently, pass in a movement vector, then the animation player will tell the char when to start playing it
		#Different types of cancel? 

		#HACK This deals with trying to attack during damage state idle, but probably not the best.
		#Should add something within Char_data to force unbreakable damage state
		if not char_data.damage_state_ == char_data.DAMAGE_STATE.IDLE:
			char_data.uncancellable = true

		

		#Obtain directional input buffers
		check_buffer()


		#check dashing, attacking, and parrying
		check_start_dash()
		check_new_attack()
		check_parry()

		# Update sidedness, give a bit of error room 
		check_side()

		update_movements(delta)

		update_move_anim(delta)

		#TODO: Calculate move velocity allowing for:
			#DASHING
			#ATTACKING
		if char_data.anim_state_ == char_data.ANIMATION_STATE.ATTACKING:
			#if want to have moves that are non-effected by gravity may need to reconsider
			#However, those can likely handle themselves in the animation player or add to attack data
			if no_grav == true:
				no_grav = false
			if not attack_data.running_type:
				decelerate(delta)
		elif char_data.anim_state_ == char_data.ANIMATION_STATE.PARRYING or char_data.anim_state_  == char_data.ANIMATION_STATE.GUARDING:
			decelerate(delta)

		#If the player is being moved by external forces, use that function.
		#Else, use the players movement
		if movement_locked:
			external_movement(external_movement_data, remaining_animation_time, delta, no_grav_during_move)
				
		else: #if the player input is locked out
			var snap_vector = Vector2.DOWN * 16 if (is_on_floor() and not jump) else Vector2.ZERO

			_velocity = move_and_slide_with_snap(
				_velocity, snap_vector, FLOOR_NORMAL, false, 2, 0.9, false
				)

					
		
	#endregion

#If dash command is within the input buffer, initiate character dashing
func check_start_dash():
	if not char_data.uncancellable:
		if 1 in cmd_buffer:
			#TODO: Decide what optimal controls are here re: backdashing
			dash_count += 1

			if dash_count <= DASH_MAX:
				if (mvmt_buffer[-1]==4 and char_data.horizontal_state_ == -1) or (mvmt_buffer[-1]==6 and char_data.horizontal_state_ == 1):
					char_data.change_anim_state(char_data.ANIMATION_STATE.DASHING)
					_velocity.x = char_data.horizontal_state_ * MAX_VELOCITY
				else:
					char_data.change_anim_state(char_data.ANIMATION_STATE.BACKDASHING)
					_velocity.x = -1 * char_data.horizontal_state_ * MAX_VELOCITY

			flush_buffer(false, true)


#region MOVEMENT mvmt_buffer PROCESSSING

#update movements, etc.
func check_buffer():
	var new_mvmt = get_dir_buttons_pressed()
	var new_cmd = get_command_inputs()
	mvmt_buffer.append(new_mvmt)
	cmd_buffer.append(new_cmd)
	check_run_buffered()
	if mvmt_buffer.size() > MAX_BUFFER_SIZE:
		mvmt_buffer.remove(0)
	if cmd_buffer.size() > MAX_BUFFER_SIZE:
		cmd_buffer.remove(0)

#gets the player input at the current moment in terms of numpad-notation
func get_dir_buttons_pressed():
	var new_input = 5
	if Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			new_input = 5
		elif Input.is_action_pressed("move_down"):
			new_input = 3
		elif Input.is_action_pressed("move_up"):
			new_input = 9
		else:
			new_input = 6
	elif Input.is_action_pressed("move_left"):
		if Input.is_action_pressed("move_down"):
			new_input = 1
		elif Input.is_action_pressed("move_up"):
			new_input = 7
		else:
			new_input = 4
	elif Input.is_action_pressed("move_down"):
		if Input.is_action_pressed("move_up"):
			new_input = 5
		else:
			new_input = 2
	elif Input.is_action_pressed("move_up"):
		new_input = 8
	return new_input

	
#Check if character is still running, preserving if character is jumping in the forward direction while running
func check_run_buffered():
	#If more than two movements stored in mvmt_buffer that do not match
	if mvmt_buffer.size() > 2 and not mvmt_buffer[-1] == mvmt_buffer[-2]:
		#If the mismatch is not resulting from a directional jump
		if not ((mvmt_buffer[-1] in [4,7] and mvmt_buffer[-2] in [4,7]) 
			or (mvmt_buffer[-1] in [6,9] and mvmt_buffer[-2] in [6,9])):
			held_run = false

func update_movements(delta):
	if not char_data.uncancellable and char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
		if mvmt_buffer.size() > 1:
			if mvmt_buffer[-1] == 4 or mvmt_buffer[-1] == 7:
				if check_run([4,5,4]) or held_run:
					_velocity.x = -MAX_VELOCITY
				else:
					_velocity.x = -WALK_VELOCITY
			elif mvmt_buffer[-1] == 6 or mvmt_buffer[-1] == 9:
				if check_run([6,5,6]) or held_run:
					_velocity.x = MAX_VELOCITY
				else:
					_velocity.x = WALK_VELOCITY
			elif mvmt_buffer[-1] == 5:
				decelerate(delta)

func decelerate(delta, mod = 1):
	# if is_on_floor():
	# 	var xv = abs(_velocity.x)
	# 	xv -= WALK_DECEL * delta
	# 	if xv < 0:
	# 		xv = 0
	# 	_velocity.x = sign(_velocity.x) * xv

	if abs(_velocity.x) > 0 and is_on_floor():
		var decel = WALK_DECEL * delta * mod
		var new_velocity = abs(_velocity.x) - decel
		var decel_velocity = char_data.horizontal_state_ * new_velocity if new_velocity > 0 else 0
		_velocity.x = decel_velocity


func check_run(sequence):
	var found = false
	var temp_buffer = mvmt_buffer.duplicate(true)
	var count = sequence.size()
	if temp_buffer.size() > sequence.size():
		for i in sequence:
			var pos = temp_buffer.find(i)
			if pos != -1:
				count -= 1
				temp_buffer = temp_buffer.slice(pos+1, temp_buffer.size()-1)
			else:
				return false
	if count == 0:
		found = true
		held_run = true
		#Clear the mvmt_buffer. May have to revist this later for more complex inputs. 
		# flush_buffer()
	return found
	pass

#Evaluates which side the player is currently on, and turns the player when 
func check_side():
	var side_left = mvmt_buffer.size() > 0 and mvmt_buffer[-1] in [1,4,7]
	var side_right = mvmt_buffer.size() > 0 and mvmt_buffer[-1] in [3,6,9]

	if char_data.anim_state_== char_data.ANIMATION_STATE.IDLE:
		if _velocity.x < 0.5 and side_left and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.R):
			char_data.change_horiz_state(char_data.HORIZONTAL_STATE.L)
		
		if _velocity.x > -0.5 and side_right and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.L):
			char_data.change_horiz_state(char_data.HORIZONTAL_STATE.R)


#clear buffers
#will clear both by default
#can override to clear only one
func flush_buffer(clear_mvmt = true, clear_cmd = true):
	if clear_mvmt:
		mvmt_buffer = []
	if clear_cmd:
		cmd_buffer = []
#endregion


#region cmd_buffer checks

#Check if player is swapping moves via the scroll wheel
#Is not a part of the buffer system
#Successful move change will slow the game down for SWAP_SLOW_TIME (.25) seconds
func check_swap_move():
	
	var scroll_up = Input.is_action_just_released("swap_up")
	var scroll_down = Input.is_action_just_released("swap_down")

	var temp_num = char_data.cur_move_num

	if scroll_down:
		char_data.select_next_move()

	if scroll_up:
		char_data.select_prev_move()

	if not char_data.cur_move_num == temp_num:
		emit_signal("selected_move_changed", char_data.cur_move_num)
		slow_time = SWAP_SLOW_TIME


func get_command_inputs():
	var dash = Input.is_action_just_pressed("dash")
	var lclick = Input.is_action_just_pressed("lclick")
	var rclick = Input.is_action_just_pressed("rclick")

	var input = 0
	if dash:
		input = 1
	elif rclick:
		input = 2
	elif lclick:
		input = 3
	
	return input

	pass
	# cmd_buffer

	#check parry, check attack, check dash


#unclear how this happens, need to reproduce
#Should find a way to incorporate this + dash into the move mvmt_buffer
#TODO Better way to handle crouching vs standing vs dashing vs jumping etc.
func check_new_attack():
	
	var matching_move_state = false

	var rclick = 2 in cmd_buffer
	var lclick = 3 in cmd_buffer


	if not char_data.uncancellable:
		if lclick or rclick:

			#Did the player click R or L
			#R click is of a higher priority
			char_data.select_attack(rclick)

			attack_data = char_data.get_move_data()

			#THIS SHOULD MOVE TO STATE MACHINE

			#match player move state to check if can perform the move
			match char_data.move_state_:
				char_data.MOVE_STATE.CROUCHING: matching_move_state = attack_data.crouch_type
				char_data.MOVE_STATE.JUMPING: matching_move_state = attack_data.air_type
				char_data.MOVE_STATE.FALLING: matching_move_state = attack_data.air_type
				#char_data.MOVE_STATE.DASHING: matching_move_state = attack_data.dashing_type
				_: matching_move_state = true

			if matching_move_state:

				if airborne_time > .1:

					#HACK force into idle
					char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
					char_data.change_move_state(char_data.MOVE_STATE.FALLING)

				char_data.change_anim_state(char_data.ANIMATION_STATE.ATTACKING)

				# slow_time = 0

				if not attack_data.running_type and not (attack_data.dashing_type and char_data.move_state_ == char_data.MOVE_STATE.DASHING):
					speed_reset()

			flush_buffer(false, true)


#Checks to see if player has hit the parry button
#Also then checks to see if 
func check_parry():
	#TODO which states can you cancel into parry from
	if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
		if 1 in mvmt_buffer or 2 in mvmt_buffer or 3 in mvmt_buffer:
			char_data.change_anim_state(char_data.ANIMATION_STATE.PARRYING)
			flush_buffer()
		#TODO THIS DECELERATE FUNCTION IS BAD, IT DOES NOT ALWAYS RUN WHEN IT SHOULD BE DUE TO UNCANCELLABLE NOT CALLING TO THIS FUNCTION ANYMORE

#Check to see if char is jumping/falling
#Will change state if 
func check_falling(delta, jump):
	
	airborne_time += delta

	#Tolerance for 
	if airborne_time > .1:
		if _velocity.y > 0:
			# Set off the jumping flag if going down.			
			char_data.change_move_state(char_data.MOVE_STATE.FALLING)
		elif not jump:
			stopping_jump = true
		
		if stopping_jump:
			_velocity.y += STOP_JUMP_FORCE * delta

	if _velocity.y < 0 and mvmt_buffer[-1] in [7,8,9]:
		if char_data.move_state_ == char_data.MOVE_STATE.WALKING:
			char_data.change_move_state(char_data.MOVE_STATE.JUMPING)
	

#Check whether run or walk animation
#based on character movement speed
func update_move_anim(delta):

	if not char_data.uncancellable and char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
		#Did the player push up at all
		var jump = mvmt_buffer.size() > 0 and mvmt_buffer[-1] in [7,8,9]

		if not is_on_floor():
			check_falling(delta, jump)

		if is_on_floor():

			airborne_time = 0
			dash_count = 0

			if char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
				char_data.change_move_state(char_data.MOVE_STATE.STANDING)

			if jump:
				_velocity.y = -JUMP_VELOCITY if not _velocity.y < 0 else _velocity.y - JUMP_VELOCITY 
				char_data.change_move_state(char_data.MOVE_STATE.JUMPING)
				stopping_jump = false

			# old movement update location
			# update_movements(delta)
			
			#CORRECT FOR THE LAG TIME OF IS_ON_FLOOR() IF CHAR HAS JUST ENTERED THE AIR
				# if not jump:
			#CORRECT FOR OVERSPEED
			if abs(_velocity.x) > MAX_VELOCITY:
				_velocity.x = sign(_velocity.x) * MAX_VELOCITY
			#CHANGE ANIMATIONS TO MATCH SPEED
			if abs(_velocity.x) > 5 and abs(_velocity.x) <= WALK_VELOCITY:
				char_data.change_move_state(char_data.MOVE_STATE.WALKING)
			elif abs(_velocity.x) > WALK_VELOCITY and sign(_velocity.x) == char_data.horizontal_state_:
				#CANNOT RUN WHILE MOVING BACKWARDS
				char_data.change_move_state(char_data.MOVE_STATE.RUNNING)
			elif abs(_velocity.x) <= 5 and not char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
				char_data.change_move_state(char_data.MOVE_STATE.STANDING)

#endregion



#SIGNALS FROM GAMESTATE CHANGES
#region 

#animations
#region 
func _on_Sprite_animation_finished():
	#HACK reset speeds shouldn't be like this
	if not current_animation in animation_player.get_animation_list():
		# if current_animation =="Backdash":
		# 	speed_reset()
		char_data.animation_completed()

	# current_animation = char_data.get_new_animation()
	#play_new_sprite()

#Overloaded to clear any external_movement_data
func _on_AnimationPlayer_animation_finished(_anim_name):
	external_movement_data = Vector2()
	remaining_animation_time = 0
	no_grav = false
	char_data.uncancellable = false
	char_data.animation_completed()


	#TODO Fix this and remove it
func force_velocity(new_velocity):
	_velocity = new_velocity



#HACK, NEED TO HAVE A DIFFERENT WAY TO DEAL WITH CANCELLING MOVES
func _on_AnimationPlayer_animation_changed(_anim_name):
	if no_grav == true:
		no_grav = false
	char_data.animation_completed()


#endregion


#attacks
#region 

func _on_Hitbox_area_entered(area):
	if area.get_class() == "Hurtbox" and area.actor_type == "enemy":
		
		var body = area.get_parent()
		# body.stunned = true
		if not body.char_data.damage_state_ == char_data.DAMAGE_STATE.INVULN:
			#HITSTOP
			OS.delay_msec(25)

			#HACK hitspark, needs improvement
			var hit_pos = get_collision_position(body)
			hitbox.emit_hitspark(hit_pos, char_data.horizontal_state_, attack_data.hitspark)

			#HACK flip enemy to face 
			if (hit_pos.x - self.global_position.x) * body.char_data.horizontal_state_> 0:
				body.flip_actor() 

			screenshake(attack_data.screenshake_duration, attack_data.screenshake_amp)

			#HACK TEMPORARY KNOCKBACK CALC
			attack_data.knockback_dir = Vector2(char_data.horizontal_state_ * abs(attack_data.knockback_dir.x), attack_data.knockback_dir.y)
			body.take_damage(attack_data.get_hit_var())
			# slow_time += attack_data.slow_time

			knockback = attack_data.self_knockback * char_data.horizontal_state_ * -1


#TODO Can probably eventually be made generic		
#HACK hitspark location calculation ENTIRELY USSELESS RIGHT NOW
#Uses the average position between the attack hitbox and the target hurtbox.  Not ideal way to calculate. 
#Ideal would probably be find both hitbox+hurtbox position and extents, calculate the overlapped regions and then find the middle of the overlapped region
func get_collision_position(body):
	# var collision_shape = body.hurtbox.get_node("CollisionShape2D")
	# var self_attack_collision_shape = attack_hitbox.get_node("CollisionShape2D")

	# var body_area_pos = collision_shape.global_position
	# var self_body_pos = self_attack_collision_shape.global_position

	# return (body_area_pos + self_body_pos) / 2

	return hitbox.get_node("CollisionShape2D").global_position



func _on_ParryBox_area_entered(area):
	if area.get_class() == "Hitbox":

		var temp_data = area.get_attack_data()
		char_data.HP += temp_data.dmg

		area.disable()
		print("PARRIED")

		hitbox.emit_hitspark(area.global_position, char_data.horizontal_state_, "parry")

		char_data.uncancellable = false
		
		reset_all_hitboxes()
		hurtbox.enable()


	pass # Replace with function body.

#endregion

#endregion

#BUG this is trhowing errors "Can't Change While Flushign Queries"
func reset_all_hitboxes():
	hitbox.shape.disabled = true
	hurtbox.enable()
	parry_box.get_node("CollisionShape2D").disabled = true

#HACK current means of playing with time manipulation
#TODO improve overall time-slow situation

#Slow down time if there is any time_slow, then subtract delta from time_slow amount
#Allows for modified slowdown rates
#Default slowdown is BASE_TIME_SLOW (.4)
func time_slow(delta, slow_mod = BASE_TIME_SLOW):
	if slow_time > 0:
		Engine.time_scale = slow_mod

		#If want things to move in normal time during full slowdown, can multiply their delta by 1/Engine.time_scale
		slow_time -= delta
		emit_signal("time_slowed")
	else:
		Engine.time_scale = 1
		slow_time = 0
		emit_signal("time_unslowed")
	
#HACK this should be fixed to a reasonable system
func speed_reset():
	if not (char_data.move_state_ == char_data.MOVE_STATE.JUMPING or char_data.move_state_ == char_data.MOVE_STATE.FALLING):
		_velocity.x = 0

	
#Getters for the gamemanager

func get_movelist():
	return char_data.get_movelist_names()

func set_movelist(movenames):
	char_data.set_movelist(movenames)


