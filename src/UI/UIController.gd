extends Control

#TODO:
#remove references to dash cooldown bar

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const INITIAL = 0

onready var grid = $MoveDisplay/Grid
onready var length = grid.length
onready var combo_counter = $Panel/Label
var curr_length
var selected = INITIAL
#
#onready var dash_cd_bar = $CooldownBars/DashCooldownBar
#var dash_cd_remaining = 0
#var max_dash_cd
onready var HP_bar = $CooldownBars/HPBar
var slowdown_cd_remaining = 0
var max_slowdown_cd

signal dialogue_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	curr_length = length

func _process(delta):
	pass

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


func set_combo_count(num):
	combo_counter.text = "COMBO COUNT \n" + str(num)


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


func change_move(num):
	grid.change_selection(num)





#PAUSE HANDLING
func pause():
	$PauseMenu.visible = true
	get_tree().paused = not get_tree().paused

func _on_PauseMenu_update_abilities(abilities):
	# $MoveDisplay/Grid.set_new_ability_order(abilities)
	pass


