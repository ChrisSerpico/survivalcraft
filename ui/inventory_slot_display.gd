extends PanelContainer
class_name InventorySlotDisplay


signal slot_display_clicked(slot_data: SlotData, was_primary: bool)


@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

var displayed_slot: SlotData
var tooltip_control: ItemTooltip


func show_tooltip():
	# TODO: do this with signals
	if tooltip_control and displayed_slot and displayed_slot.item:
		tooltip_control.show()
		tooltip_control.show_item(displayed_slot.item)


func hide_tooltip():
	if tooltip_control:
		tooltip_control.hide()


func set_display(slot: SlotData):
	displayed_slot = slot
	
	if slot.item:
		texture_rect.texture = slot.item.image
	else:
		texture_rect.texture = null
	
	if slot.count > 1:
		label.text = str(slot.count)
	else:
		label.text = ""
	
	if slot.selected:
		theme_type_variation = "HighlightedPanel"
	else:
		theme_type_variation = ""
	


func _on_gui_input(event: InputEvent):
	if event.is_action_pressed("primary"):
		slot_display_clicked.emit(displayed_slot, true)
	elif event.is_action_pressed("secondary"):
		slot_display_clicked.emit(displayed_slot, false)
