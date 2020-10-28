extends TextureRect
class_name Ability

var abilityDef
var abilityName
var moveType = 0
var color = null
var abilitySlot = null
var picked = false;

func _init(_definition, _slot):

	abilityDef = _definition

	abilityName = abilityDef["abilityName"]

	moveType = abilityDef["MoveType"]

	color = abilityDef["bg_color"]

	abilitySlot = _slot
	
	texture = abilityDef["abilityIcon"]
	mouse_filter = Control.MOUSE_FILTER_PASS;

	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND;


func pickAbility():
	mouse_filter = Control.MOUSE_FILTER_IGNORE;
	picked = true;

func putAbility():
	rect_position = Vector2(0, 0);
	mouse_filter = Control.MOUSE_FILTER_PASS;
	picked = false;
