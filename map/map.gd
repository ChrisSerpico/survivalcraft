extends TileMap
class_name Map


signal generation_finished


enum BaseTerrain {
	GRASS,
	SAND,
	WATER,
	DEEP_WATER,
	FOREST,
	CAVE
}


@export var grass_scenes: Array[MapScene]
@export var forest_scenes: Array[MapScene]
@export var cave_scenes: Array[MapScene]
@export var cave_wall_scene: PackedScene

@export var noise: FastNoiseLite
@export var cave_noise: FastNoiseLite


# Called when the node enters the scene tree for the first time.
func _ready():
	update_seed()


func generate_map(width: int, height: int, x_offset: int = 0, y_offset: int = 0):
	var cells = {
		BaseTerrain.GRASS: [] as Array[Vector2i],
		BaseTerrain.SAND: [] as Array[Vector2i],
		BaseTerrain.WATER: [] as Array[Vector2i],
		BaseTerrain.DEEP_WATER: [] as Array[Vector2i],
		BaseTerrain.FOREST: [] as Array[Vector2i],
		BaseTerrain.CAVE: [] as Array[Vector2i]
	}
	
	for x in range(width):
		for y in range(height):
			var cell_position = Vector2i(x + x_offset, y + y_offset)
			var noise_value = noise.get_noise_2d(x + x_offset, y + y_offset)
			
			if (noise_value > 0.35):
				cells[BaseTerrain.CAVE].append(cell_position)
			elif (noise_value > 0.22):
				cells[BaseTerrain.FOREST].append(cell_position)
			elif (noise_value > -.1):
				cells[BaseTerrain.GRASS].append(cell_position)
			elif (noise_value > -0.15):
				cells[BaseTerrain.SAND].append(cell_position)
			elif (noise_value > -0.25):
				cells[BaseTerrain.WATER].append(cell_position)
			else:
				cells[BaseTerrain.DEEP_WATER].append(cell_position)
	
	for terrain in cells:
		set_cells_terrain_connect(0, cells[terrain], 0, terrain, false)
	
	generate_scenes(cells[BaseTerrain.GRASS], grass_scenes)
	generate_scenes(cells[BaseTerrain.FOREST], forest_scenes)
	generate_cave_scenes(cells[BaseTerrain.CAVE], cave_scenes, cave_wall_scene)
	
	generation_finished.emit()


func generate_scenes(cells: Array[Vector2i], map_scenes: Array[MapScene]):
	var total_weight = get_total_weight(map_scenes)
	
	for cell in cells:
		var cell_position = map_to_local(cell)
		generate_scene_at_position(map_scenes, total_weight, cell_position)


func generate_cave_scenes(cells: Array[Vector2i], map_scenes: Array[MapScene], wall_scene: PackedScene):
	var total_weight = get_total_weight(map_scenes)
	
	for cell in cells:
		var cell_position = map_to_local(cell)
		
		if cave_noise.get_noise_2d(cell_position.x, cell_position.y) > 0.22:
			generate_scene_at_position(map_scenes, total_weight, cell_position)
		else:
			instantiate_scene_at_position(wall_scene, cell_position)


func get_total_weight(scene_list: Array[MapScene]) -> int:
	var total_weight = 0
	for scene in scene_list:
		total_weight += scene.weight
	
	return total_weight


func generate_scene_at_position(possible_scenes: Array[MapScene], total_weight: int, cell_position: Vector2):
	var weight_roll = randi_range(0, total_weight)
	
	for possible_scene in possible_scenes:
		weight_roll -= possible_scene.weight
		
		if weight_roll <= 0:
			if possible_scene.scene:
				instantiate_scene_at_position(possible_scene.scene, cell_position)
			
			return


func instantiate_scene_at_position(scene: PackedScene, at_position: Vector2):
	var instance = scene.instantiate() as Node2D
	instance.position = at_position
	add_child(instance)


func clear_map():
	clear()
	
	for child in get_children():
		child.queue_free()


func update_seed(new_seed: int = 0):
	if new_seed == 0:
		noise.seed = randi()
	else:
		noise.seed = new_seed
	
	cave_noise.seed = noise.seed + 1
