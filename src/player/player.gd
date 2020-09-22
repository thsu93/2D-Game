class_name Player
extends Actor


# #EXAMPLE BUFFER SYSTEM
# const COMBO_TIMEOUT = 0.3 # Timeout between key presses
# const MAX_COMBO_CHAIN = 2 # Maximum key presses in a combo

# var last_key_delta = 0    # Time since last keypress
# var key_combo = []        # Current combo
	
# func _input(event):
# 	if event is InputEventKey and event.pressed and !event.echo: # If distinct key press down
# 		print(last_key_delta)
# 		if last_key_delta > COMBO_TIMEOUT:                   # Reset combo if stale
# 			key_combo = []
		
# 		key_combo.append(event.scancode)                     # Otherwise add it to combo
# 		if key_combo.size() > MAX_COMBO_CHAIN:               # Prune if necessary
# 			key_combo.pop_front()
		
# 		print(key_combo)                                     # Log the combo (could pass to combo evaluator)
# 		last_key_delta = 0                                   # Reset keypress timer
	
# func _physics_process(delta):
# 	last_key_delta += delta                                      # Track time between keypresses


#TODO: PRIORITY SYSTEM FOR ANIMATIONS
#TODO RESOLVE CONFLICTS BETWEEN ACTOR SPEED/GRAV AND CHAR VELOCITY
#TODO MOVEMENT IS SLOPPY AS HELL, SLIDING EVERYWHERE ETC.
const WALK_ACCEL = 450.0
const WALK_DEACCEL = 3500.0
const MAX_VELOCITY = 250.0
const WALK_VELOCITY = 125.0
const JUMP_VELOCITY = 500
const STOP_JUMP_FORCE = 450.0
const DASH_SPEED = 400
const FLOOR_DETECT_DISTANCE = 20.0

var current_animation = ""

var siding_left = false
var jumping = false
var stopping_jump = false
var slowed = false

onready var platform_detector = $PlatformDetector

onready var attack_hitbox = $Sprite/Hitbox
var floor_h_velocity = 0.0

var airborne_time = 1e20
var shoot_time = 1e20

var attack_data


#HACK FOR MOVE CHECK
var l_movelist = ["Jab"]
var r_movelist = ["Hook", "Overhead", "Shoryuken"]
var count = 0


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

#TODO Ability to save movement state + data (speed, etc.)
func _physics_process(delta):
	
	# Get the controls.
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var jump = Input.is_action_pressed("jump")
	var lclick = Input.is_action_just_pressed("lclick")
	var rclick = Input.is_action_just_pressed("rclick")
	var crouch = Input.is_action_pressed("crouch")
	
	var dashing = Input.is_action_just_pressed("dash")
	var scroll_up = Input.is_action_just_released("scroll_up")
	var scroll_down = Input.is_action_just_released("scroll_down")
	
	check_if_slowed()

	if scroll_down:
		count = count + 1 if count < 2 else 2
		slowed = true
		print(r_movelist[count])

	if scroll_up:
		count = count -1 if count > 0 else 0
		slowed = true
		print(r_movelist[count])
	
	# Deapply prev floor velocity.

	# var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0.0

	#TODO Evaluate how movement control works
	#DO YOU EVEN REALLY WANT PHYSICS-BASED MOVEMENT VS DISCRETE CONTROLS MOVEMENT


	# var x_dir = -1 if move_left and not move_right else 1 if move_right and not move_left else 0
	# var direction = Vector2(x_dir, -1 if is_on_floor() and jump else 0)
	# _velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)

	#BUG DOES NOT DETECT IS ON FLOOR IF MID-ANIMATION

	#ATTACKING
	#TODO Decide how to handle momentum with moves, how to determine to preserve or not.
	#BUG moves do not come out when going through transitional state animations
	#BUG graphical bug of sliding back during jab, part of sprite rather than actual programmatic bug
	if lclick:
		#TODO ADD DEPTH
		#TODO move buffers?
		#HACK direct move insert currently
		char_data.change_anim_state("Attack", "Jab")
		attack_data = char_data.get_move_data()
		speed_reset()
		slowed = false
		#BUG char will slide while stand-jab if not forced into velocity 0

	if rclick:
		char_data.change_anim_state("Attack", r_movelist[count])
		attack_data = char_data.get_move_data()
		slowed = false
		speed_reset()

	var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if not is_on_floor() else Vector2.ZERO
	var is_on_platform = platform_detector.is_colliding()

	#DASH
	#BUG into run post-dash w/out run-start
	#BUG cannot forward dash after neutral jump in midair
	#BUG If dash is cancelled into attack WILL NOT COME OUT OF NO-GRAV STATE
	#TODO Determine if necessary
	#HACK Handling no_grav from animationplayer
	if char_data.anim_state_ == char_data.ANIMATION_STATE.DASHING:
		_velocity.x = -char_data.horizontal_state_ * DASH_SPEED

	elif char_data.anim_state_ == char_data.ANIMATION_STATE.BACKDASHING:
		_velocity.x = char_data.horizontal_state_ * DASH_SPEED
		
	
	if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
		
		# Update sidedness, give a bit of error room 
		if _velocity.x < 0.5 and move_left and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.R):
			char_data.change_horiz_state("L")
		
		if _velocity.x > -0.5 and move_right and (char_data.horizontal_state_ == char_data.HORIZONTAL_STATE.L):
			char_data.change_horiz_state("R")

		# Process jump.
		if not is_on_floor():
			if _velocity.y > 0:
				# Set off the jumping flag if going down.
				#BUG will be in fall state when taking damage due to the way the knockback vector works. unclear solution.
				char_data.change_move_state("Fall")
				print(knockback)
			elif not jump:
				stopping_jump = true
			
			if stopping_jump:
				_velocity.y += STOP_JUMP_FORCE * delta

		if dashing:
			print("dash start")
			#HACK should determine if dashing in "facing" direction vs not
			#TODO: Decide what optimal controls are here
			if (move_right and char_data.horizontal_state_ == -1) or (move_left and char_data.horizontal_state_ == 1):
				char_data.change_anim_state("Dash")
			else:
				char_data.change_anim_state("Backdash")
		
		#BUG will not update if move_state is interrupted during jump
		if is_on_floor():
			if crouch:
				if char_data.move_state_ == char_data.MOVE_STATE.CROUCHING:
					if abs(_velocity.x) > 0:
						var deaccel = WALK_DEACCEL * delta * 5
						var new_velocity = _velocity.x - deaccel if _velocity.x - deaccel > 0 else 0
						_velocity.x = new_velocity
				else:
					char_data.change_move_state("Crouch")

			elif not crouch:
				# Process logic when character is on floor.
				#BUG sometimes still standing/slow-walking in air when neutral/slow-forward jump
				#BUG Holding back direction button to slow just increases slide time
				
				
				if jump:
					_velocity.y = -JUMP_VELOCITY
					char_data.change_move_state("Jump")
					stopping_jump = false
				
				if move_left and not move_right:
					if _velocity.x > -MAX_VELOCITY:
						_velocity.x -= WALK_ACCEL * delta
					else:
						_velocity.x += WALK_DEACCEL * 2 * delta
				elif move_right and not move_left:
					if _velocity.x < MAX_VELOCITY:
						_velocity.x += WALK_ACCEL * delta
					else:
						_velocity.x -= WALK_DEACCEL * 2 * delta
				else:
					var xv = abs(_velocity.x)
					xv -= WALK_DEACCEL * delta
					if xv < 0:
						xv = 0
					_velocity.x = sign(_velocity.x) * xv

				if abs(_velocity.x) > MAX_VELOCITY:
					_velocity.x = sign(_velocity.x) * MAX_VELOCITY
				
				if abs(_velocity.x) > 5 and abs(_velocity.x) <= WALK_VELOCITY:
					char_data.change_move_state("Walk")
				elif abs(_velocity.x) > WALK_VELOCITY:
					char_data.change_move_state("Run")
				elif abs(_velocity.x) <= 5 and not char_data.move_state_ == char_data.MOVE_STATE.JUMPING:
					char_data.change_move_state("StandIdle")
		
	#TODO: Calculate move velocity allowing for:
		#DASHING
		#ATTACKING

	# Unsure how to resolve this issue. Change to feature? unclear 
	#BUG DOES NOT MOVE WITH MOVING PLATFORMS ETC.
	#BUG CANNOT HANDLE SLOPES AT ALL
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 3, 0.9, false
		)

#HACK this should be fixed to a reasonable system
func speed_reset():
	if not (char_data.move_state_ == char_data.MOVE_STATE.JUMPING or char_data.move_state_ == char_data.MOVE_STATE.FALLING):
		_velocity.x = 0

#HACK current means of playing with time manipulation
#TODO improve overall time-slow situation
func check_if_slowed():
	if slowed:
		Engine.time_scale = 0.5
	else:
		Engine.time_scale = 1

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
	if current_animation =="Backdash":
		print("Backdash End")
		speed_reset()
	char_data.animation_completed()	

	# current_animation = char_data.get_new_animation()
	#play_new_sprite()

#Does this double up with the sprite animation finish?
func _on_AnimationPlayer_animation_finished(_anim_name):
	char_data.animation_completed()

func _on_CharacterData_turn_sprite():
	self.scale.x *= -1

func _on_Hitbox_body_shape_entered(body_id, body, body_shape, area_shape ):
	print("TARGET ENTERED")
	if body.get_class() == "Actor":
		#HACK TEMPORARY KNOCKBACK CALC
		attack_data.knockback_dir = Vector2(-1 * char_data.horizontal_state_ * attack_data.knockback_dir.x, attack_data.knockback_dir.y)
		print(attack_data.get_hit_var)
		body.take_damage(attack_data.get_hit_var())
		slowed = true


#endregion




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
# 	# 	2: invulnerable(INVULN_TIME) 	#	COUNTERHIT,
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
	
	# var dashs_remaining = DASH_COUNT
	# var dashed_distance = DASH_DISTANCE
	# var dash_on_cooldown = false
	# var dodgeable_objects = ["projectile",
	# 					"melee",]
	
	
	# #TODO: Analyze the in-game need for this.   
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
	# 	dashs_remaining = DASH_COUNT
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
	# 		2: invulnerable(INVULN_TIME) 	#	COUNTERHIT,
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

#endregion
