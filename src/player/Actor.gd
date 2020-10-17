#Generic Actor Class
#Base classs for any moving in-game agent
#Nodes: "CharacterData", "Sprite", "AnimationPlayer"
#Vars: _velocity, actor_type, current_animation, knockback, external_movement_data, remaining_animation_time
#Fxns: _process (grav+knockback handling), get_class, take_damage, external_movement, play_sprite, destroy
#Signals: Screenshake
class_name Actor

extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.

signal screenshake(amplitude, duration)

#REQUIRED NODES:

onready var char_data = $CharacterData
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

#Base actor type
var actor_type = "Actor"


export var speed = Vector2(150.0, 450.0)
export var no_grav = false
onready var gravity = ProjectSettings.get("physics/2d/default_gravity")
export var movement_locked = false
var external_movement_data = Vector2()

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO
var stunned = false

var current_animation = ""

var remaining_animation_time = 0

var knockback = Vector2.ZERO
var stun_time = 0

func _ready():
	char_data.set_name(actor_type)

# _physics_process is called after the inherited _physics_process function.
# This allows the Player and Enemy scenes to be affected by gravity.
func _physics_process(delta):

	#Should stunned leave vertical falling? choice? 
	if stunned:
		_velocity.x = 0
		stun_time -= delta
		if stun_time <=0:
			stunned = false

	# else:
	if no_grav:
	#HACK probably not the best way to handle this
		_velocity.y = 0
	else:
		_velocity.y += gravity * delta
	
	if knockback != Vector2.ZERO:
		knockback = knockback.move_toward(Vector2.ZERO, 1000*delta)
		knockback = move_and_slide(knockback)

	#TODO check that this doesn't result in any problems
	if is_on_floor():
		if current_animation.begins_with("Jump"):
			char_data.change_anim_state(char_data.ANIMATION_STATE.IDLE)

#Overload the get_class() function for hit detection purposes
func get_class():
	return "Actor"

#Base class for taking damage. Overloaded in both Player and Enemy currently.
#should re-evaluate further.
func take_damage(hit_var):
	print(hit_var)
	print(hit_var["knockback_dir"])
	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"]
	char_data.take_damage(hit_var)

	stunned = true
	stun_time += hit_var["stun"]

	print(knockback)

#Function to handle non-input/AI movements
#TODO change to move to a point, vs current move for x time
func external_movement(new_move_data:Vector2, animation_time:float, delta:float = 0):

	movement_locked = true
	external_movement_data = new_move_data #CONVOLUTED WHY
	var temp_move_data = new_move_data
	temp_move_data.x = new_move_data.x * char_data.horizontal_state_
	
	remaining_animation_time = animation_time - delta
	if remaining_animation_time <= 0:
		movement_locked = false
		no_grav = false
	else:
		no_grav = true
		temp_move_data = move_and_slide(temp_move_data)
	pass



#region ANIMATION PLAY FUNCTION SIGNALS 
func play_new_sprite():
	if not current_animation == sprite.animation:
		sprite.play(current_animation)
		sprite.playing = true

func _on_CharacterData_new_sprite_animation(new_anim):	
	current_animation = new_anim
	play_new_sprite()

func _on_CharacterData_play_animation(new_anim):
	current_animation = new_anim		
	animation_player.stop(true)
	animation_player.play(current_animation)


#TODO THIS MAY CAUSE A POTENTIAL PROBLEM IF ANIMATIONS AND SPRITES DON'T LINE UP
func _on_Sprite_animation_finished():
	if not current_animation in animation_player.get_animation_list():
		char_data.animation_completed()
		
#Does this double up with the sprite animation finish?
func _on_AnimationPlayer_animation_finished(_anim_name):
	char_data.uncancellable = false
	char_data.animation_completed()
#endregion


func _on_CharacterData_turn_sprite():
	self.scale.x *= -1

#On character death
func _on_CharacterData_dead():
	print("dead")
	destroy()

#destroy body
func destroy():
	animation_player.stop(true)
	animation_player.play("Death")
	_velocity = Vector2.ZERO
	knockback = Vector2(250,0) * -char_data.horizontal_state_

	#HACK turn off collision for anything except world
	self.collision_mask = 1024

#Shakes screen for 
func screenshake(duration, amplitude):
	emit_signal("screenshake", duration, amplitude)
