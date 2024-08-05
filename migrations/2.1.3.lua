if global.beacons then goto updated end

global.beacons = {}
for _, surface in pairs(game.surfaces) do
	for _, beacon in pairs(surface.find_entities_filtered{name = 'spidertron-logistic-beacon'}) do
		global.beacons[beacon.unit_number] = beacon
		script.register_on_entity_destroyed(beacon)
	end
end

::updated::
