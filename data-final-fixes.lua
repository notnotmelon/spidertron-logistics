for _, spider in pairs(data.raw['spider-vehicle']) do
	local grid = spider.equipment_grid
	if grid then
		grid = data.raw['equipment-grid'][spider.equipment_grid]
		grid.equipment_categories[#grid.equipment_categories + 1] = 'spidertron-logistic-controller'
	end
end
