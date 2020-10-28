
#ALREADY LIFTED
#region 
# extends Panel;

# # const AbilityRect = preload("res://src/Scenes/Inventory/AbilityRect.gd")
# # const AbilitySlotClass = preload("res://src/Scenes/Inventory/ItemSlot.gd");
# # const TooltipClass = preload("res://src/Scenes/Inventory/Tooltip.gd");

# const MAX_SLOTS = 45;


# var slotList = Array();

# var holdingItem = null;
# var heldOffset = Vector2(0, 0);

# # onready var characterPanel = get_node("../CharacterPanel");
# func _ready():
# 	var slots = get_node("SlotsContainer/Slots");
# 	for _i in range(MAX_SLOTS):
# 		var slot = AbilitySlotClass.new();
# 		slot.connect("mouse_entered", self, "mouse_enter_slot", [slot]);
# 		slot.connect("mouse_exited", self, "mouse_exit_slot", [slot]);
# 		slot.connect("gui_input", self, "slot_gui_input", [slot]);
# 		slotList.append(slot);
# 		slots.add_child(slot);

# 	for i in range(10):
# 		if i == 0:
# 			continue;
# 		var panelSlot = characterPanel.slots[i];
# 		if panelSlot:
# 			panelSlot.connect("mouse_entered", self, "mouse_enter_slot", [panelSlot]);
# 			panelSlot.connect("mouse_exited", self, "mouse_exit_slot", [panelSlot]);
# 			panelSlot.connect("gui_input", self, "slot_gui_input", [panelSlot]);

# func mouse_enter_slot(_slot : AbilitySlotClass):
# 	if _slot.item:
# 		tooltip.display(_slot.item, get_global_mouse_position());

# func mouse_exit_slot(_slot : AbilitySlotClass):
# 	if tooltip.visible:
# 		tooltip.hide();
#endregion

# # func slot_gui_input(event : InputEvent, slot : AbilitySlotClass):
# # 	if event is InputEventMouseButton:
# # 		if event.button_index == BUTTON_LEFT && event.pressed:
# # 			if holdingItem:
# # 				if slot.slotType != Global.SlotType.SLOT_DEFAULT:
# # 					if canEquip(holdingItem, slot):
# # 						if !slot.item:
# # 							slot.equipItem(holdingItem, false);
# # 							holdingItem = null;
# # 						else:
# # 							var tempItem = slot.item;
# # 							slot.pickItem();
# # 							tempItem.rect_global_position = event.global_position - heldOffset;
# # 							slot.equipItem(holdingItem, false);
# # 							holdingItem = tempItem;
# # 				elif slot.item:
# # 					var tempItem = slot.item;
# # 					slot.pickItem();
# # 					tempItem.rect_global_position = event.global_position - heldOffset;
# # 					slot.putItem(holdingItem);
# # 					holdingItem = tempItem;
# # 				else:
# # 					slot.putItem(holdingItem);
# # 					holdingItem = null;
# # 			elif slot.item:
# # 				holdingItem = slot.item;
# # 				heldOffset = event.global_position - holdingItem.rect_global_position;
# # 				slot.pickItem();
# # 				holdingItem.rect_global_position = event.global_position - heldOffset;
# # 		elif event.button_index == BUTTON_RIGHT && !event.pressed:
# # 			if slot.slotType != Global.SlotType.SLOT_DEFAULT:
# # 				if slot.item:
# # 					var freeSlot = getFreeSlot();
# # 					if freeSlot:
# # 						var item = slot.item;
# # 						slot.removeItem();
# # 						freeSlot.setItem(item);
# # 			else:
# # 				if slot.item:
# # 					var itemSlotType = slot.item.slotType;
# # 					var panelSlot = characterPanel.getSlotByType(slot.item.slotType);
# # 					if itemSlotType == Global.SlotType.SLOT_RING:
# # 						if panelSlot[0].item && panelSlot[1].item:
# # 							var panelItem = panelSlot[0].item;
# # 							panelSlot[0].removeItem();
# # 							var slotItem = slot.item;
# # 							slot.removeItem();
# # 							slot.setItem(panelItem);
# # 							panelSlot[0].setItem(slotItem);
# # 							pass
# # 						elif !panelSlot[0].item && panelSlot[1].item || !panelSlot[0].item && !panelSlot[1].item:
# # 							var tempItem = slot.item;
# # 							slot.removeItem();
# # 							panelSlot[0].equipItem(tempItem);
# # 						elif panelSlot[0].item && !panelSlot[1].item:
# # 							var tempItem = slot.item;
# # 							slot.removeItem();
# # 							panelSlot[1].equipItem(tempItem);
# # 							pass
# # 					else:
# # 						if panelSlot.item:
# # 							var panelItem = panelSlot.item;
# # 							panelSlot.removeItem();
# # 							var slotItem = slot.item;
# # 							slot.removeItem();
# # 							slot.setItem(panelItem);
# # 							panelSlot.setItem(slotItem);
# # 						else:
# # 							var tempItem = slot.item;
# # 							slot.removeItem();
# # 							panelSlot.equipItem(tempItem);

# # func _input(event : InputEvent):
# # 	if holdingItem && holdingItem.picked:
# # 		holdingItem.rect_global_position = event.global_position - heldOffset;

# # func getFreeSlot():
# # 	for slot in slotList:
# # 		if !slot.item:
# # 			return slot;

# # func canEquip(item, slot):
# # 	var ring = Global.SlotType.SLOT_RING;
# # 	var ring2 = Global.SlotType.SLOT_RING2;
# # 	return item.slotType == slot.slotType || item.slotType == ring && (slot.slotType == ring || slot.slotType == ring2);