extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#TODO DOES THIS NEED TO EXIST AS A SCRIPT?
#TODO HITBOX CURRENTLY WILL IGNORE THE WORLD ENTIRELY. NECESSARY TO UNDO?

var cur_hitdata

onready var collision_shape = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	collision_shape.disabled = true
	pass # Replace with function body.


func _on_Hitspark_animation_finished():
	$Hitspark.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



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

