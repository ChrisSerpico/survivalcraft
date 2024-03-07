extends Button


signal character_texture_selected(texture: Texture2D)


@export var character_texture: Texture2D


func _on_toggled(toggled_on):
	if toggled_on:
		character_texture_selected.emit(character_texture)
