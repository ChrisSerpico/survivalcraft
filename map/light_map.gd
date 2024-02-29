extends TileMap
class_name LightMap


const MAX_LIGHT = 7

var calculated_lightmap = {}

# TODO: break these into a resource maybe?
var lights = {}
var outdoor_cells = {}
var blocked_cells = {}


func reset():
	clear()
	calculated_lightmap.clear()
	
	outdoor_cells.clear()
	blocked_cells.clear()


func add_position(cell_position: Vector2i):
	calculated_lightmap[cell_position] = 0


func set_outdoors(cell_position: Vector2i, outdoors: bool):
	outdoor_cells[cell_position] = outdoors


func block_cell(cell_position: Vector2i):
	blocked_cells[cell_position] = true


func clear_blocked(cell_position: Vector2i):
	if not blocked_cells.has(cell_position):
		return
	
	blocked_cells.erase(cell_position)
	propagate_light_at_position(cell_position)


func recalculate_outdoor_lightmap():
	var cells_to_propagate = []
	
	for outdoor_cell in outdoor_cells:
		calculated_lightmap[outdoor_cell] = MAX_LIGHT
		
		for adjacent_cell in get_adjacent_cells(outdoor_cell):
			if not outdoor_cells.has(adjacent_cell):
				cells_to_propagate.append(outdoor_cell)
				break
	
	for propagation_target in cells_to_propagate:
		propagate_light_at_position(propagation_target)


func render_lightmap():
	rerender_positions(calculated_lightmap.keys())


func rerender_positions(cell_positions: Array):
	for cell_position in cell_positions:
		set_cell(0, cell_position, 0, Vector2i(mini(calculated_lightmap[cell_position], MAX_LIGHT), 0))


func propagate_light_at_position(light_position: Vector2i):
	var brightness
	
	if outdoor_cells.has(light_position):
		brightness = MAX_LIGHT
	else:
		brightness = lights.get(light_position, 0)
	
		for cell in get_adjacent_cells(light_position):
			if blocked_cells.has(cell):
				continue
			
			var brightness_from_adjacent = calculated_lightmap.get(cell, 0) - 1
			if brightness_from_adjacent > brightness:
				brightness = brightness_from_adjacent
	
	if calculated_lightmap.get(light_position, 0) > brightness:
		return
	
	var light_level = brightness
	var visited_cells = {
		light_position: true
	}
	var cells_to_check = [light_position]
	
	while len(cells_to_check) > 0:
		for i in range(len(cells_to_check)):
			var current_cell = cells_to_check.pop_front()
			
			calculated_lightmap[current_cell] = light_level
			
			if blocked_cells.has(current_cell):
				continue
			
			for adjacent_cell in get_adjacent_cells(current_cell):
				if not visited_cells.has(adjacent_cell) and calculated_lightmap.get(adjacent_cell) < light_level:
					visited_cells[adjacent_cell] = true
					cells_to_check.append(adjacent_cell)
		
		light_level -= 1
		
		if light_level <= 0:
			break
	
	rerender_positions(visited_cells.keys())


func add_light(light_position: Vector2i, brightness: int):
	# TODO: this doesn't seem right
	if lights.has(light_position):
		remove_light(light_position)
	
	lights[light_position] = brightness
	
	if calculated_lightmap.get(light_position, 0) >= brightness:
		return
	
	propagate_light_at_position(light_position)


func remove_light(cell_position: Vector2i):
	if not lights.has(cell_position):
		return
	
	# invalidate light in area, then repropagate
	var light = lights[cell_position]
	lights.erase(cell_position)
	
	if calculated_lightmap[cell_position] > light:
		return
	
	var cleared_cells = []
	
	for x in range(cell_position.x - light + 1, cell_position.x + light):
		for y in range(cell_position.y - light + 1, cell_position.y + light):
			var clear_position = Vector2i(x, y)
			
			if calculated_lightmap[clear_position] <= light:
				calculated_lightmap[clear_position] = 0
				cleared_cells.append(clear_position)
	
	rerender_positions(cleared_cells)
	
	for cleared_cell in cleared_cells:
		propagate_light_at_position(cleared_cell)


func get_adjacent_cells(cell_position: Vector2i) -> Array:
	var adjacents = []
	
	for x in range(cell_position.x - 1, cell_position.x + 2):
		for y in range(cell_position.y - 1, cell_position.y + 2):
			var adjacent_cell = Vector2i(x, y)
			
			if adjacent_cell == cell_position or not calculated_lightmap.has(adjacent_cell):
				continue
			
			adjacents.append(adjacent_cell)
	
	return adjacents
