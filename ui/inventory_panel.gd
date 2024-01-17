extends PanelContainer
class_name InventoryPanel


@onready var flow_container: HFlowContainer = $MarginContainer/HFlowContainer

@export var inventory_slot_display: PackedScene
@export var item_tooltip: ItemTooltip


func display_inventory(inventory: InventoryData, from: int = 0, to: int = -1):
	clear()
	
	if to < 0:
		to = len(inventory.slots)
	
	for slot in inventory.slots.slice(from, to):
		var instance = inventory_slot_display.instantiate() as InventorySlotDisplay
		flow_container.add_child(instance)
		
		slot.slot_updated.connect(instance.set_display)
		instance.tooltip_control = item_tooltip
		instance.set_display(slot)


func show_selected_slot(slot_index: int):
	var slots = flow_container.get_children()
	
	if slot_index >= len(slots):
		printerr('Selected slot index out of range')
		return
	
	slots[slot_index].set_selected(true)


func clear():
	for slot_display in flow_container.get_children():
		slot_display.queue_free()
