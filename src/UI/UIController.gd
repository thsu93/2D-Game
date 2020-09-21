extends Control

#TODO:
#remove references to dash cooldown bar

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const INITIAL = 0

onready var grid = $MoveDisplay/Grid
onready var length = grid.length
var curr_length
var selected = INITIAL
#
#onready var dash_cd_bar = $CooldownBars/DashCooldownBar
#var dash_cd_remaining = 0
#var max_dash_cd
onready var slowdown_cd_bar = $CooldownBars/BulletTimeCooldownBar
onready var HP_bar = $CooldownBars/HPBar
var slowdown_cd_remaining = 0
var max_slowdown_cd

signal special_change
signal dialogue_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_length = length

func _process(delta):
	var dir = ""
	if Input.is_action_just_released("ui_swap_down"):
		dir = "down"
	if Input.is_action_just_released("ui_swap_up"):
		dir = "up"

	if not dir == "":
		var changed = grid.change_selection(dir)
		if changed:
			emit_signal("special_change", grid.get_selected_special())

	if slowdown_cd_remaining > 0:
		slowdown_cd_remaining -= delta
		slowdown_cd_bar.value = slowdown_cd_remaining / max_slowdown_cd * 100
#
#	if dash_cd_remaining > 0:
#		dash_cd_remaining -= delta
#		dash_cd_bar.value = dash_cd_remaining / max_dash_cd * 100


func get_total_cd():
	return grid.get_total_cd()

func set_movelist(movelist):
	grid.set_movelist(movelist)

func set_max_HP(maxHP):
	HP_bar.set_maxHP(maxHP)




func show_HP(curr_hp):
	$CooldownBars/HPBar.value = curr_hp

	# if not on cooldown, put on cooldown
	# if on cooldown, take damage, then swap to next closest upper. If none above, then lower. If none, then stay (char should be dead)


func slowdown_cooldown(time):
	slowdown_cd_remaining = time
	max_slowdown_cd = time
#
#func dash_cooldown(time):
#	dash_cd_remaining = time
#	max_dash_cd = time

func update_cooldowns(dmg):
	grid.increase_cooldown(dmg)



#DIALOGUE HANDLING
func set_dialogue(dialogue):
	print(dialogue)
	$Dialogue.start(dialogue)
	$Dialogue.visible = true
	$CooldownBars.visible = false
	$MoveDisplay.visible = false

func _on_DialogueBox_dialogue_complete():
	emit_signal("dialogue_finished")
	$Dialogue.visible = false
	$CooldownBars.visible = true
	$MoveDisplay.visible = true








#PAUSE HANDLING
func pause():
	$PauseMenu.visible = true
	get_tree().paused = not get_tree().paused

func _on_PauseMenu_update_abilities(abilities):
	# $MoveDisplay/Grid.set_new_ability_order(abilities)
	pass


