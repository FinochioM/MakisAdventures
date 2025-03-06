extends Node2D

@onready var tile_map = $"../TileMap"

var astar_grid: AStarGrid2D
var current_id_path: Array[Vector2i]
var target_position: Vector2
var is_moving: bool

var movement_enabled: bool = false
var highlight_cells: Array[Vector2i] = []
var max_move_distance: int = 5

func _ready() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = Vector2(8, 8)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	for x in tile_map.get_used_rect().size.x:
		for y in tile_map.get_used_rect().size.y:	
			var tile_position = Vector2i(
				x + tile_map.get_used_rect().position.x,
				y + tile_map.get_used_rect().position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			
			if tile_data == null or tile_data.get_custom_data("walkable") == false:
				astar_grid.set_point_solid(tile_position)
			
func _input(event):
	if event.is_action_pressed("left_click"):
		var mouse_pos = get_global_mouse_position()
		var map_pos = tile_map.local_to_map(mouse_pos)
		
		if is_moving:
			return
			
		if is_position_inside_player(mouse_pos):
			movement_enabled = true
			highlight_available_cells()
			return
			
		if movement_enabled and is_valid_move_position(map_pos):
			var player_map_pos = tile_map.local_to_map(global_position)
			current_id_path = astar_grid.get_id_path(player_map_pos, map_pos).slice(1)
			
			movement_enabled = false
			clear_highlights()
		else:
			movement_enabled = false
			clear_highlights()
	
func _physics_process(delta: float):
	if current_id_path.is_empty():
		return  
		
	if is_moving == false:
		target_position = tile_map.map_to_local(current_id_path.front())
		is_moving = true
	
	global_position = global_position.move_toward(target_position, 1)
	
	if global_position == target_position:
		current_id_path.pop_front()
		
		if current_id_path.is_empty() == false:
			target_position = tile_map.map_to_local(current_id_path.front())
		else:
			is_moving = false

func is_position_inside_player(pos: Vector2) -> bool:
	return global_position.distance_to(pos) < 4
	
func is_valid_move_position(map_pos: Vector2i) -> bool:
	return map_pos in highlight_cells

func highlight_available_cells():
	clear_highlights()
	
	var player_map_pos = tile_map.local_to_map(global_position)
	
	for x in range(player_map_pos.x - max_move_distance, player_map_pos.x + max_move_distance + 1):
		for y in range(player_map_pos.y - max_move_distance, player_map_pos.y + max_move_distance + 1):
			var check_pos = Vector2i(x, y)
			
			if check_pos == player_map_pos:
				continue
				
			var path = astar_grid.get_id_path(player_map_pos, check_pos)
			
			if not path.is_empty() and path.size() - 1 <= max_move_distance:
				highlight_cells.append(check_pos)
				
				tile_map.set_cell(1, check_pos, 0, Vector2i(0, 0))
				
func clear_highlights():
	tile_map.clear_layer(1)
	highlight_cells.clear()
