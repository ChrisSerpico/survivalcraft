extends InventorySlotDisplay
class_name FloatingInventorySlot


signal slot_dropped(slot: SlotData, count: int)


var over_inventory: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = get_viewport().get_mouse_position() + Vector2(-72, -size.y)
	
	if not over_inventory and displayed_slot and not displayed_slot.is_empty():
		if Input.is_action_just_pressed("primary"):
			slot_dropped.emit(displayed_slot, displayed_slot.count)
		elif Input.is_action_just_pressed("secondary"):
			slot_dropped.emit(displayed_slot, 1)


func set_floating_display(slot: SlotData):
	if slot.is_empty():
		hide()
	else:
		show()
		set_display(slot)


func set_over_inventory():
	over_inventory = true


func set_not_over_inventory():
	over_inventory = false
