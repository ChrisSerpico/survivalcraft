extends CharacterBody2D
class_name Player


@onready var animated_sprite: PlayerSprite = $AnimationPlayer
@onready var sprite_overlay: ColorRect = $Sprite2D/Overlay
@onready var interaction_ray: RayCast2D = $InteractionRay

@export var speed: float = 64
@export var interaction_range: float = 25
var speed_mod: float = 1

@export var map: TileMap

@export var inventory_size: int
@export var equipment_size: int
var inventory: InventoryData
var active_equipment_index: int = 0
var active_equipment_slot: SlotData

@export var known_recipes: Array[RecipeData]

var in_menu: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	inventory = InventoryData.new(inventory_size + equipment_size)
	select_slot(active_equipment_index)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Ongoing effects
	handle_tile_effects()
	interaction_ray.target_position = get_local_mouse_position() - interaction_ray.position
	
	# Equipment selection
	if Input.is_action_just_pressed("select_next"):
		select_slot(active_equipment_index + 1)
	elif Input.is_action_just_pressed("select_previous"):
		select_slot(active_equipment_index - 1)
	
	# Movement
	velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	velocity = velocity.normalized() * speed * speed_mod
	
	var running = Input.is_action_pressed("sprint")
	if running:
		velocity *= 2
	
	animated_sprite.update_animation(velocity, running, !in_menu and Input.is_action_pressed("primary"))
	move_and_slide()
	
		# Item usage
	if in_menu: 
		return
	
	if Input.is_action_pressed("primary") and interaction_ray.is_colliding():
		handle_primary_interaction(delta)


func select_slot(slot_index: int):
	if slot_index < 0:
		active_equipment_index = equipment_size - 1
	else:
		active_equipment_index = slot_index % equipment_size
	
	if active_equipment_slot:
		active_equipment_slot.set_selected(false)
	
	active_equipment_slot = inventory.slots[active_equipment_index]
	active_equipment_slot.set_selected(true)


func pick_up(item: Item) -> bool:
	return inventory.add_item(item)


func craft_recipe(recipe: RecipeData):
	var dropped_item_scene = inventory.craft_item(recipe)
	
	if dropped_item_scene != null:
		dropped_item_scene.position = position
		add_sibling(dropped_item_scene)


func handle_tile_effects():
	if not map:
		return
	
	var current_tile: TileData = map.get_cell_tile_data(0, map.local_to_map(position))
	
	if not current_tile:
		return
	
	var overlay_color: Color = current_tile.get_custom_data("overlay")
	var overlay_scale: float = current_tile.get_custom_data("overlay_scale")
	
	if overlay_color != Color.BLACK:
		var final_scale = 1
		if overlay_scale != 0:
			final_scale = overlay_scale
		
		sprite_overlay.color = overlay_color
		sprite_overlay.scale = Vector2(final_scale, final_scale)
		sprite_overlay.show()
	else:
		sprite_overlay.hide()
	
	var tile_speed_mod: float = current_tile.get_custom_data("speed_mod")
	
	if tile_speed_mod != 0:
		speed_mod = tile_speed_mod
	else:
		speed_mod = 1


func handle_primary_interaction(delta: float):
	if interaction_ray.get_collision_point().distance_to(position) > interaction_range:
		return
	
	var interaction_target = interaction_ray.get_collider()
	
	if interaction_target is ResourceNode:
		interaction_target.add_collection_progress(delta, active_equipment_slot.item)
	
