extends RigidBody2D
class_name Item


@onready var sprite: Sprite2D = $Sprite2D

var item_data: ItemData

var interactable: bool = true

var pickup_start: Vector2
var pickup_target: Node2D
var time_since_pickup: float
var tween_time: float = 0.3


func _ready():
	if item_data:
		sprite.texture = item_data.image


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if pickup_target:
		time_since_pickup += delta
		position = Tween.interpolate_value(pickup_start, pickup_target.position - pickup_start, time_since_pickup, tween_time, Tween.TRANS_LINEAR, Tween.EASE_IN)


func build_from_item_data(data: ItemData):
	item_data = data


func picked_up_by(node: Node2D):
	interactable = false
	pickup_start = position
	pickup_target = node
	time_since_pickup = 0
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), tween_time)
	tween.tween_callback(queue_free)


func pickup_radius_entered(node: Node2D):
	if not interactable:
		return
	
	if node is Player:
		var picked_up = node.pick_up(self)
		
		if picked_up:
			picked_up_by(node)
