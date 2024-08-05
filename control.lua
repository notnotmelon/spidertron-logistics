local update_cooldown = 4 * 60

local insert = table.insert
local sort = table.sort
local remove = table.remove
local random = math.random
local sqrt = math.sqrt
local min = math.min
local max = math.max
local match = string.match
local tonumber = tonumber
local tostring = tostring

local draw_sprite = rendering.draw_sprite
local rendering_is_valid = rendering.is_valid
local rendering_destroy = rendering.destroy

local idle = 1
local picking_up = 2
local dropping_off = 3

local spidertron_logistic_beacon = 'spidertron-logistic-beacon'
local spidertron_requester_chest = 'spidertron-requester-chest'
local spidertron_provider_chest = 'spidertron-provider-chest'
local spidertron_logistic_controller = 'spidertron-logistic-controller'

local function is_spidertron_force(force)
	if global.held_planner_forces[force.name] then return true end
	return match(force.name, '(.+)%.spidertron%-logistic%-network$') ~= nil
end

local function spidertron_network_force(base_force)
	if is_spidertron_force(base_force) then return base_force end

	local force_name = base_force.name .. '.spidertron-logistic-network'
	local force = game.forces[force_name]
	if not force then
		force = game.create_force(force_name)
		force.set_friend(base_force, true)
		force.set_cease_fire(base_force, true)
		force.disable_research()
		force.share_chart = true
		base_force.set_friend(force, true)
		base_force.set_cease_fire(force, true)
		base_force.share_chart = true
	end
	return force
end

local planners = {
	['copy-paste-tool'] = true,
	['cut-paste-tool'] = true,
	['blueprint'] = true,
	['deconstruction-planner'] = true
}

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	local player = game.get_player(event.player_index)
	local index = player.index
	local stack = player.cursor_stack
	local held_planner = global.held_planner_forces[player.force.name]
	local valid_for_read = stack and stack.valid_for_read
	
	if not valid_for_read then goto empty_stack end
	
	if stack.name == spidertron_logistic_beacon then
		if held_planner then return end
	
		if not is_spidertron_force(player.force) then
			global.original_forces[index] = player.force
		end
		
		local force = spidertron_network_force(player.force)
		
		for _, technology in pairs(player.force.technologies) do
			force.technologies[technology.name].researched = technology.researched
		end
		
		player.force = force
		return
	elseif planners[stack.name] and not held_planner then
		local spidertron_network_force = spidertron_network_force(player.force)
		for _, beacon in pairs(global.beacons) do
			if beacon.force == spidertron_network_force then
				beacon.force = player.force
			end
		end
		global.held_planner_forces[player.force.name] = true
	end
		
	::empty_stack::
		
	if held_planner and not (valid_for_read and planners[stack.name]) then
		for _, other_player in pairs(game.players) do
			local cursor = other_player.cursor_stack
			if other_player.index ~= index and other_player.force == player.force and cursor and cursor.valid_for_read and planners[cursor.name] then
				goto still_held
			end
		end
		
		global.held_planner_forces[player.force.name] = nil
		local spidertron_network_force = spidertron_network_force(player.force)
		for _, beacon in pairs(global.beacons) do
			if beacon.force == player.force and beacon.to_be_deconstructed() == false then
				beacon.force = spidertron_network_force
			end
		end
	end

	::still_held::
	
	local original_force = global.original_forces[index]
	if original_force then
		if original_force.valid and is_spidertron_force(player.force) then
			--for _, surface in pairs(game.surfaces) do player.force.clear_chart(surface) end
			player.force = original_force
		end
		global.original_forces[index] = nil
	end
end)

script.on_event(defines.events.on_cancelled_deconstruction, function(event)
	event.entity.force = spidertron_network_force(event.entity.force)
end, {{filter = 'name', name = spidertron_logistic_beacon}})

local function spidertron_network(entity)
	if entity.name == spidertron_logistic_beacon then
		return entity.logistic_network
	end
	
	local surface = entity.surface
	local force = spidertron_network_force(entity.force)
	local position = entity.position
	local x, y = position.x, position.y
	local range = 9 - 1
	local area = {{x - range, y - range}, {x + range, y + range}}
	
	if surface.count_entities_filtered{area = area, name = spidertron_logistic_beacon, force = force, to_be_deconstructed = false} == 0 then
		return nil
	end
	
	return surface.find_logistic_network_by_position(position, force)
end

local function random_order(l)
	local order = {}
	local i = 1
	for _, elem in pairs(l) do
		insert(order, random(1, i), elem)
		i = i + 1
	end
	
	return ipairs(order)
end

local function index_by_object(t, o)
	for k, v in pairs(t) do
		if k == o then return v end
	end
end

local function end_journey(unit_number, find_beacon)
	local spider_data = global.spiders[unit_number]
	if spider_data.status == idle then return end
	local spider = spider_data.entity
	
	local item = spider_data.payload_item
	local item_count = spider_data.payload_item_count
	
	local beacon_starting_point = spider
	
	local requester = spider_data.requester_target
	if requester.valid then
		beacon_starting_point = requester
		
		local requester_data = global.requesters[requester.unit_number]
		requester_data.incoming_items[item] = requester_data.incoming_items[item] - item_count
	end
	
	if spider_data.status == picking_up then
		local provider = spider_data.provider_target
		if provider.valid then
			beacon_starting_point = provider
			
			local allocated_items = global.providers[provider.unit_number].allocated_items
			allocated_items[item] = allocated_items[item] - item_count
			if allocated_items[item] == 0 then allocated_items[item] = nil end
		end
	end
	
	if find_beacon and spider.valid and spider.autopilot_destination == nil and spider.get_driver() == nil then
		local current_network = spidertron_network(beacon_starting_point)
		if current_network then
			for _, beacon in random_order(spider.surface.find_entities_filtered{name = spidertron_logistic_beacon, position = spider.position, radius = 12}) do
				if beacon.to_be_deconstructed() == false and spidertron_network(beacon) == current_network then
					spider.autopilot_destination = beacon.position
					break
				end
			end
		end
	end
	
	spider_data.provider_target = nil
	spider_data.requester_target = nil
	spider_data.payload_item = nil
	spider_data.payload_item_count = 0
	spider_data.status = idle
end

local function register_provider(provider)
	global.providers[provider.unit_number] = {
		entity = provider,
		allocated_items = {}
	}
	script.register_on_entity_destroyed(provider)
end

local function register_requester(requester, tags)
	global.requesters[requester.unit_number] = {
		entity = requester,
		requested_item = tags and tags.requested_item or nil,
		request_size = tags and tags.request_size or 0,
		incoming_items = {}
	}
	script.register_on_entity_destroyed(requester)
end

local function register_spider(spider)
	global.spiders[spider.unit_number] = {
		entity = spider,
		status = idle,
		requester_target = nil,
		provider_target = nil,
		payload_item = nil,
		payload_item_count = 0
	}
	script.register_on_entity_destroyed(spider)
end

local function register_beacon(beacon)
	global.beacons[beacon.unit_number] = beacon
	script.register_on_entity_destroyed(beacon)
	beacon.force = spidertron_network_force(beacon.force)
	beacon.backer_name = ''
end

local function stack_size(item)
	return game.item_prototypes[item].stack_size
end

local function inventory_size(entity)
	return entity.get_inventory(defines.inventory.chest).get_bar() - 1
end

local function requester_gui(player_index)
	local gui = global.requester_guis[player_index]
	if gui then return gui end
	
	local player = game.get_player(player_index)
	
	local frame = player.gui.relative.add{
		type = 'frame',
		anchor = {
			gui = defines.relative_gui_type.container_gui,
			position = defines.relative_gui_position.right,
			name = spidertron_requester_chest
		},
		caption = {'description.logistic-request'}
	}.add{
		type = 'frame',
		style = 'b_inner_frame'
	}
	
	local choose_elem_button = frame.add{
		type = 'choose-elem-button',
		elem_type = 'item'
	}
	
	local textfield = frame.add{
		type = 'textfield',
		numeric = true,
		allow_decimal = false,
		allow_negative = false,
		text = '0',
		style = 'slider_value_textfield'
	}
	
	gui = {
		choose_elem_button = choose_elem_button,
		textfield = textfield,
		last_opened_requester = nil
	}
	
	global.requester_guis[player_index] = gui
	return gui
end

script.on_event(defines.events.on_gui_opened, function(event)
	if event.gui_type ~= defines.gui_type.entity then return end
	local entity = event.entity
	if entity == nil or not entity.valid then return end
	if entity.name ~= spidertron_requester_chest then return end
	
	local player = game.get_player(event.player_index)
	local requester_data = global.requesters[entity.unit_number]
	local gui = requester_gui(event.player_index)
	
	gui.choose_elem_button.elem_value = requester_data.requested_item
	gui.textfield.text = tostring(requester_data.request_size)
	gui.last_opened_requester = requester_data
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
	local element = event.element
	local player = game.get_player(event.player_index)
	local gui = requester_gui(event.player_index)
	local choose_elem_button = gui.choose_elem_button
	
	if choose_elem_button.index ~= element.index then return end
	
	local requester_data = gui.last_opened_requester
	local item = element.elem_value
	requester_data.requested_item = item
	
	if item == nil then
		requester_data.request_size = 0
		gui.textfield.text = '0'
		return
	end
	
	local storage_space = stack_size(item) * inventory_size(requester_data.entity)
	if requester_data.request_size > storage_space then
		requester_data.request_size = storage_space
		gui.textfield.text = tostring(storage_space)
	end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
	local element = event.element
	local player = game.get_player(event.player_index)
	local gui = requester_gui(event.player_index)
	local textfield = gui.textfield
	
	if textfield.index ~= element.index then return end
	
	local text = event.text
	if text == '' then text = '0' end
	text = tonumber(text)
	
	local requester_data = gui.last_opened_requester
	if requester_data.requested_item then
		local storage_space = stack_size(requester_data.requested_item) * inventory_size(requester_data.entity)
		if text > storage_space then
			text = storage_space
		end
	end
	
	element.text = tostring(text)
	requester_data.request_size = text
end)

local function register_spider_safe(entity)
	local grid = entity.grid
	if not grid then return end
	local controller_count = grid.get_contents()[spidertron_logistic_controller]
	if controller_count ~= 0 and controller_count ~= nil then
		register_spider(entity)
		
		if controller_count > 1 then
			grid.inhibit_movement_bonus = true
			entity.active = false
		end
	end
end

script.on_event(defines.events.on_entity_settings_pasted, function(event)
	local source, destination = event.source, event.destination
	
	if destination.name == spidertron_requester_chest then
		local destination_data = global.requesters[destination.unit_number]
		if source.name == spidertron_requester_chest then 
			local source_data = global.requesters[source.unit_number]
			destination_data.requested_item = source_data.requested_item
			destination_data.request_size = source_data.request_size
		else
			destination_data.requested_item = nil
			destination_data.request_size = 0
		end
		
		local gui = requester_gui(event.player_index)
		if gui.last_opened_requester == destination_data then
			gui.choose_elem_button.elem_value = destination_data.requested_item
			gui.textfield.text = tostring(destination_data.request_size)
		end
	elseif destination.type == 'spider-vehicle' and destination.prototype.order ~= 'z[programmable]' then
		local spider = destination
		
		local unit_number = spider.unit_number
		if global.spiders[unit_number] then
			end_journey(unit_number, false)
			global.spiders[unit_number] = nil
		end
		
		register_spider_safe(spider)
	end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
	local spider = event.entity
	if spider and spider.get_driver() and global.spiders[spider.unit_number] then
		end_journey(spider.unit_number, false)
	end
end)

script.on_event(defines.events.on_player_used_spider_remote, function(event)
	local spider = event.vehicle
	if event.success and global.spiders[spider.unit_number] then
		end_journey(spider.unit_number, false)
	end
end)

local function draw_no_energy_icon(target, offset)
	draw_sprite{
		sprite = 'utility.electricity_icon',
		x_scale = 0.5,
		y_scale = 0.5,
		target = target,
		surface = target.surface,
		time_to_live = update_cooldown / 2,
		target_offset = offset
	}
end

local function draw_missing_roboport_icon(target, offset)
	draw_sprite{
		sprite = 'utility.too_far_from_roboport_icon',
		x_scale = 0.5,
		y_scale = 0.5,
		target = target,
		surface = target.surface,
		time_to_live = update_cooldown / 2,
		target_offset = offset
	}
end

local function draw_deposit_icon(target)
	local requester_data = global.requesters[target.unit_number]
	local old = requester_data.old_icon
	if old and rendering_is_valid(old) then rendering_destroy(old) end
	
	requester_data.old_icon = draw_sprite{
		sprite = 'utility.indication_arrow',
		x_scale = 1.5,
		y_scale = 1.5,
		target = target,
		surface = target.surface,
		time_to_live = 120,
		target_offset = {0, -0.75},
		orientation = 0.5,
		only_in_alt_mode = true
	}
end

local function draw_withdraw_icon(target)
	local provider_data = global.providers[target.unit_number]
	local old = provider_data.old_icon
	if old and rendering_is_valid(old) then rendering_destroy(old) end
	
	provider_data.old_icon = draw_sprite{
		sprite = 'utility.indication_arrow',
		x_scale = 1.5,
		y_scale = 1.5,
		target = target,
		surface = target.surface,
		time_to_live = 120,
		target_offset = {0, -0.75},
		only_in_alt_mode = true
	}
end

local function distance(x1, y1, x2, y2)
	if not x2 and not y2 then
		x2, y2 = y1.x, y1.y
		x1, y1 = x1.x, x1.y
	end
	return sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

local function spiders()
	local valid = {}
	
	for _, spider_data in pairs(global.spiders) do
		local spider = spider_data.entity
		if spider.active and spider_data.status == idle and spider.get_driver() == nil then
			local network = spidertron_network(spider)
			if network == nil then
				if spider.autopilot_destination == nil then
					draw_missing_roboport_icon(spider, {0, -1.75})
				end
			else
				local grid = spider.grid
				for _, equipment in ipairs(grid.equipment) do
					if equipment.name == spidertron_logistic_controller and equipment.energy == equipment.max_energy then
						local in_network = index_by_object(valid, network) or {}
						valid[network] = in_network
						valid[network][#in_network + 1] = spider
						goto valid
					end
				end
				draw_no_energy_icon(spider, {0, -1.75})
			end
		end
		::valid::
	end
	
	return valid
end

local function requester_sort_function(a, b)
	local a_filled = a.percentage_filled
	local b_filled = b.percentage_filled
	return a_filled == b_filled and a.random_sort_order < b.random_sort_order or a_filled < b_filled
end

local function requesters()
	local result = {}
	
	for _, requester_data in pairs(global.requesters) do
		local requester = requester_data.entity
		if requester.to_be_deconstructed() then goto continue end
		
		local network = spidertron_network(requester)
		if network == nil then
			draw_missing_roboport_icon(requester)
			goto continue
		end
		
		local item = requester_data.requested_item
		if not item or not requester.can_insert(item) then goto continue end
		
		local incoming = requester_data.incoming_items[item] or 0
		local request_size = requester_data.request_size
		local already_had = requester.get_item_count(item)
		
		requester_data.real_amount = request_size - incoming - already_had
		if requester_data.real_amount <= 0 then goto continue end
		requester_data.percentage_filled = (incoming + already_had) / request_size
		requester_data.random_sort_order = random()
		
		local requesters = index_by_object(result, network)
		if requesters == nil then
			result[network] = {requester_data}
		else
			requesters[#requesters + 1] = requester_data
		end
		
		::continue::
	end
	
	for _, requesters in pairs(result) do
		sort(requesters, requester_sort_function)
	end
	
	return result
end

local function providers()
	local result = {}

	for _, provider_data in pairs(global.providers) do
		local provider = provider_data.entity
			
		if provider.to_be_deconstructed() then goto continue end
		
		local network = spidertron_network(provider)
		if not network then
			draw_missing_roboport_icon(provider)
			goto continue
		end
		
		local contains = provider.get_inventory(defines.inventory.chest).get_contents()
		if next(contains) == nil then goto continue end
		provider_data.contains = contains
		
		local providers = index_by_object(result, network)
		if providers == nil then
			result[network] = {provider_data}
		else
			providers[#providers + 1] = provider_data
		end
		
		::continue::
	end
	
	return result
end

local function assign_spider(spiders, requester_data, provider_data, can_provide)
	local provider = provider_data.entity
	local item = requester_data.requested_item
	
	local position = provider.position
	local x, y = position.x, position.y
	local spider
	local best_distance
	local spider_index
	for i, canidate in ipairs(spiders) do
		if canidate.can_insert(item) then
			local canidate_position = canidate.position
			local distance = distance(x, y, canidate_position.x, canidate_position.y)
			
			if not spider or best_distance > distance then
				spider = canidate
				best_distance = distance
				spider_index = i
			end
		end
	end
	if not spider then return false end
	
	local spider_data = global.spiders[spider.unit_number]
	local amount = requester_data.real_amount
	
	if can_provide > amount then can_provide = amount end
	provider_data.allocated_items[item] = (provider_data.allocated_items[item] or 0) + can_provide
	requester_data.incoming_items[item] = (requester_data.incoming_items[item] or 0) + can_provide
	requester_data.real_amount = amount - can_provide
	spider_data.status = picking_up
	spider_data.requester_target = requester_data.entity
	spider_data.provider_target = provider
	spider_data.payload_item = item
	spider_data.payload_item_count = can_provide
	spider.autopilot_destination = provider.position

	remove(spiders, spider_index)
	return true
end

script.on_nth_tick(update_cooldown, function(event)
	local requests = requesters()
	local spiders = spiders()
	local providers = providers()
	
	for network, requesters in pairs(requests) do
		if global.held_planner_forces[network.force.name] then goto next_network end
	
		local providers = index_by_object(providers, network)
		if not providers then goto next_network end
		
		local spiders_on_network = index_by_object(spiders, network)
		if not spiders_on_network or #spiders_on_network == 0 then goto next_network end
		
		for _, requester_data in ipairs(requesters) do
			local item = requester_data.requested_item
			local max = 0
			local best_provider
			for _, provider_data in ipairs(providers) do
				local can_provide = (provider_data.contains[item] or 0) - (provider_data.allocated_items[item] or 0)
				if can_provide > max then
					max = can_provide
					best_provider = provider_data
				end
			end
			
			if best_provider ~= nil then
				if not assign_spider(spiders_on_network, requester_data, best_provider, max) or #spiders_on_network == 0 then
					goto next_network
				end
			end
		end
		::next_network::
	end
end)

local function deposit_already_had(spider_data)
	local spider = spider_data.entity

	local contains = spider.get_inventory(defines.inventory.spider_trunk).get_contents()
	if next(contains) == nil then return end
	
	local network = spidertron_network(spider)
	if not network then return end
	
	local requesters = {}
	local i = 1
	for _, requester_data in pairs(global.requesters) do
		local requester = requester_data.entity
		local item = requester_data.requested_item
		if item and contains[item] and requester.can_insert(item) and requester.get_item_count(item) + (requester_data.incoming_items[item] or 0) ~= requester_data.request_size then
			if spidertron_network(requester) == network then
				requesters[i] = requester
				i = i + 1
			end
		end
	end
	
	if #requesters == 0 then return end
	
	local position = spider.position
	local requester = spider.surface.get_closest({position.x, position.y - 2}, requesters)
	local requester_data = global.requesters[requester.unit_number]
	
	local item = requester_data.requested_item
	local incoming = requester_data.incoming_items[item] or 0
	local already_had = requester_data.request_size - requester.get_item_count(item) - incoming
	local can_provide = spider.get_item_count(item)
	if can_provide > already_had then can_provide = already_had end
	
	requester_data.incoming_items[item] = incoming + can_provide
		
	spider_data.status = dropping_off
	spider_data.requester_target = requester_data.entity
	spider_data.payload_item = item
	spider_data.payload_item_count = can_provide
	spider.autopilot_destination = requester.position
end

script.on_event(defines.events.on_spider_command_completed, function(event)
	local spider = event.vehicle
	local unit_number = spider.unit_number
	local spider_data = global.spiders[unit_number]
	
	local goal
	if spider_data == nil or spider_data.status == idle then
		return
	elseif spider_data.status == picking_up then
		if not spider_data.requester_target.valid then
			end_journey(unit_number, true)
			return
		end
		goal = spider_data.provider_target
	elseif spider_data.status == dropping_off then
		goal = spider_data.requester_target
	end
	
	spider.autopilot_destination = nil
	
	if not goal.valid or goal.to_be_deconstructed() or spider.surface ~= goal.surface or distance(spider.position, goal.position) > 6 then
		end_journey(unit_number, true)
		return
	end
	
	local item = spider_data.payload_item
	local item_count = spider_data.payload_item_count
	local requester = spider_data.requester_target
	local requester_data = global.requesters[requester.unit_number]
	
	if spider_data.status == picking_up then
		local provider = spider_data.provider_target
		local provider_data = global.providers[provider.unit_number]
		
		local contains = provider.get_item_count(item)
		if contains > item_count then contains = item_count end
		local already_had = spider.get_item_count(item)
		if already_had > item_count then already_had = item_count end
		
		if contains + already_had == 0 then
			end_journey(unit_number, true)
			return
		end
		
		local can_insert = min(contains - already_had, item_count)
		local actually_inserted = can_insert <= 0 and 0 or spider.insert{name = item, count = can_insert}
		if actually_inserted + already_had == 0 then
			end_journey(unit_number, true)
			return
		end
		
		if actually_inserted ~= 0 then
			provider.remove_item{name = item, count = actually_inserted}
			draw_withdraw_icon(provider)
		end
		spider_data.payload_item_count = actually_inserted + already_had
		requester_data.incoming_items[item] = requester_data.incoming_items[item] - item_count + actually_inserted + already_had
		
		spider.autopilot_destination = spider_data.requester_target.position
		
		local allocated_items = provider_data.allocated_items
		allocated_items[item] = allocated_items[item] - item_count
		if allocated_items[item] == 0 then allocated_items[item] = nil end
		
		spider_data.status = dropping_off
	elseif spider_data.status == dropping_off then
		local can_insert = min(spider.get_item_count(item), item_count)
		local actually_inserted = can_insert == 0 and 0 or requester.insert{name = item, count = can_insert}
			   
		if actually_inserted ~= 0 then
			spider.remove_item{name = item, count = actually_inserted}
			draw_deposit_icon(requester)
		end
		
		end_journey(unit_number, true)
		deposit_already_had(spider_data)
	end
end)

script.on_event(defines.events.on_entity_destroyed, function(event)
	local unit_number = event.unit_number
	
	if global.spiders[unit_number] then
		end_journey(unit_number, false)
		global.spiders[unit_number] = nil
	elseif global.requesters[unit_number] then
		global.requesters[unit_number] = nil
	elseif global.providers[unit_number] then
		global.providers[unit_number] = nil
	elseif global.beacons[unit_number] then
		global.beacons[unit_number] = nil
	end
end)

local function built(event)
	local entity = event.created_entity or event.entity

	if entity.type == 'spider-vehicle' and entity.prototype.order ~= 'z[programmable]' then
		register_spider_safe(entity)
	elseif entity.name == spidertron_requester_chest then
		register_requester(entity, event.tags)
	elseif entity.name == spidertron_provider_chest then
		register_provider(entity)
	elseif entity.name == spidertron_logistic_beacon then
		register_beacon(entity)
	end
end

script.on_event(defines.events.on_built_entity, built)
script.on_event(defines.events.on_robot_built_entity, built)
script.on_event(defines.events.script_raised_built, built)
script.on_event(defines.events.script_raised_revive, built)

local function save_blueprint_data(blueprint, mapping)
	for i, entity in ipairs(mapping) do
		if entity.valid then
			local requester_data = global.requesters[entity.unit_number]
			if requester_data then
				blueprint.set_blueprint_entity_tag(i, 'requested_item', requester_data.requested_item)
				blueprint.set_blueprint_entity_tag(i, 'request_size', requester_data.request_size)
			end
		end
	end
end

script.on_event(defines.events.on_player_setup_blueprint, function(event)
	local player = game.players[event.player_index]
	
	local cursor = player.cursor_stack
	if cursor and cursor.valid_for_read and cursor.type == 'blueprint' then
		save_blueprint_data(cursor, event.mapping.get())
	else
		global.blueprint_mappings[player.index] = event.mapping.get()
	end
end)

script.on_event(defines.events.on_player_configured_blueprint, function(event)
	local player = game.players[event.player_index]
	local mapping = global.blueprint_mappings[player.index]
	local cursor = player.cursor_stack
	
	if cursor and cursor.valid_for_read and cursor.type == 'blueprint' and mapping and #mapping == cursor.get_blueprint_entity_count() then
		save_blueprint_data(cursor, mapping)
	end
	global.blueprint_mappings[player.index] = nil
end)

script.on_event(defines.events.on_player_removed_equipment, function(event)
	if event.equipment ~= spidertron_logistic_controller then return end

	local grid = event.grid
	local count = grid.get_contents()[spidertron_logistic_controller]
	
	if count == nil then count = 0 end
	if count > 1 then return end

	local player = game.get_player(event.player_index)
	local entity
	for _, spider in pairs(player.surface.find_entities_filtered{type = 'spider-vehicle'}) do
		local spider_grid = spider.grid
		if spider_grid and spider_grid == grid then
			entity = spider
			break
		end
	end
	
	if entity == nil then return end
	
	if count == 1 then
		grid.inhibit_movement_bonus = false
		entity.active = true
	elseif count == 0 then
		local unit_number = entity.unit_number
		end_journey(unit_number, false)
		global.spiders[unit_number] = nil
	end
end)

script.on_event(defines.events.on_player_placed_equipment, function(event)
	if event.equipment.name ~= spidertron_logistic_controller then return end

	local player = game.get_player(event.player_index)
	local grid = event.grid
	local entity
	for _, spider in pairs(player.surface.find_entities_filtered{type = 'spider-vehicle'}) do
		local spider_grid = spider.grid
		if spider_grid and spider_grid == grid then
			entity = spider
			break
		end
	end
	
	if entity == nil then return end
	if entity.prototype.order == 'z[programmable]' then return end
	
	if grid.get_contents()[spidertron_logistic_controller] > 1 then
		grid.inhibit_movement_bonus = true
		entity.active = false
	end
               
	if not global.spiders[entity.unit_number] then
		register_spider(entity)
	end
end)

local function setup()
	global.spiders = global.spiders or {}
	global.requesters = global.requesters or {}
	global.requester_guis = global.requester_guis or {}
	global.providers = global.providers or {}
	global.original_forces = global.original_forces or {}
	global.held_planner_forces = global.held_planner_forces or {}
	global.beacons = global.beacons or {}
	global.blueprint_mappings = global.blueprint_mappings or {}
end

script.on_init(setup)
script.on_configuration_changed(setup)
