extends Panel


const abilityrect = preload("res://src/Inventory/AbilityRect.gd")

signal holding(held)

# Change this to initially generate, and report back post-unpause what the new order of abilities is
onready var normals_display = $HBoxContainer/Normals
onready var specials_display = $HBoxContainer/Specials
onready var tooltip = $Tooltip

var holdingAbility = null
var original_slot = null
var heldOffset = Vector2(0, 0);


func _ready():
	initialize_all_slots()

func initialize_all_slots():
	for slot in normals_display.get_children():
		slot.connect("mouse_entered", self, "mouse_enter_slot", [slot]);
		slot.connect("mouse_exited", self, "mouse_exit_slot", [slot]);
		slot.connect("gui_input", self, "slot_gui_input", [slot]);
		slot.moveType = Global.MoveType.NORMAL

	for slot in specials_display.get_children():
		slot.connect("mouse_entered", self, "mouse_enter_slot", [slot]);
		slot.connect("mouse_exited", self, "mouse_exit_slot", [slot]);
		slot.connect("gui_input", self, "slot_gui_input", [slot]);
		slot.moveType = Global.MoveType.SPECIAL


func mouse_enter_slot(_slot : AbilitySlotClass):
	if _slot.ability:
		tooltip.set_hovering()
		tooltip.display(_slot.ability, get_global_mouse_position())

func mouse_exit_slot(_slot : AbilitySlotClass):
	if tooltip.visible:
		tooltip.set_not_hovering();

#Given a X by 2 array, create appropriate abilitys in each slot that match current moveset
func populate(array):
	var normals_list = []
	var specials_list = []
	for move in array[0]:
		normals_list.append(Global.abilityDictionary[move])
	for move in array[1]:
		specials_list.append(Global.abilityDictionary[move])
	
	for i in range(normals_list.size()):

		var temp_normal_slot = normals_display.get_child(i)
		var temp_special_slot = specials_display.get_child(i)

		var temp_normal = abilityrect.new(normals_list[i], temp_normal_slot)
		var temp_special = abilityrect.new(specials_list[i], temp_special_slot)

		temp_normal_slot.setAbility(temp_normal)
		temp_special_slot.setAbility(temp_special)


func update_abilities():
	pass

func get_updated_list():
	var normals_list = []
	var specials_list = []
	for move in normals_display.get_children():
		normals_list.append(move.ability.abilityName)
	for move in specials_display.get_children():
		specials_list.append(move.ability.abilityName)
	return [normals_list, specials_list]


func slot_gui_input(event : InputEvent, slot : AbilitySlotClass):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if holdingAbility:
				if slot.moveType != Global.MoveType.DEFAULT: #Unnecessary, probably
					if canEquip(holdingAbility, slot):

						if !slot.ability:
							slot.equipAbility(holdingAbility, false);
							holdingAbility = null;

						else:
							var tempAbility = slot.ability;
							slot.pickAbility();
							tempAbility.rect_global_position = event.global_position - heldOffset;
							slot.equipAbility(holdingAbility, false);
							holdingAbility = tempAbility;

				elif slot.ability:
					var tempAbility = slot.ability;
					slot.pickAbility();
					tempAbility.rect_global_position = event.global_position - heldOffset;
					slot.putAbility(holdingAbility);
					holdingAbility = tempAbility;

				else:
					slot.putAbility(holdingAbility);
					holdingAbility = null;

			elif slot.ability:
				holdingAbility = slot.ability;
				heldOffset = event.global_position - holdingAbility.rect_global_position;
				slot.pickAbility();
				holdingAbility.rect_global_position = event.global_position - heldOffset;



		emit_signal("holding", not holdingAbility == null)
		# elif event.button_index == BUTTON_RIGHT && !event.pressed:
		# 	if slot.slotType != Global.SlotType.SLOT_DEFAULT:
		# 		if slot.ability:
		# 			var freeSlot = getFreeSlot();
		# 			if freeSlot:
		# 				var ability = slot.ability;
		# 				slot.removeAbility();
		# 				freeSlot.setAbility(ability);
		# 	else:
		# 		if slot.ability:
		# 			var abilitySlotType = slot.ability.slotType;
		# 			var panelSlot = characterPanel.getSlotByType(slot.ability.slotType);
		# 			if abilitySlotType == Global.SlotType.SLOT_RING:
		# 				if panelSlot[0].ability && panelSlot[1].ability:
		# 					var panelAbility = panelSlot[0].ability;
		# 					panelSlot[0].removeAbility();
		# 					var slotAbility = slot.ability;
		# 					slot.removeAbility();
		# 					slot.setAbility(panelAbility);
		# 					panelSlot[0].setAbility(slotAbility);
		# 					pass
		# 				elif !panelSlot[0].ability && panelSlot[1].ability || !panelSlot[0].ability && !panelSlot[1].ability:
		# 					var tempAbility = slot.ability;
		# 					slot.removeAbility();
		# 					panelSlot[0].equipAbility(tempAbility);
		# 				elif panelSlot[0].ability && !panelSlot[1].ability:
		# 					var tempAbility = slot.ability;
		# 					slot.removeAbility();
		# 					panelSlot[1].equipAbility(tempAbility);
		# 					pass
		# 			else:
		# 				if panelSlot.ability:
		# 					var panelAbility = panelSlot.ability;
		# 					panelSlot.removeAbility();
		# 					var slotAbility = slot.ability;
		# 					slot.removeAbility();
		# 					slot.setAbility(panelAbility);
		# 					panelSlot.setAbility(slotAbility);
		# 				else:
		# 					var tempAbility = slot.ability;
		# 					slot.removeAbility();
		# 					panelSlot.equipAbility(tempAbility);

#TODO have the image follow the cursor around. Unsure why it doesn't right now.
func _input(event : InputEvent):
	if holdingAbility && holdingAbility.picked:
		holdingAbility.rect_global_position = event.global_position - heldOffset

# func getFreeSlot():
# 	for slot in slotList:
# 		if !slot.ability:
# 			return slot;

func canEquip(ability, slot):
	return ability.moveType == slot.moveType
