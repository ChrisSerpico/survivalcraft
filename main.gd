extends Node
class_name Main


enum GameState {
	MAIN_MENU,
	READY_FOR_NEW,
	IN_GAME,
	PAUSE_MENU,
	INVENTORY_MENU
}


# In-game node refs
@onready var map: Map = $World/Map
@onready var player_camera: PlayerCamera = $Camera2D

# Control node refs
# New Game Menu
@onready var new_game_menu: Control = $ControlLayer/NewGameMenu
@onready var map_seed_input: SpinBox = $ControlLayer/NewGameMenu/MarginContainer/VBoxContainer/SeedInputContainer/SeedInput
@onready var map_width_input: SpinBox = $ControlLayer/NewGameMenu/MarginContainer/VBoxContainer/MapSizeInputs/Width
@onready var map_height_input: SpinBox = $ControlLayer/NewGameMenu/MarginContainer/VBoxContainer/MapSizeInputs/Height

# Inventory
@onready var inventory_display: Control = $ControlLayer/InventoryDisplay
@onready var player_inventory_display: InventoryPanel = $ControlLayer/InventoryDisplay/VBoxContainer/PlayerInventory
@onready var player_inventory_separator: HSeparator = $ControlLayer/InventoryDisplay/VBoxContainer/HSeparator
@onready var player_equipment_display: InventoryPanel = $ControlLayer/InventoryDisplay/VBoxContainer/EquipSlots
@onready var player_crafting_panel: CraftingPanel = $ControlLayer/InventoryDisplay/VBoxContainer/CraftingPanel

@onready var floating_slot_display: FloatingInventorySlot = $ControlLayer/FloatingSlot

# Other
@onready var pause_menu: Control = $ControlLayer/PauseMenu
@onready var loading_panel: Control = $ControlLayer/LoadingPanel

# Player
@export var player_scene: PackedScene
@export var player_texture: Texture2D

# Internal variables
var current_state: GameState = GameState.MAIN_MENU
var local_player_instance: Player


# Called when the node enters the scene tree for the first time.
func _ready():
	map.generate_map(40, 24, -20, -12)
	
	map.seed_updated.connect(pause_menu._on_seed_updated)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if current_state == GameState.IN_GAME or current_state == GameState.PAUSE_MENU:
		if Input.is_action_just_pressed("ui_cancel"):
			toggle_pause_menu()
	if current_state == GameState.IN_GAME or current_state == GameState.INVENTORY_MENU:
		if Input.is_action_just_pressed("show_inventory"):
			toggle_inventory_menu()


func start_new_game():
	current_state = GameState.READY_FOR_NEW
	
	new_game_menu.hide()
	loading_panel.show()
	
	# dumb way to get ui to refresh before beginning generation
	await get_tree().create_timer(0.1).timeout
	
	var width = map_width_input.value
	var height = map_height_input.value
	
	map.clear_map()
	map.update_seed(int(map_seed_input.value))
	map.generate_map(width, height, -roundi(width / 2), -roundi(height / 2))


func spawn_player():
	if current_state != GameState.READY_FOR_NEW:
		return
	
	loading_panel.hide()
	inventory_display.show()
	
	local_player_instance = player_scene.instantiate() as Player
	map.add_child(local_player_instance)
	local_player_instance.change_sprite(player_texture)
	
	local_player_instance.map = map
	local_player_instance.moved_tiles.connect(map._on_player_moved_tiles)
	
	player_camera.camera_target = local_player_instance
	
	player_inventory_display.display_inventory(local_player_instance.inventory, local_player_instance.equipment_size)
	player_equipment_display.display_inventory(local_player_instance.inventory, 0, local_player_instance.equipment_size)
	player_inventory_display.inventory_slot_clicked.connect(local_player_instance.slot_clicked)
	player_equipment_display.inventory_slot_clicked.connect(local_player_instance.slot_clicked)
	
	floating_slot_display.set_display(local_player_instance.floating_slot)
	floating_slot_display.slot_dropped.connect(local_player_instance.drop_from_slot)
	local_player_instance.floating_slot.slot_updated.connect(floating_slot_display.set_floating_display)
	
	player_crafting_panel.display_recipe_list(local_player_instance.known_recipes, local_player_instance.inventory)
	player_crafting_panel.recipe_craft_attempted.connect(local_player_instance.craft_recipe)
	local_player_instance.recipe_list_updated.connect(player_crafting_panel.display_recipe_list)
	
	current_state = GameState.IN_GAME


func return_to_main_menu():
	pause_menu.hide()
	inventory_display.hide()
	map.clear_map()
	player_camera.zoom = Vector2(4, 4)
	player_camera.offset = Vector2(0, 0)
	
	current_state = GameState.MAIN_MENU
	
	map.update_seed()
	map.generate_map(72, 36, -36, -18)
	
	new_game_menu.show()


func exit_game():
	get_tree().quit()


func get_local_player() -> Player:
	return local_player_instance


func toggle_inventory_menu():
	if current_state == GameState.IN_GAME:
		current_state = GameState.INVENTORY_MENU
		player_inventory_display.visible = true
		player_inventory_separator.visible = true
		player_crafting_panel.visible = true
		
		local_player_instance.in_menu = true
	else:
		current_state = GameState.IN_GAME
		player_inventory_display.visible = false
		player_inventory_separator.visible = false
		player_crafting_panel.visible = false 
		
		local_player_instance.in_menu = false


func toggle_pause_menu():
	if current_state == GameState.PAUSE_MENU:
		current_state = GameState.IN_GAME
		pause_menu.hide()
		local_player_instance.in_menu = false
	else:
		current_state = GameState.PAUSE_MENU
		pause_menu.show()
		local_player_instance.in_menu = true


func _on_character_texture_selected(texture: Texture2D):
	player_texture = texture
