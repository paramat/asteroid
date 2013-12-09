-- asteroid lvm/pm version 0.4.4 by paramat
-- For latest stable Minetest back to 0.4.8
-- Depends default
-- Licenses: code WTFPL, textures CC BY SA
-- For use as a stacked realm in v6, indev or v7 mapgen

-- TODO
-- Glass from dust, mese powered furnace?
-- Hydroponics in dust, nutrient liquid from leaves and water ice

-- Variables

local YMIN = 11000 -- Approximate realm limits.
local YMAX = 13000
local XMIN = -33000
local XMAX = 33000
local ZMIN = -33000
local ZMAX = 33000

local ASCOT = 1.0 --  -- Large asteroid / comet nucleus noise threshold.
local SASCOT = 1.0 --  -- Small asteroid / comet nucleus noise threshold.
local STOT = 0.125 --  -- Asteroid stone threshold.
local COBT = 0.05 --  -- Asteroid cobble threshold.
local GRAT = 0.02 --  -- Asteroid gravel threshold.
local ICET = 0.05 --  -- Comet ice threshold.
local ATMOT = -0.2 --  -- Comet atmosphere threshold.
local FISTS = 0.01 -- 0.01 -- Fissure noise threshold at surface. Controls size of fissures and amount / size of fissure entrances at surface.
local FISEXP = 0.3 -- 0.3 -- Fissure expansion rate under surface.
local ORECHA = 3*3*3 --  -- Ore 1/x chance per stone node (iron, mese ore, copper, gold, diamond).
local CPCHU = 0 -- Maximum craters per chunk.
local CRMIN = 5 -- Crater radius minimum, radius includes dust and obsidian layers.
local CRRAN = 8 -- Crater radius range.

-- 3D Perlin noise 1 for large structures

local np_large = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=128, z=256},
	seed = -83928935,
	octaves = 5,
	persist = 0.6
}

-- 3D Perlin noise 3 for fissures

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x=64, y=64, z=64},
	seed = -188881,
	octaves = 4,
	persist = 0.5
}

-- 3D Perlin noise 4 for small structures

local np_small = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=64, z=128},
	seed = 1000760700090,
	octaves = 4,
	persist = 0.6
}

-- 3D Perlin noise 5 for ore selection

local np_ores = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	seed = -70242,
	octaves = 1,
	persist = 0.5
}

-- 3D Perlin noise 6 for comet atmosphere

local np_latmos = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=128, z=256},
	seed = -83928935,
	octaves = 3,
	persist = 0.6
}

-- 3D Perlin noise 7 for small comet atmosphere

local np_satmos = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=64, z=128},
	seed = 1000760700090,
	octaves = 2,
	persist = 0.6
}

-- Stuff

asteroid = {}

local c_air
local c_stone
local c_cobble
local c_gravel
local c_dust
local c_ironore
local c_copperore
local c_goldore
local c_diamondore
local c_meseore
local c_waterice
local c_atmos
local c_snowblock

dofile(minetest.get_modpath("asteroid").."/nodes.lua")

-- On dignode function. Atmosphere flows into a dug hole.

minetest.register_on_dignode(function(pos, oldnode, digger)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	for i = -1,1 do
	for j = -1,1 do
	for k = -1,1 do
		if not (i == 0 and j == 0 and k == 0) then
			local nodename = minetest.get_node({x=x+i,y=y+j,z=z+k}).name
			if nodename == "asteroid:atmos" then	
				minetest.add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
				return
			end
		end
	end
	end
	end
end)

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.x < XMIN or maxp.x > XMAX
	or minp.y < YMIN or maxp.y > YMAX
	or minp.z < ZMIN or maxp.z > ZMAX then
		return
	end
	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	print ("[asteroid] chunk ("..x0.." "..y0.." "..z0..")")
	local sidelen = x1 - x0 + 1 -- chunk side length
	--local vplanarea = sidelen ^ 2 -- vertical plane area, used if calculating noise index from x y z
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local minpos = {x=x0, y=y0, z=z0}
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	c_air = minetest.get_content_id("air")
	c_obsidian = minetest.get_content_id("default:obsidian")
	
	c_stone = minetest.get_content_id("asteroid:stone")
	c_cobble = minetest.get_content_id("asteroid:cobble")
	c_gravel = minetest.get_content_id("asteroid:gravel")
	c_dust = minetest.get_content_id("asteroid:dust")
	c_ironore = minetest.get_content_id("asteroid:ironore")
	c_copperore = minetest.get_content_id("asteroid:copperore")
	c_goldore = minetest.get_content_id("asteroid:goldore")
	c_diamondore = minetest.get_content_id("asteroid:diamondore")
	c_meseore = minetest.get_content_id("asteroid:meseore")
	c_waterice = minetest.get_content_id("asteroid:waterice")
	c_atmos = minetest.get_content_id("asteroid:atmos")
	c_snowblock = minetest.get_content_id("asteroid:snowblock")
	
	local nvals1 = minetest.get_perlin_map(np_large, chulens):get3dMap_flat(minpos)
	local nvals3 = minetest.get_perlin_map(np_fissure, chulens):get3dMap_flat(minpos)
	local nvals4 = minetest.get_perlin_map(np_small, chulens):get3dMap_flat(minpos)
	local nvals5 = minetest.get_perlin_map(np_ores, chulens):get3dMap_flat(minpos)
	local nvals6 = minetest.get_perlin_map(np_latmos, chulens):get3dMap_flat(minpos)
	local nvals7 = minetest.get_perlin_map(np_satmos, chulens):get3dMap_flat(minpos)
	
	local ni = 1
	for z = z0, z1 do -- for each vertical plane do
	for y = y0, y1 do -- for each horizontal row do
	local vi = area:index(x0, y, z) -- LVM index for first node in x row
	for x = x0, x1 do -- for each node do
		local noise1abs = math.abs(nvals1[ni]) 
		local noise4abs = math.abs(nvals4[ni]) 
		local comet = false
		if nvals6[ni] < -(ASCOT + ATMOT) or (nvals7[ni] < -(SASCOT + ATMOT) and nvals1[ni] < ASCOT) then 
			comet = true -- comet biome
		end
		if noise1abs > ASCOT or noise4abs > SASCOT then -- if below surface then
			local noise1dep = noise1abs - ASCOT -- noise1dep zero at surface, positive beneath
			if math.abs(nvals3[ni]) > FISTS + noise1dep * FISEXP then -- if no fissure then
				local noise4dep = noise4abs - SASCOT -- noise4dep zero at surface, positive beneath
				if not comet or (comet and (noise1dep > math.random() + ICET or noise4dep > math.random() + ICET)) then
					-- asteroid or asteroid materials in comet
					if noise1dep >= STOT or noise4dep >= STOT then
						-- stone/ores
						if math.random(ORECHA) == 2 then
							if nvals5[ni] > 0.6 then
								data[vi] = c_goldore
							elseif nvals5[ni] < -0.6 then
								data[vi] = c_diamondore
							elseif nvals5[ni] > 0.2 then
								data[vi] = c_meseore
							elseif nvals5[ni] < -0.2 then
								data[vi] = c_copperore
							else
								data[vi] = c_ironore
							end
						else
							data[vi] = c_stone
						end
					elseif noise1dep >= COBT or noise4dep >= COBT then
						data[vi] = c_cobble
					elseif noise1dep >= GRAT or noise4dep >= GRAT then
						data[vi] = c_gravel
					else
						data[vi] = c_dust
					end
				else -- comet materials
					if noise1dep >= ICET or noise4dep >= ICET then
						data[vi] = c_waterice
					else
						data[vi] = c_snowblock
					end
				end
			elseif comet then -- fissures, if comet then add comet atmosphere
				data[vi] = c_atmos
			end
		elseif comet then -- if comet atmosphere then
			data[vi] = c_atmos
		end
		ni = ni + 1
		vi = vi + 1
	end
	end
	end
	-- craters
	for ci = 1, CPCHU do -- iterate
		local cr = CRMIN + math.floor(math.random() ^ 2 * CRRAN) -- exponential radius
		local cx = math.random(minp.x + cr, maxp.x - cr) -- centre x
		local cz = math.random(minp.z + cr, maxp.z - cr) -- centre z
		local comet = false
		local surfy = false
		for y = y1, y0 + cr, -1 do
			local vi = area:index(cx, y, cz) -- LVM index for node
			local nodeid = data[vi]
			if nodeid == c_dust
			or nodeid == c_gravel
			or nodeid == c_cobble then
				surfy = y
				break
			elseif nodename == c_snowblock
			or nodename == c_waterice then
				comet = true
				surfy = y
				break
			end
		end
		if surfy and y1 - surfy > 8 then -- if surface found and 8 node space above impact node then
			for x = cx - cr, cx + cr do -- for each plane do
				for z = cz - cr, cz + cr do -- for each column do
					for y = surfy - cr, surfy + cr do -- for each node do
						local vi = area:index(x, y, z) -- LVM index for node
						local nr = ((x - cx) ^ 2 + (y - surfy) ^ 2 + (z - cz) ^ 2) ^ 0.5
						if nr <= cr - 2 then
							if comet then
								data[vi] = c_atmos
							else
								data[vi] = c_air
							end
						elseif nr <= cr - 1 then
							local nodeid = data[vi]
							if nodeid == c_gravel
							or nodeid == c_cobble
							or nodeid == c_stone
							or nodeid == c_diamondore
							or nodeid == c_goldore
							or nodeid == c_meseore
							or nodeid == c_copperore
							or nodeid == c_ironore then
								data[vi] = c_dust
							end
						elseif nr <= cr then
							local nodeid = data[vi]
							if nodeid == c_cobble
							or nodeid == c_stone then
								data[vi] = c_obsidian -- obsidian buried under dust
							end
						end
					end
				end
			end
		end
	end
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[asteroid] time "..chugent.." ms")
end)