extends Resource
class_name InventoryData


signal inventory_updated(inventory: InventoryData)


@export var slots: Array[SlotData] = []


func _init(size: int = 8):
	add_slots(size)


func clear():
	var current_size = len(slots)
	slots.clear()
	add_slots(current_size)


func add_slots(num: int):
	for i in range(num):
		var new_slot = SlotData.new()
		slots.append(new_slot)
		new_slot.slot_updated.connect(_on_slot_updated)


# TODO: Handle adding multiple items
func add_item(item: Item) -> bool:
	return add_item_from_data(item.item_data)


func add_item_from_data(item_data: ItemData) -> bool:
	if not item_data:
		return false
	
	if item_data.stackable:
		for slot in slots:
			if slot.is_empty():
				continue
			elif slot.can_stack(item_data):
				slot.add_item(item_data)
				return true
	
	for slot in slots:
		if slot.is_empty():
			slot.add_item(item_data)
			return true
	
	return false


func get_total(searched_item: ItemData) -> int:
	var total = 0
	
	for slot in slots:
		if slot.item == searched_item:
			total += slot.count
	
	return total


func can_craft(recipe: RecipeData) -> bool:
	for input in recipe.inputs:
		if not has_item_count(input.item_data, input.count):
			return false
	
	return true


func has_item_count(item: ItemData, count: int):
	return get_total(item) >= count


func craft_item(recipe: RecipeData) -> Item:
	if not can_craft(recipe):
		return
	
	for input_item in recipe.inputs:
		var to_remove = input_item.count
		
		for slot in slots:
			if slot.item == input_item.item_data:
				to_remove -= slot.remove_count(to_remove)
			
			if to_remove <= 0:
				break
		
	if add_item_from_data(recipe.output.item_data):
		return null
	else:
		return recipe.output.item_data.get_scene_instance()


func _on_slot_updated(_slot: SlotData):
	inventory_updated.emit(self)
