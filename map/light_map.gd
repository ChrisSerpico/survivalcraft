extends TileMap
class_name LightMap


const LIGHTING_MAX = 11

var lights = {}
var calculated_lightmap = {}

# TODO: break these into a resource 
var indoor_cells = {}
var blocked_cells = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func reset():
	lights.clear()
	calculated_lightmap.clear()
	indoor_cells.clear()
	blocked_cells.clear()


func add_position(cell_position: Vector2i):
	if calculated_lightmap.has(cell_position):
		return
	
	calculated_lightmap[cell_position] = -99


func set_indoors(cell_position, indoors: bool):
	indoor_cells[cell_position] = indoors


func set_blocked(cell_position: Vector2i, blocked: bool):
	blocked_cells[cell_position] = blocked


func add_light(position: Vector2i, brightness: int):
	lights[position] = brightness
	
	if (brightness > calculated_lightmap[position]):
		recalculate_in_area(position.x, position.y, brightness, brightness)


func remove_light(position: Vector2i):
	var brightness = lights.get(position, 0)
	lights.erase(position)
	
	recalculate_in_area(position.x, position.y, brightness, brightness)


func recalculate_all():
	recalculate_for_positions(calculated_lightmap.keys())


func recalculate_in_area(x_origin: int, y_origin: int, width: int, height: int):
	var cells_to_recalculate = []
	for x in range(x_origin - width, x_origin + width + 1):
		for y in range(y_origin - height, y_origin + height + 1):
			cells_to_recalculate.append(Vector2i(x, y))
	
	recalculate_for_positions(cells_to_recalculate)


# TODO: queue this and only do a certain amount of updates each _process
func recalculate_for_positions(positions: Array):
	for position in positions:
		if not indoor_cells.get(position, false):
			calculated_lightmap[position] = LIGHTING_MAX
		elif lights.has(position):
			calculated_lightmap[position] = lights[position]
		else:
			calculated_lightmap[position] = 0
	
	var changed = true
	while changed:
		changed = false
		
		for position in positions:
			if calculated_lightmap[position] == LIGHTING_MAX:
				continue
			
			var highest_adjacent = get_highest_adjacent_lighting(position)
			
			if highest_adjacent > calculated_lightmap[position] + 1:
				calculated_lightmap[position] = highest_adjacent - 1
				changed = true
	
	for cell_position in positions:
		set_cell(0, cell_position, 0, Vector2i(maxi(calculated_lightmap[cell_position], 0), 0))


func get_highest_adjacent_lighting(cell_position: Vector2i) -> int:
	var highest_lighting = 0
	
	for x in range(cell_position.x - 1, cell_position.x + 2):
		for y in range(cell_position.y - 1, cell_position.y + 2):
			var check_position = Vector2i(x, y)
			
			if check_position == cell_position or blocked_cells.get(check_position, false):
				continue
			elif calculated_lightmap.has(check_position):
				highest_lighting = maxi(highest_lighting, calculated_lightmap[check_position])
	
	return highest_lighting
