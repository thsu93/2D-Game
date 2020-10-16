extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#TODO DOES THIS NEED TO EXIST AS A SCRIPT?
#TODO HITBOX CURRENTLY WILL IGNORE THE WORLD ENTIRELY. NECESSARY TO UNDO?

var cur_attack_data = null
var dir = 1
signal time_slow(slow_amt)

onready var hitspark = $Hitbox/Hitspark
onready var collision_shape = $Hitbox/CollisionShape2D
var actor = "player"
var target = "enemy"

# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.disabled = true
	pass # Replace with function body.

func set_actor(new_actor):
	actor = new_actor

func set_target(new_target):
	target = new_target

func _on_Hitspark_animation_finished():
	hitspark.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Hitbox_body_shape_entered(body_id, body, body_shape, area_shape):
	if body.get_class() == "Actor" and body.actor_type == target:

		# body.stunned = true

		#HITSTOP
		OS.delay_msec(25)

		#HACK hitspark
		var hit_pos = get_collision_position(body)
		emit_hitspark(hit_pos)


		#HACK TEMPORARY KNOCKBACK CALC
		cur_attack_data.knockback_dir = Vector2(dir * abs(cur_attack_data.knockback_dir.x), cur_attack_data.knockback_dir.y)
		body.take_damage(cur_attack_data.get_hit_var())


		if actor == "player":
			emit_signal("time_slow", cur_attack_data.slow_time)
		
		#TODO How to prevent double-hitting of moves
		#Is this even necessary? It won't maintain hitting
		#Should probably handle this differently, given the possibility of hitting through two enemies
		#attack_hitbox.get_node("CollisionShape2D").disabled = true



#HACK hitspark location calculation
#Uses the average position between the attack hitbox and the target hurtbox.  Not ideal way to calculate. 
#Ideal would probably be find both hitbox+hurtbox position and extents, calculate the overlapped regions and then find the middle of the overlapped region
func get_collision_position(body):
	var body_area_pos = body.get_node("CollisionShape2D").global_position
	var self_body_pos = collision_shape.global_position
	return (body_area_pos + self_body_pos) / 2


#Emit a hitspark sprite at the given position		
func emit_hitspark(hit_pos):
	#Find where the hitspark should be located
	hitspark.global_position = hit_pos
	hitspark.visible = true
	hitspark.frame = 0
	hitspark.scale.x = abs(hitspark.scale.x) * dir
	hitspark.play(cur_attack_data.hitspark)
#endregion

# type GetHitVar struct {
# 	hitBy          [][2]int32
# 	hit1           [2]int32
# 	hit2           [2]int32
# 	attr           int32
# 	_type          HitType
# 	airanimtype    Reaction
# 	groundanimtype Reaction
# 	airtype        HitType
# 	groundtype     HitType
# 	damage         int32
# 	hitcount       int32
# 	fallcount      int32
# 	hitshaketime   int32
# 	hittime        int32
# 	slidetime      int32
# 	ctrltime       int32
# 	xvel           float32
# 	yvel           float32
# 	yaccel         float32
# 	hitid          int32
# 	xoff           float32
# 	yoff           float32
# 	fall           Fall
# 	playerNo       int
# 	fallf          bool
# 	guarded        bool
# 	p2getp1state   bool
# 	forcestand     bool
# 	dizzypoints    int32
# 	guardpoints    int32
# 	redlife        int32
# 	score          float32
# }


# type Projectile struct {
# 	hitdef          HitDef
# 	id              int32
# 	anim            int32
# 	anim_fflg       bool
# 	hitanim         int32
# 	hitanim_fflg    bool
# 	remanim         int32
# 	remanim_fflg    bool
# 	cancelanim      int32
# 	cancelanim_fflg bool
# 	scale           [2]float32
# 	angle           float32
# 	clsnScale       [2]float32
# 	remove          bool
# 	removetime      int32
# 	velocity        [2]float32
# 	remvelocity     [2]float32
# 	accel           [2]float32
# 	velmul          [2]float32
# 	hits            int32
# 	misstime        int32
# 	priority        int32
# 	priorityPoints  int32
# 	sprpriority     int32
# 	edgebound       int32
# 	stagebound      int32
# 	heightbound     [2]int32
# 	pos             [2]float32
# 	facing          float32
# 	shadow          [3]int32
# 	supermovetime   int32
# 	pausemovetime   int32
# 	ani             *Animation
# 	timemiss        int32
# 	hitpause        int32
# 	oldPos          [2]float32
# 	newPos          [2]float32
# 	aimg            AfterImage
# 	palfx           *PalFX
# 	localscl        float32
# 	parentAttackmul float32
# 	platform        bool
# 	platformWidth   [2]float32
# 	platformHeight  [2]float32
# 	platformAngle   float32
# 	platformFence   bool
# }

