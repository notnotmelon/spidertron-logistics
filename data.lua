local circuit_connections = require 'circuit-connections'

local nothing = {
	filename = '__spidertron-logistics__/graphics/nothing.png',
	priority = 'extra-high',
	size = 1
}

data:extend{
	{
		type = 'item',
		name = 'spidertron-requester-chest',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-requester-chest.png',
		icon_size = 64,
		stack_size = 50,
		place_result = 'spidertron-requester-chest',
		order = 'b[personal-transport]-c[spidertron]-d[depot]',
		subgroup = 'transport',
	},
	{
		type = 'item',
		name = 'spidertron-provider-chest',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-provider-chest.png',
		icon_size = 64,
		stack_size = 50,
		place_result = 'spidertron-provider-chest',
		order = 'b[personal-transport]-c[spidertron]-d[depot]',
		subgroup = 'transport',
	},
	{
		type = 'item',
		name = 'spidertron-logistic-controller',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-logistic-controller.png',
		icon_size = 64,
		icon_mipmaps = 4,
		stack_size = 10,
		placed_as_equipment_result = 'spidertron-logistic-controller',
		order = 'b[personal-transport]-c[spidertron]-c[controller]',
		subgroup = 'transport',
	},
	{
		type = 'item',
		name = 'spidertron-logistic-beacon',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-logistic-beacon.png',
		icon_size = 64,
		stack_size = 50,
		place_result = 'spidertron-logistic-beacon',
		order = 'b[personal-transport]-c[spidertron]-c[beacon]',
		subgroup = 'transport',
	},
	{
		type = 'equipment-category',
		name = 'spidertron-logistic-controller',
	},
	{
		type = 'container',
		name = 'spidertron-provider-chest',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-provider-chest.png',
		icon_size = 64,
		inventory_size = 50,
		picture = {layers = {
			{
				filename = '__spidertron-logistics__/graphics/entity/spidertron-provider-chest.png',
				height = 100,
				hr_version = {
					filename = '__spidertron-logistics__/graphics/entity/hr-spidertron-provider-chest.png',
					height = 199,
					priority = 'high',
					scale = 0.5,
					width = 207
				},
				priority = 'high',
				width = 104,
			},
			{
				draw_as_shadow = true,
				filename = '__spidertron-logistics__/graphics/entity/shadow.png',
				height = 75,
				hr_version = {
					draw_as_shadow = true,
					filename = '__spidertron-logistics__/graphics/entity/hr-shadow.png',
					height = 149,
					priority = 'high',
					scale = 0.5,
					shift = {0.5625, 0.5},
					width = 277,
				},
				priority = 'high',
				shift = {0.5625, 0.5},
				width = 138,
			},
		}},
		circuit_connector_sprites = circuit_connections.circuit_connector_sprites,
		circuit_wire_connection_point = circuit_connections.circuit_wire_connection_point,
		circuit_wire_max_distance = circuit_connections.circuit_wire_max_distance,
		max_health = 600,
		minable = {mining_time = 1, result = 'spidertron-provider-chest'},
		corpse = 'artillery-turret-remnants',
		fast_replaceable_group = 'spidertron-container',
		close_sound = {
			filename = '__base__/sound/metallic-chest-close.ogg',
			volume = 0.6
		},
		open_sound = {
			filename = '__base__/sound/metallic-chest-open.ogg',
			volume = 0.6
		},
		collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
		selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
		flags = {'placeable-neutral', 'player-creation'},
		se_allow_in_space = true
	},
	{
		type = 'container',
		icon = '__spidertron-logistics__/graphics/icon/spidertron-requester-chest.png',
		icon_size = 64,
		name = 'spidertron-requester-chest',
		inventory_size = 50,
		picture = {layers = {
			{
				filename = '__spidertron-logistics__/graphics/entity/spidertron-requester-chest.png',
				height = 100,
				hr_version = {
					filename = '__spidertron-logistics__/graphics/entity/hr-spidertron-requester-chest.png',
					height = 199,
					priority = 'high',
					scale = 0.5,
					width = 207
				},
				priority = 'high',
				width = 104,
			},
			{
				draw_as_shadow = true,
				filename = '__spidertron-logistics__/graphics/entity/shadow.png',
				height = 75,
				hr_version = {
					draw_as_shadow = true,
					filename = '__spidertron-logistics__/graphics/entity/hr-shadow.png',
					height = 149,
					priority = 'high',
					scale = 0.5,
					shift = {0.5625, 0.5},
					width = 277,
				},
				priority = 'high',
				shift = {0.5625, 0.5},
				width = 138,
			},
		}},
		circuit_connector_sprites = circuit_connections.circuit_connector_sprites,
		circuit_wire_connection_point = circuit_connections.circuit_wire_connection_point,
		circuit_wire_max_distance = circuit_connections.circuit_wire_max_distance,
		max_health = 600,
		minable = {mining_time = 1, result = 'spidertron-requester-chest'},
		corpse = 'artillery-turret-remnants',
		fast_replaceable_group = 'spidertron-container',
		close_sound = {
			filename = '__base__/sound/metallic-chest-close.ogg',
			volume = 0.6
		},
		open_sound = {
			filename = '__base__/sound/metallic-chest-open.ogg',
			volume = 0.6
		},
		collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
		selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
		flags = {'placeable-neutral', 'player-creation'},
		se_allow_in_space = true
	},
	{
		name = 'spidertron-logistic-controller',
		type = 'movement-bonus-equipment',
		energy_consumption = '100kW',
		movement_bonus = settings.startup['spidertron-speed'].value / -100,
		categories = {'spidertron-logistic-controller'},
		shape = {
			type = 'full',
			width = 1,
			height = 1
		},
		energy_source = {
			usage_priority = 'secondary-input',
			type = 'electric',
		},
		sprite = {
			filename = '__spidertron-logistics__/graphics/equipment/spidertron-logistic-controller.png',
			size = {32, 32}
		}
	},
	{
		type = 'recipe',
		name = 'spidertron-requester-chest',
		ingredients = {
			{'logistic-chest-requester', 4},
			{'spidertron-remote', 1}
		},
		energy_required = 4,
		results = {{'spidertron-requester-chest', 1}},
		enabled = false
	},
	{
		type = 'recipe',
		name = 'spidertron-provider-chest',
		ingredients = {
			{'logistic-chest-passive-provider', 4},
			{'spidertron-remote', 1}
		},
		energy_required = 4,
		results = {{'spidertron-provider-chest', 1}},
		enabled = false
	},
	{
		type = 'recipe',
		name = 'spidertron-logistic-controller',
		ingredients = {
			{'rocket-control-unit', 10},
			{'processing-unit', 10},
			{'spidertron-remote', 1}
		},
		results = {{'spidertron-logistic-controller', 1}},
		enabled = false
	},
	{
		type = 'recipe',
		name = 'spidertron-logistic-beacon',
		ingredients = {
			{'steel-plate', 10},
			{'processing-unit', 2},
			{'spidertron-remote', 1}
		},
		results = {{'spidertron-logistic-beacon', 1}},
		enabled = false
	},
	{
		type = 'technology',
		name = 'spidertron-logistic-system',
		icon = '__spidertron-logistics__/graphics/technology/spidertron-logistics-system.png',
		icon_size = 128,
		effects = {
			{
				recipe = 'spidertron-logistic-controller',
				type = 'unlock-recipe'
			},
			{
				recipe = 'spidertron-logistic-beacon',
				type = 'unlock-recipe'
			},
			{
				recipe = 'spidertron-requester-chest',
				type = 'unlock-recipe'
			},
			{
				recipe = 'spidertron-provider-chest',
				type = 'unlock-recipe'
			}
		},
		prerequisites = {
			'spidertron',
			'logistic-system'
		},
		unit = {
			count = 3000,
			ingredients = {
				{'automation-science-pack', 1},
				{'logistic-science-pack', 1},
				{'chemical-science-pack', 1},
				{'production-science-pack', 1},
				{'utility-science-pack', 1},
			},
			time = 30
		}
	},
	{
		name = 'spidertron-logistic-beacon',
		type = 'roboport',
		energy_source = {
			type = 'electric',
			usage_priority = 'secondary-input',
			buffer_capacity = '24MW'
		},
		energy_usage = '400kW',
		recharge_minimum = '400kW',
		robot_slots_count = 0,
		material_slots_count = 0,
		base = {
			filename = '__base__/graphics/entity/beacon/beacon-top.png',
			hr_version = {
				filename = '__base__/graphics/entity/beacon/hr-beacon-top.png',
				scale = 0.5,
				shift = {0.09375, -0.59375},
				height = 140,
				width = 96
			},
			shift = {0.09375, -0.59375},
			height = 70,
			width = 48
		},
		base_patch = nothing,
		base_animation = nothing,
		door_animation_up = nothing,
		door_animation_down = nothing,
		recharging_animation = nothing,
		request_to_open_door_timeout = 0,
		spawn_and_station_height = 0,
		charge_approach_distance = 0,
		logistics_radius = 9.5,
		construction_radius = 0,
		charging_energy = '0W',
		max_health = 100,
		minable = {mining_time = 1, result = 'spidertron-logistic-beacon'},
		corpse = 'beacon-remnants',
		collision_box = {{-0.7, -0.7}, {0.7, 0.7}},
		selection_box = {{-1, -1}, {1, 1}},
		flags = {'placeable-neutral', 'player-creation'},
		icon = '__spidertron-logistics__/graphics/icon/spidertron-logistic-beacon.png',
		icon_size = 64,
		logistics_connection_distance = 18
	}
}

if mods["Insectitron"] then
    table.remove(data.raw.technology["spidertron-logistic-system"].prerequisites, 1)
    table.insert(data.raw.technology["spidertron-logistic-system"].prerequisites, "insectitron")
elseif mods["spidertrontiers-community-updates"] then
    table.remove(data.raw.technology["spidertron-logistic-system"].prerequisites, 1)
    table.insert(data.raw.technology["spidertron-logistic-system"].prerequisites, "spidertron_mk0")
end
