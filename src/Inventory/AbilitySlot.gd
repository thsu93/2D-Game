extends Panel
class_name AbilitySlotClass

export(Global.MoveType) var moveType = Global.MoveType.DEFAULT;

var slotIndex;
var ability = null;
var abilityName
var style;
var UI = null

func _init():
	mouse_filter = Control.MOUSE_FILTER_PASS;
	style = StyleBoxFlat.new();
	refreshColors();
	style.set_border_width_all(2);
	set('custom_styles/panel', style);


func _ready():
	pass

func setAbility(newAbility):

	
#HACK SUPER HARD CODED GROSS
#TODO THIS DOES NOT SCALE WHEN MAXIMIZING WINDOW
	if UI == null:
		UI = get_tree().get_root().get_node("Stage").UI

	delete_children()
	add_child(newAbility)

	ability = newAbility
	ability.abilitySlot = self
	moveType = ability.moveType

	update_ability_info()
	refreshColors()

func pickAbility():
	ability.pickAbility();
	remove_child(ability);
	UI.add_child(ability);
	ability = null;
	refreshColors();

func putAbility(newAbility):
	ability = newAbility;
	ability.abilitySlot = self;
	ability.putAbility();
	UI.remove_child(newAbility);
	add_child(ability);
	refreshColors();

func removeAbility():
	remove_child(ability);
	ability = null;
	refreshColors();

func equipAbility(newAbility, rightClick =  true):
	if !rightClick:
		UI.remove_child(newAbility);
	putAbility(newAbility)
	refreshColors();

func refreshColors():
	if ability:
		style.bg_color = ability.color;
		style.border_color = Color(Color.black);
	else:
		style.bg_color = Color("#8B7258");
		style.border_color = Color("#534434");

func delete_children():
	for n in get_children():
		self.remove_child(n)
		n.queue_free()

func update_ability_info():
	abilityName = ability.abilityName
