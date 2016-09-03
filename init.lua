-- Parameters

local YMIN = 11000
local YMAX = 13000
local XMIN = -33000
local XMAX = 33000
local ZMIN = -33000
local ZMAX = 33000

local ASCOT = 1.0 -- Large asteroid / comet nucleus noise threshold.
local SASCOT = 1.0 -- Small asteroid / comet nucleus noise threshold.
local STOT = 0.125 -- Asteroid stone threshold.
local COBT = 0.05 -- Asteroid cobble threshold.
local GRAT = 0.02 -- Asteroid gravel threshold.
local ICET = 0.05 -- Comet ice threshold.
local ATMOT = -0.2 -- Comet atmosphere threshold.
local FISTS = 0.01 -- Fissure noise threshold at surface. Controls size of fissures
					-- and amount / size of fissure entrances at surface.
local FISEXP = 0.3 -- Fissure expansion rate under surface.
local ORECHA = 3 * 3 * 3 -- Ore 1/x chance per stone node.
local CPCHU = 1 -- Maximum craters per chunk.
local CRMIN = 5 -- Crater radius minimum, radius includes dust and obsidian layers.
local CRRAN = 8 -- Crater radius range.
local DEBUG = false

-- 3D Perlin noise 1 for large structures

local np_large = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 128, z = 256},
	seed = -83928935,
	octaves = 5,
	persist = 0.6
}

-- 3D Perlin noise 4 for small structures

local np_small = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 64, z = 128},
	seed = 1000760700090,
	octaves = 4,
	persist = 0.6
}

-- 3D Perlin noise 3 for fissures

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x = 64, y = 64, z = 64},
	seed = -188881,
	octaves = 3,
	persist = 0.5
}

-- 3D Perlin noise 5 for ore selection

local np_ores = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 128, z = 128},
	seed = -70242,
	octaves = 1,
	persist = 0.5
}

-- 3D Perlin noise 6 for comet atmosphere

local np_latmos = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 128, z = 256},
	seed = -83928935,
	octaves = 3,
	persist = 0.6
}

-- 3D Perlin noise 7 for small comet atmosphere

local np_satmos = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 64, z = 128},
	seed = 1000760700090,
	octaves = 2,
	persist = 0.6
}


-- Do files

dofile(minetest.get_modpath("asteroid").."/nodes.lua")


-- Constants

local c_air = minetest.get_content_id("air")
local c_obsidian = minetest.get_content_id("default:obsidian")
	
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


-- On dignode function. Atmosphere flows into a dug hole.

minetest.register_on_dignode(function(pos, oldnode, digger)
	local x = pos.x
	local y = pos.y
	local z = pos.z

	for i = -1, 1 do
	for j = -1, 1 do
	for k = -1, 1 do
		if not (i == 0 and j == 0 and k == 0) then
			local nodename = minetest.get_node({x = x + i, y = y + j, z = z + k}).name
			if nodename == "asteroid:atmos" then	
				minetest.add_node(pos, {name = "asteroid:atmos"})
				return
			end
		end
	end
	end
	end
end)


-- Initialise noise objects to nil

local nobj_large = nil
local nobj_small = nil
local nobj_fissure = nil
local nobj_ores = nil
local nobj_latmos = nil
local nobj_satmos = nil


-- Localise noise buffers

local nbuf_large
local nbuf_small
local nbuf_fissure
local nbuf_ores
local nbuf_latmos
local nbuf_satmos


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

	local sidelen = x1 - x0 + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minpos = {x = x0, y = y0, z = z0}
	
	nobj_large   = nobj_large   or minetest.get_perlin_map(np_large,   chulens)
	nobj_small   = nobj_small   or minetest.get_perlin_map(np_small,   chulens)
	nobj_fissure = nobj_fissure or minetest.get_perlin_map(np_fissure, chulens)
	nobj_ores    = nobj_ores    or minetest.get_perlin_map(np_ores,    chulens)
	nobj_latmos  = nobj_latmos  or minetest.get_perlin_map(np_latmos,  chulens)
	nobj_satmos  = nobj_satmos  or minetest.get_perlin_map(np_satmos,  chulens)
	
	local nvals_large   = nobj_large  :get3dMap_flat(minpos, nbuf_large)
	local nvals_small   = nobj_small  :get3dMap_flat(minpos, nbuf_small)
	local nvals_fissure = nobj_fissure:get3dMap_flat(minpos, nbuf_fissure)
	local nvals_ores    = nobj_ores   :get3dMap_flat(minpos, nbuf_ores)
	local nvals_latmos  = nobj_latmos :get3dMap_flat(minpos, nbuf_latmos)
	local nvals_satmos  = nobj_satmos :get3dMap_flat(minpos, nbuf_satmos)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	
	local ni = 1
	for z = z0, z1 do
	for y = y0, y1 do
		local vi = area:index(x0, y, z)
		for x = x0, x1 do
			local nabs_large = math.abs(nvals_large[ni])
			local nabs_small = math.abs(nvals_small[ni])
			local comet = false
			if nvals_latmos[ni] < -(ASCOT + ATMOT) or
					(nvals_satmos[ni] < -(SASCOT + ATMOT) and
					nvals_large[ni] < ASCOT) then 
				comet = true -- comet biome
			end

			if nabs_large > ASCOT or nabs_small > SASCOT then -- if below surfaces
				local nlargedep = nabs_large - ASCOT -- zero at surface, positive beneath
				if math.abs(nvals_fissure[ni]) > FISTS + nlargedep * FISEXP then
					-- no fissure
					local nsmalldep = nabs_small - SASCOT
					if not comet or (comet and (nlargedep > math.random() + ICET or
							nsmalldep > math.random() + ICET)) then
						-- asteroid or asteroid materials in comet
						if nlargedep >= STOT or nsmalldep >= STOT then
							-- stone/ores
							if math.random(ORECHA) == 2 then
								if nvals_ores[ni] > 0.6 then
									data[vi] = c_goldore
								elseif nvals_ores[ni] < -0.6 then
									data[vi] = c_diamondore
								elseif nvals_ores[ni] > 0.2 then
									data[vi] = c_meseore
								elseif nvals_ores[ni] < -0.2 then
									data[vi] = c_copperore
								else
									data[vi] = c_ironore
								end
							else
								data[vi] = c_stone
							end
						elseif nlargedep >= COBT or nsmalldep >= COBT then
							data[vi] = c_cobble
						elseif nlargedep >= GRAT or nsmalldep >= GRAT then
							data[vi] = c_gravel
						else
							data[vi] = c_dust
						end
					else -- comet materials
						if nlargedep >= ICET or nsmalldep >= ICET then
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
			local vi = area:index(cx, y, cz)
			local nodeid = data[vi]
			if nodeid == c_dust
					or nodeid == c_gravel
					or nodeid == c_cobble then
				surfy = y
				break
			elseif nodeid == c_snowblock
					or nodeid == c_waterice then
				comet = true
				surfy = y
				break
			end
		end

		if surfy and y1 - surfy > 8 then -- if surface found and 8 node space above
			for x = cx - cr, cx + cr do
				for z = cz - cr, cz + cr do
					for y = surfy - cr, surfy + cr do
						local vi = area:index(x, y, z)
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
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t1) * 1000)
	if DEBUG then
		print ("[asteroid] chunk generation "..chugent.." ms")
	end
end)
