class_name Enemy2
extends Actor

#TODO use char_data instead

signal combo(num)

onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var hurtbox = $CollisionShape2D

#HACK 
var dir_switch_time = .2

var combo_counter = 0

func _init():
	actor_type = "enemy"

# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():

	current_animation = "StandIdle"
	sprite.playing = true
	sprite.animation = current_animation
	sprite.speed_scale = 2

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
			emit_signal("combo", combo_counter)

	if char_data.damage_state_ == char_data.DAMAGE_STATE.IDLE:
		if char_data.anim_state_ == char_data.ANIMATION_STATE.IDLE:
			_velocity = calculate_move_velocity(_velocity)


			if abs(_velocity.x) > 5 and not char_data.move_state_ == char_data.MOVE_STATE.WALKING:
				char_data.change_move_state(char_data.MOVE_STATE.WALKING)

			elif abs(_velocity.x) < 5 and not char_data.move_state_ == char_data.MOVE_STATE.STANDING:
				char_data.change_move_state(char_data.MOVE_STATE.STANDING)

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


func take_damage(hit_var):
	print("TOOK DAMAGE    ", hit_var["dmg"], "     ", hit_var["movename"])
	print(hit_var["knockback_dir"])
	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"]
	char_data.take_damage(hit_var["dmg"])

	if hit_var["rooted"]:
		knockback = Vector2()

	stunned = true
	stun_time = hit_var["stun"]
	combo_counter += 1
	emit_signal("combo", combo_counter)
	

#On character death
func _on_CharacterData_dead():
	print("death signal sent")
	destroy()

func destroy():
	animation_player.stop(true)
	animation_player.play("Death")
	print("dead")
	_velocity = Vector2.ZERO
	knockback = Vector2(250,0) * -char_data.horizontal_state_

	#HACK turn off collision for anything except world
	self.collision_mask = 1024



