class_name Actor
extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.

var actor_type = "unknown"


export var speed = Vector2(150.0, 450.0)
export var no_grav = false
onready var gravity = ProjectSettings.get("physics/2d/default_gravity")

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO
var stunned = false

#Be aware that these will require all nodes of agents to be named explicitly as such
#unless manually overloaded
onready var char_data = $CharacterData


onready var sprite = $Sprite


onready var animation_player = $AnimationPlayer
var current_animation = ""

var knockback = Vector2.ZERO
var overwrite = false

# _physics_process is called after the inherited _physics_process function.
# This allows the Player and Enemy scenes to be affected by gravity.
func _physics_process(delta):

	#Should stunned leave vertical falling? choice? 
	if stunned:
		_velocity = Vector2()
	else:
		if no_grav:
		#HACK probably not the best way to handle this
			_velocity.y = 0
		else:
			_velocity.y += gravity * delta
		
		if knockback != Vector2.ZERO:
			knockback = knockback.move_toward(Vector2.ZERO, 1000*delta)
			knockback = move_and_slide(knockback)

#Overload the get_class() function for hit detection purposes
func get_class():
	return "Actor"

func take_damage(hit_var):
	print("TOOK DAMAGE    ", hit_var["dmg"], "     ", hit_var["movename"])
	print(hit_var["knockback_dir"])
	knockback = hit_var["knockback_dir"] * hit_var["knockback_val"]
	char_data.take_damage(hit_var["dmg"])
	print(knockback)


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
	animation_player.play(current_animation)

	
func _on_Sprite_animation_finished():
	#HACK reset speeds shouldn't be like this
	if not current_animation in animation_player.get_animation_list():
		char_data.animation_completed()
		
#Does this double up with the sprite animation finish?
func _on_AnimationPlayer_animation_finished(_anim_name):
	char_data.uncancellable = false
	char_data.animation_completed()
#endregion


func _on_CharacterData_turn_sprite():
	self.scale.x *= -1