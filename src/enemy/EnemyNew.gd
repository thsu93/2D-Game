class_name Enemy2
extends Actor

#TODO use char_data instead

enum State {
	WALKING,
	DAMAGED,
	DEAD
}

var _state = State.WALKING

onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var hurtbox = $CollisionShape2D

func _init():
	actor_type = "enemy"

# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():

	char_data.set_name(actor_type)

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
	_velocity = calculate_move_velocity(_velocity)

	# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

	# We flip the Sprite depending on which way the enemy is moving.
	sprite.scale.x = abs(sprite.scale.x) if _velocity.x > 0 else abs(sprite.scale.x)*-1

	update_animation()

func update_animation():
	var animation = char_data.get_new_animation()
	if animation != animation_player.current_animation:
		animation_player.play(animation)

# This function calculates a new velocity whenever you need it.
# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
func calculate_move_velocity(linear_velocity):
	var velocity = linear_velocity
	
	if _state == State.DAMAGED:
		velocity.x = 0
	
	if knockback == Vector2():
		if not floor_detector_left.is_colliding():
			velocity.x = speed.x
		elif not floor_detector_right.is_colliding():
			velocity.x = -speed.x


	#BUG Enemy will spin uncontrollably if trappepd 
	if is_on_wall():
		velocity.x *= -1

	return velocity
	

func get_new_animation():
	var animation_new = ""
	if _state == State.WALKING:
		animation_new = "Walk" if abs(_velocity.x) > 5 else "StandIdle"
	elif _state == State.DAMAGED:
		animation_new = "StandDamage"
	elif _state == State.DEAD:
		animation_new = "destroy"
	return animation_new

func _on_CharacterData_dead():
	print("signal sent")
	destroy()

func take_damage(hit_var):
	print("TOOK DAMAGE    ", hit_var["dmg"], "     ", hit_var["movename"])
	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"]
	char_data.take_damage(hit_var["dmg"])
	stunned = true
	_state = State.DAMAGED
	print(knockback)


func _on_AnimationPlayer_animation_finished(_anim_name):
	
	#HACK
	if _state == State.DAMAGED:
		stunned = false
		_state = State.WALKING
		_velocity.x = speed.x
		print("finished damage")

	char_data.animation_completed()

func _on_CharacterData_turn_sprite():
	sprite.scale *= -1




func destroy():
	print("destroying")
	_state = State.DEAD
	_velocity = Vector2.ZERO

	#HACK turn off collision for anything except world
	self.collision_mask = 1024