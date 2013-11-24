-- asteroid lvm/pm version 0.4.1 by paramat
-- For latest stable Minetest back to 0.4.8
-- Depends default
-- Licenses: code WTFPL, textures CC BY SA
-- For use as a stacked realm in v6, indev or v7 mapgen

-- Variables

local YMIN = 11000 -- Approximate realm bottom.
local YMAX = 13000 -- Approximate realm top.
local XMIN = -33000 -- Approximate realm edges.
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

local ORECHA = 5*5*5 --  -- Ore 1/x chance per stone node (iron, mese ore, copper, gold, diamond).

-- 3D Perlin noise 1 for large structures
local perl1 = {
	SEED1 = -92929422,
	OCTA1 = 5, --
	PERS1 = 0.6, -- 
	SCAL1 = 256, --
	VSCAL1 = 128, --
}

-- 3D Perlin noise 3 for fissures
local perl3 = {
	SEED3 = -188881,
	OCTA3 = 4, -- 
	PERS3 = 0.5, -- 
	SCAL3 = 64, -- 
}

-- 3D Perlin noise 4 for small structures
local perl4 = {
	SEED4 = 1000760700090,
	OCTA4 = 4, -- 
	PERS4 = 0.6, -- 
	SCAL4 = 128, -- 
	VSCAL4 = 64, -- 
}

-- 3D Perlin noise 5 for ore selection
local perl5 = {
	SEED5 = -70242,
	OCTA5 = 1, -- 
	PERS5 = 0.5, -- 
	SCAL5 = 128, -- 
}

-- 3D Perlin noise 6 for comet atmosphere
local perl6 = {
	SEED6 = -92929422,
	OCTA6 = 2, --
	PERS6 = 0.6, -- 
	SCAL6 = 256, --
	VSCAL6 = 128, --
}

-- 3D Perlin noise 7 for small comet atmosphere
local perl7 = {
	SEED7 = 1000760700090,
	OCTA7 = 1, -- 
	PERS7 = 0.6, -- 
	SCAL7 = 128, -- 
	VSCAL7 = 64, -- 
}

-- Stuff

asteroid = {}

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
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	local sidelen = x1 - x0 + 1 -- chunk side length
	local vplanarea = sidelen ^ 2 -- vertical plane area, used when calculating index from x y x
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_stone = minetest.get_content_id("asteroid:stone")
	local c_cobble = minetest.get_content_id("asteroid:cobble")
	local c_gravel = minetest.get_content_id("asteroid:gravel")
	local c_dust = minetest.get_content_id("asteroid:dust")
	local c_ironore = minetest.get_content_id("asteroid:ironore")
	local c_copperore = minetest.get_content_id("asteroid:copperore")
	local c_goldore = minetest.get_content_id("asteroid:goldore")
	local c_diamondore = minetest.get_content_id("asteroid:diamondore")
	local c_meseore = minetest.get_content_id("asteroid:meseore")
	local c_waterice = minetest.get_content_id("asteroid:waterice")
	local c_atmos = minetest.get_content_id("asteroid:atmos")
	local c_snowblock = minetest.get_content_id("asteroid:snowblock")

	local perlin1 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl1.SCAL1, y=perl1.VSCAL1, z=perl1.SCAL1}, seed=perl1.SEED1, octaves=perl1.OCTA1, persist=perl1.PERS1},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	local perlin3 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl3.SCAL3, y=perl3.SCAL3, z=perl3.SCAL3}, seed=perl3.SEED3, octaves=perl3.OCTA3, persist=perl3.PERS3},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	local perlin4 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl4.SCAL4, y=perl4.VSCAL4, z=perl4.SCAL4}, seed=perl4.SEED4, octaves=perl4.OCTA4, persist=perl4.PERS4},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	local perlin5 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl5.SCAL5, y=perl5.SCAL5, z=perl5.SCAL5}, seed=perl5.SEED5, octaves=perl5.OCTA5, persist=perl5.PERS5},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	local perlin6 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl6.SCAL6, y=perl6.VSCAL6, z=perl6.SCAL6}, seed=perl6.SEED6, octaves=perl6.OCTA6, persist=perl6.PERS6},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	local perlin7 = minetest.get_perlin_map(
		{offset=0, scale=1, spread={x=perl7.SCAL7, y=perl7.VSCAL7, z=perl7.SCAL7}, seed=perl7.SEED7, octaves=perl7.OCTA7, persist=perl7.PERS7},
		{x=sidelen, y=sidelen, z=sidelen}
		)
	
	local nvals1 = perlin1:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	local nvals3 = perlin3:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	local nvals4 = perlin4:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	local nvals5 = perlin5:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	local nvals6 = perlin6:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	local nvals7 = perlin7:get3dMap_flat({x=minp.x, y=minp.y, z=minp.z})
	
	local ni = 1
	for z = z0, z1 do -- for each plane do
	for y = y0, y1 do -- for each column do
	for x = x0, x1 do -- for each node do
		local vi = area:index(x, y, z) -- LVM index for node
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
	end
	end
	end
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
end)