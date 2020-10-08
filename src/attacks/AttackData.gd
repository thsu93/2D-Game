extends Node
class_name AttackData

#region ATTACK-RELATED VARIABLES
var movename = "None" #Perhaps should have different names for internal and Player-facing tracking
var dmg = 0
var attacker = "None" 

var cost = 0

var slow_time = .25


var hitstun = .5

#These variables are supposed to dictate the movements of the attacker as it attacks
var velocity = 0
var direction = Vector2()
var anim_time = 0

#These variables are intended to dictate the movements of the attacked target
#is added to get_hit_var
var knockback_val = 150
var knockback_dir = Vector2(1,0)

#Is the move allowed to occur from a particular state? 
#IE if char is crouching and does a non-crouch-type move, will not come out. 
var ground_type = true #can occur when standing on ground
var air_type = true #can occur when in the air
var crouch_type = true #can occur while crouching
var running_type = false #can occur while running (ie does not stop momentum)
var dashing_type = false #can occur while dashing (ie does not cancel dash)



var priority = 0 #? unsure if will have this system

#How much damage scaling for combos
#Currently have yet to implement this system 
var damage_scaling = 1
var hitstun_scaling = 1



#Special properties of the attack, for the attacker
var invincibility = false
var invincibility_time = 0

#Special properties of the attack, when hitting the defender
var special_state = "none" #TODO Consider ways to implement ground-bounce/wall-bounce/wall-splats etc.
var rooted = false
var wall_bounces = false
var ground_bounces = false

#Timers related to the attack
var duration = 0 #How long the attack lasts for.  Unsure if necessary.
var cancellable_time #How long before the char can cancel the attack into the next or movements

#Data passed to agent hit by attack
#TODO: Decide what variables should be in here
var hit_var = {
    "attacker" : attacker,
    "movename" : movename,
    "dmg": dmg,
    "knockback_dir": knockback_dir,
    "knockback_val": knockback_val,
    "stun" : hitstun,
}

#endregion

#region ASSOCIATED EXTERNAL RESOURCES

#Sounds associated with the given attack
var attack_sound #sound char makes when attacking
var hit_sound #sound move makes on hit

#Other sprites to bring out 
var associated_scenes = null #Any external scenes (projectiles, summons, etc.)
var attack_effects #particles or other external effects
var hitspark = "default" #Type of hitspark to play on hit

#endregion

func get_hit_var():

    var updated_hit_var = {
    "attacker" : attacker,
    "movename" : movename,
    "dmg": dmg,
    "knockback_dir": knockback_dir,
    "knockback_val": knockback_val,
    "stun" : hitstun,
    "rooted" : rooted
    }
    
    return updated_hit_var

func print_data():
	print(dmg)

# FOR REFERENCE
# MUGEN's data structs
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