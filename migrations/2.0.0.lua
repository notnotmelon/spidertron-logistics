if not global.logistic_spiders or not global.providers or not global.requesters then goto updated end

local removed = 0
for _, spider_data in pairs(global.logistic_spiders) do
	removed = removed + 1
	spider_data[1].destroy()
end

global.logistic_spiders = nil
global.providers = nil
global.requesters = nil

for _, surface in pairs(game.surfaces) do
	for _, entity in pairs(surface.find_entities_filtered{name = {'spidertron-provider-chest', 'spidertron-requester-chest'}}) do
		removed = removed + 1
		entity.destroy()
	end
end

if removed ~= 0 then
	game.print('Thanks for updating spidertron logistics to version 2.0.0')
	game.print('I automatically removed ' .. removed .. ' entities from the spidertron network beacuse they were not compatible with the new version.')
	game.print('If this change is unacceptable then quit the game without saving and manually downgrade the mod.')
	game.print('Otherwise, enjoy the new features and bugfixes!')
end

::updated::
