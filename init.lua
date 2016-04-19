local gui_ids = {}
minetest.register_on_leaveplayer(function(player)
	gui_ids[player:get_player_name()] = nil
end)

local function reset_player(player)
	player:moveto({x = 0, y = 0, z = 0}, false)
end

local scores = {}
local update_interval = 0.1
local count = 0
minetest.register_globalstep(function(dtime)
	count = count + dtime
	if count < update_interval then
		return
	end
	count = 0
	for _,player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:getpos()
		local dist = math.sqrt(pos.x^2 + pos.z^2)
		local current_score = math.floor(dist*100)/100
		local best = scores[name] or 0
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
					text="Current: "..current_score.."m",
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
		if pos.y < -10
		or player:get_player_control().aux1 then
			reset_player(player)
		elseif pos.y > -5 and (not scores[name] or scores[name] < current_score) then
			scores[name] = current_score
		end
	end
end)

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

local c_stone  = minetest.get_content_id("default:stone")
local dist = 3
minetest.register_on_generated(function(minp, maxp)
	if minp.y > -2 then
		return
	end

	-- Set up voxel manip
	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local a = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	if maxp.y > -30 then
		-- Add pillars
		local minz = math.ceil(minp.z/dist)*dist
		local minx = math.ceil(minp.x/dist)*dist
		for z = minz, maxp.z, dist do
			for x = minx, maxp.x, dist do
				for vi in a:iter(x,minp.y,z, x,math.min(maxp.y, -2),z) do
					data[vi] = c_stone
				end
			end
		end
	end
	if minp.y <= -30 then
		-- Add solid ground
		for vi in a:iter(minp.x,minp.y,minp.z, maxp.x,math.min(maxp.y, -30),maxp.z) do
			data[vi] = c_stone
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
end)

minetest.register_on_respawnplayer(function(player)
	if player then
		reset_player(player)
		return true
	end

	return false
end)

