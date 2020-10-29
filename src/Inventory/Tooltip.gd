extends NinePatchRect

# const Ability = preload("res://src/Scenes/Inventory/Ability.gd");

onready var nameLabel = get_node("Ability Name");
onready var typeLabel = get_node("Ability Type");

const HOVER_TIME = .75
var timer = 0
var hovering = false

func _process(delta):
	if hovering:
		timer += delta


	if timer > HOVER_TIME:
		visible = true
	else:
		visible = false
	pass


func display(_ability : Ability, mousePos : Vector2):
	nameLabel.set_text(_ability.abilityName)

	var type = "Normal" if _ability.moveType == 1 else "Special"
	typeLabel.set_text("Type: " + type)

	rect_size = Vector2(128, 64)
	rect_global_position = Vector2(mousePos.x + 5, mousePos.y + 5)

func set_hovering():
	hovering = true

func set_not_hovering():
	hovering = false
	visible = false
	timer = 0
	pass