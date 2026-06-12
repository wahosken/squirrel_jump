extends Node


func get_random_appearance_id_except(current_id: String) -> String:

	var ids = APPEARANCES.keys()

	ids.erase(current_id)

	if ids.is_empty():
		return current_id

	return ids.pick_random()


const APPEARANCES := {
	"squirrel": {
		"display_name": "Brown",
		"skin": "squirrel",

		"body": Color("bd967e"),
		"shade": Color("9a605b"),
		"belly": Color("fcf1d7"),
		"nose": Color("2e2931"),
		"shadow": Color("533d3f"),
		"eye": Color("fef9e8")
	},

	"squirrel_gold": {
		"display_name": "Gold",
		"skin": "squirrel",

		"body": Color("e4ac34"),
		"shade": Color("875a07"),
		"belly": Color("fcf8b0"),
		"nose": Color("1a1f38"),
		"shadow": Color("503917"),
		"eye": Color("fef9e8")
	},

	"squirrel_storybook_gold": {
		"display_name": "Storybook Gold",
		"skin": "squirrel",

		"body": Color("f0c04d"),
		"shade": Color("d4951d"),
		"belly": Color("fff0b8"),
		"nose": Color("1a1f38"),
		"shadow": Color("8b5f14"),
		"eye": Color("fef9e8")
	},

	"squirrel_white": {
		"display_name": "White",
		"skin": "squirrel",

		"body": Color("dbd8fc"),
		"shade": Color("8681c5"),
		"belly": Color("f0f0f7"),
		"nose": Color("271731"),
		"shadow": Color("474190"),
		"eye": Color("fef9e8")
	},

	"squirrel_winter_white": {
		"display_name": "Winter White",
		"skin": "squirrel",

		"body": Color("f4f0e8"),
		"shade": Color("ddd6cc"),
		"belly": Color("fffdf6"),
		"nose": Color("271731"),
		"shadow": Color("b6aea4"),
		"eye": Color("fef9e8")
	},

	"squirrel_skeleton": {
		"display_name": "Skeleton",
		"skin": "squirrel_skeleton",

		"body": Color("bd967e"),
		"shade": Color("9a605b"),
		"belly": Color("fcf1d7"),
		"nose": Color("2e2931"),
		"shadow": Color("533d3f"),
		"eye": Color("fef9e8")
	},

	# Natural Colors

	"squirrel_gray": {
		"display_name": "Gray",
		"skin": "squirrel",

		"body": Color("b5aca4"),
		"shade": Color("978b82"),
		"belly": Color("e5ddd1"),
		"nose": Color("2e2931"),
		"shadow": Color("6a6060"),
		"eye": Color("fef9e8")
	},

	"squirrel_black": {
		"display_name": "Black",
		"skin": "squirrel",

		"body": Color("56525b"),
		"shade": Color("3d3942"),
		"belly": Color("d6d0c8"),
		"nose": Color("2e2931"),
		"shadow": Color("26232a"),
		"eye": Color("fef9e8")
	},

	"squirrel_midnight": {
		"display_name": "Midnight",
		"skin": "squirrel",

		"body": Color("52586b"),
		"shade": Color("3a3f50"),
		"belly": Color("d7d8de"),
		"nose": Color("2e2931"),
		"shadow": Color("232733"),
		"eye": Color("fef9e8")
	},

	"squirrel_cocoa_black": {
		"display_name": "Cocoa Black",
		"skin": "squirrel",

		"body": Color("5a4a46"),
		"shade": Color("423532"),
		"belly": Color("ddd0c0"),
		"nose": Color("2e2931"),
		"shadow": Color("2b2321"),
		"eye": Color("fef9e8")
	},

	"squirrel_obsidian": {
		"display_name": "Obsidian",
		"skin": "squirrel",

		"body": Color("4c4c54"),
		"shade": Color("2f2f35"),
		"belly": Color("e2ddd6"),
		"nose": Color("2e2931"),
		"shadow": Color("17171a"),
		"eye": Color("fef9e8")
	},

	"squirrel_silver_black": {
		"display_name": "Silver-Black",
		"skin": "squirrel",

		"body": Color("76767c"),
		"shade": Color("535359"),
		"belly": Color("e5e5e5"),
		"nose": Color("2e2931"),
		"shadow": Color("2c2c31"),
		"eye": Color("fef9e8")
	},

	"squirrel_red": {
		"display_name": "Red",
		"skin": "squirrel",

		"body": Color("d97a4a"),
		"shade": Color("bf5d35"),
		"belly": Color("f4e7d5"),
		"nose": Color("2e2931"),
		"shadow": Color("803a2a"),
		"eye": Color("fef9e8")
	},

	"squirrel_real_red": {
		"display_name": "Real Red",
		"skin": "squirrel",

		"body": Color("d08a58"),
		"shade": Color("b86c42"),
		"belly": Color("f2e6d3"),
		"nose": Color("2e2931"),
		"shadow": Color("824a34"),
		"eye": Color("fef9e8")
	},

	"squirrel_fox_orange": {
		"display_name": "Fox",
		"skin": "squirrel",

		"body": Color("e28d47"),
		"shade": Color("c4632e"),
		"belly": Color("f6ead8"),
		"nose": Color("2e2931"),
		"shadow": Color("7f3d24"),
		"eye": Color("fef9e8")
	},

	"squirrel_autumn": {
		"display_name": "Autumn",
		"skin": "squirrel",

		"body": Color("c8754e"),
		"shade": Color("a5583a"),
		"belly": Color("eddcc9"),
		"nose": Color("2e2931"),
		"shadow": Color("6d3c2d"),
		"eye": Color("fef9e8")
	},

	"squirrel_chestnut": {
		"display_name": "Chestnut",
		"skin": "squirrel",

		"body": Color("9a6a52"),
		"shade": Color("7a4e3c"),
		"belly": Color("e7d6be"),
		"nose": Color("2e2931"),
		"shadow": Color("53342a"),
		"eye": Color("fef9e8")
	},

	"squirrel_silver": {
		"display_name": "Silver",
		"skin": "squirrel",

		"body": Color("c7c7ce"),
		"shade": Color("a6a7b0"),
		"belly": Color("ececf1"),
		"nose": Color("2e2931"),
		"shadow": Color("747681"),
		"eye": Color("fef9e8")
	},

	# Cozy Collection

	"squirrel_caramel": {
		"display_name": "Caramel",
		"skin": "squirrel",

		"body": Color("d0a06a"),
		"shade": Color("b17c4b"),
		"belly": Color("f0e2c7"),
		"nose": Color("2e2931"),
		"shadow": Color("7b5533"),
		"eye": Color("fef9e8")
	},

	"squirrel_honey": {
		"display_name": "Honey",
		"skin": "squirrel",

		"body": Color("ddb56f"),
		"shade": Color("c48f48"),
		"belly": Color("f6e8c8"),
		"nose": Color("2e2931"),
		"shadow": Color("8a6331"),
		"eye": Color("fef9e8")
	},

	"squirrel_cocoa": {
		"display_name": "Cocoa",
		"skin": "squirrel",

		"body": Color("88614e"),
		"shade": Color("67473a"),
		"belly": Color("e2d0bf"),
		"nose": Color("2e2931"),
		"shadow": Color("442f28"),
		"eye": Color("fef9e8")
	},

	"squirrel_cinnamon": {
		"display_name": "Cinnamon",
		"skin": "squirrel",

		"body": Color("c18865"),
		"shade": Color("a16649"),
		"belly": Color("ead9c7"),
		"nose": Color("2e2931"),
		"shadow": Color("704632"),
		"eye": Color("fef9e8")
	},

	# Mountain Collection

	"squirrel_granite": {
		"display_name": "Granite",
		"skin": "squirrel",

		"body": Color("a6a29b"),
		"shade": Color("86817a"),
		"belly": Color("e6e0d6"),
		"nose": Color("2e2931"),
		"shadow": Color("5c5955"),
		"eye": Color("fef9e8")
	},

	"squirrel_slate": {
		"display_name": "Slate",
		"skin": "squirrel",

		"body": Color("8a8d96"),
		"shade": Color("696c74"),
		"belly": Color("dad8d1"),
		"nose": Color("2e2931"),
		"shadow": Color("484a50"),
		"eye": Color("fef9e8")
	},

	"squirrel_alpine": {
		"display_name": "Alpine",
		"skin": "squirrel",

		"body": Color("c5d0d7"),
		"shade": Color("a3afb7"),
		"belly": Color("f0f1ec"),
		"nose": Color("2e2931"),
		"shadow": Color("707a82"),
		"eye": Color("fef9e8")
	},

	# Forest Collection

	"squirrel_moss": {
		"display_name": "Moss",
		"skin": "squirrel",

		"body": Color("9da882"),
		"shade": Color("7c8a63"),
		"belly": Color("e3ddcc"),
		"nose": Color("2e2931"),
		"shadow": Color("566043"),
		"eye": Color("fef9e8")
	},

	"squirrel_pine": {
		"display_name": "Pine",
		"skin": "squirrel",

		"body": Color("6f8570"),
		"shade": Color("556857"),
		"belly": Color("d8d4c6"),
		"nose": Color("2e2931"),
		"shadow": Color("39483a"),
		"eye": Color("fef9e8")
	},

	"squirrel_birch": {
		"display_name": "Birch",
		"skin": "squirrel",

		"body": Color("d4d0c5"),
		"shade": Color("b3aea0"),
		"belly": Color("f2efe8"),
		"nose": Color("2e2931"),
		"shadow": Color("817b73"),
		"eye": Color("fef9e8")
	},

	"squirrel_walnut": {
		"display_name": "Walnut",
		"skin": "squirrel",

		"body": Color("86624c"),
		"shade": Color("664937"),
		"belly": Color("e3d2bc"),
		"nose": Color("2e2931"),
		"shadow": Color("453024"),
		"eye": Color("fef9e8")
	},

	# Gem Collection

	"squirrel_sapphire": {
		"display_name": "Sapphire",
		"skin": "squirrel",

		"body": Color("7d96b8"),
		"shade": Color("5e7594"),
		"belly": Color("e3e6ec"),
		"nose": Color("2e2931"),
		"shadow": Color("404f67"),
		"eye": Color("fef9e8")
	},

	"squirrel_emerald": {
		"display_name": "Emerald",
		"skin": "squirrel",

		"body": Color("76a27f"),
		"shade": Color("588063"),
		"belly": Color("e5e1d6"),
		"nose": Color("2e2931"),
		"shadow": Color("3b5745"),
		"eye": Color("fef9e8")
	},

	"squirrel_amethyst": {
		"display_name": "Amethyst",
		"skin": "squirrel",

		"body": Color("9a88a8"),
		"shade": Color("796887"),
		"belly": Color("e7e0e9"),
		"nose": Color("2e2931"),
		"shadow": Color("55475f"),
		"eye": Color("fef9e8")
	},

	"squirrel_ruby": {
		"display_name": "Ruby",
		"skin": "squirrel",

		"body": Color("b27872"),
		"shade": Color("915953"),
		"belly": Color("eee2d8"),
		"nose": Color("2e2931"),
		"shadow": Color("643c39"),
		"eye": Color("fef9e8")
	},

	# Completionist

	"squirrel_moonlight": {
		"display_name": "Moonlight",
		"skin": "squirrel",

		"body": Color("dce3f0"),
		"shade": Color("b7c1d2"),
		"belly": Color("fafaf8"),
		"nose": Color("2e2931"),
		"shadow": Color("7f8899"),
		"eye": Color("fef9e8")
	},

	"squirrel_starlight": {
		"display_name": "Starlight",
		"skin": "squirrel",

		"body": Color("aeb5d8"),
		"shade": Color("848cb3"),
		"belly": Color("f0eef8"),
		"nose": Color("2e2931"),
		"shadow": Color("5a6180"),
		"eye": Color("fef9e8")
	},

	"squirrel_aurora": {
		"display_name": "Aurora",
		"skin": "squirrel",

		"body": Color("8bb5a9"),
		"shade": Color("6d958c"),
		"belly": Color("e5ece6"),
		"nose": Color("2e2931"),
		"shadow": Color("4b6761"),
		"eye": Color("fef9e8")
	}
}
