#Class that controls the movement and manages hitting data of the enemy
#TODO how to structure AI
class_name Enemy2
extends Actor


signal combo(num)
signal shake



onready var HP_Bar = $HP_Bar
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var player_detector = $PlayerDetector

onready var hitspark = $Sprite/Hitbox/Hitspark

var dir_switch_time = .2


var landed_hit = false


var ATTACK_TIMER = 1.5
var timer = 0
var hit_timer = 0

#JAB, LUNGE, UPPER, ELBOW

var turn_timer = 0


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

	HP_Bar.visible = false



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
			invuln_timer.start()
			char_data.toggle_invuln()

	if not char_data.cur_state in char_data.DAMAGE_STATES and not char_data.cur_state in  char_data.ACTION_STATES:
		_velocity = calculate_move_velocity(_velocity)

		if abs(_velocity.x) > 5:
			char_data.change_state(char_data.CHAR_STATE.WALKING)

		elif abs(_velocity.x) < 5:
			char_data.change_state(char_data.CHAR_STATE.STANDING)

	else:
		_velocity.x = 0

	# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

	
	turn_timer += _delta

	run_ai(_delta)

	display_HP()

#Function that runs the AI for the enemy
#Currently very basic, requires far more work
#Current plan: Will attack if player enters collider in front of enemy, with a timer changing when the enemy attacks.
func run_ai(_delta):
	timer += _delta
	if landed_hit:
		if char_data.cur_attack.movename == "Jab": 
			char_data.next_move()
			attack()
			timer = 0
			
		
		else: 
			hit_timer = 0
			char_data.base_move()

		landed_hit = false

	elif timer > ATTACK_TIMER and not char_data.cur_state in char_data.DAMAGE_STATES:
		if player_detector.is_colliding():
			timer = 0
			attack()


func attack():
	hitbox.enable()
	print(hitbox.active)
	hit_timer = 0
	char_data.change_state(char_data.CHAR_STATE.ATTACKING)

#TODO: Make the HP bars flip. Probably have them be in their own scene with own handler. 	

#Function that displays the HP bar above the enemy, if their HP is less than maximum
#More for debug purposes at the moment, will have to consider for full game
func display_HP():
	if char_data.HP < char_data.max_HP:
		HP_Bar.visible = true
		HP_Bar.value = char_data.HP/char_data.max_HP * 100
	else:
		HP_Bar.visible = false

	#If want to use flip of HP_bar, rect_scale.x, not scale.x

# This function calculates a new velocity whenever you need it.
# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
func calculate_move_velocity(linear_velocity):
	var velocity = linear_velocity

	if knockback == Vector2():

		if (not floor_detector_left.is_colliding()
			or not floor_detector_right.is_colliding()
			or is_on_wall()):
			if not char_data.cur_state == char_data.CHAR_STATE.TURNING and turn_timer > .2:
				char_data.change_state(char_data.CHAR_STATE.TURNING)
				
				#HACK timer w/ on-wall taking time to reset

				turn_timer = 0


		velocity.x = speed.x * char_data.horizontal_state_

	return velocity


#TODO clean up?
#Overloaded take_damage function, taking into consideration: 
#knockback scaling
#damage scaling
#combo counts
#stun effects
func take_damage(hit_var):
	hit_var["dmg"] /= damage_scaling_mult
	
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


	reset_all_hitboxes()
	
#Turns off hitspark when given a signal by the hitspark
func _on_Hitspark_animation_finished():
	hitspark.visible = false
	pass # Replace with function body.


#What to do when the enemy hits the player	
func _on_Hitbox_area_entered(area):
	print(hitbox.active)
	if hitbox.active:
		if area.get_class() == "Hurtbox" and area.actor_type == "player":
			var body = area.get_parent()

			# body.stunned = true

			#HITSTOP
			OS.delay_msec(25)

			# #HACK hitspark
			# var hit_pos = get_collision_position(body)
			# emit_hitspark(hit_pos)

			attack_data = char_data.cur_attack

			screenshake(attack_data.screenshake_duration, attack_data.screenshake_amp)

			#HACK TEMPORARY KNOCKBACK CALC
			attack_data.knockback_dir = Vector2(char_data.horizontal_state_ * abs(attack_data.knockback_dir.x), attack_data.knockback_dir.y)
			body.take_damage(attack_data.get_hit_var())

			landed_hit = true

