local gui_ids = {}
local count = 0
local scores = {}
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	gui_ids[name] = nil
end)
minetest.register_globalstep(function(dtime)	
	count = count + dtime
	if count > 0.5 then
		count = 0
		local players = minetest.get_connected_players()
		for _,player in pairs(players) do
			local name = player:get_player_name()
			local pos = player:getpos()
			local dist = math.sqrt(pos.x^2 + pos.z^2)
			local best = 0
			if scores[name] then
				best = scores[name]
			end
			if gui_ids[name] then
				player:hud_change(gui_ids[name].current, "text", "Current: "..(math.floor(dist*100)/100).."m")
				player:hud_change(gui_ids[name].best, "text", "Best: "..best.."m")
			else
				gui_ids[name] = {
					current = player:hud_add({
						hud_elem_type = "text",
						name = "jump_d",
						number = 0xFFFFFF,
						position = {x=0.99, y=0.05},
						text="Current: "..(math.floor(dist*100)/100).."m",
						scale = {x=200,y=25},
						alignment = {x=-1, y=0}
					}),
					best = player:hud_add({
						hud_elem_type = "text",
						name = "jump_b",
						number = 0xFFFFFF,
						position = {x=0.99, y=0.09},
						text="Best: "..best.."m",
						scale = {x=200,y=25},
						alignment = {x=-1, y=0}
					})
				}
			end
			if pos.y > -1 and (not scores[name] or scores[name] < (math.floor(dist*100)/100)) then
				scores[name] = (math.floor(dist*100)/100)
			end
			if pos.y < -10 then
				player:moveto({x = 0, y = 2, z = 0}, false)
			end
		end
	end
end)

minetest.register_on_mapgen_init(function(mgparams)
		minetest.set_mapgen_params({mgname="singlenode"})
end)
 
minetest.register_on_generated(function(minp, maxp, seed)
	-- Set up voxel manip
	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local a = VoxelArea:new{
			MinEdge={x=emin.x, y=emin.y, z=emin.z},
			MaxEdge={x=emax.x, y=emax.y, z=emax.z},
	} 
	local data = vm:get_data() 
	local c_stone  = minetest.get_content_id("default:stone")
	local c_lava  = minetest.get_content_id("default:lava_source")
	local dist = 3
	
	-- Loop through
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			if x % dist == 0 and z % dist == 0 and minp.y <= 0 then
				for y = minp.y, maxp.y do
					if y <= 0 then
						local vi = a:index(x, y, z)
						data[vi] = c_stone
					end
				end
			elseif minp.y <= -20 then
				for y = minp.y, maxp.y do
					if y <= -30 then
						local vi = a:index(x, y, z)
						data[vi] = c_stone
					elseif y <= -20 then
						local vi = a:index(x, y, z)
						data[vi] = c_lava
					end
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
end)

minetest.register_on_respawnplayer(function(player)
	if player then
		player:moveto({x = 0, y = 2, z = 0}, false)
		return true
	end

	return false
end)

