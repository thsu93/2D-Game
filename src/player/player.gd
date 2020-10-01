class_name Player
extends Actor


#TODO: PRIORITY SYSTEM FOR ANIMATIONS
#TODO ADJUST MIDAIR SPEED, AIR DEACCEL, MOVE AWAY FROM HARD STOP 
const WALK_ACCEL = 450.0
const WALK_DEACCEL = 3500.0
const MAX_VELOCITY = 200.0
const WALK_VELOCITY = 125.0
const JUMP_VELOCITY = 500
const STOP_JUMP_FORCE = 450.0
const DASH_SPEED = 300
const FLOOR_DETECT_DISTANCE = 20.0
const BUFFER_MAX = 10

var current_animation = ""

var siding_left = false
var jumping = false
var stopping_jump = false
var slow_time = 0

#TODO still have to fix platform detection
onready var platform_detector = $PlatformDetector

onready var attack_hitbox = $Sprite/Hitbox
var floor_h_velocity = 0.0

var airborne_time = 0

var attack_data

export var input_locked = false
var external_movement_data = Vector2()
var external_anim_time = 0

var buffer_length = 0
var buffered_movements = []
var held_buffer = false

#HACK TEMPORARY FOR MOVE CHECK, EVENTUALLY SHOULD BE UPDATED OUT OF PLAYERDATA


func _init():
	actor_type = "player"

func _ready():
	current_animation = "StandIdle"
	self.scale.x = -1
	sprite.playing = true
	sprite.speed_scale = 3
	animation_player.playback_speed = 1.5
	char_data.sprite_library = sprite.frames.get_animation_names()
	char_data.animation_player_library = animation_player.get_animation_list()
	print(char_data.animation_player_library)
	print(char_data.sprite_library)
	animation_player.stop()

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
func _physics_process(delta):

	#if there is any slowed-down time, check
	time_slow(delta)

	if not input_locked:

		# Get the controls. 

		var lclick = Input.is_action_just_pressed("lclick")
		var rclick = Input.is_action_just_pressed("rclick")
		
		var dashing = Input.is_action_just_pressed("dash")
		var scroll_up = Input.is_action_just_released("scroll_up")
		var scroll_down = Input.is_action_just_released("scroll_down")

		#Can likely get rid of these commands given 
		var move_left = Input.is_action_pressed("move_left")
		var move_right = Input.is_action_pressed("move_right")
		var jump = Input.is_action_pressed("jump")
		var crouch = Input.is_action_pressed("crouch")

		if scroll_down:
			char_data.select_next_move()
			slow_time += .25

		if scroll_up:
			char_data.select_prev_move()
			slow_time += .25
		
		#PRESERVE CURRENT VELOCITY IF NO INPUTS ARE GIVEN
		_velocity = _velocity

		#BUG DOES NOT DETECT IS ON FLOOR IF MID-ANIMATION

		#ATTACKING

		#TODO Decide how to handle momentum with moves, how to determine to preserve or not.
		#TODO buffer move inputs
		#BUG? moves do not come out when going through transitional state animations
		#BUG Attacking during the crouchdown/stand up animations is a bit janky
		#HACK the way attack movement is handled is incredibly janky and should not be done this way
		#Currently, pass in a movement vector, then the animation player will tell the char when to start playing it

		if not char_data.uncancellable:
			if lclick:
				#TODO ADD DEPTH
				#TODO move buffers?
				char_data.change_anim_state(char_data.ANIMATION_STATE.ATTACKING)
				attack_data = char_data.get_move_data()
				external_movement_data = Vector2(attack_data.direction.x * char_data.horizontal_state_ * -1, attack_data.direction.y) * attack_data.velocity
				external_anim_time = attack_data.anim_time
				slow_time = 0
				#BUG char will slide while stand-jab if not forced into velocity 0

			if rclick:
				char_data.change_anim_state(char_data.ANIMATION_STATE.ATTACKING, true)
				attack_data = char_data.get_move_data()
				external_movement_data = Vector2(attack_data.direction.x * char_data.horizontal_state_ * -1, attack_data.direction.y) * attack_data.velocity
				external_anim_time = attack_data.anim_time
				slow_time = 0

		if char_data.anim_state_ == char_data.ANIMATION_STATE.ATTACKING:
			#if want to have moves that are non-effected by gravity may need to reconsider
			#However, those can likely handle themselves in the animation player
			if no_grav == true:
				no_grav = false
			if not attack_data.running_type:
				decelerate(delta)


		#TODO THIS SNAP VECTOR IS REALLY BAD
		# var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if not is_on_floor() else Vector2.ZERO
		var snap_vector = Vector2.DOWN * 16 if (is_on_floor() and not jump) else Vector2.ZERO
		var is_on_platform = platform_detector.is_colliding()

		#DASH
		#BUG get to run post-dash w/out run-start
		#BUG If dash is cancelled into attack WILL NOT COME OUT OF NO-GRAV STATE
		#BUG Ending backdashing will cause the character to go into running state while still moving backwards.
		#HACK Handling no_grav from animationplayer
		if char_data.anim_state_ == char_data.ANIMATION_STATE.DASHING:
			_velocity.x = -char_data.horizontal_state_ * DASH_SPEED

		elif char_data.anim_state_ == char_data.ANIMATION_STATE.BACKDASHING:
			_velocity.x = char_data.horizontal_state_ * DASH_SPEED
			
		
		#If no special state
		#TODO this is a bad wayof handling this interaction
		#You should do better later
		if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
			
			# Update sidedness, give a bit of error room 
			if _velocity.x < 0.5 and move_left and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.R):
				char_data.change_horiz_state(char_data.HORIZONTAL_STATE.L)
			
			if _velocity.x > -0.5 and move_right and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.L):
				char_data.change_horiz_state(char_data.HORIZONTAL_STATE.R)

			if dashing:
				print("dash start")
				#HACK should determine if dashing in "facing" direction vs not
				#TODO: Decide what optimal controls are here
				if (move_right and char_data.horizontal_state_ == -1) or (move_left and char_data.horizontal_state_ == 1):
					char_data.change_anim_state(char_data.ANIMATION_STATE.DASHING)
				else:
					char_data.change_anim_state(char_data.ANIMATION_STATE.BACKDASHING)
			
			#Obtain directional input buffers
			check_buffer()
			update_movements(delta)
			
			# Process jump.
			if not is_on_floor():
				airborne_time += delta
				if airborne_time > .1:
					if _velocity.y > 0:
						# Set off the jumping flag if going down.				
						char_data.change_move_state(char_data.MOVE_STATE.FALLING)
					elif not jump:
						stopping_jump = true
					
					if stopping_jump:
						_velocity.y += STOP_JUMP_FORCE * delta
			
			#BUG will not update if char never goes to fall_state
			if is_on_floor():
				if char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
					char_data.change_move_state(char_data.MOVE_STATE.STANDING)
				airborne_time = 0
				if crouch:
					if char_data.move_state_ == char_data.MOVE_STATE.CROUCHING:
						if abs(_velocity.x) > 0:
							var deaccel = WALK_DEACCEL * delta * 5
							var new_velocity = _velocity.x - deaccel if _velocity.x - deaccel > 0 else 0
							_velocity.x = new_velocity
					else:
						char_data.change_move_state(char_data.MOVE_STATE.CROUCHING)

				elif not crouch:
					# Process logic when character is on floor.
					if jump:
						_velocity.y = -JUMP_VELOCITY
						char_data.change_move_state(char_data.MOVE_STATE.JUMPING)
						stopping_jump = false

					# old movement update location
					# update_movements(delta)

					#CORRECT FOR OVERSPEED
					if abs(_velocity.x) > MAX_VELOCITY:
						_velocity.x = sign(_velocity.x) * MAX_VELOCITY
					
					#CORRECT FOR THE LAG TIME OF IS_ON_FLOOR() IF CHAR HAS JUST ENTERED THE AIR
					if not jump:
						#CHANGE ANIMATIONS TO MATCH SPEED
						if abs(_velocity.x) > 5 and abs(_velocity.x) <= WALK_VELOCITY:
							char_data.change_move_state(char_data.MOVE_STATE.WALKING)
						elif abs(_velocity.x) > WALK_VELOCITY and not sign(_velocity.x) == char_data.horizontal_state_:
							#CANNOT RUN WHILE MOVING BACKWARDS
							char_data.change_move_state(char_data.MOVE_STATE.RUNNING)
						elif abs(_velocity.x) <= 5 and not char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
							char_data.change_move_state(char_data.MOVE_STATE.STANDING)
			
		#TODO: Calculate move velocity allowing for:
			#DASHING
			#ATTACKING

		# Unsure how to resolve this issue. Change to feature? unclear 
		# WILL SLIDE DOWN HILLS, UNSURE IF DESIRED IMPLEMENTATION.
		_velocity = move_and_slide_with_snap(
			_velocity, snap_vector, FLOOR_NORMAL, false, 2, 0.9, false
			)

	
	else: #if the player input is locked out
		external_movement(delta)
#endregion


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
			if check_dash([4,5,4]) or held_buffer:
				_velocity.x = -MAX_VELOCITY
			else:
				_velocity.x = -WALK_VELOCITY
			# if _velocity.x > -MAX_VELOCITY:
			# 	_velocity.x -= WALK_ACCEL * delta
			# else:
			# 	_velocity.x += WALK_DEACCEL * 2 * delta
		elif buffered_movements[-1] == 6:
			if check_dash([6,5,6]) or held_buffer:
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


func check_dash(sequence):
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
		print("success")
	return found
	pass

func flush_buffer():
	buffered_movements = []


#HACK this should be fixed to a reasonable system
func speed_reset():
	if not (char_data.move_state_ == char_data.MOVE_STATE.JUMPING or char_data.move_state_ == char_data.MOVE_STATE.FALLING):
		_velocity.x = 0

# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
	linear_velocity,
	direction,
	speed,
	is_jump_interrupted
):
	var velocity = linear_velocity
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		velocity.y = 0.0
	return velocity


func play_new_sprite():
	if not current_animation == sprite.animation:
		sprite.play(current_animation)
		sprite.playing = true
		

#SIGNALS FROM GAMESTATE CHANGES
#region 

func _on_CharacterData_new_sprite_animation(new_anim):	
	current_animation = new_anim
	play_new_sprite()

func _on_CharacterData_play_animation(new_anim):
	current_animation = new_anim
	animation_player.play(current_animation)

func _on_Sprite_animation_finished():
	#HACK reset speeds shouldn't be like this
	if not current_animation in animation_player.get_animation_list():
		if current_animation =="Backdash":
			speed_reset()
		char_data.animation_completed()

	# current_animation = char_data.get_new_animation()
	#play_new_sprite()

#Does this double up with the sprite animation finish?
func _on_AnimationPlayer_animation_finished(_anim_name):
	print(_anim_name, " finished")
	char_data.uncancellable = false
	char_data.animation_completed()

#Function to handle non-player movements
#TODO change to move to a point, not move for x time
func external_movement(delta):
	if external_anim_time < 0:
		input_locked = false
		no_grav = false
	else:
		no_grav = true
		external_movement_data = move_and_slide(external_movement_data)
		external_anim_time -= delta
	print(external_movement_data)
	pass

func force_velocity(new_velocity):
	_velocity = new_velocity

#HACK, NEED TO HAVE A DIFFERENT WAY TO DEAL WITH CANCELLING MOVES
func _on_AnimationPlayer_animation_changed(_anim_name):
	if no_grav == true:
		no_grav = false
	char_data.animation_completed()

func _on_CharacterData_turn_sprite():
	self.scale.x *= -1

func _on_Hitbox_body_shape_entered(body_id, body, body_shape, area_shape):
	print("TARGET ENTERED")
	if body.get_class() == "Actor":

		#HITSTOP
		OS.delay_msec(25)

		#Find where the hitspark should be located
		var hit_pos = get_collision_position(body)


		#HACK TEMPORARY KNOCKBACK CALC
		attack_data.knockback_dir = Vector2(-1 * char_data.horizontal_state_ * abs(attack_data.knockback_dir.x), attack_data.knockback_dir.y)
		print(attack_data.get_hit_var)
		body.take_damage(attack_data.get_hit_var())
		slow_time += attack_data.slow_time


		#HACK turn off hitbox once has collided
		#Should probably handle this differently, given the possibility of hitting through two enemies
		attack_hitbox.get_node("CollisionShape2D").disabled = true

		#HACK hitspark
		$Sprite/Hitbox/Hitspark.global_position = hit_pos
		$Sprite/Hitbox/Hitspark.visible = true
		$Sprite/Hitbox/Hitspark.frame = 0
		$Sprite/Hitbox/Hitspark.scale.x = abs($Sprite/Hitbox/Hitspark.scale.x) * char_data.horizontal_state_
		$Sprite/Hitbox/Hitspark.play(attack_data.hitspark)


#HACK hitspark location calculation
#Uses the average position between the attack hitbox and the target hurtbox.  Not ideal way to calculate. 
#Ideal would probably be find both hitbox+hurtbox position and extents, calculate the overlapped regions and then find the middle of the overlapped region
func get_collision_position(body):
	var body_area_pos = body.get_node("CollisionShape2D").global_position
	var self_body_pos = $Sprite/Hitbox/CollisionShape2D.global_position
	return (body_area_pos + self_body_pos) / 2
	#endregion


#HACK current means of playing with time manipulation
#TODO improve overall time-slow situation

func time_slow(delta):
	if slow_time > 0:
		Engine.time_scale = .5
		slow_time -= delta
	else:
		Engine.time_scale = 1
		slow_time = 0
	
func get_HP():
	return char_data.HP

func get_max_HP():
	return char_data.max_HP


#DEPRECATED CODE
#region 


#ENEMY SPAWNING 
	# var spawn = Input.is_action_pressed("spawn")
	# if spawn:
	# 	call_deferred("_spawn_enemy_above")

	# func _spawn_enemy_above():
	# 	var e = Enemy.instance()
	# 	e.position = position + 50 * Vector2.UP
	# 	get_parent().add_child(e)



#OLD STATE CHANGE FUNCTIONS
	#region 
	
# func _on_CharacterData_anim_state_change(_state):
# 	print("ACTION STATE CHANGE")
# 	#if attacking, get the type of attack animation
# 	#if moving
# 	match _state:
# 		0: current_animation = "StandIdle" #StandIdle
# 		1: current_animation = "Walk" #Moving
# 		2: current_animation = "Run" #Attacking
# 			#if attacking, get the type of attack animation from attacker
# 			#HACK: currently does not handle anything other than LClick
# 		3: current_animation = "Dash" #Dashing
# 		#4: Blocking 
# 			#TODO: determine if want blocking
# 		5: pass #TURNING, LET HORIZONTAL HANDLE THE ANIMATION INSTEAD
# 			#TODO: determine how to handle disabled animations
# 		_: current_animation = "StandIdle"

# 	play_new_sprite()

# func _on_CharacterData_damage_state_change(_state):
# 	print("DAMAGE STATE CHANGE")
# 	#HACK obviously need to handle things better
# 	# emit_signal("damage_taken")
# 	# match _state:
# 	# 	0: current_animation = "StandIdle" 	#	IDLE,
# 	# 	1: invulnerable(INVULN_TIME) 	#	HIT,
# 	# 	2: invulnerable(INVULN_TIME) 	#	movelist_numERHIT,
# 	# 	3: print("invuln")				#	INVULN,
# 	play_new_sprite()

# func _on_CharacterData_move_state_change(_state):	
# 	print("MOVE STATE CHANGE")
# 	match _state:
# 		0: current_animation = "CrouchDown"
# 		1: current_animation = "CrouchIdle"
# 		2: current_animation = "StandUp"
# 		3: current_animation = "StandIdle"
# 		4: current_animation = "Jump"
# 		5: current_animation = "Falling"
# 	play_new_sprite()

# func _on_CharacterData_horizontal_state_change(_state):	
# 	print("HORIZONTAL STATE CHANGE")
# 	match char_data.move_state_:
# 		0: current_animation = "CrouchTurn"
# 		1: current_animation = "CrouchTurn"
# 		2: current_animation = "StandTurn"
# 		3: current_animation = "StandTurn"
# 		4: current_animation = "JumpTurn"
# 		5: current_animation = "JumpTurn"
# 	play_new_sprite()
	#endregion


	#OLD VARIABLES

	# var type = "player"

	# onready var char_data = $CharacterData
	# onready var sprite = $Sprite
	# onready var animation_player = $AnimationPlayer
	# onready var dodge_field = $DodgeField
	# onready var dodge_hitbox = $DodgeField/DodgeHitbox
	 
	# var motion = Vector2()
	# onready var dash_dir_vector = Vector2()
	
	# onready var dash_cd_timer = Timer.new()
	# onready var invuln_timer = Timer.new()
	
	# var dashs_remaining = DASH_movelist_num
	# var dashed_distance = DASH_DISTANCE
	# var dash_on_cooldown = false
	# var dodgeable_objects = ["projectile",
	# 					"melee",]
	
	# var forced_movement = false
	# var external_speed = 0
	# var external_direction = Vector2(0,0)
	# var external_time = 0
	
	
	# var current_animation = "StandIdle"
	# var current_animation_dir = "S"
	
	# signal game_over
	# signal damage_taken
	
	
	#OLD TIMER SETTING
	# # Called when the node enters the scene tree for the first time.
	# func _ready():
	# 	dash_cd_timer.set_one_shot(true)
	# 	dash_cd_timer.set_wait_time(DASH_COOLDOWN)
	# 	dash_cd_timer.connect("timeout", self, "on_dash_cooldown_complete")
	# 	add_child(dash_cd_timer)
		
	# 	invuln_timer.set_one_shot(true)
	# 	invuln_timer.set_wait_time(INVULN_TIME)
	# 	invuln_timer.connect("timeout", self, "on_invuln_end")
	# 	add_child(invuln_timer)
	
	# 	dodge_field.set_parent(self)
	# 	dodge_field.set_dodgeables(dodgeable_objects)
	
	# 	#Default Sprite Position
	# 	sprite.playing = true
	# 	sprite.speed_scale = 2
	# 	sprite.animation = current_animation + current_animation_dir
	

	#OLD MOVEMENT PROCESSING
	# func _physics_process(delta):
	# 	if not char_data.anim_state_ == char_data.ANIMATION_STATE.DISABLED:
	
	# 		if char_data.anim_state_ == char_data.ANIMATION_STATE.DASHING:
	# 			dashing(delta)
			
	# 		elif char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE or char_data.anim_state_ == char_data.ANIMATION_STATE.MOVING:
	# 			#Char movement
	# 			movement(delta)
				
	# 			#Char dashing
	# 			if (Input.is_action_just_pressed("ui_dash") 
	# 				and not dash_on_cooldown
	# 				and dashs_remaining > 0):
	# 				start_dash()
				
			
	# 		#Allow for god mode
	# 		if Input.is_action_just_pressed("god_mode"):
	# 			char_data.toggle_invuln()
	
	# 	elif forced_movement:
	# 		external_movement(delta)
	# 		pass
	
	# #GETTERS
	# #region [GETTERS]
	# func get_type():
	# 	return type
	
	# func get_max_HP():
	# 	return char_data.max_HP
		
	# func get_HP():
	# 	return char_data.get_HP()
	
	# func get_r_movelist():
	# 	return char_data.get_r_movelist()
	
	# func check_type():
	# 	return char_data.get_selected_type()
	
	# func instance_scene():
	# 	return char_data.instance_scene()
	
	# func special_on_lockout():
	# 	return char_data.special_on_lockout()
	
	# func get_move():
	# 	return char_data.get_move()
	# #endregion
	
	# #SETTERS
	# #region 
	# func set_camera(path):
	# 	$CameraTransform.set_remote_node(path)
	
	# func set_HP(total_cd_amt):
	# 	char_data.set_HP(total_cd_amt)
	
	# func set_special(num):
	# 	char_data.current_move = num
	
	# 	#endregion
	
	# #CHANGE STATE FUNCTIONS
	# #region 
	# func change_dir_state(direction):
	# 	match direction:
	# 		Vector2(0,1): char_data.direction_state_ = 0  #S
	# 		Vector2(-1,1): char_data.direction_state_ = 1  #SW
	# 		Vector2(-1,0): char_data.direction_state_ = 2  #W
	# 		Vector2(-1,-1): char_data.direction_state_ = 3  #NW
	# 		Vector2(0,-1): char_data.direction_state_ = 4  #N
	# 		Vector2(1,-1): char_data.direction_state_ = 5  #NE
	# 		Vector2(1,0): char_data.direction_state_ = 6  #E
	# 		Vector2(1,1): char_data.direction_state_ = 7  #SE
	# #endregion
	
	# #USER MOVEMENT
	# #region 
	# func movement(delta):
	# 	var direction = Vector2()
	# 	var cur_speed = SPEED		
	# 	if Input.is_action_pressed("ui_up"):
	# 		direction += Vector2(0,-1)
	# 	if Input.is_action_pressed("ui_down"):
	# 		direction += Vector2(0, 1)
	# 	if Input.is_action_pressed("ui_right"):
	# 		direction += Vector2(1,0)
	# 	if Input.is_action_pressed("ui_left"):
	# 		direction += Vector2(-1,0)
	
	# 	change_dir_state(direction)
	
	# 	if direction != Vector2():
	# 		char_data.anim_state_ = char_data.ANIMATION_STATE.MOVING
	# 		dash_dir_vector = direction
	# 	else:
	# 		char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	
	# 	motion = move_and_slide(direction.normalized() * cur_speed * delta) 
		
	# # func set_new_direction(direction):
	# # 	if dash_dir_vector != direction:
	# # 		dash_dir_vector = cart(direction)
	# # 		dash_dir_vector = direction
	
	# #endregion
	
	# #EXTERNAL MOVEMENT
	# #region 
	
	# func external_movement(delta):
	# 	motion = move_and_collide(external_speed * external_direction * delta)
	# 	external_time -= delta
	# 	if (external_time <= 0):
	# 		char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	# 		forced_movement = false
	# 		external_speed = 0
	# 		external_direction = Vector2(0,0)
	
	# func force_movement(direction, speed_mult, anim_time):
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.DISABLED
	# 	forced_movement = true
	# 	external_speed = speed_mult * DASH_SPEED
	# 	external_direction = direction
	# 	external_time = anim_time
			
	# #endregion
	
	# #DASH
	# #region 
	
	# func start_dash():
	# 	dashs_remaining -= 1
	# 	dodge_hitbox.disabled = false
	# 	dir_state_to_dash_direction()
	# 	self.set_collision_mask_bit(3, false)
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.DASHING
	
	# 	# print("dash start")
	# 	# dash_effect.visible = true
	# 	# dash_effect.rotation_degrees = rad2deg(dir.angle())
	# 	# dash_effect.play()
	
	# func dashing(delta):
	# 	var delta = DASH_SPEED * delta if dashed_distance > DASH_SPEED * delta else dashed_distance
	# 	motion = move_and_collide(delta*dash_dir_vector)
	# 	dashed_distance -= delta
	# 	if dashed_distance <= 0:
	# 		stop_dash()
	
	# func stop_dash():
	# 	dashed_distance = DASH_DISTANCE
	
	# 	if dashs_remaining <= 0:
	# 		dash_on_cooldown = true
		
	# 	dash_cd_timer.start()
	# 	dodge_hitbox.disabled = true
	# 	self.set_collision_mask_bit(3, true)
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	
	# func on_dash_cooldown_complete():
	# 	dash_on_cooldown = false
	# 	dashs_remaining = DASH_movelist_num
	# 	dashed_distance = DASH_DISTANCE
	
	
	# func dir_state_to_dash_direction():
	# 	var temp = Vector2()
	# 	match char_data.direction_state_:
	# 		0: temp = Vector2(0,1)  
	# 		1: temp = Vector2(-1,1)
	# 		2: temp = Vector2(-1,0)
	# 		3: temp = Vector2(-1,-1)
	# 		4: temp = Vector2(0,-1)
	# 		5: temp = Vector2(1,-1)
	# 		6: temp = Vector2(1,0)
	# 		7: temp = Vector2(1,1)
	# 	dash_dir_vector = temp.normalized()
	# 	if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
	# 		dash_dir_vector = dash_dir_vector * -1
	
	# #endregion
	
	
	# #DODGING
	# #region 
	
	# #TODO: This part has to feel really satisfying
	# #Timeslow + Chain dodge Nier-esque?
	
	# func _on_DodgeField_body_entered(body):
	# 	if (body.has_method("get_type") and 
	# 		dodgeable_objects.has(body.get_type())):
	# 		body.take_damage(self)
	# 		char_data.heal(DODGE_HEAL)
	
	# #endregion
	
	# #CHARACTER ANIMATIONS
	# #region 
	# # func animation_handler():
	# # 	var anim_name = "StandIdle"
	# # 	if char_data.anim_state_ == char_data.ANIMATION_STATE.MOVING:
	# # 		anim_name = "Walk"
	# # 	anim_name += dash_dir_vector_cart
	
	# # func _on_DashEffect_animation_finished():
	# # 	dash_effect.visible = false
	
	
	# #TODO: WORK ON THIS POST-ANIMATIONS
	# func play_new_sprite():
	# 	#if attacking, need to call AnimationPlayer to run appropriate hitbox etc.
	# 	var old_anim = sprite.animation
	# 	var new_anim =  current_animation + current_animation_dir
	
	# 	#preserve frame of animation upon change of direction only
	# 	#currently only works for Run
	# 	var new_frame = sprite.frame if current_animation in old_anim else 0
	
	
	# 	print(new_anim, new_frame)
	# 	if char_data.anim_state_ == char_data.ANIMATION_STATE.ATTACKING:
	# 		animation_player.play(new_anim)
	# 		#HACK need to decide what to do regarding this
	# 	else:
	# 		sprite.animation = new_anim
	# 		sprite.frame = new_frame
	
	# func _on_AnimationPlayer_animation_finished(_anim):
	# 	print("finished")
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	# 	pass
	
	# #endregion
	
	# #DAMAGE MECHANICS
	# #region 
	# func take_damage(obj):
	# 	char_data.take_damage(obj.attack_data.damage)
	# 		#TODO: Invuln timer way too slow proportional to cooldown times. 
	# 	if "knockback_val" in obj.attack_data:
	# 		motion = move_and_collide(obj.direction * obj.attack_data.knockback_val)
	
	# func invulnerable(time):
	# 	invuln_timer.start(time)
	# 	current_animation = "Damaged"
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.DISABLED
	# 	char_data.damage_state_ = char_data.DAMAGE_STATE.INVULN
		
	# func on_invuln_end():
	# 	char_data.damage_state_ = char_data.DAMAGE_STATE.IDLE
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	# 	play_new_sprite()
	# #endregion
	
	# #SIGNALS FROM GAMESTATE CHANGES
	# #region 
	# func _on_CharacterData_anim_state_change(_state):
	# 	#if attacking, get the type of attack animation
	# 	#if moving
	# 	match _state:
	# 		0: current_animation = "StandIdle" #StandIdle
	# 		1: current_animation = "Run" #Moving
	# 		2: current_animation = "Kick" #Attacking
	# 			#if attacking, get the type of attack animation from attacker
	# 			#HACK: currently does not handle anything other than LClick
	# 		3: current_animation = "Dash" #Dashing
	# 		#4: Blocking 
	# 			#TODO: determine if want blocking
	# 		5: pass 
	# 			#TODO: determine how to handle disabled animation
	# 		_: current_animation = "StandIdle"
	# 	play_new_sprite()
	
	# func _on_CharacterData_damage_state_change(_state):
	# 	#HACK obviously need to handle things better
	# 	emit_signal("damage_taken")
	# 	match _state:
	# 		0: current_animation = "StandIdle" 	#	IDLE,
	# 		1: invulnerable(INVULN_TIME) 	#	HIT,
	# 		2: invulnerable(INVULN_TIME) 	#	movelist_numERHIT,
	# 		3: print("invuln")				#	INVULN,
	# 	play_new_sprite()
	
	# func _on_CharacterData_direction_state_change(_state):	
	# 	match _state:
	# 		0: current_animation_dir = "S"
	# 		1: current_animation_dir = "SW"
	# 		2: current_animation_dir = "W"
	# 		3: current_animation_dir = "NW"
	# 		4: current_animation_dir = "N"
	# 		5: current_animation_dir = "NE"
	# 		6: current_animation_dir = "E"
	# 		7: current_animation_dir = "SE"
	# 	play_new_sprite()
	# #endregion
	
	# #SIGNALS TO GAMEMANAGER
	# #region 
	
	# #HEALTH INFORMATION SIGNALS
	# func _on_HPData_dead():
	# 	emit_signal("game_over")
	# 	pass # Replace with function body.
	
	# #endregion
	
	
	# #TURN ON/OFF ANY CHAR INTERACTIONS
	# #region 
	
	# func disable():
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.DISABLED
	# 	$Drawer.disable()
	
	# func enable():
	# 	char_data.anim_state_ = char_data.ANIMATION_STATE.IDLE
	# 	$Drawer.enable()
	
	# #endregion

				#DEPRECATED ACCEL/DECEL MOVE CODE
				# if move_left and not move_right:
				# 	if _velocity.x > -MAX_VELOCITY:
				# 		_velocity.x -= WALK_ACCEL * delta
				# 	else:
				# 		_velocity.x += WALK_DEACCEL * 2 * delta
				# elif move_right and not move_left:
				# 	if _velocity.x < MAX_VELOCITY:
				# 		_velocity.x += WALK_ACCEL * delta
				# 	else:
				# 		_velocity.x -= WALK_DEACCEL * 2 * delta
				# else:
				# 	var xv = abs(_velocity.x)
				# 	xv -= WALK_DEACCEL * delta
				# 	if xv < 0:
				# 		xv = 0
				# 	_velocity.x = sign(_velocity.x) * xv

#endregion
