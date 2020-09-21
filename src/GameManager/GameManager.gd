extends Node

export(String)var title_scene

export(NodePath)var player_path
export(NodePath)var UI_control_path
export(NodePath)var camera_path
export(NodePath)var spawn_layer_path

var player
var UI
var camera
var spawn_layer
var select
var slowed = false
var slowable = true

onready var slowdown_timer = Timer.new()
onready var slowdown_cd_timer = Timer.new()
const BULLET_TIME_LENGTH = 1
const BULLET_TIME_CD_LENGTH = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	
	player = get_node(player_path)
	UI = get_node(UI_control_path)
	camera = get_node(camera_path)
	spawn_layer = get_node(spawn_layer_path)
	
	player.set_camera(camera.get_path())
	
	slowdown_timer.set_one_shot(true)
	slowdown_timer.set_wait_time(BULLET_TIME_LENGTH)
	slowdown_timer.connect("timeout", self, "on_timeout_complete")
	add_child(slowdown_timer)
	
	slowdown_cd_timer.set_one_shot(true)
	slowdown_cd_timer.set_wait_time(BULLET_TIME_CD_LENGTH)
	slowdown_cd_timer.connect("timeout", self, "on_slowdown_timeout_complete")
	add_child(slowdown_cd_timer)

	UI.set_max_HP(player.get_max_HP())
	UI.set_movelist(player.get_movelist())


func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_esc"):
		UI.pause()
	if Input.is_action_just_pressed("click") or Input.is_action_just_pressed("rclick"):
		unslow_time()
	check_if_slowed()
	update_HP()


#TIMESLOW MECHANICS
func slow_time():
	if slowable:
		slowed = true
		slowable = false
		slowdown_timer.start()

func unslow_time():
	if slowed:
		slowed = false
		slowdown_cd_timer.start()
		_on_slowdown_cooldown()

func on_timeout_complete():
	unslow_time()

func on_slowdown_timeout_complete():
	slowable = true

func check_if_slowed():
	if slowed:
		Engine.time_scale = 0.5
	else:
		Engine.time_scale = 1

func _on_slowdown_cooldown():
	UI.slowdown_cooldown(BULLET_TIME_CD_LENGTH)	
	
	
#POSITIONAL DATA MECHANICS
func get_player_pos():
	return player.get_position()
	
	
#OBJECT SPAWNING MECHANICS
func spawn(obj):
	spawn_layer.add_child(obj)

#func _on_Char_dash_cooldown(DASH_COOLDOWN):
#	UI.dash_cooldown(DASH_COOLDOWN)
#

#CHAR HP MANAGEMENT MECHANICS
func _on_Char_game_over():
	get_tree().change_scene(title_scene)

func _on_Char_damage_taken():
#	DETERMINE SCREENSHAKE VALS
	camera.shake(.3, 5, 15)

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
func _on_Control_special_change(new_selection):
	player.set_special(new_selection)
	slow_time()
