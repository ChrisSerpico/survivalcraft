extends CharacterBody2D
class_name Player


signal recipe_list_updated(recipe_list: Array[RecipeData], inventory: InventoryData)
signal moved_tiles(previous_position: Vector2i, new_position: Vector2i, player_instance: Player)


@onready var base_sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: PlayerSprite = $AnimationPlayer
@onready var sprite_overlay: ColorRect = $Sprite2D/Overlay
@onready var interaction_ray: RayCast2D = $InteractionRay

@export var speed: float = 64
@export var interaction_range: float = 25
var speed_mod: float = 1

@export var map: TileMap
var current_tile_position: Vector2i

@export var inventory_size: int
@export var equipment_size: int
var inventory: InventoryData
var active_equipment_index: int = 0
var active_equipment_slot: SlotData
var floating_slot: SlotData

@export var known_recipes: Array[RecipeData]

@export var base_luminosity: int = 2

var ejection_speed: float = 350

var in_menu: bool = false

# Easter egg stuff
var found_gold: bool = false
var found_sapphire: bool = false
var found_recipe: bool = false
@export var gold_bar_data: ItemData
@export var sapphire_data: ItemData
@export var sapphire_pick_recipe: RecipeData


# Called when the node enters the scene tree for the first time.
func _ready():
	inventory = InventoryData.new(inventory_size + equipment_size)
	floating_slot = SlotData.new()
	
	select_slot(active_equipment_index)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Ongoing effects
	handle_tile_effects()
	interaction_ray.target_position = get_local_mouse_position() - interaction_ray.position
	
	# TODO: offset this with a variable rather than a magic number
	var tile_position = map.local_to_map(position + Vector2.UP * 7)
	if tile_position != current_tile_position:
		moved_tiles.emit(current_tile_position, tile_position, self)
		current_tile_position = tile_position
	
	# Equipment selection
	if Input.is_action_just_pressed("select_next"):
		select_slot(active_equipment_index + 1)
	elif Input.is_action_just_pressed("select_previous"):
		select_slot(active_equipment_index - 1)
	if Input.is_action_just_pressed("drop"):
		drop_active_item()
	
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


func slot_clicked(slot_data: SlotData, was_primary: bool):
	if floating_slot.is_empty():
		stack_to_floating(slot_data, !was_primary)
	else:
		stack_from_floating(slot_data, !was_primary)


func stack_to_floating(slot_data: SlotData, half: bool = false):
	if half:
		floating_slot.split_from_slot(slot_data)
	else:
		floating_slot.stack_from_slot(slot_data)


func stack_from_floating(to_slot: SlotData, single: bool = false):
	if not single:
		to_slot.stack_from_slot(floating_slot)
	else:
		to_slot.add_from_slot(floating_slot)


func pick_up(item: Item) -> bool:
	check_easter_egg_recipe(item.item_data)
	return inventory.add_item(item)


func drop_active_item():
	if not active_equipment_slot.is_empty():
		eject_item(active_equipment_slot.item.get_scene_instance())
		active_equipment_slot.remove_one()


func drop_from_slot(slot: SlotData, count: int):
	for i in range(count):
		eject_item(slot.item.get_scene_instance())
	
	slot.remove_count(count)


func craft_recipe(recipe: RecipeData):
	var dropped_item_scenes = inventory.craft_item(recipe) as Array[Item]
	
	check_easter_egg_recipe(recipe.output.item_data)
	
	if not dropped_item_scenes.is_empty():
		for scene in dropped_item_scenes:
			scene.position = position
			add_sibling(scene)


func eject_item(item: Item):
	item.position = position
	add_sibling(item)
	
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = position.angle_to_point(mouse_pos)
	item.apply_central_impulse(Vector2.from_angle(angle_to_mouse).normalized() * ejection_speed)


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


func get_luminosity():
	var highest_luminosity = base_luminosity
	
	for i in range(equipment_size):
		if not inventory.slots[i].is_empty():
			highest_luminosity = maxi(inventory.slots[i].item.luminosity, highest_luminosity)
	
	return highest_luminosity


func change_sprite(new_sprite: Texture2D):
	base_sprite.texture = new_sprite


# TODO: remove/change once easter egg is finished 
func check_easter_egg_recipe(item: ItemData):
	if found_recipe:
		return
	
	if item == gold_bar_data:
		found_gold = true
	elif item == sapphire_data:
		found_sapphire = true
	
	if found_gold and found_sapphire:
		known_recipes.append(sapphire_pick_recipe)
		recipe_list_updated.emit(known_recipes, inventory)
		found_recipe = true
