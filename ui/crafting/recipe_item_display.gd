extends VBoxContainer
class_name RecipeItemDisplay


signal recipe_item_hovered(recipe_item: RecipeItem)
signal recipe_item_unhovered()


@onready var item_image: TextureRect = $ItemImage
@onready var count_display: Label = $CountDisplay

var current_recipe_item: RecipeItem


func display_recipe_item(recipe_item: RecipeItem):
	current_recipe_item = recipe_item
	
	item_image.texture = recipe_item.item_data.image
	
	if recipe_item.count > 1:
		count_display.text = str(recipe_item.count) + "x"
	else:
		count_display.text = ""


func show_craftable():
	item_image.modulate = Color(1, 1, 1, 1)
	count_display.modulate = Color(1, 1, 1, 1)


func show_uncraftable():
	item_image.modulate = Color('a50000')
	count_display.modulate = Color('a50000')


func _on_mouse_entered():
	recipe_item_hovered.emit(current_recipe_item)


func _on_mouse_exited():
	recipe_item_unhovered.emit()
