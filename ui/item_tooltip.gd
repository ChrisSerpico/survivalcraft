extends PanelContainer
class_name ItemTooltip


@onready var item_image: TextureRect = $MarginContainer/VBoxContainer/NameContainer/ItemIcon
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameContainer/ItemName
@onready var desc_label: Label = $MarginContainer/VBoxContainer/ItemDescription

@onready var stats_label: Label = $MarginContainer/VBoxContainer/ItemStats
@onready var stats_separator: HSeparator = $MarginContainer/VBoxContainer/HSeparator2


func _process(_delta):
	position = get_viewport().get_mouse_position() + Vector2(8, -size.y)


func show_item(item: ItemData):
	show()
	
	item_image.texture = item.image
	name_label.text = item.name
	desc_label.text = item.description
	
	var stat_desc = get_item_stat_string(item)
	
	if stat_desc != "":
		stats_label.text = stat_desc
		stats_label.show()
		stats_separator.show()
	else:
		stats_label.hide()
		stats_separator.hide()
	
	reset_size()


func hide_display():
	hide()


func get_item_stat_string(item: ItemData) -> String:
	var stat_desc = ""
	
	if item.base_damage > 1:
		stat_desc += "Damage: " + str(item.base_damage)
	if item.collection_strength != ResourceNode.CollectionStrength.NONE:
		stat_desc += "Tool Level: " + ResourceNode.CollectionStrength.keys()[item.collection_strength].capitalize()
	if item.collection_speed_mod != 1:
		stat_desc += "Collection Speed: " + str(item.collection_speed_mod)
	
	return stat_desc
