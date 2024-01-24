extends TileMap
class_name LightMap


const MAX_LIGHT = 7

var outdoor_lightmap = {}
var temp_lightmap = {}
var calculated_lightmap = {}

# TODO: break these into a resource maybe?
var lights = {}
var outdoor_cells = {}
var blocked_cells = {}


func reset():
	clear()
	calculated_lightmap.clear()
	outdoor_lightmap.clear()
	temp_lightmap.clear()
	
	outdoor_cells.clear()
	blocked_cells.clear()


func add_position(cell_position: Vector2i):
	calculated_lightmap[cell_position] = 0


func set_outdoors(cell_position: Vector2i, outdoors: bool):
	outdoor_cells[cell_position] = outdoors


func set_blocked(cell_position: Vector2i, blocked: bool):
	blocked_cells[cell_position] = blocked


func recalculate_lightmap():
	recalculate_lightmap_for_positions(calculated_lightmap.keys())


func recalculate_lightmap_in_area(origin: Vector2i, dist: int):
	var cells_to_recalculate = []
	for x in range(origin.x - dist, origin.x + dist + 1):
		for y in range(origin.y - dist, origin.y + dist + 1):
			cells_to_recalculate.append(Vector2i(x, y))
	
	recalculate_lightmap_for_positions(cells_to_recalculate)


func recalculate_lightmap_for_positions(cell_positions: Array):
	for cell_position in cell_positions:
		calculated_lightmap[cell_position] = maxi(temp_lightmap.get(cell_position, 0), outdoor_lightmap.get(cell_position, 0))
	
	rerender_positions(cell_positions)


func recalculate_outdoor_lightmap():
	var cells_to_propogate = []
	
	for outdoor_cell in outdoor_cells:
		outdoor_lightmap[outdoor_cell] = MAX_LIGHT
		
		for adjacent_cell in get_adjacent_cells(outdoor_cell):
			if not outdoor_cells.has(adjacent_cell) and calculated_lightmap.has(adjacent_cell):
				cells_to_propogate.append(adjacent_cell)
	
	for propogation_target in cells_to_propogate:
		propogate_light_at_position(propogation_target, outdoor_lightmap, MAX_LIGHT - 1)


func render_lightmap():
	rerender_positions(calculated_lightmap.keys())


func rerender_positions(cell_positions: Array):
	for cell_position in cell_positions:
		set_cell(0, cell_position, 0, Vector2i(mini(calculated_lightmap[cell_position], MAX_LIGHT), 0))


func propogate_light_at_position(position: Vector2i, light_map: Dictionary, brightness: int):
	if light_map.get(position, 0) >= brightness:
		return
	
	var light_level = brightness
	var visited_cells = {
		position: true
	}
	var cells_to_check = [position]
	
	while len(cells_to_check) > 0:
		for i in range(len(cells_to_check)):
			var next_cell = cells_to_check.pop_front()
			
			if light_map.get(next_cell, 0) >= light_level:
				continue
			
			light_map[next_cell] = light_level
			
			if blocked_cells.has(next_cell):
				continue
			
			for adjacent_cell in get_adjacent_cells(next_cell):
				if not visited_cells.has(adjacent_cell):
					visited_cells[adjacent_cell] = true
					cells_to_check.append(adjacent_cell)
		
		light_level -= 1
		
		if light_level <= 0:
			break


func add_light(position: Vector2i, brightness: int):
	if lights.has(position):
		remove_light(position)
	
	lights[position] = brightness
	
	if temp_lightmap.get(position, 0) >= brightness:
		return
	
	propogate_light_at_position(position, temp_lightmap, brightness)
	recalculate_lightmap_in_area(position, brightness - 1)


func remove_light(cell_position: Vector2i):
	if not lights.has(cell_position):
		return
	
	# invalidate light in area, propagate lights in that area, then propagate adjacent light into area
	var light = lights[cell_position]
	lights.erase(cell_position)
	
	var cleared_cells = []
	var edge_cells = []
	
	for x in range(cell_position.x - light, cell_position.x + light + 1):
		for y in range(cell_position.y - light, cell_position.y + light + 1):
			var clear_position = Vector2i(x, y)
			
			if x == cell_position.x - light or x == cell_position.x + light + 1:
				edge_cells.append(clear_position)
			elif y == cell_position.y - light or y == cell_position.y + light + 1:
				edge_cells.append(clear_position)
			
			temp_lightmap[clear_position] = 0
			cleared_cells.append(clear_position)
	
	for cleared_cell in cleared_cells:
		if lights.has(cleared_cell):
			propogate_light_at_position(cleared_cell, temp_lightmap, lights[cleared_cell])
	
	for edge_cell in edge_cells:
		var highest_adjacent_light = 0
		
		for adjacent_to_edge in get_adjacent_cells(edge_cell):
			highest_adjacent_light = temp_lightmap.get(adjacent_to_edge, 0)
		
		propogate_light_at_position(edge_cell, temp_lightmap, highest_adjacent_light - 1)
	
	recalculate_lightmap_in_area(cell_position, light - 1)


func get_adjacent_cells(cell_position: Vector2i) -> Array:
	var adjacents = []
	
	for x in range(cell_position.x - 1, cell_position.x + 2):
		for y in range(cell_position.y - 1, cell_position.y + 2):
			var adjacent_cell = Vector2i(x, y)
			
			if adjacent_cell == cell_position:
				continue
			
			adjacents.append(adjacent_cell)
	
	return adjacents
