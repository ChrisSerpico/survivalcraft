extends HBoxContainer
class_name RecipeDisplay


signal recipe_item_hovered(recipe_item: RecipeItem)
signal recipe_item_unhovered()


@export var recipe_item_display_scene: PackedScene

@onready var arrow_image: Control = $Arrow

var displayed_recipe: RecipeData


func display_recipe(recipe: RecipeData):
	displayed_recipe = recipe
	
	for child in get_children():
		if child != arrow_image:
			child.queue_free()
	
	for input in recipe.inputs:
		add_recipe_item_display(input)
	
	move_child(arrow_image, -1)
	
	add_recipe_item_display(recipe.output)
	
	reset_size()


func add_recipe_item_display(recipe_item: RecipeItem):
	var instance = recipe_item_display_scene.instantiate() as RecipeItemDisplay
	add_child(instance)
	instance.display_recipe_item(recipe_item)
	
	instance.recipe_item_hovered.connect(_on_recipe_item_hovered)
	instance.recipe_item_unhovered.connect(_on_recipe_item_unhovered)


func update_craftability(inventory: InventoryData):
	for child in get_children():
		if child is RecipeItemDisplay:
			if inventory.has_item_count(child.current_recipe_item.item_data, child.current_recipe_item.count):
				child.show_craftable()
			else:
				child.show_uncraftable()
	
	if (inventory.can_craft(displayed_recipe)):
		get_child(-1).show_craftable()
	else:
		get_child(-1).show_uncraftable()


func _on_recipe_item_hovered(recipe_item: RecipeItem):
	recipe_item_hovered.emit(recipe_item)


func _on_recipe_item_unhovered():
	recipe_item_unhovered.emit()
