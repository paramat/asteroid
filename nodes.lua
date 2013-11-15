-- Nodes

minetest.register_node("asteroid:lava", {
	description = "AST lava",
	inventory_image = minetest.inventorycube("asteroid_lava.png"),
	drawtype = "liquid",
	tiles = {
		{name="asteroid_lava_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=3.0}}
	},
	paramtype = "light",
	light_source = LIGHT_MAX - 1,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	liquidtype = "source",
	liquid_alternative_flowing = "air",
	liquid_alternative_source = "default:lava_source",
	damage_per_second = 4*2,
	post_effect_color = {a=192, r=255, g=64, b=0},
	groups = {lava=3, liquid=2, hot=3, igniter=1},
})

minetest.register_node("asteroid:airlike", {
	drawtype = "airlike",
	tiles = {""},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = true,
	diggable = false,
	buildable_to = true,
	groups = {not_in_creative_inventory=1},
})

minetest.register_node("asteroid:stone", {
	description = "AST Stone",
	tiles = {"asteroid_stone.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:cobble", {
	description = "AST Cobble",
	tiles = {"asteroid_cobble.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:gravel", {
	description = "AST gravel",
	tiles = {"asteroid_gravel.png"},
	groups = {crumbly=2},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.2},
	}),
})

minetest.register_node("asteroid:dust", {
	description = "AST Dust",
	tiles = {"asteroid_dust.png"},
	groups = {crumbly=3},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.1},
	}),
})

minetest.register_node("asteroid:ironore", {
	description = "AST Iron Ore",
	tiles = {"asteroid_stone.png^default_mineral_iron.png"},
	groups = {cracky=2},
	drop = "default:iron_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:copperore", {
	description = "AST Copper Ore",
	tiles = {"asteroid_stone.png^default_mineral_copper.png"},
	groups = {cracky=2},
	drop = "default:copper_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:goldore", {
	description = "AST Gold Ore",
	tiles = {"asteroid_stone.png^default_mineral_gold.png"},
	groups = {cracky=2},
	drop = "default:gold_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:diamondore", {
	description = "AST Diamond Ore",
	tiles = {"asteroid_stone.png^default_mineral_diamond.png"},
	groups = {cracky=1},
	drop = "default:diamond",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:meseore", {
	description = "AST Mese Ore",
	tiles = {"asteroid_stone.png^default_mineral_mese.png"},
	groups = {cracky=1},
	drop = "default:mese_crystal",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:waterice", {
	description = "AST Water Ice",
	tiles = {"asteroid_waterice.png"},
	groups = {cracky=3,melts=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:atmos", {
	drawtype = "glasslike",
	tiles = {"asteroid_atmos.png"},
	alpha = 0,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=23, r=241, g=248, b=255},
	groups = {not_in_creative_inventory=1},
})

minetest.register_node("asteroid:snowblock", {
	description = "AST Snow Block",
	tiles = {"asteroid_snowblock.png"},
	groups = {crumbly=3,melts=2},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.2},
	}),
})

minetest.register_node("asteroid:stonebrick", {
	description = "Asteroid Stone Brick",
	tiles = {"asteroid_stonebricktop.png", "asteroid_stonebrickbot.png", "asteroid_stonebrick.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:stoneslab", {
	description = "Asteroid Stone Slab",
	tiles = {"asteroid_stonebricktop.png", "asteroid_stonebrickbot.png", "asteroid_stonebrick.png"},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	buildable_to = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5}
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5}
		},
	},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

-- Crafting

minetest.register_craft({
	output = "asteroid:cobble",
	recipe = {
		{"asteroid:stone"},
	},
})

minetest.register_craft({
	output = "asteroid:gravel",
	recipe = {
		{"asteroid:cobble"},
	},
})

minetest.register_craft({
	output = "asteroid:dust",
	recipe = {
		{"asteroid:gravel"},
	},
})

minetest.register_craft({
	output = "asteroid:stonebrick 4",
	recipe = {
		{"asteroid:stone", "asteroid:stone"},
		{"asteroid:stone", "asteroid:stone"},
	}
})

minetest.register_craft({
	output = "asteroid:stoneslab 4",
	recipe = {
		{"asteroid:stone", "asteroid:stone"},
	}
})

minetest.register_craft({
	output = "default:water_source",
	recipe = {
		{"asteroid:waterice"},
	},
})

minetest.register_craft({
	output = "default:water_source",
	recipe = {
		{"asteroid:snowblock"},
	},
})