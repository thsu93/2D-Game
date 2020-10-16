#Class that controls the movement and manages hitting data of the enemy
#Data and attack AI are contained within actor's char_data file
#TODO how to structure AI
class_name Enemy2
extends Actor


signal combo(num)
signal shake

onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var hurtbox = $CollisionShape2D

onready var hitspark = $Sprite/Hitbox/Hitspark
onready var hitbox = $Sprite/Hitbox

#HACK 
var dir_switch_time = .2

var combo_counter = 0

var knockback_scaling_mult = 1
var damage_scaling_mult = 1

func _init():
	actor_type = "enemy"

# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():

	current_animation = "StandIdle"
	sprite.playing = true
	sprite.animation = current_animation
	sprite.speed_scale = 2

	animation_player.playback_speed = 1.5

	char_data.sprite_library = sprite.frames.get_animation_names()
	char_data.animation_player_library = animation_player.get_animation_list()

	char_data.horizontal_state_ = char_data.HORIZONTAL_STATE.R
	_velocity.x = speed.x

# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# At a glance, you can see that the physics process loop:
# 1. Calculates the move velocity.
# 2. Moves the character.
# 3. Updates the sprite direction.
# 4. Updates the animation.

# Splitting the physics process logic into functions not only makes it
# easier to read, it help to change or improve the code later on:
# - If you need to change a calculation, you can use Go To -> Function
#   (Ctrl Alt F) to quickly jump to the corresponding function.
# - If you split the character into a state machine or more advanced pattern,
#   you can easily move individual functions.
func _physics_process(_delta):

	stun_time -= _delta

	if stun_time<0:
		if combo_counter > 0:
			combo_counter = 0
			knockback_scaling_mult = 1
			damage_scaling_mult = 1
			emit_signal("combo", combo_counter)

	if char_data.damage_state_ == char_data.DAMAGE_STATE.IDLE:
		if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
			_velocity = calculate_move_velocity(_velocity)

			if abs(_velocity.x) > 5 and not char_data.move_state_ == char_data.MOVE_STATE.WALKING:
				char_data.change_move_state(char_data.MOVE_STATE.WALKING)

			elif abs(_velocity.x) < 5 and not char_data.move_state_ == char_data.MOVE_STATE.STANDING:
				char_data.change_move_state(char_data.MOVE_STATE.STANDING)

		elif char_data.anim_state_ == char_data.ANIMATION_STATE.ATTACKING:
			_velocity.x = 0

	else:
		_velocity.x = 0

	# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y



# This function calculates a new velocity whenever you need it.
# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
func calculate_move_velocity(linear_velocity):
	var velocity = linear_velocity

	if knockback == Vector2():

		if (not floor_detector_left.is_colliding()
			or not floor_detector_right.is_colliding()
			or is_on_wall()):
			if velocity.x < 0: 
				char_data.change_horiz_state(char_data.HORIZONTAL_STATE.R)
			else: 
				char_data.change_horiz_state(char_data.HORIZONTAL_STATE.L)

		velocity.x = speed.x * char_data.horizontal_state_

	return velocity


#TODO clean up?
#Overloaded take_damage function, taking into consideration: 
#knockback scaling
#damage scaling
#combo counts
#stun effects
func take_damage(hit_var):

	#HACK
	hit_var["dmg"] /= damage_scaling_mult
	print("TOOK DAMAGE    ", hit_var["dmg"], "     ", hit_var["movename"])
	
	char_data.take_damage(hit_var)

	damage_scaling_mult += hit_var["damage_scaling"]

	#Cant rooted and knockback just be the same thing?
	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"] * knockback_scaling_mult
	if hit_var["rooted"]:
		knockback = Vector2()

	knockback_scaling_mult *= (1+ hit_var["knockback_scaling"])
	

	stunned = true
	stun_time = hit_var["stun"]
	combo_counter += 1
	emit_signal("combo", combo_counter)
	emit_signal("shake")
	



#On character death
func _on_CharacterData_dead():
	destroy()

#destroy body
func destroy():
	animation_player.stop(true)
	animation_player.play("Death")
	_velocity = Vector2.ZERO
	knockback = Vector2(250,0) * -char_data.horizontal_state_

	#HACK turn off collision for anything except world
	self.collision_mask = 1024


func _on_Hitspark_animation_finished():
	hitspark.visible = false
	pass # Replace with function body.

func _on_Hitbox_body_shape_entered(body_id, body, body_shape, area_shape):
	if body.get_class() == "Actor" and body.actor_type == "player":

		# body.stunned = true

		#HITSTOP
		OS.delay_msec(25)

		# #HACK hitspark
		# var hit_pos = get_collision_position(body)
		# emit_hitspark(hit_pos)

		var attack_data = char_data.cur_attack

		#HACK TEMPORARY KNOCKBACK CALC
		attack_data.knockback_dir = Vector2(char_data.horizontal_state_ * abs(attack_data.knockback_dir.x), attack_data.knockback_dir.y)
		body.take_damage(attack_data.get_hit_var())
		
		#TODO How to prevent double-hitting of moves
		#Is this even necessary? It won't maintain hitting
		#Should probably handle this differently, given the possibility of hitting through two enemies
		#attack_hitbox.get_node("CollisionShape2D").disabled = true


