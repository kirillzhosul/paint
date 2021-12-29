/// @description Initialising.
// @author Kirill Zhosul (@kirillzhosul)

#region Structs.

#region Layer.

function sEditorLayer(name) constructor{
	// Layer struct.
	
	// Layer name.
	self.name = name;
	
	// Layer surface.
	self.surface = surface_create(controller.editor_width, controller.editor_height);
	
	// Layer buffer.
	self.buffer = buffer_create(1, buffer_grow, 1);
	
	// Layer is visible.
	self.is_visible = true;
	
	self.create_surface = function (){
		// @description Creates surface.
		
		// Create.
		self.surface = surface_create(controller.editor_width, controller.editor_height);
	}
	
	self.show = function (){
		// @description Shows (draws) layer.
		
		// Retunring if not visible.
		if (not self.is_visible) return;
		
		if (not surface_exists(self.surface)){
			// If surface is not exists.
			
			// Loading surface.
			self.create_surface();
			buffer_set_surface(self.buffer, self.surface, 0);
		}else{
			// If all OK.
			
			// Buffering surface.
			buffer_get_surface(self.buffer, self.surface, 0);
		}

		// Drawing.
		draw_surface_ext(self.surface, controller.editor_view_x, controller.editor_view_y, controller.editor_zoom, controller.editor_zoom, 0, c_white, 1);
	}
	
	self.reset = function (surface){
		// @description Reset.
		
		// Destroy old data.
		self.free();
		
		// Set surface.
		self.surface = surface;
		
		// Create and set buffer.
		self.buffer = buffer_create(1, buffer_grow, 1);
		buffer_get_surface(self.buffer, self.surface, 0);
	}
	
	self.free = function(){
		// @description Frees layer.
		
		// Free layer.
		surface_free(self.surface);
		buffer_delete(self.buffer);
	}
}

#endregion

#region Stack command.

function sEditorStackCommand(layer_index, layer_surface) constructor{
	// Stack command struct.
	
	// Layer index.
	self.layer_index = layer_index;
	
	// Layer surface.
	self.layer_surface = layer_surface;
	
	self.free = function(){
		// @description Frees stack command.
		
		// Free surface.
		surface_free(self.layer_surface);
	}
}

#endregion

#region Vector.

function sPoint(x, y) constructor{
	// Point (Simply, Vector2, Vec2) struct.
	
	// Position.
	self.x = x;
	self.y = y;
}

// Null point.
#macro POINT_NULL new sPoint(0, 0)

#endregion

#endregion

#region Settings.

// Selected by start tool.
#macro EDITOR_DEFAULT_SELECTED_TOOL eEDITOR_TOOL.PENCIL

// Colors.
#macro EDITOR_LAYER_DEFAULT_COLOR c_white
#macro EDITOR_DRAW_COLOR c_red

// Editor size.
#macro EDITOR_WIDTH floor(room_width / 2);
#macro EDITOR_HEIGHT floor(room_height / 2);

// Zoom values.
#macro EDITOR_ZOOM_STEP 0.25
#macro EDITOR_ZOOM_MIN 0.25
#macro EDITOR_ZOOM_MAX 5

// Draw (non-rectangular) values.
#macro EDITOR_DRAW_CURVE 0.1
#macro EDITOR_DRAW_THRESHOLD 2
#macro EDITOR_DRAW_RADIUS 8

// Filter for the explorer.
#macro EDITOR_EXPLORER_PROJECT_FILTER "Images (PNG)|*.png"

// Editor tools.
enum eEDITOR_TOOL{
	PENCIL,
	ERASER,
	RECTANGLE,
	ELLIPSE
}

// Draw functions for the tools.
EDITOR_TOOLS_DRAW_FUNCTIONS = ds_map_create();
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.PENCIL]    = draw_rectangle;
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.ERASER]    = draw_rectangle;
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.RECTANGLE] = draw_rectangle;
EDITOR_TOOLS_DRAW_FUNCTIONS[? eEDITOR_TOOL.ELLIPSE]   = draw_ellipse;

// All rectangular tools.
EDITOR_TOOLS_RECTANGULAR = ds_map_create();
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.PENCIL]    = false;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.ERASER]    = false;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.RECTANGLE] = true;
EDITOR_TOOLS_RECTANGULAR[? eEDITOR_TOOL.ELLIPSE]   = true;

#endregion

#region Functions.

#region Layers.

function editor_layer_selected_get_surface(){
	// @description Returns surface for the current selected layer.
	// @returns {surface} Selected layer surface.
	
	// Returning.
	return editor_layer_get(editor_selected_layer).surface;
}

function editor_layer_new(layer_name){
	// @description Creates new layer in editor.
	// @param {string} layer_name Name for layer.
	// @returns {real} Layer index.
	
	// Adding layer in editor layers.
	array_push(editor_layers, new sEditorLayer(layer_name));
	
	// TODO.
	editor_command_stack_clear();
	
	// Returning layer index.
	return array_length(editor_layers) - 1;
}

function editor_layer_get(layer_index){
	// @description Returns editor layer with given index.
	// @returns {array} Layer.
	
	// Returning layer.
	return array_get(editor_layers, layer_index);
}

function editor_layer_clear(layer_index, color){
	// @description Clears layer with given color.
	// @param {real} layer_index Layer index to clear.
	// @param {color} color With what color clear.
	
	// Getting layer surface.
	surface_set_target(editor_layer_get(layer_index).surface);

	// Clearing.
	draw_clear(color);
	
	// Resetting current surface.
	surface_reset_target();
	
	// TODO.
	editor_command_stack_clear();
}

function editor_layer_select(layer_index){
	// @description Selects layer.
	// @param {real} layer_index Layer index to select.
	
	// Selecting.
	editor_selected_layer = layer_index;
}

function editor_layer_switch_visibility(layer_index){
	// @description Switch layer visibility.
	// @param {real} layer_index Layer index to switch visibility..
	
	// Not processing if invalid layer.
	if (is_undefined(layer_index)) return;
	
	// Getting layer.
	var current_layer = editor_layer_get(layer_index);
	
	// Switching visibility.
	current_layer.is_visible = not current_layer.is_visible;
}

function editor_layers_free(){
	// @description Frees all layers.
	
	for (var current_layer_index = 0;current_layer_index < array_length(editor_layers); current_layer_index++){
		// Iterate over all layers.
		
		// Free.
		editor_layer_get(current_layer_index).free();
	}
	
	// Clearing.
	editor_layers = [];
	
	// TODO.
	editor_command_stack_clear();
}

function editor_layer_delete(layer_index){
	// @description Deletes layer.
	
	// Do not process if invalid.
	if (is_undefined(editor_selected_layer)) return;
	
	if (editor_selected_layer == layer_index){
		// If deleting selected layer.
		
		// Selecting moved.
		editor_selected_layer = layer_index - 1;
		
		if (editor_selected_layer == -1){
			// If run out of bounds.
			
			if (array_length(editor_layers) - 1 != 0){
				// If there is any layer.
				
				// Select first layer.
				editor_selected_layer = 0;
			}else{
				// If last layer.
				
				// Set invalid layer.
				editor_selected_layer = undefined;
			}
		}
	}
	
	// Deleting layer.
	array_delete(editor_layers, layer_index, 1);
	
	// TODO.
	editor_command_stack_clear();
}

function editor_layer_move_up(layer_index){
	// @description Moves layer up.
	// @param {real} layer_index Index to move.
	
	// Not processing if invalid layer.
	if (is_undefined(layer_index)) return;
	
	// Returning if first already.
	if (layer_index == 0) return;
	
	if (editor_selected_layer == layer_index){
		// If moving selected layer.
		
		// Selecting new index.
		editor_selected_layer = layer_index - 1;
	}
	
	// Moving layer.
	editor_layer_move(layer_index, layer_index - 1);
}

function editor_layer_move_down(layer_index){
	// @description Moves layer up.
	// @param {real} layer_index Index to move.
	
	// Not processing if invalid layer.
	if (is_undefined(layer_index)) return;
	
	// Returning if first already.
	if (layer_index == array_length(editor_layers) - 1) return;
	
	if (editor_selected_layer == layer_index){
		// If moving selected layer.
		
		// Selecting new index.
		editor_selected_layer = layer_index + 1;
	}
	
	// Moving layer.
	editor_layer_move(layer_index, layer_index + 1);
}

function editor_layer_move(index_one, index_two){
	// @description Swaps layers.
	// @param {real} index_one First index to swap.
	// @param {real} indeX_two Second index to swap.

	// Swap buffer.
	var swap_buffer = editor_layers[@ index_one];
	
	// Swapping.
	editor_layers[@ index_one] = editor_layers[@ index_two];
	editor_layers[@ index_two] = swap_buffer;
	
	// TODO - Clear stack for now.
	editor_command_stack_clear();
}

#endregion

#region Drawing.

function editor_draw(){
	// @description Draws editor.
	
	// Drawing layers.
	editor_draw_layers();

	// Rectangular tool preview.
	editor_draw_rectangular_tool_preview();

	// Drawing interface.
	editor_draw_interface();
}

function editor_draw_rectangular_tool_preview(){
	// @description Draws preview for the rectangular tool.
	
	// Returning if not currently drawing any shape.
	if (not editor_rectangular_shape) return;
	
	// Returning if not rectangular tool.
	if (not editor_selected_tool_is_rectangular()) return;

	// Drawing color.
	draw_set_color(EDITOR_DRAW_COLOR);
			
	// Get position.
	var x1 = clamp(editor_rectangular_shape_start.x, editor_view_x, editor_view_x + editor_width * editor_zoom);
	var y1 = clamp(editor_rectangular_shape_start.y, editor_view_y, editor_view_y + editor_height * editor_zoom);
	var x2 = clamp(editor_rectangular_shape_end.x, editor_view_x - 1, editor_view_x + editor_width * editor_zoom - 1);
	var y2 = clamp(editor_rectangular_shape_end.y, editor_view_y - 1, editor_view_y + editor_height * editor_zoom - 1);
	
	// Draw shape function.
	var draw_function = EDITOR_TOOLS_DRAW_FUNCTIONS[? editor_selected_tool];

	// Call draw.
	draw_function(x1, y1, x2, y2, false);
}

function editor_draw_layers(){
	// @description Draws editor layers.

	for (var current_layer_index = array_length(editor_layers) - 1;current_layer_index >= 0; current_layer_index--){
		// Iterating over all layers.
	
		// Showing layer.
		editor_layer_get(current_layer_index).show();
	}
}

function editor_draw_interface(){
	// @description Draws editor interface.
	
	// Drawing color, font.
	draw_set_color(c_white);
	draw_set_font(ui_interface_font);

	// Draw offset, position.
	var offset = 3;
	var draw_x = 0;
	var draw_y = 3;
	
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
	
	// Command Stack.
	
	// Drawing counter text.
	var text = "Undo Stack:\n" + string(array_length(editor_command_stack));
	draw_text(room_width - string_width(text), 0, text);
	
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
	if (array_length(editor_layers) == 0) draw_text(floor(offset * .5), draw_y, "...No layers!");
	
	for (var current_layer_index = 0;current_layer_index < array_length(editor_layers); current_layer_index++){
		// Iterating over all layers.
		
		// Getting layer.
		var current_layer = editor_layer_get(current_layer_index);
		
		if (current_layer_index == editor_selected_layer){
			// If selected layer.
			
			// Color.
			draw_set_color(current_layer.is_visible ? c_yellow : c_olive);
		}else{
			// If not selected.
			
			// Color.
			draw_set_color(current_layer.is_visible ? c_white : c_gray);
		}
		
		// Getting layer name.
		var layer_name = "\"" + current_layer.name + "\"";
		
		// Drawing layer button with select feature.
		if (draw_button_text(floor(offset * .5), draw_y + offset * current_layer_index, layer_name)) editor_layer_select(current_layer_index);
	}
}

function draw_button_sprite(x, y, sprite){
	// @description Draws sprite and returns is pressed or not.
	// @param {real} x X position to draw on.
	// @param {real} y Y position to draw on.
	// @param {sprite} sprite Sprite to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_sprite(sprite, image_index, x, y);
	
	// Returning.
	if (point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_get_width(sprite), y + sprite_get_height(sprite))){
		// If hovered.
		
		// Returning is clicked.
		return mouse_check_button_pressed(mb_left);
	}
	
	// Not clicked.
	return false;
}

function draw_button_text(x, y, text){
	// @description Draws text and returns is pressed or not.
	// @param {real} x X position to draw on.
	// @param {real} y Y position to draw on.
	// @param {string} text String to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_text(x, y, text);
	
	// Returning.
	if (point_in_rectangle(mouse_x, mouse_y, x, y, x + string_width(text), y + string_height(text))){
		// If hovered.
		
		// Returning is clicked.
		return mouse_check_button_pressed(mb_left);
	}
	
	// Not clicked.
	return false;
}

#endregion

#region Command.

function editor_command_stack_clear(){
	// @description Clears command stack.
	
	for (var command_index = 0; command_index < array_length(editor_command_stack); command_index++){
		// For every command.
		
		// Free.
		editor_command_stack[command_index].free();
		editor_command_stack[command_index] = undefined;
	}
	
	// Reset stack.
	editor_command_stack = [];
}

function editor_command_undo(){
	// @description Undo command.
	
	// Return if no commands.
	if (array_length(editor_command_stack) == 0) return;
	
	// Disallow to undo when holding mouse.
	if (mouse_check_button(mb_left)) return;
	
	// Get command.
	var command = array_pop(editor_command_stack);
	
	// Get layer.
	var current_layer = editor_layers[command.layer_index];
	
	// Reset layer.
	current_layer.reset(command.layer_surface);
}

#endregion

#region Updating.

function __editor_update_draw_function(x1, y1, x2, y2){
	// @description Draw function for the update draw.

	// Get difference.
	var difference = abs(x1 - x2) + abs(y1 - y2);
									
	if (difference >= EDITOR_DRAW_RADIUS / EDITOR_DRAW_THRESHOLD){
		// If difference too much.
										
		// Recursion.
		__editor_update_draw_function(lerp(x1, x2, EDITOR_DRAW_CURVE), lerp(y1, y2, EDITOR_DRAW_CURVE), x2, y2);
	}
									
	// Main element.
	draw_circle(x1, y1, EDITOR_DRAW_RADIUS, false);
}

function editor_update(){
	// @description Updates editor.
	
	// Updating move.
	editor_update_move();
	
	// Updating draw.
	editor_update_mouse_draw();
	
	// Updating hotkeys.
	editor_update_hotkeys();
}

function editor_update_hotkeys(){
	// @description Updates hotkeys.
	
	// Keybind.
	if (not keyboard_check(vk_control)) return;
	
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

function editor_update_draw_begin(){
	// @description Updates draw begin (Mouse pressed).
	
	// Getting layer draw positions.
	var draw_x = editor_project_x(mouse_x);
	var draw_y = editor_project_y(mouse_y);

	if editor_position_is_valid(draw_x, draw_y){
		// If valid.
			
		// Create command surface.
		var command_surface = surface_create(controller.editor_width, controller.editor_height);
		surface_copy(command_surface, 0, 0, editor_layer_selected_get_surface());
		
		// Remember command.
		editor_command_stack_temporary = new sEditorStackCommand(editor_selected_layer, command_surface);
	}
		
	// Clear queue.
	editor_clear_mouse_queue();
			
	// Add click point.
	ds_list_add(editor_mouse_queue_x, mouse_x, mouse_x);
	ds_list_add(editor_mouse_queue_y, mouse_y, mouse_y);
		
	// Mark project as unsaved.
	editor_project_is_saved = false;
		
	// Update title.
	editor_project_update_window_title();
}

function editor_update_draw_end(){
	// @description Updates draw end (Mouse released).
		
	if (not editor_selected_tool_is_rectangular()){
		// If not rectangular tools.
			
		// Push command.
		if (not is_undefined(editor_command_stack_temporary)){
			array_push(editor_command_stack, editor_command_stack_temporary);
			editor_command_stack_temporary = undefined;
		}
	}else{
		// If rectangular.
		
		// Drawing color.
		draw_set_color(EDITOR_DRAW_COLOR);

		// Start draw.
		surface_set_target(editor_layer_selected_get_surface());

		// Draw shape function.
		var draw_function = EDITOR_TOOLS_DRAW_FUNCTIONS[? editor_selected_tool];

		// Draw final shape.
		draw_function(editor_project_x(editor_rectangular_shape_start.x), 
						editor_project_y(editor_rectangular_shape_start.y), 
						editor_project_x(editor_rectangular_shape_end.x), 
						editor_project_y(editor_rectangular_shape_end.y), 
						false);
						   
			
		// End shape.
		editor_rectangular_shape = false;
		editor_rectangular_shape_start = POINT_NULL;
		editor_rectangular_shape_end = POINT_NULL;
				
		// End draw.
		surface_reset_target();
	}
}

function editor_update_draw(){
	// @description Updates draw (Mouse hold).
	
	if (editor_selected_tool_is_rectangular()){
		// If rectangular tools.

		// Rectangular shape.
		__editor_update_draw_rectangular();
	}else{
		// If not rectangular tools. 

		// Simple shape.
		__editor_update_draw();
	}
}

function __editor_update_draw_rectangular(){
	// @description Updates draw for rectangular.
	
	if (mouse_check_button_pressed(mb_left)){
		// If hold begin.
				
		// Begin shape.
		editor_rectangular_shape = true;
		editor_rectangular_shape_start = new sPoint(mouse_x, mouse_y);
		editor_rectangular_shape_end = new sPoint(mouse_x, mouse_y);
	}

	// Rectangular shape end.
	editor_rectangular_shape_end = new sPoint(mouse_x, mouse_y);
}

function __editor_update_draw(){
	// Updates draw for simple.
	
	// Update queue.
	var queue_points_count = window_mouse_queue_get(editor_mouse_queue_x, editor_mouse_queue_y);
	if (mouse_check_button_pressed(mb_left)) queue_points_count += 2;
			
	if (queue_points_count != 0){
		// If we have something to draw.
				
		if (editor_selected_tool == eEDITOR_TOOL.ERASER){
			// If eraser.
					
			// GPU Blendbmode.
			gpu_set_blendmode(bm_subtract);
		}
				
		// Drawing color.
		draw_set_color(EDITOR_DRAW_COLOR);
				
		// Start draw.
		surface_set_target(editor_layer_selected_get_surface());
				
		for (var queue_point_index = queue_points_count - 1; queue_point_index >= 0; queue_point_index --){
			// For all queue points.
					
			// Skip if we gonna break.
			if (queue_point_index - 1 < 0) continue;
					
			// Getting layer draw positions.
			var draw_x = editor_project_x(editor_mouse_queue_x[| queue_point_index]);
			var draw_y = editor_project_y(editor_mouse_queue_y[| queue_point_index]);
								
			// Get previous.
			var draw_x_previous = editor_project_x(editor_mouse_queue_x[| queue_point_index - 1]);
			var draw_y_previous = editor_project_y(editor_mouse_queue_y[| queue_point_index - 1]);
								
			switch(editor_selected_tool){
				// Selecting tool.
					
				case eEDITOR_TOOL.ERASER:
					// If eraser.
	
					// Drawing.
					__editor_update_draw_function(draw_x_previous, draw_y_previous, draw_x, draw_y);
				break;
				case eEDITOR_TOOL.PENCIL:
					// If pencil.
	
					// Drawing.
					__editor_update_draw_function(draw_x_previous, draw_y_previous, draw_x, draw_y);
				break;
				default:
					// Should not be happened.
				break;
			}
		}
	
		// End draw.
		surface_reset_target();

		if (editor_selected_tool == eEDITOR_TOOL.ERASER){
			// If eraser.
					
			// GPU Blendbmode.
			gpu_set_blendmode(bm_normal);
		}
				
		// Clear queue.
		editor_clear_mouse_queue();
	}
}

#endregion

function editor_update_mouse_draw(){
	// @description Uupdates editor draw.
	
	// Return if no selected layer.
	if (is_undefined(editor_selected_layer)){
		// Clear queue.
		editor_clear_mouse_queue();
		return;
	}
	
	// Draw begin (Mouse pressed).
	if (mouse_check_button_pressed(mb_left)) editor_update_draw_begin();

	// Draw end (mouse released).
	if (mouse_check_button_released(mb_left)) editor_update_draw_end();
	
	// Draw (mouse hold).
	if (mouse_check_button(mb_left)) editor_update_draw();
}

function editor_update_move(){
	// @description Updates editor move.
	
	if (mouse_check_button_pressed(mb_right)){
		// If click.
		
		// Remebmer editor move pos.
		editor_move_x = mouse_x;
		editor_move_y = mouse_y;
	}else{
		// If not click.
		
		if (mouse_check_button(mb_right)){
			// If hold.
			
			// Moving.
			editor_view_x += (mouse_x - editor_move_x);
			editor_view_y += (mouse_y - editor_move_y);
			
			// Remember position.
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
	// @description Opens new project.
	
	// Undefined project filename.
	editor_project_filename = undefined;
	
	// Free layers.
	editor_layers_free();
	
	// Editor width, height.
	editor_width = EDITOR_WIDTH;
	editor_height = EDITOR_HEIGHT;
	
	// Creating default layer and selecting it.
	editor_layer_select(editor_layer_new("Base"));

	// Clearing base layer with defalt color. 
	editor_layer_clear(editor_selected_layer, EDITOR_LAYER_DEFAULT_COLOR);
	
	// Clear command stack.
	editor_command_stack_clear();
	
	// Unsave.
	editor_project_is_saved = false;
	
	// Updating title.
	editor_project_update_window_title();
}

function editor_project_open(){
	// @description Opens project from file.
	
	// Getting selected filename.
	var selected_filename = get_open_filename(EDITOR_EXPLORER_PROJECT_FILTER, "");
	
	// If not existing file.
	if (not file_exists(selected_filename)) return;
	
	// Project filename.
	editor_project_filename = selected_filename;
	
	// Clearing layers.
	editor_layers_free();
	
	// Loding sprite.
	var loaded_sprite = sprite_add(selected_filename, 1, false, false, 0, 0);
	
	// Resize.
	editor_width = sprite_get_width(loaded_sprite);
	editor_height = sprite_get_height(loaded_sprite);
	
	// New layer.
	var file_layer = editor_layer_new("File");
	
	// Selecting layer.
	editor_layer_select(file_layer);
	
	// Clear command stack.
	editor_command_stack_clear();
	
	// Drawing loaded image.
	surface_set_target(editor_layer_get(file_layer).surface);
	
	// Drawing sprite.
	draw_sprite(loaded_sprite, 0, 0, 0);
	
	// Resetting.
	surface_reset_target();
	
	// Deleting sprite.
	sprite_delete(loaded_sprite);
	
	// Mark as saved.
	editor_project_is_saved = true;
	
	// Updating title.
	editor_project_update_window_title();
}

function editor_project_update_window_title(){
	// @description Updates window title.
	
	// Project name.
	var project = "(No project)";
	
	// Save title text.
	var save_state = editor_project_is_saved ? "" : "*UNSAVED* ";
	
	if (not is_undefined(editor_project_filename)){
		// If project opened.
		
		// Project.
		project = "(Project " + editor_project_filename + ")";
	}
	
	
	// Update title.
	window_set_caption(string_replace(game_project_name, "_", " ") + " " + save_state + project);
}

function editor_project_save(){
	// @description Saves project.
	
	if (is_undefined(editor_project_filename)){
		// If undefined project filename.
		
		// Getting filename.
		editor_project_filename = get_save_filename(EDITOR_EXPLORER_PROJECT_FILTER, "");
		
		// Update.
		editor_project_update_window_title();
	}
	
	// New surface.
	var result_surface = surface_create(editor_width, editor_height);
	
	// Setting surface.
	surface_set_target(result_surface);
	
	for (var current_layer_index = array_length(editor_layers) - 1; current_layer_index >= 0; current_layer_index--){
		// Iterating over all layers.
	
		// Getting layer.
		var current_layer = editor_layer_get(current_layer_index);
		
		if (not surface_exists(current_layer.surface)){
			// If surface is not exists.
			
			// Loading surface.
			current_layer.create_surface();
			buffer_set_surface(current_layer.buffer, current_layer.surface, 0);
		}
		
		// Drawing.
		draw_surface(current_layer.surface, 0, 0);
	}
	
	// Resetting surface target.
	surface_reset_target();
	
	// Saving.
	surface_save(result_surface, editor_project_filename);
	
	// Free memory.
	surface_free(result_surface);
	
	// Mark project as saved.
	editor_project_is_saved = true;
	
	// Update title.
	editor_project_update_window_title();
}

#endregion

#region Other.

function editor_project_x(window_x){
	// @description Projects given x to editor surface x. 
	// @param {real} window_x X from mouse_x or queue.
	// @returns {real} Projected x.
	
	// Returning projected point.
	return (window_x - editor_view_x) / editor_zoom;
}

function editor_project_y(window_y){
	// @description Projects given y to editor surface y. 
	// @param {real} window_y Y from mouse_y or queue.
	// @returns {real} Projected y.
	
	// Returning projected point.
	return (window_y - editor_view_y) / editor_zoom;
}

function editor_position_is_valid(draw_x, draw_y){
	// @description Returns is given (X, Y) is valid (in editor position) or not.
	// @returns {bool} Is valid or not.
	
	// Returning.
	return (draw_x > 0 and draw_x < editor_width) and (draw_y > 0 and draw_y < editor_height);
}

function editor_clear_mouse_queue(){
	// @description Clears mouse queue.
	
	// Clear queue.
	ds_list_clear(editor_mouse_queue_x);
	ds_list_clear(editor_mouse_queue_y);
	window_mouse_queue_clear();
}

function editor_close_event(){
	// @description Handles close event, asking user that he wants save file or not.
	
	// Skip if project is already saved.
	if (editor_project_is_saved) return;
	
	// Asking user.
	var dialog = show_question("Project is not saved, do you want to save it right now?");
	
	if (dialog){
		// If user preferred to save project.
		
		// Save project.
		editor_project_save();
	};
}

function editor_selected_tool_is_rectangular(){
	// @description Returns is selected tool is rectangular tool or not.
	// @returns {bool} Is rectangular or not.
	
	// Returning.
	return EDITOR_TOOLS_RECTANGULAR[? editor_selected_tool];
}

#endregion

#endregion

#region Entry point.

// Lists for window_mouse_queque extension.
editor_mouse_queue_x = ds_list_create();
editor_mouse_queue_y = ds_list_create();

// Rectangular shape position.
// TODO: Add vector2 struct.
editor_rectangular_shape = false;
editor_rectangular_shape_start = POINT_NULL;
editor_rectangular_shape_end = POINT_NULL;

// Editor width, height.
editor_width = EDITOR_WIDTH;
editor_height = EDITOR_HEIGHT;

// Editor layers surfaces.
editor_layers = [];

// Command stack for undo.
editor_command_stack = [];
editor_command_stack_temporary = undefined;

// Current selected layer.
editor_selected_layer = 0;

// Edtir project filename.
editor_project_filename = undefined;

// Is current project saved or not.
editor_project_is_saved = false;

// Current selected tool.
editor_selected_tool = EDITOR_DEFAULT_SELECTED_TOOL;

// Move positions.
editor_move_x = -1;
editor_move_y = -1;

// Current zoom level.
editor_zoom = 1;

// Current view positions.
editor_view_x = editor_width / 2;
editor_view_y = editor_height / 2;

// Opening new file.
editor_project_new();

// Updating title.
editor_project_update_window_title();

// Initialise queue.
window_mouse_queue_init();

#endregion