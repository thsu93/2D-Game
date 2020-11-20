

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

	
#given a new horizontal state, attempt to change to that new state
#if is not current direction, flip the character
# #No longer called from char directly, just called after 
# func change_horiz_state(dir):
# 	#if trying to turn to the direction already facing
# 	if not dir == horizontal_state_:
# 		evaluate_state_change(dir, "HORIZONTAL")

# #given a new movement state, attempt to change to that new state
# #if new state is the same as current state, simply refreshes the animation
# func change_move_state(new_state):
# 	if not new_state == move_state_:
# 		evaluate_state_change(new_state, "MOVEMENT")
# 	else:
# 		update_current_animation()

# #given a new damage state, attempt to change to that new state 
# #currently does nothing at all, never called.
# func change_damage_state(new_state):
# 	if damage_state_ == DAMAGE_STATE.IDLE:
# 		damage_state_ = new_state
# 	pass


# #given a new animation state, attempt to change to that new state
# #Currently only checks against Dash/Backdash/Attack/Idle
# func change_anim_state(new_state):
		
# 	if new_state == ANIMATION_STATE.IDLE:
# 		anim_state_ = ANIMATION_STATE.IDLE
# 	else:
# 		evaluate_state_change(new_state, "ANIMATION")
# 	pass

# #endregion

# #region Evaluate State Change

# #See if char is currently able to change state
# #Prioritizes Damage -> Animation -> Movement state changes.
# #TODO this has gotta be better somehow, it's a convoluted mess
# func evaluate_state_change(new_state, state_changed):
# 	#HIGHEST PRIORITY
# 	#Currently does not check this ever, as damage state changes always pass and thus never need to be evaluated
# 	if state_changed == "DAMAGE":
# 		pass
# 		#Should probably change animation state to idle to indicate deferring


# 	#If not currently animating
# 	#TODO THIS IS WHERE THE PRIORITY SYSTEM WOULD GO
# 	#This is a mess
# 	if state_changed == "ANIMATION":
# 		if not anim_state_ == ANIMATION_STATE.TURNING:
# 			if new_state == ANIMATION_STATE.DASHING:
# 				anim_state_ = ANIMATION_STATE.DASHING
# 				move_state_ = MOVE_STATE.DASHING
			
# 			elif new_state == ANIMATION_STATE.BACKDASHING:
# 				anim_state_ = ANIMATION_STATE.BACKDASHING
# 				move_state_ = MOVE_STATE.BACKDASHING

# 			elif new_state == ANIMATION_STATE.PARRYING:
# 				anim_state_ = ANIMATION_STATE.PARRYING
			
# 			elif new_state == ANIMATION_STATE.ATTACKING:
# 				if process_attack():
# 					anim_state_ = ANIMATION_STATE.ATTACKING

# 			elif new_state == ANIMATION_STATE.GUARDING:
# 				anim_state_ = ANIMATION_STATE.GUARDING


# 	if anim_state_ == ANIMATION_STATE.IDLE:
# 		#start turning
# 		if state_changed == "HORIZONTAL":
# 			anim_state_ = ANIMATION_STATE.TURNING
				
# 		if state_changed == "MOVEMENT":
			
# 			#HIGHEST PRIORITY CHANGE 
# 			if new_state == MOVE_STATE.JUMPING:
# 				move_state_ = MOVE_STATE.JUMPING
# 				pass #Should not require any changes to the animation state


# 			if new_state == MOVE_STATE.CROUCHING:
# 				anim_state_ = ANIMATION_STATE.CROUCH_DOWN

# 			#IF ANY CHANGES OUT OF CROUCHING, EXCEPTING JUMPING
# 			if move_state_ == MOVE_STATE.CROUCHING:
# 				if new_state != MOVE_STATE.CROUCHING:
# 					anim_state_ = ANIMATION_STATE.STAND_UP
			
# 			if new_state == MOVE_STATE.STANDING:

# 				if move_state_ == MOVE_STATE.RUNNING:
# 					anim_state_ = ANIMATION_STATE.RUN_STOP

# 				else:
# 					move_state_ = MOVE_STATE.STANDING

			
# 			if new_state == MOVE_STATE.FALLING:
# 				move_state_ = MOVE_STATE.FALLING
# 				pass #should not require any changes to the animation state
			
# 			if new_state == MOVE_STATE.WALKING:

# 				if move_state_ == MOVE_STATE.RUNNING:
# 					anim_state_ = ANIMATION_STATE.RUN_STOP
# 				else:
# 					move_state_ = MOVE_STATE.WALKING
		
# 			if new_state == MOVE_STATE.RUNNING:
# 				if not move_state_ == MOVE_STATE.JUMPING:
# 					anim_state_ = ANIMATION_STATE.RUN_START
# 				pass

# 	else: #If playing another animation right now
# 		pass #Do not update anything
	
# 	update_current_animation()
# #endregion


# #region Animation Changes

# #Updates the actor's animation to fit the current state of the state machine
# #prioritizes damage, then animations, then movement
# func update_current_animation(new_anim = null):

# 	if not new_anim:
# 		new_anim = current_animation

# 	if not damage_state_ == DAMAGE_STATE.IDLE:
# 		if damage_state_ == DAMAGE_STATE.GUARDING:
# 			new_anim = "Guard"
# 		#DAMAGE ANIMATIONS HANDLED WITHIN TAKE_DAMAGE

# 		pass #deal with 

# 	if anim_name_dictionary.has(anim_state_ ):
# 		new_anim = anim_name_dictionary[anim_state_]
	
# 	# elif anim_state_ == ANIMATION_STATE.DASHING:
# 	# 	# if move_state_ == MOVE_STATE.JUMPING or move_state_ == MOVE_STATE.FALLING:
# 	# 	# 	new_anim ="JumpDash"
# 	# 	# else:
# 	# 	# 	new_anim = "Dash"
# 	# 	new_anim = "Dash"
# 	# elif anim_state_ == ANIMATION_STATE.BACKDASHING:
# 	# 	new_anim = "Backdash"
	
# 	# elif anim_state_ == ANIMATION_STATE.PARRYING:
# 	# 	new_anim = "Parry"

# 	# elif anim_state_ == ANIMATION_STATE.TURNING:
# 	# 	new_anim = "Turn"

# 	# #Transitional Animations
# 	# elif anim_state_ == ANIMATION_STATE.CROUCH_DOWN:
# 	# 	new_anim = "CrouchDown"
# 	# elif anim_state_ == ANIMATION_STATE.STAND_UP:
# 	# 	new_anim = "StandUp"
# 	# elif anim_state_ == ANIMATION_STATE.RUN_START:
# 	# 	new_anim = "RunStart"
# 	# elif anim_state_ == ANIMATION_STATE.RUN_STOP:
# 	# 	new_anim = "RunStop"

	
# 	elif anim_state_ == ANIMATION_STATE.ATTACKING:
# 		new_anim = cur_attack.movename
# 		pass
# 		#no attacking animations current
# 		#should probably defer this call to a more complex function given possible variants
# 		#no attacking animations current
# 		#have jumping/crouching/standing variants to consider as well 
# 	elif anim_state_ == ANIMATION_STATE.DODGING:
# 		pass
# 		#no attacking animations current

# 	elif anim_state_ == ANIMATION_STATE.IDLE:
# 		#defer to the movement-controlled animations
# 		match move_state_:
# 			MOVE_STATE.CROUCHING: new_anim = "CrouchIdle"
# 			MOVE_STATE.JUMPING: new_anim = "Jump" 
# 			MOVE_STATE.FALLING: new_anim = "Fall"
# 			MOVE_STATE.RUNNING: new_anim = "Run"
# 			MOVE_STATE.WALKING: new_anim = "Walk"
# 			MOVE_STATE.GUARDING: new_anim = "Guard"
# 			_: new_anim = "StandIdle"
# 		pass

# 	new_anim = match_vert_state(new_anim)
	
# 	# if not new_anim == current_animation: #probably redundant check
# # 		print(new_anim)
# 	if new_anim in animation_player_library:
# 		emit_signal("play_animation", new_anim)
# 		current_animation = new_anim
# 	elif new_anim in sprite_library:
# 		emit_signal("new_sprite_animation", new_anim)
# 		current_animation = new_anim
# 	else:
# 		print("ERROR ANIMATION NOT IN LIBRARY: ", new_anim)



# #Fixes the animation to match the movestate of the character, if possible
# #IE will correct for running/in-air/crouching/dashing animations
# func match_vert_state(new_anim):
	
# 	#Create a placeholder animation name, and then append the movestate descriptor to the front
# 	var temp_anim = new_anim
# 	match move_state_:
# 		MOVE_STATE.CROUCHING : 	temp_anim = "Crouch" + new_anim
# 		MOVE_STATE.STANDING : 	temp_anim = "Stand" + new_anim
# 		MOVE_STATE.JUMPING : 	temp_anim = "Jump" + new_anim
# 		MOVE_STATE.FALLING : 	temp_anim = "Jump" + new_anim
# 		MOVE_STATE.WALKING : 	temp_anim = "Walk" + new_anim
# 		MOVE_STATE.RUNNING : 	temp_anim = "Run" + new_anim
# 		MOVE_STATE.DASHING :	temp_anim = "Dash" + new_anim

# 	#If movestate+anim exists in the sprite or animation player, 
# 	#or if the animation exists on its own without a descriptor,
# 	#return the animation value
# 	if temp_anim in sprite_library or temp_anim in animation_player_library:
# 		return temp_anim
# 	elif new_anim in sprite_library or new_anim in animation_player_library:
# 		return new_anim

# 	#Otherwise, check if a standing version exists but the player is not in a matching state
# 	#and no movestate-generic animation exists
# 	#HACK Probably not the best practice
# 	else:
		
# 		temp_anim = "Stand" + new_anim
# 		if temp_anim in sprite_library or temp_anim in animation_player_library:
# 			return temp_anim
# 		else: # new_anim in sprite_library or new_anim in animation_player_library
# 			return new_anim #This seems like it should never be called


# #Handle any state changes that automatically occur on completion of an animation
# #Then call to update state depending on which state was changed 
# func animation_completed():
	
# 	waiting_for_animation_completion = false

# 	#Variable to track if the move state should change given the animation
# 	var move_state_change = false

# 	#Change damage state back at the end of taking damage
# 	if anim_state_ == ANIMATION_STATE.DAMAGED:
# 		damage_state_ = DAMAGE_STATE.IDLE

# 	#if in the turning state, change horizontal state
# 	if anim_state_ == ANIMATION_STATE.TURNING:
# 		if char_name != "player":
# 			horizontal_state_ *= -1 #FLIP SIDE
# 			emit_signal("turn_sprite")

# 	#Check if the animation_state was a transitional animation
# 	else:
# 		move_state_change = true
# 		match anim_state_:
# 			ANIMATION_STATE.RUN_START:		move_state_ = MOVE_STATE.RUNNING
# 			ANIMATION_STATE.RUN_STOP:		move_state_ = MOVE_STATE.STANDING
# 			ANIMATION_STATE.CROUCH_DOWN:	move_state_ = MOVE_STATE.CROUCHING
# 			ANIMATION_STATE.STAND_UP:		move_state_ = MOVE_STATE.STANDING
# 			ANIMATION_STATE.BACKDASHING:	move_state_ = MOVE_STATE.STANDING
# 			ANIMATION_STATE.DASHING: 		move_state_ = MOVE_STATE.RUNNING #Forces player into run post-dash if fowrward dashing
# 			ANIMATION_STATE.IDLE: 			move_state_change = MOVE_STATE.STANDING
# 			_: move_state_change = false

# 	anim_state_ = ANIMATION_STATE.IDLE

# 	if move_state_change:
# 		change_move_state(move_state_)
# 	else: 
# 		evaluate_state_change(anim_state_, "ANIMATION")


# 	if cur_state == CHAR_STATE.RUN_START:
# 		change_state(CHAR_STATE.RUNNING)

# 	elif cur_state == CHAR_STATE.RUN_STOP:
# 		change_state(CHAR_STATE.STANDING)

# 	elif cur_state == CHAR_STATE.GUARDING:
# 		pass
	
# 	elif cur_state == CHAR_STATE.RUNNING:
# 		pass	

# 	elif cur_state == CHAR_STATE.WALKING:
# 		pass
	
# 	elif cur_state == CHAR_STATE.JUMPING:
# 		pass

# 	elif cur_state == CHAR_STATE.FALLING:
# 		pass

# 	#One-shot animations
# 	else:
# 		if cur_state == CHAR_STATE.TURNING:
# 			horizontal_state_*=-1
# 			emit_signal("turn_sprite")

# 		cur_state = CHAR_STATE.WAITING_FOR_UPDATE
# 		# if air_state == AIR_STATE.IN_AIR:
# 		# 	change_state(CHAR_STATE.FALLING)
# 		# else:
# 		# 	#TODO double setting state, find why
# 		# 	change_state(CHAR_STATE.STANDING)

# 	change_animation()


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

	
	# func check_crouch(delta):
# 	if char_data.move_state_ == char_data.MOVE_STATE.CROUCHING:
# 		if abs(_velocity.x) > 0:
# 			var decel = WALK_DECEL * delta * 5
# 			var new_velocity = _velocity.x - decel if _velocity.x - decel > 0 else 0
# 			_velocity.x = new_velocity
# 	else:
# 		char_data.change_move_state(char_data.MOVE_STATE.CROUCHING)



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
