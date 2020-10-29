extends Node

export(String)var title_scene

export(NodePath)var player_path
export(NodePath)var UI_control_path

var player
var UI
var camera
var select
var slowed = false
var slowable = true

# onready var slowdown_timer = Timer.new()
# onready var slowdown_cd_timer = Timer.new()
const BULLET_TIME_LENGTH = 1
const BULLET_TIME_CD_LENGTH = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	
	player = get_node(player_path)

	camera = player.camera

	UI = get_node(UI_control_path)
	
	# slowdown_timer.set_one_shot(true)
	# slowdown_timer.set_wait_time(BULLET_TIME_LENGTH)
	# slowdown_timer.connect("timeout", self, "on_timeout_complete")
	# add_child(slowdown_timer)
	
	# slowdown_cd_timer.set_one_shot(true)
	# slowdown_cd_timer.set_wait_time(BULLET_TIME_CD_LENGTH)
	# slowdown_cd_timer.connect("timeout", self, "on_slowdown_timeout_complete")
	# add_child(slowdown_cd_timer)

	UI.set_max_HP(player.get_max_HP())
	UI.set_movelist(player.get_movelist())


func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_esc"):
		UI.pause(not get_tree().paused)
	# if Input.is_action_just_pressed("click") or Input.is_action_just_pressed("rclick"):
	# 	unslow_time()
	# check_if_slowed()
	update_HP()	
	
#POSITIONAL DATA MECHANICS
func get_player_pos():
	return player.get_position()
	
	
#CHAR HP MANAGEMENT MECHANICS
func _on_Char_game_over():
	get_tree().change_scene(title_scene)

func _on_Enemy_combo(num:int):
	UI.set_combo_count(num)


#TODO Frequency changed by attack data, or just duration/amp 
func _on_Actor_screenshake(duration, amplitude):
	camera.shake(duration, 300, amplitude)
	pass

func update_HP():
	UI.show_HP(player.get_HP())

#on start dialogue
#disable player, set invuln?
#start control

#DIALOGUE MECHANICS
func _on_Control_dialogue_finished():
	player.enable()
	player.vulnerable()

func _on_StaticBody2D_start_dialogue(dialogue_path):
	player.disable()
	player.invulnerable()
	UI.set_dialogue(dialogue_path)


#SPECIAL MECHANICS
func _on_Player_selected_move_changed(num):
	UI.change_move(num)

#DOES NOT WORK
func _input(event):
	if event.is_action_pressed("ui_esc"):
		if get_tree().paused:
			UI.pause(false)

func update_player_movelist(movelist):
	player.set_movelist(movelist)
	UI.set_movelist(player.get_movelist())

func _on_Control_update_abilities(abilities):
	update_player_movelist(abilities)