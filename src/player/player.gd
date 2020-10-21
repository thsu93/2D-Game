class_name Player
extends Actor


signal selected_move_changed(cur_move_num)
signal player_died

#TODO: PRIORITY SYSTEM FOR ANIMATIONS
#TODO ADJUST MIDAIR SPEED, AIR DEACCEL, MOVE AWAY FROM HARD STOP 
const WALK_ACCEL = 450.0
const WALK_DEACCEL = 3500.0
const MAX_VELOCITY = 200.0
const WALK_VELOCITY = 125.0
const JUMP_VELOCITY = 500
const STOP_JUMP_FORCE = 450.0
const DASH_SPEED = 300
const DASH_MAX = 2

const FLOOR_DETECT_DISTANCE = 20.0

const BUFFER_MAX = 10

var stopping_jump = false
var slow_time = 0

onready var camera = $Camera
onready var platform_detector = $PlatformDetector
onready var attack_hitbox = $Sprite/Hitbox
onready var hitspark = $Sprite/Hitbox/Hitspark



var floor_h_velocity = 0.0

var airborne_time = 0

var attack_data

var buffer_length = 0
var buffered_movements = []
var held_buffer = false

var dash_count = 0


func _init():
	actor_type = "player"

func _ready():

	no_grav = false

	current_animation = "StandIdle"
	sprite.playing = true
	sprite.animation = current_animation

	self.scale.x = -1
	sprite.speed_scale = 3
	animation_player.playback_speed = 1.5

	char_data.sprite_library = sprite.frames.get_animation_names()
	char_data.animation_player_library = animation_player.get_animation_list()


#Priority in calculations:
#If in locked animations (dash, attacks, dodges)
#If turning
#If in air, calculate jump/fall
#If not, crouching?
#If not crouch, calculate walk or run

#PROCESS INPUT + CALCULATE PHYSICS
#region 
#TODO Ability to save movement state + data (speed, etc.) ?
#TODO Refactor code to use input buffer rather than repeat move checks
#TODO deal with uncancellable+movement_locked
#probably change to all input locked vs just movement locked
func _physics_process(delta):

	if Input.is_action_pressed("slow_time_debug"):
		slow_time += delta

	#if there is any slowed-down time, add delta to the slow timer
	time_slow(delta)

	#TODO INSERT DEATH CODE HERE
	#HACK THIS IS NOT GOOD CODING PRACTICE
	if not char_data.damage_state_ == char_data.DAMAGE_STATE.DEAD:
		# Get the controls.
		var dashing = Input.is_action_just_pressed("dash")

		#Can likely get rid of these commands given 
		var move_left = Input.is_action_pressed("move_left")
		var move_right = Input.is_action_pressed("move_right")
		var jump = Input.is_action_pressed("jump")
		var crouch = Input.is_action_pressed("crouch")

		check_change_move()

		#BUG DOES NOT DETECT IS ON FLOOR IF MID-ANIMATION
		#Player will slide along floor 
		#ATTACKING

		#TODO How to get immediate moves out (e.g. dashing moves to come out immediately)
		#TODO buffer move inputs
		#BUG? moves do not come out when going through transitional state animations
		#BUG Attacking during the crouchdown/stand up animations is a bit janky
		#Currently, pass in a movement vector, then the animation player will tell the char when to start playing it
		#Different types of cancel? 

		#HACK This deals with trying to attack during damage state idle, but probably not the best.
		#Should add something within Char_data to force unbreakable damage state
		if not char_data.damage_state_ == char_data.DAMAGE_STATE.IDLE:
			char_data.uncancellable = true

		#check attacks and dashing
		if not char_data.uncancellable:
			check_new_attack()

			if char_data.anim_state_ == char_data.ANIMATION_STATE.ATTACKING:
				#if want to have moves that are non-effected by gravity may need to reconsider
				#However, those can likely handle themselves in the animation player or add to attack data
				if no_grav == true:
					no_grav = false
				if not attack_data.running_type:
					decelerate(delta)

			if dashing:
				#HACK should determine if dashing in "facing" direction vs not
				#TODO: Decide what optimal controls are here
				dash_count += 1
				if dash_count <= DASH_MAX:
					if (move_left and char_data.horizontal_state_ == -1) or (move_right and char_data.horizontal_state_ == 1):
						char_data.change_anim_state(char_data.ANIMATION_STATE.DASHING)
					else:
						char_data.change_anim_state(char_data.ANIMATION_STATE.BACKDASHING)
					
		
		#If not in special state
		#TODO this is a bad wayof handling this interaction
		#You should do better later
		if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
			
			# Update sidedness, give a bit of error room 
			check_side(move_left, move_right)
			
			#Obtain directional input buffers
			check_buffer()
			update_movements(delta)
			
			#Process jump/fall	
			if not is_on_floor():
				check_falling(delta, jump)

			if is_on_floor():

				airborne_time = 0
				dash_count = 0

				if char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
					char_data.change_move_state(char_data.MOVE_STATE.STANDING)
				

				if crouch:
					check_crouch(delta)

				elif not crouch:
					# Process logic when character is on floor.
					if jump:
						_velocity.y = -JUMP_VELOCITY
						char_data.change_move_state(char_data.MOVE_STATE.JUMPING)
						stopping_jump = false

					# old movement update location
					# update_movements(delta)
					
					#CORRECT FOR THE LAG TIME OF IS_ON_FLOOR() IF CHAR HAS JUST ENTERED THE AIR
					if not jump:
						check_move_anim()
						
		#TODO: Calculate move velocity allowing for:
			#DASHING
			#ATTACKING

		if not movement_locked:
			# Unsure how to resolve this issue. Change to feature? unclear 
			# WILL SLIDE DOWN SLOPES, UNSURE IF DESIRED IMPLEMENTATION.
			var snap_vector = Vector2.DOWN * 16 if (is_on_floor() and not jump) else Vector2.ZERO
			_velocity = move_and_slide_with_snap(
				_velocity, snap_vector, FLOOR_NORMAL, false, 2, 0.9, false
				)
		
		#BUG WILL NOT WORK IF EXTERNAL_MOVEMNT_DATA IS 0
		else: #if the player input is locked out
			external_movement(external_movement_data, remaining_animation_time, delta)
	#endregion



#region MOVEMENT BUFFER PROCESSSING

func get_buttons_pressed():
	var new_input = 5
	if Input.is_action_pressed("move_right"):
		if Input.is_action_pressed("move_left"):
			new_input = 5
		elif Input.is_action_pressed("crouch"):
			new_input = 3
		elif Input.is_action_pressed("jump"):
			new_input = 9
		else:
			new_input = 6
	elif Input.is_action_pressed("move_left"):
		if Input.is_action_pressed("crouch"):
			new_input = 1
		elif Input.is_action_pressed("jump"):
			new_input = 7
		else:
			new_input = 4
	elif Input.is_action_pressed("crouch"):
		if Input.is_action_pressed("jump"):
			new_input = 5
		else:
			new_input = 2
	elif Input.is_action_pressed("jump"):
		new_input = 8
	return new_input

func check_buffer():
	var new_move = get_buttons_pressed()
	buffered_movements.append(new_move)
	check_held()
	if buffered_movements.size() > BUFFER_MAX:
		buffered_movements.remove(0)

#Check if still running, preserving if character is jumping while running
func check_held():
	#If more than two movements stored in buffer that do not match
	if buffered_movements.size() > 2 and not buffered_movements[-1] == buffered_movements[-2]:
		#If the mismatch is not resulting from a jump
		if not ((buffered_movements[-1] in [4,7] and buffered_movements[-2] in [4,7]) 
			or (buffered_movements[-1] in [6,9] and buffered_movements[-2] in [6,9])):
			held_buffer = false

func update_movements(delta):
	if buffered_movements.size() > 1:
		if buffered_movements[-1] == 4:
			if check_run([4,5,4]) or held_buffer:
				_velocity.x = -MAX_VELOCITY
			else:
				_velocity.x = -WALK_VELOCITY
			# if _velocity.x > -MAX_VELOCITY:
			# 	_velocity.x -= WALK_ACCEL * delta
			# else:
			# 	_velocity.x += WALK_DEACCEL * 2 * delta
		elif buffered_movements[-1] == 6:
			if check_run([6,5,6]) or held_buffer:
				_velocity.x = MAX_VELOCITY
			else:
				_velocity.x = WALK_VELOCITY
		elif buffered_movements[-1] == 5:
			decelerate(delta)

func decelerate(delta):
	if is_on_floor():
		var xv = abs(_velocity.x)
		xv -= WALK_DEACCEL * delta
		if xv < 0:
			xv = 0
		_velocity.x = sign(_velocity.x) * xv


func check_run(sequence):
	var found = false
	var temp_buffer = buffered_movements.duplicate(true)
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
		held_buffer = true
		#Clear the buffer. May have to revist this later for more complex inputs. 
		flush_buffer()
	return found
	pass

func flush_buffer():
	buffered_movements = []
#endregion

#TODO try to improve this so it can be usued in base Actor script	
func check_side(move_left, move_right):
	if _velocity.x < 0.5 and move_left and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.R):
		char_data.change_horiz_state(char_data.HORIZONTAL_STATE.L)
	
	if _velocity.x > -0.5 and move_right and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.L):
		char_data.change_horiz_state(char_data.HORIZONTAL_STATE.R)


#Check if player is swapping moves		
func check_change_move():
	
	var scroll_up = Input.is_action_just_released("scroll_up")
	var scroll_down = Input.is_action_just_released("scroll_down")

	var temp_num = char_data.cur_move_num

	if scroll_down:
		char_data.select_next_move()
		slow_time += .1

	if scroll_up:
		char_data.select_prev_move()
		slow_time += .1

	if not char_data.cur_move_num == temp_num:
		emit_signal("selected_move_changed", char_data.cur_move_num)
	

#BUG gets stuck in attack animation sometimes after taking damage
#unclear how this happens, need to reproduce	
#Should find a way to incorporate this + dash into the move buffer
#TODO Better way to handle crouching vs standing vs dashing vs jumping etc.
func check_new_attack():
	
	var lclick = Input.is_action_just_pressed("lclick")
	var rclick = Input.is_action_just_pressed("rclick")

	var matching_move_state = false

	if lclick or rclick:
		#Did the player click R or L
		char_data.select_attack(rclick)

		attack_data = char_data.get_move_data()

		#match player move state to check if can perform the move
		match char_data.move_state_:
			char_data.MOVE_STATE.CROUCHING: matching_move_state = attack_data.crouch_type
			char_data.MOVE_STATE.JUMPING: matching_move_state = attack_data.air_type
			char_data.MOVE_STATE.FALLING: matching_move_state = attack_data.air_type
			#char_data.MOVE_STATE.DASHING: matching_move_state = attack_data.dashing_type
			#BUG this does not let moves cancel out of dash. removed. Unsure if this will have significant impact on Dash-type moves
			_: matching_move_state = true


		if matching_move_state:

			if airborne_time > .1:
				#HACK force into idle
				char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
				char_data.change_move_state(char_data.MOVE_STATE.FALLING)

			char_data.change_anim_state(char_data.ANIMATION_STATE.ATTACKING)

			slow_time = 0

			if not attack_data.running_type and not (attack_data.dashing_type and char_data.move_state_ == char_data.MOVE_STATE.DASHING):
				speed_reset()


#Check to see if char is falling or not
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

func check_crouch(delta):
	if char_data.move_state_ == char_data.MOVE_STATE.CROUCHING:
		if abs(_velocity.x) > 0:
			var deaccel = WALK_DEACCEL * delta * 5
			var new_velocity = _velocity.x - deaccel if _velocity.x - deaccel > 0 else 0
			_velocity.x = new_velocity
	else:
		char_data.change_move_state(char_data.MOVE_STATE.CROUCHING)

#Check whether run or 
func check_move_anim():
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


#HACK this should be fixed to a reasonable system
func speed_reset():
	if not (char_data.move_state_ == char_data.MOVE_STATE.JUMPING or char_data.move_state_ == char_data.MOVE_STATE.FALLING):
		_velocity.x = 0

#SIGNALS FROM GAMESTATE CHANGES
#region 
func _on_Sprite_animation_finished():
	#HACK reset speeds shouldn't be like this
	if not current_animation in animation_player.get_animation_list():
		if current_animation =="Backdash":
			speed_reset()
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

func _on_Hitbox_body_shape_entered(_body_id, body, _body_shape, _area_shape):
	if body.get_class() == "Actor" and body.actor_type == "enemy":

		# body.stunned = true

		#HITSTOP
		OS.delay_msec(25)

		#HACK hitspark, needs improvement
		var hit_pos = get_collision_position(body)
		emit_hitspark(hit_pos)

		#HACK flip enemy to face 
		if (hit_pos.x - self.global_position.x) * body.char_data.horizontal_state_> 0:
			body.flip_actor() 

		screenshake(attack_data.screenshake_duration, attack_data.screenshake_amp)

		#HACK TEMPORARY KNOCKBACK CALC
		attack_data.knockback_dir = Vector2(char_data.horizontal_state_ * abs(attack_data.knockback_dir.x), attack_data.knockback_dir.y)
		body.take_damage(attack_data.get_hit_var())
		slow_time += attack_data.slow_time


#HACK hitspark location calculation
#Uses the average position between the attack hitbox and the target hurtbox.  Not ideal way to calculate. 
#Ideal would probably be find both hitbox+hurtbox position and extents, calculate the overlapped regions and then find the middle of the overlapped region
func get_collision_position(body):
	var body_area_pos = body.get_node("CollisionShape2D").global_position
	var self_body_pos = $Sprite/Hitbox/CollisionShape2D.global_position
	return (body_area_pos + self_body_pos) / 2


#Emit a hitspark sprite at the given position		
func emit_hitspark(hit_pos):
	#Find where the hitspark should be located
	hitspark.global_position = hit_pos
	hitspark.visible = true
	hitspark.frame = 0
	hitspark.scale.x = abs(hitspark.scale.x) * char_data.horizontal_state_
	hitspark.play(attack_data.hitspark)


func _on_Hitspark_animation_finished():
	hitspark.visible = false
#endregion


#HACK current means of playing with time manipulation
#TODO improve overall time-slow situation

func time_slow(delta):
	if slow_time > 0:
		Engine.time_scale = .1
		slow_time -= delta
	else:
		Engine.time_scale = 1
		slow_time = 0
	
func get_HP():
	return char_data.HP

func get_max_HP():
	return char_data.max_HP
