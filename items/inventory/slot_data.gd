extends Resource
class_name SlotData


signal slot_updated(slot: SlotData)


@export var item: ItemData
@export var count: int
@export var stack_limit: int = 128
var selected: bool = false


func is_empty() -> bool:
	return not item


func clear():
	item = null
	count = 0
	
	slot_updated.emit(self)


func add_item(item_data: ItemData):
	if is_empty():
		item = item_data
		count = 1
	elif can_stack(item_data):
		count += 1
	
	slot_updated.emit(self)


func remove_count(to_remove: int) -> int:
	var left_to_remove = to_remove
	
	if to_remove >= count:
		left_to_remove -= count
		clear()
	else:
		count -= to_remove
		left_to_remove = 0
	
	slot_updated.emit(self)
	return left_to_remove


func can_stack(other_item: ItemData):
	if is_empty():
		return true
	
	return item.stackable and item == other_item and count < stack_limit

# TODO: it HAS to be possible to clean up this code lol 
# Specifically split the other slot code into a different function and
# combine some of these functions into one 
func stack_from_slot(other_slot: SlotData):
	if not other_slot.item:
		return
	
	if is_empty():
		item = other_slot.item
		count = other_slot.count
		other_slot.clear()
	elif item != other_slot.item:
		var temp_item = other_slot.item
		other_slot.item = item
		item = temp_item
		
		var temp_count = other_slot.count
		other_slot.count = count
		count = temp_count
		
		other_slot.slot_updated.emit(other_slot)
	else:
		var total = count + other_slot.count
		
		if total > stack_limit:
			var leftover = total - stack_limit
			count = stack_limit
			
			other_slot.count = leftover
			other_slot.slot_updated.emit(other_slot)
		else:
			count = total
			other_slot.clear()
	
	slot_updated.emit(self)


func split_from_slot(other_slot: SlotData):
	if not other_slot.item:
		return
	
	if not other_slot.item.stackable or other_slot.count == 1:
		item = other_slot.item
		count = other_slot.count
		other_slot.clear()
	else:
		var half = other_slot.count / 2
		item = other_slot.item
		count = half
		other_slot.count = other_slot.count - half
		
		other_slot.slot_updated.emit(other_slot)
		
	slot_updated.emit(self)


func add_from_slot(other_slot: SlotData):
	if not other_slot.item:
		return
	
	if is_empty() or can_stack(other_slot.item):
		add_item(other_slot.item)
		other_slot.count -= 1
		if other_slot.count <= 0:
			other_slot.clear()
		else:
			other_slot.slot_updated.emit(other_slot)


func set_selected(val: bool):
	selected = val
	slot_updated.emit(self)
