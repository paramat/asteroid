-- asteroid 0.1.1 by paramat
-- For latest stable Minetest back to 0.4.3
-- Depends default
-- Licenses: Code WTFPL. Textures CC BY-SA: stone by celeron55 (recoloured), sand by VanessaE (recoloured), snow and ice by Splizard.

-- Variables

local ONGEN = true -- (true / false) Enable / disable generation.
local YMIN = 13000 -- Approximate realm bottom.
local YMAX = 14000 -- Approximate realm top.
local XMIN = -16000 -- Approximate realm edges.
local XMAX = 16000
local ZMIN = -16000
local ZMAX = 16000
local ASCOTH = 0.8 -- 0.8 -- Asteroid / comet nucleus noise threshold. Controls size.
local SQUFAC = 2 -- 2 -- Vertical squash factor.

local FISOFF = 0.01 -- 0.01 -- Fissure noise offset. Controls size of fissures and amount / size of fissure entrances at surface.
local FISEXP = 0.4 -- 0.4 -- Fissure expansion rate under surface.

local MESCHA = 23*23*23 -- 23*23*23 -- 1/x chance of mese.
local IROCHA = 5*5*5 -- 5*5*5 -- 1/x chance of iron ore in asteroid.

local DUSAMP = 0.1 -- 0.1 -- Dust depth amplitude and depth of ores.
local DUSRAN = 0.01 -- 0.01 -- Dust depth randomness.
local DUSOFF = 0 -- 0 -- Dust depth offset.

local SNOAMP = 0.1 -- 0.1 -- Snow depth amplitude.
local SNORAN = 0.01 -- 0.01 -- Snow depth randomness.
local SNOOFF = 0 -- 0 -- Snow depth offset.

local ATMDEP = 0.3 -- 0.3 -- Comet atmosphere depth.

local PROG = true

-- 3D Perlin noise 1 for surfaces
local SEEDDIFF1 = 46894681234
local OCTAVES1 = 6 -- 6
local PERSISTENCE1 = 0.5 -- 0.5
local SCALE1 = 256 -- 256

-- 3D Perlin noise 2 for dust depth
local SEEDDIFF2 = 21532
local OCTAVES2 = 4 -- 4
local PERSISTENCE2 = 0.6 -- 0.6
local SCALE2 = 128 -- 128

-- 3D Perlin noise 3 for fissures
local SEEDDIFF3 = 6398643
local OCTAVES3 = 4 -- 4
local PERSISTENCE3 = 0.5 -- 0.5
local SCALE3 = 64 -- 64

-- Stuff

asteroid = {}

-- Nodes of Yesod

minetest.register_node("asteroid:stone", {
	description = "AST Stone",
	tiles = {"asteroid_stone.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:ironore", {
	description = "AST Iron Ore",
	tiles = {"asteroid_stone.png^default_mineral_iron.png"},
	groups = {cracky=3},
	drop = "default:iron_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:dust", {
	description = "AST Dust",
	tiles = {"asteroid_dust.png"},
	groups = {crumbly=3},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.1},
	}),
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
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=24, r=255, g=255, b=255},
	groups = {not_in_creative_inventory=1},
})

minetest.register_node("asteroid:snode", {
	description = "AST Snow Node",
	tiles = {"asteroid_snode.png"},
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
	output = "default:cobble",
	recipe = {
		{"asteroid:stone"},
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
		{"asteroid:snode"},
	},
})

-- On dignode. Atmosphere flows into a dug hole.

minetest.register_on_dignode(function(pos, oldnode, digger)
	local env = minetest.env
	local x = pos.x
	local y = pos.y
	local z = pos.z
	for i = -1,1 do
	for j = -1,1 do
	for k = -1,1 do
		if not (i == 0 and j == 0 and k == 0) then
			local nodename = env:get_node({x=x+i,y=y+j,z=z+k}).name
			if nodename == "asteroid:atmos" then	
				env:add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
				print ("[moonrealm] Atmosphere flows into hole")
				return
			end
		end
	end
	end
	end
end)

-- On generated function

if ONGEN then
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.x < XMIN or maxp.x > XMAX
		or minp.y < YMIN or maxp.y > YMAX
		or minp.z < ZMIN or maxp.z > ZMAX then
			return
		end
		local x1 = maxp.x
		local y1 = maxp.y
		local z1 = maxp.z
		local x0 = minp.x
		local y0 = minp.y
		local z0 = minp.z
		local env = minetest.env
		local perlin1 = env:get_perlin(SEEDDIFF1, OCTAVES1, PERSISTENCE1, SCALE1)
		local perlin2 = env:get_perlin(SEEDDIFF2, OCTAVES2, PERSISTENCE2, SCALE2)
		local perlin3 = env:get_perlin(SEEDDIFF3, OCTAVES3, PERSISTENCE3, SCALE3)
		for x = x0, x1 do -- for each plane do
			if PROG then
				print ("[asteroid] plane "..x - x0.." chunk ("..minp.x.." "..minp.y.." "..minp.z..")")
			end
			for z = z0, z1 do -- for each column do
				for y = y0, y1 do -- for each node do
					local noise1 = perlin1:get3d({x=x,y=y*SQUFAC,z=z})
					local noise1abs = math.abs(noise1) 
					if noise1abs > ASCOTH then -- if below surface then
						local comet = false
						if noise1 < 0 then comet = true end
						local noise3 = perlin3:get3d({x=x,y=y,z=z})
						local noise1dep = noise1abs - ASCOTH -- noise1dep zero at surface
						if math.abs(noise3) - noise1dep * FISEXP - FISOFF > 0 then -- if no cave then
							local ore = false
							if noise1dep > DUSAMP then ore = true end
							local noise2 = perlin2:get3d({x=x,y=y,z=z})
							if noise1 > 0 then -- if asteroid then
								local thrsto = noise2 * DUSAMP + DUSOFF + math.random() * DUSRAN
								if noise1dep >= thrsto then -- if stone then
									if ore and math.random(MESCHA) == 2 then
										env:add_node({x=x,y=y,z=z},{name="default:mese"})
									elseif ore and math.random(IROCHA) == 2 then
										env:add_node({x=x,y=y,z=z},{name="asteroid:ironore"})
									else
										env:add_node({x=x,y=y,z=z},{name="asteroid:stone"})
									end
								else -- dust
									env:add_node({x=x,y=y,z=z},{name="asteroid:dust"})
								end
							else -- comet
								local thrice = noise2 * SNOAMP + SNOOFF + math.random() * SNORAN
								if noise1dep >= thrice then -- if ice then
									if ore and math.random(MESCHA) == 2 then
										env:add_node({x=x,y=y,z=z},{name="default:mese"})
									else
										env:add_node({x=x,y=y,z=z},{name="asteroid:waterice"})
									end
								else -- snow node
									env:add_node({x=x,y=y,z=z},{name="asteroid:snode"})
								end
							end
						elseif comet then -- cave, if comet then add comet atmosphere
							env:add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
						end
					elseif noise1 < -ASCOTH + ATMDEP then -- if comet atmosphere
						env:add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
					end
				end
			end
		end
	end)
end
