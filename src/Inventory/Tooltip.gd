extends NinePatchRect

# const Ability = preload("res://src/Scenes/Inventory/Ability.gd");

onready var nameLabel = get_node("Ability Name");
onready var typeLabel = get_node("Ability Type");

func display(_ability : Ability, mousePos : Vector2):
	visible = true

	nameLabel.set_text(_ability.abilityName)

	var type = "Normal" if _ability.moveType == 1 else "Special"
	typeLabel.set_text("Type: " + type)

	rect_size = Vector2(128, 64)
	rect_global_position = Vector2(mousePos.x + 5, mousePos.y + 5)
