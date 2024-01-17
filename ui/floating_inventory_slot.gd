extends InventorySlotDisplay
class_name FloatingInventorySlot


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = get_viewport().get_mouse_position() + Vector2(-72, -size.y)


func set_floating_display(slot: SlotData):
	if slot.is_empty():
		hide()
	else:
		show()
		set_display(slot)
