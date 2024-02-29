extends Node2D
class_name Entity


signal entity_removed(instance: Entity)


@export var blocks_light: bool = false


func create_instance(instance: Node2D):
	instance.position = position
	add_sibling(instance)


func remove():
	entity_removed.emit(self)
	queue_free()
