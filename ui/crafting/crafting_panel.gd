extends HSplitContainer
class_name CraftingPanel


signal recipe_craft_attempted(recipe: RecipeData)
signal item_hovered(item: ItemData)
signal item_unhovered()


@export var recipe_button_scene: PackedScene
@onready var recipe_button_container: VBoxContainer = $RecipeList/ScrollContainer/MarginContainer/VBoxContainer

@onready var displayed_recipe_name: Label = $DisplayedRecipe/MarginContainer/VBoxContainer/RecipeName
@onready var recipe_display: RecipeDisplay = $DisplayedRecipe/MarginContainer/VBoxContainer/RecipeDisplay

@onready var craft_button: Button = $DisplayedRecipe/MarginContainer/VBoxContainer/CraftButton

var connected_inventory: InventoryData
var selected_recipe: RecipeData


func display_recipe_list(recipes: Array[RecipeData], inventory: InventoryData):
	for child in recipe_button_container.get_children():
		child.queue_free()
	selected_recipe = null
	
	connected_inventory = inventory
	connected_inventory.inventory_updated.connect(_on_inventory_updated)
	
	for recipe in recipes:
		var new_button = recipe_button_scene.instantiate() as RecipeButton
		new_button.set_recipe(recipe)
		new_button.recipe_selected.connect(select_recipe)
		recipe_button_container.add_child(new_button)
		
		# select first recipe by default 
		if selected_recipe == null:
			select_recipe(recipe)
	
	update_craftability()


func select_recipe(recipe: RecipeData):
	selected_recipe = recipe
	displayed_recipe_name.text = "Crafting " + recipe.recipe_name
	recipe_display.display_recipe(recipe)
	
	update_craftability()


func update_craftability():
	for recipe_button: RecipeButton in recipe_button_container.get_children():
		if connected_inventory.can_craft(recipe_button.recipe):
			recipe_button.show_craftable()
		else:
			recipe_button.show_uncraftable()
	
	if connected_inventory.can_craft(selected_recipe):
		craft_button.text = "Craft!"
		craft_button.disabled = false
	else:
		craft_button.text = "Missing Components"
		craft_button.disabled = true
	
	recipe_display.update_craftability(connected_inventory)


func _on_craft_button_pressed():
	recipe_craft_attempted.emit(selected_recipe)


func _on_recipe_display_recipe_item_hovered(recipe_item: RecipeItem):
	item_hovered.emit(recipe_item.item_data)


func _on_recipe_display_recipe_item_unhovered():
	item_unhovered.emit()


func _on_inventory_updated(_inventory: InventoryData):
	update_craftability()
