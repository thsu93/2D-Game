extends Node
class_name Global

enum MoveType {
	DEFAULT = 0,
	NORMAL = 1,
	SPECIAL = 2
}

const MoveColor = {
	"Jab": {
		"background": "#808080"
	},
	"Hook": {
		"background": "#1b51d1",
	},
	"Combo (Light)": {
		"background": "#ffdf1d",
	},
	"Corkscrew": {
		"background": "#ffdf1d",
	},
	"Overhead": {
		"background": "#ffdf1d",
	},
	"Combo (Heavy)": {
		"background": "#ec5300",
	},
}

const abilityImages = [
	preload("res://src/Inventory/images/Ac_Ring05.png"),
	preload("res://src/Inventory/images/A_Armor05.png"),
	preload("res://src/Inventory/images/A_Armour02.png"),
	preload("res://src/Inventory/images/A_Shoes03.png"),
	preload("res://src/Inventory/images/C_Elm03.png"),
	preload("res://src/Inventory/images/E_Wood02.png"),
	preload("res://src/Inventory/images/P_Red02.png"),
	preload("res://src/Inventory/images/W_Sword001.png"),
	preload("res://src/Inventory/images/Ac_Necklace03.png"),
];

const abilityDictionary = {
	"Jab": {
		"abilityName": "Jab",
		"abilityIcon": abilityImages[0],
		"bg_color" : Color.red,
		"MoveType": MoveType.NORMAL,
	},
	"Hook": {
		"abilityName": "Hook",
		"abilityIcon": abilityImages[7],
		"bg_color" : Color.orange,
		"MoveType": MoveType.NORMAL,
	},
	"Combo (Light)": {
		"abilityName": "Combo (Light)",
		"abilityIcon": abilityImages[2],
		"bg_color" : Color.purple,
		"MoveType": MoveType.NORMAL,
	},
	"Corkscrew": {
		"abilityName": "Corkscrew",
		"abilityIcon": abilityImages[4],
		"bg_color" : Color.pink,
		"MoveType": MoveType.SPECIAL,
	},
	"Overhead": {
		"abilityName": "Overhead",
		"abilityIcon": abilityImages[3],
		"bg_color" : Color.green,
		"MoveType": MoveType.SPECIAL,
	},
	"Combo (Heavy)": {
		"abilityName": "Combo (Heavy)",
		"abilityIcon": abilityImages[5],
		"bg_color" : Color.brown,
		"MoveType": MoveType.SPECIAL
	},
};