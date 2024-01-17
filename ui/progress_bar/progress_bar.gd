extends Control
class_name CustomProgressBar


const MIN_SIZE = 2
const MAX_SIZE = 22

@onready var fill: TextureRect = $Background/Fill


var percentage: float:
	set(value):
		percentage = value
		fill.size.x = lerp(MIN_SIZE, MAX_SIZE, clampf(percentage, 0, 1))


func _ready():
	percentage = 0


func update_percentage(new_percent: float):
	percentage = new_percent
