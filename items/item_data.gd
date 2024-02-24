extends Resource
class_name ItemData


@export var name: String = "ERROR_NO_NAME"
@export var image: Texture2D
@export var stackable: bool = false
@export_multiline var description: String = "ERROR_NO_DESC"

@export var dropped_base_scene: PackedScene

@export_group("Collection")
@export var collection_strength: ResourceNode.CollectionStrength = ResourceNode.CollectionStrength.NONE
@export var collection_types: Array[ResourceNode.CollectionType] = []
@export var collection_speed_mod: float = 1.0

@export_group("Damage")
@export var base_damage: int = 1

@export_group("Lighting")
@export var luminosity: int = 1


func get_scene_instance() -> Item:
	var instance = dropped_base_scene.instantiate() as Item
	instance.build_from_item_data(self)
	return instance
	
