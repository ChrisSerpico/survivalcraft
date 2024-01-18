extends Area2D
class_name ResourceNode


signal progress_changed(percentage: float)
signal resource_created(instance: Node2D)
signal resources_depleted


enum CollectionStrength {
	NONE,
	STONE,
	IRON,
	SAPPHIRE
}
enum CollectionType {
	ANY,
	AXE,
	PICKAXE
}


@export var progress_bar_scene: PackedScene

@export var required_collection_strength: CollectionStrength = CollectionStrength.NONE
@export var required_collection_type: CollectionType = CollectionType.ANY
@export var dropped_item: ItemData
@export var item_count: int
@export var base_time_to_collect: float

@export var secondary_items: Array[ResourceNodeItem]
var secondary_drops: Dictionary
var total_secondary_drops: int = 0
var mean_time_to_drop: float

var collection_time: float = 0
var ejection_speed: float = 200

var mouse_over: bool = false


func _ready():
	for item in secondary_items:
		var count = randi_range(item.min_produced, item.max_produced)
		secondary_drops[item] = count
		total_secondary_drops += count
	
	if total_secondary_drops > 0:
		mean_time_to_drop = base_time_to_collect / total_secondary_drops


func add_collection_progress(progress: float, used_item: ItemData):
	if not mouse_over:
		return
	
	if used_item:
		if used_item.collection_strength < required_collection_strength:
			return
		elif required_collection_type != CollectionType.ANY and not used_item.collection_types.has(required_collection_type):
			return
		else:
			progress *= used_item.collection_speed_mod
	elif required_collection_strength > CollectionStrength.NONE or required_collection_type != CollectionType.ANY:
		return
	
	if collection_time == 0:
		begin_collecting()
	
	collection_time += progress
	progress_changed.emit(collection_time / base_time_to_collect)
	
	if total_secondary_drops > 0 and progress / mean_time_to_drop >= randf():
		var selected_resource = secondary_drops.keys()[randi_range(0, len(secondary_drops.keys()) - 1)] as ResourceNodeItem
		eject_item(selected_resource.item)
		
		total_secondary_drops -= 1
		secondary_drops[selected_resource] -= 1
		
		if secondary_drops[selected_resource] <= 0:
			secondary_drops.erase(selected_resource)
	
	if collection_time >= base_time_to_collect:
		for i in range(item_count):
			eject_item(dropped_item)
		
		for key: ResourceNodeItem in secondary_drops.keys():
			for drop in range(secondary_drops[key]):
				eject_item(key.item)
		
		resources_depleted.emit()


func eject_item(item_data: ItemData):
	var instance = item_data.get_scene_instance()
	resource_created.emit(instance)
	instance.apply_central_impulse(Vector2(randf_range(-1, 1) * ejection_speed, randf_range(-1, 1) * ejection_speed))


func begin_collecting():
	var bar_instance = progress_bar_scene.instantiate() as CustomProgressBar
	progress_changed.connect(bar_instance.update_percentage)
	add_child(bar_instance)
	bar_instance.position = position


func _on_mouse_exited():
	mouse_over = false


func _on_mouse_entered():
	mouse_over = true
