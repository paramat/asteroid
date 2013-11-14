-- asteroid 0.3.0 by paramat
-- For latest stable Minetest back to 0.4.7 stable
-- Depends default
-- Licenses: code WTFPL, textures CC BY SA

-- Variables

local ONGEN = true -- (true / false) Realm generation.
local PROG = true -- Print generation progress to terminal.

local YMIN = 13000 -- Approximate realm bottom.
local YMAX = 14000 -- Approximate realm top.
local XMIN = -16000 -- Approximate realm edges.
local XMAX = 16000
local ZMIN = -16000
local ZMAX = 16000

local ASCOT = 1.0 --  -- Large asteroid / comet nucleus noise threshold.
local PERSAV = 0.6 --  -- Persistence1 average.
local PERSAMP = 0.1 --  -- Persistence1 amplitude.
local SASCOT = 1.0 --  -- Small asteroid / comet nucleus noise threshold.
local SQUFAC = 2 --  -- Vertical squash factor.

local LAVAT = 0.6 --  -- Asteroid lava threshold.
local STOT = 0.1 --  -- Asteroid stone threshold.
local COBT = 0.05 --  -- Asteroid cobble threshold.
local GRAT = 0.02 --  -- Asteroid gravel threshold.

local ICET = 0.1 --  -- Comet ice threshold.
local ATMOT = -0.2 --  -- Comet atmosphere threshold.

local FISTS = 0.01 -- 0.01 -- Fissure noise threshold at surface. Controls size of fissures and amount / size of fissure entrances at surface.
local FISEXP = 0.3 -- 0.3 -- Fissure expansion rate under surface.

local ORECHA = 4*4*4 --  -- Ore 1/x chance per stone node (iron, mese ore, copper, gold, diamond).

-- 3D Perlin noise 1 for large structures
local perl1 = {
	SEED1 = -92929422,
	OCTA1 = 5, --
	SCAL1 = 256, --
}

-- 3D Perlin noise 2 for varying persistence of noise1
local perl2 = {
	SEED2 = 595668,
	OCTA2 = 2, -- 
	PERS2 = 0.6, -- 
	SCAL2 = 1024, -- 
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
}

-- 3D Perlin5 for ore selection
local perl5 = {
	SEED5 = -70242,
	OCTA5 = 2, -- 
	PERS5 = 0.6, -- 
	SCAL5 = 256, -- 
}

-- Stuff

asteroid = {}

dofile(minetest.get_modpath("asteroid").."/nodes.lua")

-- On dignode function. Atmosphere flows into a dug hole.

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
		local perlin2 = minetest.get_perlin(perl2.SEED2, perl2.OCTA2, perl2.PERS2, perl2.SCAL2)
		local perlin3 = minetest.get_perlin(perl3.SEED3, perl3.OCTA3, perl3.PERS3, perl3.SCAL3)
		local perlin4 = minetest.get_perlin(perl4.SEED4, perl4.OCTA4, perl4.PERS4, perl4.SCAL4)
		local perlin5 = minetest.get_perlin(perl5.SEED5, perl5.OCTA5, perl5.PERS5, perl5.SCAL5)
		for x = x0, x1 do -- for each plane do
			if PROG then
				print ("[asteroid] "..x - x0.." ("..minp.x.." "..minp.y.." "..minp.z..")")
			end
			for z = z0, z1 do -- for each column do
				for y = y0, y1 do -- for each node do
					local noise2 = perlin2:get3d({x=x,y=y,z=z})
					local pers1 = PERSAV + noise2 * PERSAMP
					local perlin1 = minetest.get_perlin(perl1.SEED1, perl1.OCTA1, pers1, perl1.SCAL1)
					local noise1 = perlin1:get3d({x=x,y=y*SQUFAC,z=z})
					local noise1abs = math.abs(noise1) 
					local noise4 = perlin4:get3d({x=x,y=y*SQUFAC,z=z})
					local noise4abs = math.abs(noise4) 
					if noise1abs > ASCOT or noise4abs > SASCOT then -- if below surface then
						local comet = false
						if noise1 < -(ASCOT + ATMOT) or noise4 < -(SASCOT + ATMOT) then 
							comet = true
						end
						local noise1dep = noise1abs - ASCOT -- noise1dep zero at surface, positive beneath
						local noise4dep = noise4abs - SASCOT -- noise4dep zero at surface, positive beneath
						if not comet and noise1dep >= LAVAT then -- if large asteroid and lava depth then
							minetest.add_node({x=x,y=y,z=z},{name="asteroid:lava"})
						else -- structure with fissures
							local noise3 = perlin3:get3d({x=x,y=y,z=z})
							if math.abs(noise3) > FISTS + noise1dep * FISEXP then -- if no cave then
								if not comet or (comet and (math.random() < noise1dep or math.random() < noise4dep)) then
									-- asteroid or asteroid materials in comet
									if noise1dep >= STOT or noise4dep >= STOT then
										-- stone/ores
										if math.random(ORECHA) == 2 then
											local noise5 = perlin5:get3d({x=x,y=y,z=z})
											if noise5 > 1 then
												minetest.add_node({x=x,y=y,z=z},{name="asteroid:goldore"})
											elseif noise5 < -1 then
												minetest.add_node({x=x,y=y,z=z},{name="asteroid:diamondore"})
											elseif noise5 > 0.3 then
												minetest.add_node({x=x,y=y,z=z},{name="asteroid:meseore"})
											elseif noise5 < -0.3 then
												minetest.add_node({x=x,y=y,z=z},{name="asteroid:copperore"})
											else
												minetest.add_node({x=x,y=y,z=z},{name="asteroid:ironore"})
											end
										else
											minetest.add_node({x=x,y=y,z=z},{name="asteroid:stone"})
										end
									elseif noise1dep >= COBT or noise4dep >= COBT then
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:cobble"})
									elseif noise1dep >= GRAT or noise4dep >= GRAT then
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:gravel"})
									else
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:dust"})
									end
								else -- comet
									if noise1dep >= ICET or noise4dep >= ICET then
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:waterice"})
									else
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:snowblock"})
									end
								end
							elseif comet then -- cave, if comet then add comet atmosphere
								minetest.add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
							end
						end
					elseif noise1 < -(ASCOT + ATMOT) or noise4 < -(SASCOT + ATMOT) then -- if comet atmosphere
						minetest.add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
					end
				end
			end
		end
	end)
end