/// @description Initialising.
/// @author (с) 2021 Kirill Zhosul (@kirillzhosul)

#region Structs.

#region Layer.

function sEditorLayer(name) constructor{
	/// @description Layer struct.
	/// @param {string} name Name of the layer.
	
	self.name = name;
	self.is_visible = true;
	
	self.surface = surface_create(controller.editor_width, controller.editor_height);
	self.buffer = buffer_create(1, buffer_grow, 1);
	
	self.create_surface = function (){
		/// @description Creates surface.
		self.surface = surface_create(controller.editor_width, controller.editor_height);
	}
	
	self.show = function (){
		/// @description Shows (draws) layer.
		if (not self.is_visible) return;
		
		if (not surface_exists(self.surface)){
			self.create_surface();
			buffer_set_surface(self.buffer, self.surface, 0);
			
			controller.editor_show_error(":Layer: Surface not found! Loaded from the buffered data!");
		}else{
			buffer_get_surface(self.buffer, self.surface, 0);
		}

		draw_surface_ext(self.surface, 
						 controller.editor_view_x, controller.editor_view_y, 
						 controller.editor_zoom, controller.editor_zoom, 
						 0, EDITOR_LAYER_DEFAULT_COLOR, 1);
	}
	
	self.reset = function(surface){
		/// @description Resets layer by new surface with clearing old trash.
		/// @param {surface} surface New surface to set.
		self.free();
		self.surface = surface;
		
		self.buffer = buffer_create(1, buffer_grow, 1);
		buffer_get_surface(self.buffer, self.surface, 0);
	}
	
	self.free = function(){
		/// @description Frees layer.
		surface_free(self.surface);
		buffer_delete(self.buffer);
	}
}

#endregion

#region Undo-Stack command.

function sEditorStackCommand(layer_index, layer_surface) constructor{
	/// @description Undo-Stack command struct.
	/// @param {real} layer_index Index of the layer.
	/// @param {surface} layer_surface Surface of the layer.
	
	self.layer_index = layer_index;
	self.layer_surface = layer_surface;
	
	self.free = function(){
		/// @description Frees memory used by stack command (by freeing it surface).
		surface_free(self.layer_surface);
	}
}

#endregion

#region Vector 2D (Point).

#macro POINT_NULL new sPoint(0, 0)
function sPoint(x=0, y=0) constructor{
	/// @description Vector2 implementation as 2D point.
	/// @param {real} x X position.
	/// @param {real} y Y position.
	self.x = x;
	self.y = y;
}

#endregion

#endregion

#region Settings.

#macro EDITOR_EXPLORER_PROJECT_FILTER "Images (PNG)|*.png"

#macro EDITOR_DEFAULT_SELECTED_TOOL eEDITOR_TOOL.PENCIL

#macro EDITOR_LAYER_DEFAULT_COLOR c_white
#macro EDITOR_BACKGROUND_COLOR $333333
#macro EDITOR_DRAW_COLOR c_red

#macro EDITOR_WIDTH floor(room_width / 2);
#macro EDITOR_HEIGHT floor(room_height / 2);

#macro EDITOR_ZOOM_STEP 0.25
#macro EDITOR_ZOOM_MIN 0.25
#macro EDITOR_ZOOM_MAX 5

// Releated to non-rectangular tools.
#macro EDITOR_DRAW_CURVE 0.1
#macro EDITOR_DRAW_THRESHOLD 2
#macro EDITOR_DRAW_RADIUS 8

#endregion

#region Editor tools settings.

enum eEDITOR_TOOL{
	// Default.
	PENCIL, ERASER,
	
	// Rectangular.
	RECTANGLE, ELLIPSE
}

EDITOR_TOOLS_DRAW_FUNCTIONS = ds_map_create();
EDITOR_TOOLS_RECTANGULAR = ds_map_create();

// Pencil.
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.PENCIL] = draw_rectangle;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.PENCIL]    = false;

// Eraser.
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.ERASER] = draw_rectangle;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.ERASER]    = false;

// Rectangle.
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.RECTANGLE] = draw_rectangle;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.RECTANGLE]    = true;

// Ellipse.
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.ELLIPSE] = draw_ellipse;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.ELLIPSE]    = true;

#endregion

#region Functions.

#region Layers.

function editor_layer_new(layer_name){
	/// @description Creates new layer in editor.
	/// @param {string} layer_name Name for layer.
	/// @returns {real} Layer index.
	array_push(editor_layers, new sEditorLayer(layer_name));
	
	// TODO (#5).
	// Remove this.
	editor_command_stack_clear();
	
	// New layer index.
	return array_length(editor_layers) - 1;
}

function editor_layer_get(layer_index){
	/// @description Returns editor layer with given index.
	/// @returns {array} Layer.
	return array_get(editor_layers, layer_index);
}

function editor_layer_clear(layer_index, color){
	/// @description Clears layer with given color.
	/// @param {real} layer_index Layer index to clear.
	/// @param {color} color With what color clear.
	
	surface_set_target(editor_layer_get(layer_index).surface);
	draw_clear(color);
	surface_reset_target();
	
	// TODO (#5).
	// Remove this.
	editor_command_stack_clear();
}

function editor_layer_switch_visibility(layer_index){
	/// @description Switch layer visibility.
	/// @param {real} layer_index Layer index to switch visibility..
	if (is_undefined(layer_index)) return;
	
	var current_layer = editor_layer_get(layer_index);
	current_layer.is_visible = not current_layer.is_visible;
}

function editor_layers_free(){
	/// @description Frees all layers.
	
	while(array_length(editor_layers) > 0){
		array_pop(editor_layers).free();
	}
	
	// TODO (#5).
	// Remove this.
	editor_command_stack_clear();
}

function editor_layer_delete(layer_index){
	/// @description Deletes layer.
	/// @param {real} layer_index Index of the layer to delete.
	if (is_undefined(editor_selected_layer)) return;
	
	// Updating selected layer order.
	if (editor_selected_layer == layer_index){
		editor_selected_layer = layer_index - 1;
		if (editor_selected_layer == -1){
			if (array_length(editor_layers) - 1 != 0){
				// If there is any layer.
				editor_selected_layer = 0;
			}else{
				// If last layer.
				editor_selected_layer = undefined;
			}
		}
	}
	
	array_delete(editor_layers, layer_index, 1);
	
	// TODO (#5).
	// Remove this.
	editor_command_stack_clear();
}

function editor_layer_move_up(layer_index){
	/// @description Moves layer up.
	/// @param {real} layer_index Index to move.
	if (is_undefined(layer_index)) return;
	if (layer_index == 0) return;
	
	// Found selected layer.
	if (editor_selected_layer == layer_index){
		editor_selected_layer = layer_index - 1;
	}

	editor_layer_move(layer_index, layer_index - 1);
}

function editor_layer_move_down(layer_index){
	/// @description Moves layer up.
	/// @param {real} layer_index Index to move.
	if (is_undefined(layer_index)) return;
	if (layer_index == array_length(editor_layers) - 1) return;
	
	// Found selected layer.
	if (editor_selected_layer == layer_index){
		editor_selected_layer = layer_index + 1;
	}
	
	editor_layer_move(layer_index, layer_index + 1);
}

function editor_layer_move(index_one, index_two){
	/// @description Swaps layers.
	/// @param {real} index_one First index to swap.
	/// @param {real} indeX_two Second index to swap.

	var swap_buffer = editor_layers[@ index_one];
	editor_layers[@ index_one] = editor_layers[@ index_two];
	editor_layers[@ index_two] = swap_buffer;
	
	// TODO (#5).
	// Remove this.
	editor_command_stack_clear();
}

#endregion

#region Drawing.

function editor_draw(){
	/// @description Draws editor.
	draw_clear(EDITOR_BACKGROUND_COLOR);
	editor_draw_layers();
	editor_draw_rectangular_tool_preview();
	editor_draw_interface();
}

function editor_draw_rectangular_tool_preview(){
	/// @description Draws preview for the rectangular tool.
	if (not editor_rectangular_shape) return;
	if (not editor_selected_tool_is_rectangular()) return;

	var draw_function = EDITOR_TOOLS_DRAW_FUNCTIONS[? editor_selected_tool];
	
	var x1 = clamp(editor_rectangular_shape_start.x, editor_view_x, editor_view_x + editor_width * editor_zoom);
	var y1 = clamp(editor_rectangular_shape_start.y, editor_view_y, editor_view_y + editor_height * editor_zoom);
	var x2 = clamp(editor_rectangular_shape_end.x, editor_view_x - 1, editor_view_x + editor_width * editor_zoom - 1);
	var y2 = clamp(editor_rectangular_shape_end.y, editor_view_y - 1, editor_view_y + editor_height * editor_zoom - 1);
	
	draw_set_color(EDITOR_DRAW_COLOR);
	draw_function(x1, y1, x2, y2, false);
}

function editor_draw_layers(){
	/// @description Draws editor layers.

	for (var current_layer_index = array_length(editor_layers) - 1;current_layer_index >= 0; current_layer_index--){
		editor_layer_get(current_layer_index).show();
	}
}

function editor_draw_interface(){
	/// @description Draws editor interface.
	var offset = 3;
	var draw_x = 0;
	var draw_y = 3;
	
	draw_set_color(c_white);
	draw_set_font(ui_interface_font);
	
	// Layer buttons.
	
	// New layer.
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_new)) editor_selected_layer = editor_layer_new("Layer " + string(array_length(editor_layers)));
	
	// Delete layer.
	draw_x += sprite_get_width(ui_button_layer_new) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_delete)) editor_layer_delete(editor_selected_layer);
	
	// Layer up.
	draw_x += sprite_get_width(ui_button_layer_delete) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_up)) editor_layer_move_up(editor_selected_layer);
	
	// Layer down.
	draw_x += sprite_get_width(ui_button_layer_up) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_down)) editor_layer_move_down(editor_selected_layer);

	// Layer visibility.
	draw_x += sprite_get_width(ui_button_layer_down) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_visibility)) editor_layer_switch_visibility(editor_selected_layer);
	
	// Draw offset, y.
	offset = 3;
	draw_y = room_height - sprite_get_width(ui_button_layer_tool_pencil) - 3;
	
	// Error message.
	if (editor_last_error_message != ""){
		var text = "There is error during processing last operation! ";
		draw_set_color(c_red);
		draw_text(room_width - string_width(editor_last_error_message), room_height - string_height(editor_last_error_message), editor_last_error_message);
		draw_set_color(c_white)
		draw_text(room_width - string_width(text), room_height - string_height(editor_last_error_message) - string_height(text), text);
	}
	
	// Tools buttons.
	
	// Pencil tool.
	draw_x = 0;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_tool_pencil)) editor_selected_tool = eEDITOR_TOOL.PENCIL;
	
	// Eraser tool.
	draw_x = sprite_get_width(ui_button_layer_tool_pencil) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_tool_eraser)) editor_selected_tool = eEDITOR_TOOL.ERASER;

	// Rectangle tool.
	draw_x += sprite_get_width(ui_button_layer_tool_eraser) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_tool_rectangle)) editor_selected_tool = eEDITOR_TOOL.RECTANGLE;
	
	// Ellipse tool.
	draw_x += sprite_get_width(ui_button_layer_tool_rectangle) + offset;
	if (draw_button_sprite(draw_x, draw_y, ui_button_layer_tool_ellipse)) editor_selected_tool = eEDITOR_TOOL.ELLIPSE;	
	
	// Drawing layers text.
	draw_text(offset, sprite_get_height(ui_button_layer_new) + offset, "Layers: ");
	
	// Layers position.
	draw_y = (sprite_get_height(ui_button_layer_new) + offset + string_height("Layers"));
	offset = 20;
	
	// No layers text.
	var layers_count = array_length(editor_layers);
	if (layers_count == 0){
		draw_text(floor(offset * .5), draw_y, "...No layers!");
	}else{
		for (var current_layer_index = 0;current_layer_index < layers_count; current_layer_index++){
			var current_layer = editor_layer_get(current_layer_index);
		
			// TODO: Seems like unreadable/unexpected.
			if (current_layer_index == editor_selected_layer){
				draw_set_color(current_layer.is_visible ? c_yellow : c_olive);
			}else{
				draw_set_color(current_layer.is_visible ? c_white : c_gray);
			}
		
			var layer_name = "\"" + current_layer.name + "\"";
			if (draw_button_text(floor(offset * .5), draw_y + offset * current_layer_index, layer_name)){
				editor_selected_layer = current_layer_index;
			}
		}
	}
}

function draw_button_sprite(x, y, sprite){
	/// @description Draws sprite and returns is pressed or not.
	/// @param {real} x X position to draw on.
	/// @param {real} y Y position to draw on.
	/// @param {sprite} sprite Sprite to draw.
	/// @returns {bool} Is clicked or not.
	
	draw_sprite(sprite, image_index, x, y);
	
	if (point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_get_width(sprite), y + sprite_get_height(sprite))){
		return mouse_check_button_pressed(mb_left);
	}
	
	return false;
}

function draw_button_text(x, y, text){
	/// @description Draws text and returns is pressed or not.
	/// @param {real} x X position to draw on.
	/// @param {real} y Y position to draw on.
	/// @param {string} text String to draw.
	/// @returns {bool} Is clicked or not.
	
	draw_text(x, y, text);
	
	if (point_in_rectangle(mouse_x, mouse_y, x, y, x + string_width(text), y + string_height(text))){
		return mouse_check_button_pressed(mb_left);
	}
	
	return false;
}

#endregion

#region Command.

function editor_command_stack_clear(){
	/// @description Clears command stack.
	
	while(array_length(editor_command_stack) > 0){
		array_pop(editor_command_stack).free();
	}
}

function editor_command_undo(){
	/// @description Undo command.
	if (array_length(editor_command_stack) == 0) return;
	
	// TODO (#5).
	// Remove this.
	if (mouse_check_button(mb_left)) return;
	
	var command = array_pop(editor_command_stack);
	var current_layer = editor_layers[command.layer_index];
	
	if (not surface_exists(command.layer_surface)){
		editor_show_error("Undo command was blocked as command stack surface not exists!");
		return;
	}
	
	current_layer.reset(command.layer_surface);
}

#endregion

#region Updating.

function editor_update(){
	/// @description Updates editor.
	editor_update_move();
	editor_update_mouse_draw();
	editor_update_hotkeys();
}

function editor_update_hotkeys(){
	/// @description Updates hotkeys.
	if (not keyboard_check(vk_control)) return; // Keybind.
	
	// Undo command.
	if (keyboard_check_pressed(ord("Z"))) return editor_command_undo();
	
	// Open hotkey.
	if (keyboard_check_pressed(ord("O"))) return editor_project_open();
	
	// New hotkey.
	if (keyboard_check_pressed(ord("N"))) return editor_project_new();
	
	// Save hotkey.
	if (keyboard_check_pressed(ord("S"))) return editor_project_save();
}

#region Update Draw.

function __editor_update_draw_function(x1, y1, x2, y2){
	/// @description Draw function for the update draw.
	/// @param {real} x1 Left x.
	/// @param {real} y1 Top y.
	/// @param {real} x2 Right x.
	/// @param {real} y2 Bottom x.
	
	var difference = abs(x1 - x2) + abs(y1 - y2);						
	if (difference >= EDITOR_DRAW_RADIUS / EDITOR_DRAW_THRESHOLD){
		__editor_update_draw_function(lerp(x1, x2, EDITOR_DRAW_CURVE), lerp(y1, y2, EDITOR_DRAW_CURVE), x2, y2);
	}
									
	draw_circle(x1, y1, EDITOR_DRAW_RADIUS, false);
}

function editor_update_draw_begin(){
	/// @description Updates draw begin (Mouse pressed).
	editor_clear_mouse_queue();
	
	var draw_x = editor_project_x(mouse_x, false);
	var draw_y = editor_project_y(mouse_y, false);

	if editor_position_is_valid(draw_x, draw_y){
		var command_surface = surface_create(controller.editor_width, controller.editor_height);
		surface_copy(command_surface, 0, 0, editor_layer_get(editor_selected_layer).surface);
	
		editor_command_stack_temporary = new sEditorStackCommand(editor_selected_layer, command_surface);
	}
		
	var window_mouse_x = window_mouse_get_x();
	var window_mouse_y = window_mouse_get_y();
	ds_list_add(editor_mouse_queue_x, window_mouse_x, window_mouse_x);
	ds_list_add(editor_mouse_queue_y, window_mouse_y, window_mouse_y);
	
	editor_project_is_saved = false;
	editor_project_update_window_title();
}

function editor_update_draw_end(){
	/// @description Updates draw end (Mouse released).
		
	if (not is_undefined(editor_command_stack_temporary)){
		array_push(editor_command_stack, editor_command_stack_temporary);
		editor_command_stack_temporary = undefined;
	}
	
	if (editor_selected_tool_is_rectangular()){
		var draw_function = EDITOR_TOOLS_DRAW_FUNCTIONS[? editor_selected_tool];
		
		draw_set_color(EDITOR_DRAW_COLOR);
		surface_set_target(editor_layer_get(editor_selected_layer).surface);
		draw_function(editor_project_x(editor_rectangular_shape_start.x, false), 
					  editor_project_y(editor_rectangular_shape_start.y, false), 
					  editor_project_x(editor_rectangular_shape_end.x, false), 
					  editor_project_y(editor_rectangular_shape_end.y, false), 
				      false);
		surface_reset_target();
		
		editor_rectangular_shape = false;
		editor_rectangular_shape_start = POINT_NULL;
		editor_rectangular_shape_end = POINT_NULL;
	}
}

function editor_update_draw(){
	/// @description Updates draw (Mouse hold).
	
	if (editor_selected_tool_is_rectangular()){
		__editor_update_draw_rectangular();
	}else{
		__editor_update_draw();
	}
}

function __editor_update_draw_rectangular(){
	/// @description Updates draw for rectangular.
	
	if (mouse_check_button_pressed(mb_left)){
		// If hold begin.
		editor_rectangular_shape = true;
		editor_rectangular_shape_start = new sPoint(mouse_x, mouse_y);
		editor_rectangular_shape_end = new sPoint(mouse_x, mouse_y);
	}

	editor_rectangular_shape_end = new sPoint(mouse_x, mouse_y);
}

function __editor_update_draw(){
	/// @description Updates draw.
	
	var queue_points_count = window_mouse_queue_get(editor_mouse_queue_x, editor_mouse_queue_y);
	if (mouse_check_button_pressed(mb_left)) queue_points_count += 2;
			
	if (queue_points_count != 0){
		draw_set_color(EDITOR_DRAW_COLOR);
		surface_set_target(editor_layer_get(editor_selected_layer).surface);
		if (editor_selected_tool == eEDITOR_TOOL.ERASER) gpu_set_blendmode(bm_subtract);
		
		for (var queue_point_index = queue_points_count - 1; queue_point_index >= 0; queue_point_index --){
			if (queue_point_index - 1 < 0) continue;
					
			var draw_x = editor_project_x(editor_mouse_queue_x[| queue_point_index], true);
			var draw_y = editor_project_y(editor_mouse_queue_y[| queue_point_index], true);
								
			var draw_x_previous = editor_project_x(editor_mouse_queue_x[| queue_point_index - 1], true);
			var draw_y_previous = editor_project_y(editor_mouse_queue_y[| queue_point_index - 1], true);
								
			switch(editor_selected_tool){
				case eEDITOR_TOOL.ERASER: case eEDITOR_TOOL.PENCIL:
					__editor_update_draw_function(draw_x_previous, draw_y_previous, draw_x, draw_y);
				break;
			}
		}
		
		if (editor_selected_tool == eEDITOR_TOOL.ERASER) gpu_set_blendmode(bm_normal);
		surface_reset_target();
		editor_clear_mouse_queue();
	}
}

#endregion

function editor_update_mouse_draw(){
	/// @description Updates editor draw.
	if (is_undefined(editor_selected_layer)){
		editor_clear_mouse_queue(); // Clearing to await new layer, and not have trash later.
		return;
	}
	
	// Draw begin.
	if (mouse_check_button_pressed(mb_left)) editor_update_draw_begin();

	// Draw.
	if (mouse_check_button(mb_left)) editor_update_draw();
	
	// Draw end.
	if (mouse_check_button_released(mb_left)) editor_update_draw_end();
}

function editor_update_move(){
	/// @description Updates editor move.
	
	if (mouse_check_button_pressed(mb_right)){
		editor_move_x = mouse_x;
		editor_move_y = mouse_y;
	}else{
		if (mouse_check_button(mb_right)){
			editor_view_x += (mouse_x - editor_move_x);
			editor_view_y += (mouse_y - editor_move_y);

			editor_move_x = mouse_x;
			editor_move_y = mouse_y;
		}
	}
	
	if (mouse_wheel_up()){
		// Zoom in.
		editor_zoom = clamp(editor_zoom + EDITOR_ZOOM_STEP, EDITOR_ZOOM_MIN, EDITOR_ZOOM_MAX);
	}else{
		if (mouse_wheel_down()){
			// Zoom out.
			editor_zoom = clamp(editor_zoom - EDITOR_ZOOM_STEP, EDITOR_ZOOM_MIN, EDITOR_ZOOM_MAX);
		}
	}
}

#endregion

#region Projects.

function editor_project_new(){
	/// @description Opens new project.
	editor_project_filename = undefined;

	editor_width = EDITOR_WIDTH;
	editor_height = EDITOR_HEIGHT;
	
	editor_layers_free();
	editor_command_stack_clear();
	
	editor_selected_layer = editor_layer_new("Base");
	editor_layer_clear(editor_selected_layer, EDITOR_LAYER_DEFAULT_COLOR);
	
	editor_project_is_saved = false;
	editor_project_update_window_title();
}

function editor_project_open(){
	/// @description Opens project from file.
	var selected_filename = get_open_filename(EDITOR_EXPLORER_PROJECT_FILTER, "");
	if (selected_filename == "") return;
	editor_project_filename = selected_filename;

	if (not file_exists(selected_filename)){
		editor_show_error("Failed to open project! File not exists!");
		return;
	}

	var loaded_sprite = sprite_add(selected_filename, 1, false, false, 0, 0);
	
	editor_width = sprite_get_width(loaded_sprite);
	editor_height = sprite_get_height(loaded_sprite);
	
	editor_command_stack_clear();
	editor_layers_free();
	var file_layer = editor_layer_new("File");
	editor_selected_layer = file_layer;
	
	surface_set_target(editor_layer_get(file_layer).surface);
	draw_sprite(loaded_sprite, 0, 0, 0);
	surface_reset_target();
	sprite_delete(loaded_sprite);
	
	editor_project_is_saved = true;
	editor_project_update_window_title();
}

function editor_project_update_window_title(){
	/// @description Updates window title.
	var project = "(No project)";
	var save_state = editor_project_is_saved ? "" : "*UNSAVED* ";
	
	if (not is_undefined(editor_project_filename)){
		project = "(Project " + editor_project_filename + ")";
	}
	
	window_set_caption("Paint Editor " + save_state + project);
}

function editor_project_save(){
	/// @description Saves project.
	
	if (is_undefined(editor_project_filename)){
		editor_project_filename = get_save_filename(EDITOR_EXPLORER_PROJECT_FILTER, "");
		if (editor_project_filename == "") return;
		
		editor_project_update_window_title();
	}
	
	var result_surface = surface_create(editor_width, editor_height);
	surface_set_target(result_surface);
	
	for (var current_layer_index = array_length(editor_layers) - 1; current_layer_index >= 0; current_layer_index--){
		var current_layer = editor_layer_get(current_layer_index);
		
		if (not surface_exists(current_layer.surface)){
			current_layer.create_surface();
			buffer_set_surface(current_layer.buffer, current_layer.surface, 0);
			
			editor_show_error("Not found one of the layers while saving!");
		}
		
		draw_surface(current_layer.surface, 0, 0);
	}
	
	surface_reset_target();
	surface_save(result_surface, editor_project_filename);
	surface_free(result_surface);
	
	editor_project_is_saved = true;
	editor_project_update_window_title();
}

function editor_show_error(error_message){
	/// @description Show error.
	/// @param {string} error_message Message to show.
	editor_last_error_message = error_message;
}

#endregion

#region Other.

function editor_project_x(window_x, window_apply_scale){
	/// @description Projects given x to editor surface x. 
	/// @param {real} window_x X from mouse_x or queue.
	/// @param {real} window_apply_scale If true, applies window scale for the point.
	/// @returns {real} Projected x.
	if (window_apply_scale) window_x *= (room_width / window_get_width());
	return (window_x - editor_view_x) / editor_zoom;
}

function editor_project_y(window_y, window_apply_scale){
	/// @description Projects given y to editor surface y. 
	/// @param {real} window_y Y from mouse_y or queue.
	/// @param {real} window_apply_scale If true, applies window scale for the point.
	/// @returns {real} Projected y.
	if (window_apply_scale) window_y *= (room_height / window_get_height());
	return (window_y - editor_view_y) / editor_zoom;
}

function editor_position_is_valid(draw_x, draw_y){
	/// @description Returns is given (X, Y) is valid (in editor position) or not.
	/// @returns {bool} Is valid or not.
	return (draw_x > 0 and draw_x < editor_width) and (draw_y > 0 and draw_y < editor_height);
}

function editor_clear_mouse_queue(){
	/// @description Clears mouse queue.
	ds_list_clear(editor_mouse_queue_x);
	ds_list_clear(editor_mouse_queue_y);
	window_mouse_queue_clear();
}

function editor_close_event(){
	/// @description Handles close event, asking user that he wants save file or not.
	if (editor_project_is_saved) return;
	
	var dialog = show_question("Project is not saved, do you want to save it right now?");
	if (dialog){
		editor_project_save();
	};
	
	// Game stopped and closed here.
}

function editor_selected_tool_is_rectangular(){
	/// @description Returns is selected tool is rectangular tool or not.
	/// @returns {bool} Is rectangular or not.
	return EDITOR_TOOLS_RECTANGULAR[? editor_selected_tool];
}

#endregion

#endregion

#region Variables (Entry point).

// EDITOR_TOOLS_DRAW_FUNCTIONS;
// EDITOR_TOOLS_RECTANGULAR;
// [Declared above].

// Rectangular tools.
editor_rectangular_shape       = false;
editor_rectangular_shape_start = POINT_NULL;
editor_rectangular_shape_end   = POINT_NULL;

editor_width  = EDITOR_WIDTH;
editor_height = EDITOR_HEIGHT;

editor_layers = [];

// Undo system.
editor_command_stack           = [];
editor_command_stack_temporary = undefined;

editor_last_error_message = "";

editor_selected_layer = 0;
editor_selected_tool  = EDITOR_DEFAULT_SELECTED_TOOL;

editor_move_x = -1;
editor_move_y = -1;

editor_zoom = 1;

editor_view_x = editor_width / 2;
editor_view_y = editor_height / 2;

// Queue for mouse position grabbing (window_mouse_queue extension).
editor_mouse_queue_x = ds_list_create();
editor_mouse_queue_y = ds_list_create();
window_mouse_queue_init();

// Project initialising.
editor_project_filename = undefined;
editor_project_is_saved = false;
editor_project_new();
editor_project_update_window_title();

#endregion