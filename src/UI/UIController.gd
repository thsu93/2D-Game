extends Control

signal update_abilities(abilities_list)

const INITIAL = 0


onready var combo_counter = $Panel/Label

onready var pause_menu = $PauseMenu

onready var HP_bar = $CooldownBars/HPBar

onready var dialogue_box = $Dialogue

onready var move_display = $MoveDisplay

var curr_length
var selected = INITIAL

#var dash_cd_remaining = 0
#var max_dash_cd
var slowdown_cd_remaining = 0
var max_slowdown_cd

signal dialogue_finished


func set_movelist(movelist):
	pause_menu.set_movelist(movelist)
	move_display.set_movelist(movelist)

func set_max_HP(maxHP):
	HP_bar.set_maxHP(maxHP)

func show_HP(curr_hp):
	HP_bar.value = curr_hp

	# if not on cooldown, put on cooldown
	# if on cooldown, take damage, then swap to next closest upper. If none above, then lower. If none, then stay (char should be dead)


func slowdown_cooldown(time):
	slowdown_cd_remaining = time
	max_slowdown_cd = time
#
#func dash_cooldown(time):
#	dash_cd_remaining = time
#	max_dash_cd = time

# func update_cooldowns(dmg):
# 	move_display.increase_cooldown(dmg)


func set_combo_count(num):
	combo_counter.text = "COMBO COUNT \n" + str(num)


#DIALOGUE HANDLING
func set_dialogue(dialogue):
	print(dialogue)
	dialogue_box.start(dialogue)
	dialogue_box.visible = true
	move_display.visible = false

func _on_DialogueBox_dialogue_complete():
	emit_signal("dialogue_finished")
	dialogue_box.visible = false
	move_display.visible = true


func change_move(num):
	move_display.change_selection(num)

#PAUSE HANDLING
func pause(pausing):
	pause_menu.visible = pausing

	if not pausing:
		#Send movelist update
		pass
	
	get_tree().paused = pausing
	
func _on_PauseMenu_unpause():
	pause(false)

func _on_PauseMenu_update_abilities(abilities):
	emit_signal("update_abilities", abilities)
	pass
	
