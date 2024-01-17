extends Camera2D
class_name PlayerCamera


@onready var camera_target

var drag: bool = false
var drag_origin: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not camera_target:
		return
	
	position = camera_target.position
	
	if Input.is_action_just_pressed("debug_zoom_in"):
		zoom = zoom * 1.1
	elif Input.is_action_just_pressed("debug_zoom_out"):
		zoom = zoom * 0.9
	elif Input.is_action_just_pressed("debug_drag_camera"):
		drag = true
		drag_origin = get_global_mouse_position()
	elif Input.is_action_just_released("debug_drag_camera"):
		drag = false
	
	if drag:
		offset += (drag_origin - get_global_mouse_position())
