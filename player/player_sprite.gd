extends AnimationPlayer
class_name PlayerSprite


enum Direction { UP, DOWN, LEFT, RIGHT }

var facing: Direction = Direction.DOWN
var player_instance: Player


func _ready():
	player_instance = get_parent()


func update_animation(velocity: Vector2, running: bool = false, acting: bool = false):
	var moving = !velocity.is_zero_approx()
	
	if (!moving and acting):
		var mouse_pos = player_instance.get_global_mouse_position()
		var angle_to_mouse = player_instance.position.angle_to_point(mouse_pos)
		
		if (angle_to_mouse >= PI * -.25 and angle_to_mouse < PI * .25):
			facing = Direction.RIGHT
		elif (angle_to_mouse >= PI * .25 and angle_to_mouse < PI * .75):
			facing = Direction.DOWN
		elif (angle_to_mouse >= PI * .75 or angle_to_mouse < PI * -.75):
			facing = Direction.LEFT
		else:
			facing = Direction.UP
			
	else:
		if (velocity.y < 0):
			facing = Direction.UP
		elif (velocity.y > 0):
			facing = Direction.DOWN
		elif (velocity.x < 0):
			facing = Direction.LEFT
		elif (velocity.x > 0):
			facing = Direction.RIGHT
	
	var animation: String
	var speed: float = 1
	
	if (not moving):
		if acting:
			animation = get_animation_from_prefix("action")
		else:
			animation = get_animation_from_prefix("idle")
	else:
		animation = get_animation_from_prefix("move")
	
	if running:
		speed *= 2
	
	speed_scale = speed
	play(animation)


func get_animation_from_prefix(prefix: String) -> String:
	var base = prefix + "_"
	
	match facing:
		Direction.UP:
			base += "up"
		Direction.DOWN:
			base += "down"
		Direction.LEFT:
			base += "left"
		Direction.RIGHT:
			base += "right"
	
	return base
