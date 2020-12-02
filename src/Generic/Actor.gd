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

#sent to the gamemanager, which is then sent to the camera
signal screenshake(amplitude, duration)

const DEFAULT_ANIM_PLAYER_SPEED = 1.5

#REQUIRED NODES:

onready var char_data = $CharacterData
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var hurtbox = $Hurtbox
onready var hitbox = $Sprite/Hitbox
onready var platform_detector = $PlatformDetector

#Base actor type
#Currently include "actor", "player", "enemy"
#Used in get_class() to convey what actor type
var actor_type = "actor"

#Attack data of the currently selected move
var attack_data = null

#Amount of time player will be invulnerable for after combo-ed.
#Temporary, eventually want to get to a point where resets and such maybe?
const INVULN_TIME = .3


export var speed = Vector2(150.0, 450.0)
export var no_grav = false
onready var gravity = ProjectSettings.get("physics/2d/default_gravity")
export var movement_locked = false
var external_movement_data = Vector2()
var no_grav_during_move = true

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO
var stunned = false

var current_animation = "StandIdle"

var remaining_animation_time = 0

var knockback = Vector2.ZERO
var stun_time = 0

var combo_counter = 0

var knockback_scaling_mult = 1
var damage_scaling_mult = 1



onready var invuln_timer = Timer.new()

#initialize data associated with character
#start animations
func _ready():

	char_data.set_name(actor_type)
	hurtbox.set_actor_type(actor_type)
	hitbox.set_actor_type(actor_type)
	hitbox.set_actor(self)


	sprite.playing = true
	sprite.animation = current_animation

	
	char_data.sprite_library = sprite.frames.get_animation_names()
	char_data.animation_player_library = animation_player.get_animation_list()

	invuln_timer.set_one_shot(true)
	invuln_timer.set_wait_time(INVULN_TIME)
	invuln_timer.connect("timeout", self, "on_invuln_end")
	add_child(invuln_timer)

	animation_player.playback_speed = DEFAULT_ANIM_PLAYER_SPEED

	no_grav = false

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

	#Make sure any jumping move animations are cancelled upon landing
	if is_on_floor():
		char_data.change_air_state(char_data.AIR_STATE.GROUNDED)
	else:
		if not (char_data.cur_state == char_data.CHAR_STATE.DASHING or 
			char_data.cur_state == char_data.CHAR_STATE.BACKDASHING or
			char_data.cur_state == char_data.CHAR_STATE.ATTACKING): 
				#TODO revisit this last one, if neeed be for getting hit out of air
			char_data.change_air_state(char_data.AIR_STATE.IN_AIR)

#Getters for GameManager

#Get actor's current HP
func get_HP():
	return char_data.HP

#Get actor's current Max HP
func get_max_HP():
	return char_data.max_HP

#Overload the get_class() function for hit detection purposes
func get_class():
	return "Actor"


#reset the hitboxes to base states
#Will reset attack hitbox to off 
#Will reset hurtbox to on
func reset_all_hitboxes():
	hitbox.disable()
	hurtbox.enable()


#Method to flip the actor and state machine immediately, without processing the turn animation
#Called to flip actor to face damaged side.
#TODO Should have back-stab damage, animations?
func flip_actor():
	self.scale.x *= -1
	char_data.horizontal_state_ *= -1

#Base fxn for taking damage. Overloaded in both Player and Enemy currently.
#should re-evaluate further to simplify
func take_damage(hit_var):

	print(hit_var)
	print(hit_var["knockback_dir"])

	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"]
	char_data.take_damage(hit_var)

	stunned = true
	stun_time += hit_var["stun"]

	reset_all_hitboxes()

	print(knockback)

#At the end of invuln, turn it off in character data
func on_invuln_end():
	if char_data.invuln:
		char_data.toggle_invuln()


#Function to handle non-input/AI movements
#Given a vector for how fast to move, a float of how long to move at that speed
#delta is passed in to subtract
#no_grav_during to set to only control X or not
#Don't know why this doesn't work without using remaining_animation_time
func external_movement(new_move_data:Vector2, animation_time:float, delta:float = 0, no_grav_during = true):

	movement_locked = true
	no_grav_during_move = no_grav_during
	external_movement_data = new_move_data #CONVOLUTED WHY
	var temp_move_data = new_move_data
	temp_move_data.x = new_move_data.x * char_data.horizontal_state_
	
	remaining_animation_time = animation_time - delta
	if remaining_animation_time <= 0:
		movement_locked = false
		no_grav = false
	else:
		no_grav = no_grav_during_move
		if not no_grav:
			temp_move_data.y = _velocity.y
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
	reset_all_hitboxes()

	#HACK
	if char_data.cur_state == char_data.CHAR_STATE.ATTACKING:
		hitbox.enable()

	current_animation = new_anim
	animation_player.stop(true)
	animation_player.play(current_animation)


#THIS MAY CAUSE A POTENTIAL PROBLEM IF ANIMATIONS AND SPRITES DON'T LINE UP
		
#Overloaded to clear any external_movement_data
func _on_AnimationPlayer_animation_finished(_anim_name):
	external_movement_data = Vector2()
	remaining_animation_time = 0
	no_grav = false
	char_data.uncancellable = false
	
	animation_player.playback_speed = DEFAULT_ANIM_PLAYER_SPEED

	char_data.animation_completed()

#endregion

#Force turning of sprite without going through turn animation
func _on_CharacterData_turn_sprite():
	self.scale.x *= -1

#On character death
func _on_CharacterData_dead():
	print(actor_type, " is dead")
	destroy()

#destroy body
func destroy():
	animation_player.stop(true)
	animation_player.play("Death")
	_velocity = Vector2.ZERO
	knockback = Vector2(250,0) * -char_data.horizontal_state_

	#HACK turn off collision for anything except world
	self.collision_mask = 1024

#Shakes screen for duration and amplitude
#TODO Should this contain modifiers for frequency as well?
func screenshake(duration, amplitude):
	emit_signal("screenshake", duration, amplitude)
