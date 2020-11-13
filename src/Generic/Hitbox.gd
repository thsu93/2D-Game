class_name Hitbox
extends GenericBox


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var hitspark = $Hitspark
var actor = null


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_class():
	return "Hitbox"
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_actor(_actor):
	actor = _actor

#gets the attack data currently withhin the actor_type
func get_attack_data():
	return actor.char_data.cur_attack

#Emit a hitspark sprite at a given global position
#Will select from hitboxes associated with the attackdata
func emit_hitspark(hit_pos, dir, spark):
	#Find where the hitspark should be located
	hitspark.global_position = hit_pos
	hitspark.visible = true
	hitspark.frame = 0
	hitspark.scale.x = abs(hitspark.scale.x) * dir
	hitspark.play(spark)

#Turn off the hitspark once completed
func _on_Hitspark_animation_finished():
	hitspark.visible = false
