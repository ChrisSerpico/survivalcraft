extends Node2D


func create_instance(instance: Node2D):
	instance.position = position
	add_sibling(instance)


func remove():
	queue_free()
