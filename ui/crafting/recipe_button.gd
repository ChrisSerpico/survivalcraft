extends Button
class_name RecipeButton


signal recipe_selected(recipe: RecipeData)


var recipe: RecipeData


func set_recipe(new_recipe: RecipeData):
	recipe = new_recipe
	text = recipe.recipe_name
	icon = recipe.output.item_data.image


func show_craftable():
	theme_type_variation = ""


func show_uncraftable():
	theme_type_variation = "RedButton"


func _on_pressed():
	recipe_selected.emit(recipe)
