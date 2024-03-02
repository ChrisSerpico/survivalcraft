extends PanelContainer


@onready var seed_label: Label = $MarginContainer/VBoxContainer/SeedLabel


func _on_seed_updated(new_seed: int):
	seed_label.text = "Seed: " + str(new_seed)
