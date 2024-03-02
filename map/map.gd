extends TileMap
class_name Map


signal generation_finished
signal seed_updated(new_seed: int)


enum BaseTerrain {
	GRASS,
	SAND,
	WATER,
	DEEP_WATER,
	FOREST,
	CAVE
}


@onready var light_map: LightMap = $LightMap

# Note!! These need to be in order from highest region to lowest region (based on noise cutoff)
@export var biome_regions: Array[BiomeRegion]

@export var noise: FastNoiseLite
@export var cave_noise: FastNoiseLite

var max_north_south_bias: float = .7


func _ready():
	update_seed()


func generate_map(width: int, height: int, x_offset: int = 0, y_offset: int = 0):
	light_map.reset()
	
	var north_south_bias_step = max_north_south_bias / (height / 2.0)
	
	for y in range(height):
		var current_bias = clampf((y + y_offset) * (-north_south_bias_step), -1 , 1)
		for x in range(width):
			var cell_position = Vector2i(x + x_offset, y + y_offset)
			var noise_value = noise.get_noise_2d(x + x_offset, y + y_offset) + current_bias
			
			light_map.add_position(cell_position)
			
			var biome: Biome
			for biome_region in biome_regions:
				if noise_value > biome_region.noise_value_cutoff:
					biome = biome_region.biome
					break
			
			if not biome:
				push_error('Could not find biome for position', cell_position) 
				return
			
			set_cells_terrain_connect(0, [cell_position], 0, biome.terrain_id, false)
			if not biome.indoors:
				light_map.set_outdoors(cell_position, true)
			
			if biome.is_cave:
				generate_cave_scene(cell_position, biome.map_scenes, biome.cave_wall_scenes)
			else:
				generate_scene(cell_position, biome.map_scenes)
	
	light_map.recalculate_outdoor_lightmap()
	light_map.render_lightmap()
	
	generation_finished.emit()


func generate_scene(cell: Vector2i, map_scenes: Array[MapScene]):
	var total_weight = get_total_weight(map_scenes)
	var cell_position = map_to_local(cell)
	generate_scene_at_position(map_scenes, total_weight, cell_position)


func generate_cave_scene(cell: Vector2i, map_scenes: Array[MapScene], wall_scenes: Array[MapScene]):
	var total_weight = get_total_weight(map_scenes)
	var total_wall_weight = get_total_weight(wall_scenes)
	
	var local_cell_position = map_to_local(cell)
	
	if cave_noise.get_noise_2d(local_cell_position.x, local_cell_position.y) > 0.22:
		generate_scene_at_position(map_scenes, total_weight, local_cell_position)
	else:
		generate_scene_at_position(wall_scenes, total_wall_weight, local_cell_position)


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
	var instance = scene.instantiate() as Entity
	instance.position = at_position
	add_child(instance)
	instance.entity_removed.connect(_on_entity_removed)
	
	if instance.blocks_light:
		light_map.block_cell(local_to_map(at_position))


func clear_map():
	clear()
	
	for child in get_children():
		if child is LightMap:
			continue
		
		child.queue_free()


func update_seed(new_seed: int = 0):
	if new_seed == 0:
		randomize()
		noise.seed = randi()
	else:
		seed(new_seed)
		noise.seed = new_seed
	
	cave_noise.seed = noise.seed + 1
	
	seed_updated.emit(noise.seed)


func _on_player_moved_tiles(previous_position: Vector2i, new_position: Vector2i, player_instance: Player):
	light_map.remove_light(previous_position)
	light_map.add_light(new_position, player_instance.get_luminosity())


func _on_entity_removed(entity_instance: Entity):
	if (entity_instance.blocks_light):
		light_map.clear_blocked(local_to_map(entity_instance.position))
