extends Node
class_name AttackData

var movename = "None"
var dmg = 0
var attacker = "None"

var cost = 0

#movement modifiers
var velocity = 0
var direction = 0
var duration = 0

#TODO: decide if want the following datums
var ground_type = "" #Standing, Crouching, Jumping, others? T/F vs descriptor
var air_type = ""
var priority = 0 #? unsure if will have this system
var knockback_val = 0
var knockback_dir = Vector2(1,0)
var scaling = 1
var hitstun = 1
var invincibility = false
var invincibility_time = 0
var special_state = "none"

var attack_sound #sound char makes when attacking
var hit_sound #sound move makes on hit

var cancellable_time 

var get_hit_var = {
    "dmg": dmg,
    "knockback_dir": knockback_dir,
    "knockback_val": knockback_val,
} #data passed to agent hit by attack
#pass as dict

func print_data():
	print(dmg)

# type HitDef struct {
# 	hitsound                   [2]int32
# 	guardsound                 [2]int32
# 	ground_type                HitType
# 	air_type                   HitType
# 	ground_slidetime           int32
# 	guard_slidetime            int32
# 	ground_hittime             int32
# 	guard_hittime              int32
# 	air_hittime                int32
# 	guard_ctrltime             int32
# 	airguard_ctrltime          int32
# 	guard_dist                 int32
# 	yaccel                     float32
# 	ground_velocity            [2]float32
# 	guard_velocity             float32
# 	air_velocity               [2]float32
# 	airguard_velocity          [2]float32
# 	ground_cornerpush_veloff   float32
# 	air_cornerpush_veloff      float32
# 	down_cornerpush_veloff     float32
# 	guard_cornerpush_veloff    float32
# 	airguard_cornerpush_veloff float32
# 	air_juggle                 int32
# 	p1sprpriority              int32
# 	p2sprpriority              int32
# 	p1getp2facing              int32
# 	p1facing                   int32
# 	p2facing                   int32
# 	p1stateno                  int32
# 	p2stateno                  int32
# 	p2getp1state               bool
# 	forcestand                 int32
# 	ground_fall                bool
# 	air_fall                   bool
# 	down_velocity              [2]float32
# 	down_hittime               int32
# 	down_bounce                bool
# 	id                         int32
# 	chainid                    int32
# 	nochainid                  [2]int32
# 	hitonce                    int32
# 	numhits                    int32
# 	hitgetpower                int32
# 	guardgetpower              int32
# 	hitgivepower               int32
# 	guardgivepower             int32
# 	palfx                      PalFXDef
# 	envshake_time              int32
# 	envshake_freq              float32
# 	envshake_ampl              int32
# 	envshake_phase             float32
# 	mindist                    [2]float32
# 	maxdist                    [2]float32
# 	snap                       [2]float32
# 	snapt                      int32
# 	fall                       Fall
# 	playerNo                   int
# 	kill                       bool
# 	guard_kill                 bool
# 	forcenofall                bool
# 	lhit                       bool
# 	dizzypoints                int32
# 	guardpoints                int32
# 	redlife                    int32
# 	score                      [2]float32
# }