/// @description Initialising.
// @author Kirill Zhosul (@kirillzhosul)

#region Structs.

#region Layer.

function editor_layer(name) constructor{
	// Layer struct.
	
	// Layer name.
	self.name = name;
	
	// Layer surface.
	self.surface = surface_create(controller.editor_width, controller.editor_heigth);
	
	// Layer buffer.
	self.buffer = buffer_create(1, buffer_grow, 1);
	
	// Layer is visible.
	self.is_visible = true;

	self.show = function(){
		// @function editor_layer.show()
		// @description Function that shows (draws) layer.
		
		// Retunring if not visible.
		if not self.is_visible return;
		
		if not surface_exists(self.surface){
			// If surface is not exists.
			
			// Loading surface.
			self.surface = surface_create(controller.editor_width, controller.editor_heigth);
			self.surface = buffer_get_surface(self.buffer, self.surface, 0);
		}else{
			// If all OK.
			
			// Buffering surface.
			buffer_set_surface(self.buffer, self.surface, 0);
		}
		
		// Drawing.
		draw_surface(self.surface, controller.editor_view_x, controller.editor_view_y);
	}
	
	self.free = function(){
		// @function editor_layer.free()
		// @description Function that frees layer.
		
		// Free layer.
		surface_free(self.surface);
		buffer_delete(self.buffer);
	}
}

#endregion

#endregion

#region Macros, enums.

// Editor tools.
enum eEDITOR_TOOL{
	PENCIL,
	ERASER
}

#endregion

#region Functions.

#region Layers.

function editor_layer_new(layer_name){
	// @function editor_layer_new(layer_name)
	// @description Function that creates new layer in editor.
	// @param {string} layer_name Name for layer.
	// @returns {real} Layer index.
	
	// Adding layer in editor layers.
	array_push(editor_layers, new editor_layer(layer_name));
	
	// Returning layer index.
	return array_length(editor_layers) - 1;
}

function editor_layer_get(layer_index){
	// @function editor_layer_get(layer_index)
	// @description Function that returns editor layer with given index.
	// @returns {array} Layer.
	
	// Returning layer.
	return array_get(editor_layers, layer_index);
}

function editor_layer_clear(layer_index, color){
	// @function editor_layer_clear(layer_index, color)
	// @description Function that clears layer with given color.
	// @param {real} layer_index Layer index to clear.
	// @param {color} color With what color clear.
	
	// Getting layer surface.
	surface_set_target(editor_layer_get(layer_index).surface)

	// Clearing.
	draw_clear(color)
	
	// Resetting current surface.
	surface_reset_target();
}

function editor_layer_select(layer_index){
	// @function editor_layer_select(layer_index)
	// @description Function that selects layer.
	// @param {real} layer_index Layer index to select.
	
	// Selecting.
	editor_selected_layer = layer_index;
}

function editor_layer_switch_visibility(layer_index){
	// @function editor_layer_switch_visibility(layer_index)
	// @description Function that switch layer visibility.
	// @param {real} layer_index Layer index to switch visibility..
	
	// Not processing if invalid layer.
	if is_undefined(layer_index) return;
	
	// Getting layer.
	var current_layer = editor_layer_get(layer_index);
	
	// Switching visibility.
	current_layer.is_visible = not current_layer.is_visible;
}

function editor_layers_free(){
	// @function editor_layers_free()
	// @description Function that frees all layers.
	
	for (var current_layer_index = 0;current_layer_index < array_length(editor_layers); current_layer_index++){
		// Iterate over all layers.
		
		// Free.
		editor_layer_get(current_layer_index).free();
	}
	
	// Clearing.ed
	editor_layers = [];
}

function editor_layer_delete(layer_index){
	// @function editor_layer_delete(layer_index)
	// @description Function that deletes layer.
	
	// Do not process if invalid.
	if is_undefined(editor_selected_layer) return;
	
	
	if editor_selected_layer == layer_index{
		// If deleting selected layer.
		
		// Selecting moved.
		editor_selected_layer = layer_index - 1;
		
		if editor_selected_layer == -1{
			// If run out of bounds.
			
			// Set invalid layer.
			editor_selected_layer = undefined;
		}
	}
	
	// Deleting layer.
	array_delete(editor_layers, layer_index, 1);
}

function editor_layer_move_up(layer_index){
	// @function editor_layer_move_up(layer_index)
	// @description Function that moves layer up.
	
	// Not processing if invalid layer.
	if is_undefined(layer_index) return;
	
	// Returning if first already.
	if layer_index == 0 return;
	
	if editor_selected_layer == layer_index{
		// If moving selected layer.
		
		// Selecting new index.
		editor_selected_layer = layer_index - 1;
	}
	
	// Moving layer.
	editor_layer_move(layer_index, layer_index - 1);
}

function editor_layer_move_down(layer_index){
	// @function editor_layer_move_up(layer_index)
	// @description Function that moves layer up.
	
	// Not processing if invalid layer.
	if is_undefined(layer_index) return;
	
	// Returning if first already.
	if layer_index == array_length(editor_layers) - 1 return;
	
	if editor_selected_layer == layer_index{
		// If moving selected layer.
		
		// Selecting new index.
		editor_selected_layer = layer_index + 1;
	}
	
	// Moving layer.
	editor_layer_move(layer_index, layer_index + 1);
}

function editor_layer_move(index_one, index_two){
	// @function editor_layer_move(index_one, index_two)
	// @description Function that swaps layers.
	
	// Swap buffer.
	var swap_buffer = editor_layers[@ index_one];
	
	// Swapping.
	editor_layers[@ index_one] = editor_layers[@ index_two];
	editor_layers[@ index_two] = swap_buffer;
}

#endregion

#region Drawing.

function editor_draw(){
	// @function editor_draw()
	// @description Function that draws editor.
	
	// Drawing layers.
	editor_draw_layers();
	
	// Drawing interface.
	editor_draw_interface(0, 0);
	

}

function editor_draw_layers(){
	// @function editor_draw_layers()
	// @description Function that draws editor layers.

	for (var current_layer_index = array_length(editor_layers) - 1;current_layer_index >= 0; current_layer_index--){
		// Iterating over all layers.
	
		// Showing layer.
		editor_layer_get(current_layer_index).show();
	}
}

function editor_draw_interface(x, y){
	// @function editor_draw_interface()
	// @description Function that draws editor interface.
	
	// Drawing color, font.
	draw_set_color(c_white);
	draw_set_font(ui_interface_font);

	// Draw offset, y.
	var offset = 3;
	y = 3;
	
	// Layer buttons.
	
	// New layer.
	x = 0;
	if draw_button_sprite(x, y, ui_button_layer_new){
		editor_selected_layer = editor_layer_new("Layer " + string(array_length(editor_layers)));
	}
	// Delete layer.
	x += sprite_get_width(ui_button_layer_new) + offset;
	if draw_button_sprite(x, y, ui_button_layer_delete){
		editor_layer_delete(editor_selected_layer);
	}
	// Layer up.
	x += sprite_get_width(ui_button_layer_delete) + offset;
	if draw_button_sprite(x, y, ui_button_layer_up){
		editor_layer_move_up(editor_selected_layer);
	}
	// Layer down.
	x += sprite_get_width(ui_button_layer_up) + offset;
	if draw_button_sprite(x, y, ui_button_layer_down){
		editor_layer_move_down(editor_selected_layer);
	}
	// Layer visibility.
	x += sprite_get_width(ui_button_layer_down) + offset;
	if draw_button_sprite(x, y, ui_button_layer_visibility){
		editor_layer_switch_visibility(editor_selected_layer);
	}
	
	// Draw offset, y.
	offset = 3;
	y = room_height - sprite_get_width(ui_button_layer_tool_pencil) - 3;
	
	// Tools buttons.
	
	// Pencil tool.
	x = 0;
	if draw_button_sprite(x, y, ui_button_layer_tool_pencil){
		// Current selected tool.
		editor_selected_tool = eEDITOR_TOOL.PENCIL;
	}
	// Eraser tool.
	x = sprite_get_width(ui_button_layer_tool_pencil) + offset;
	if draw_button_sprite(x, y, ui_button_layer_tool_eraser){
		// Current selected tool.
		editor_selected_tool = eEDITOR_TOOL.ERASER;
	}
	
	// Drawing layers text.
	draw_text(offset, sprite_get_height(ui_button_layer_new) + offset, "Layers: ");
	
	// Layers position.
	y = (sprite_get_height(ui_button_layer_new) + offset + string_height("Layers"));
	offset = 20;
	
	if array_length(editor_layers) == 0{
		// If empty.
		
		// No layers.
		draw_text(floor(offset * .5), y, "...No layers!");
	}
	
	for (var current_layer_index = 0;current_layer_index < array_length(editor_layers); current_layer_index++){
		// Iterating over all layers.
		
		// Getting layer.
		var current_layer = editor_layer_get(current_layer_index);
		
		if current_layer_index == editor_selected_layer{
			// If selected layer.
			
			if current_layer.is_visible{
				// If visible.
				
				// Setting color.
				draw_set_color(c_yellow);
			}else{
				// If not visible.
				
				// Setting color.
				draw_set_color(c_olive);
			}
		}else{
			// If not selected.
			
			if current_layer.is_visible{
				// If visible.
				
				// Setting color.
				draw_set_color(c_white);
			}else{
				// If not visible.
				
				// Setting color.
				draw_set_color(c_gray);
			}
		}
		
		// Getting layer name.
		var _layer_name = "\"" + current_layer.name + "\""
		
		// Drawing layer.
		if draw_button_text(floor(offset * .5), y + offset * current_layer_index, _layer_name){
			// If clicked.
			
			// Selecting layer.
			editor_layer_select(current_layer_index);
		}
	}
}

function draw_button_sprite(x, y, sprite){
	// @function draw_button_sprite(x, y, sprite)
	// @description Function that draws sprite and returns is pressed or not.
	// @param {real} x X position to draw on.
	// @param {real} y Y position to draw on.
	// @param {sprite} sprite Sprite to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_sprite(sprite, image_index, x, y);
	
	// Returning.
	if point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_get_width(sprite), y + sprite_get_height(sprite)){
		// If hovered.
		
		// Returning.
		if mouse_check_button_pressed(mb_left) return true;
	}
	
	// Returning.
	return false;
}

function draw_button_text(x, y, text){
	// @function draw_button_text(x, y, text)
	// @description Function that draws text and returns is pressed or not.
	// @param {real} x X position to draw on.
	// @param {real} y Y position to draw on.
	// @param {string} text String to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_text(x, y, text);
	
	// Returning.
	if point_in_rectangle(mouse_x, mouse_y, x, y, x + string_width(text), y + string_height(text)){
		// If hovered.
		
		// Returning.
		if mouse_check_button_pressed(mb_left) return true;
	}
	
	// Returning.
	return false;
}

#endregion

#region Updating.

function editor_update(){
	// @function editor_update()
	// @description Function that updates editor.
	
	// Updating move.
	editor_update_move();
	
	// Updating draw.
	editor_update_draw();
	
	// Updating hotkeys.
	editor_update_hotkeys();
}

function editor_update_hotkeys(){
	// @function editor_update_hotkeys()
	// @description Function that updates hotkeys.
	
	// Open hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("O")) return editor_project_open();
	
	// New hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("N")) return editor_project_new();
	
	// Save hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("S")) return editor_project_save()
}

function editor_update_draw(){
	// @function editor_update_draw()
	// @description Function that updates editor draw.
	
	if mouse_check_button_pressed(mb_left){
		// If start drawing.
		
		// Clear queue.
		ds_list_clear(editor_mouse_queue_x);
		ds_list_clear(editor_mouse_queue_y);
		window_mouse_queue_clear();
	}
	
	if mouse_check_button(mb_left){
		// If pressed.
		
		// Update queue.
		var queue_points_count = window_mouse_queue_get(editor_mouse_queue_x, editor_mouse_queue_y);

		if queue_points_count != 0{
			// If we have something to draw.
			
			// Getting layer.
			var current_layer = editor_layer_get(editor_selected_layer);
			
			// Start draw.
			surface_set_target(current_layer.surface);
			draw_primitive_begin(pr_linestrip);
			
			// Tools.
			switch(editor_selected_tool){
				case eEDITOR_TOOL.ERASER:
					// GPU Blendbmode.
					gpu_set_blendmode(bm_subtract);
				break;
				case eEDITOR_TOOL.PENCIL:
					// Drawing color.
					draw_set_color(c_green);
				break;
			}
							
			var draw_function = function __draw_function(x1, y1, x2, y2){
				// @function __draw_function()
				// @description Function that draws.
								
				// Settings.
				var curve = 0.1;
				var threeshold = 2;
				var radius = 8;
								
				// Get difference.
				var difference = abs(x1 - x2) + abs(y1 - y2);
								
				if difference >= radius / threeshold{
					// If difference too much.
									
					// Recursion.
					__draw_function(lerp(x1, x2, curve), lerp(y1, y2, curve), x2, y2);
				}
								
				// Main element.
				draw_circle(x1, y1, radius, false);
			};
			
			for (var queue_point_index = queue_points_count - 1; queue_point_index >= 0; queue_point_index --){
				// For all queue points.
				
				// Getting layer draw positions.
				var draw_x = editor_mouse_queue_x[| queue_point_index] - editor_view_x;
				var draw_y = editor_mouse_queue_y[| queue_point_index] - editor_view_y;
							
				// Skip if we gonna break.
				if queue_point_index - 1 < 0 continue;
				
				// Get previous.
				var draw_x_previous = editor_mouse_queue_x[| queue_point_index - 1] - editor_view_x;
				var draw_y_previous = editor_mouse_queue_y[| queue_point_index - 1] - editor_view_y;
							

				switch(editor_selected_tool){
					// Selecting tool.
				
					case eEDITOR_TOOL.ERASER:
						// If eraser.

						// Drawing.
						draw_function(draw_x_previous, draw_y_previous, draw_x, draw_y);
					break;
					case eEDITOR_TOOL.PENCIL:
						// If pencil.

						// Drawing.
						draw_function(draw_x_previous, draw_y_previous, draw_x, draw_y);
					break;
				}

			}

			// End draw.
			draw_primitive_end();
			surface_reset_target();
			
			// GPU Blendbmode.
			gpu_set_blendmode(bm_normal);
			
			// Clear queue.
			ds_list_clear(editor_mouse_queue_x);
			ds_list_clear(editor_mouse_queue_y);
			window_mouse_queue_clear();
		}
	}
}

function editor_update_move(){
	// @function editor_update_move()
	// @description Function that updates editor move.
	
	if mouse_check_button_pressed(mb_right){
		// If click.
		
		// Remebmer editor move pos.
		editor_move_x = mouse_x;
		editor_move_y = mouse_y;
	}else{
		// If not click.
		
		if mouse_check_button(mb_right){
			// If hold.
			
			// Moving.
			editor_view_x += mouse_x - editor_move_x;
			editor_view_y += mouse_y - editor_move_y;
			
			// Remember position.
			editor_move_x = mouse_x;
			editor_move_y = mouse_y;
		}
	}
}

#endregion

#region Projects.

function editor_project_new(){
	// @function editor_project_new()
	// @description Function that opens new project.
	
	// Undefined project filename.
	editor_project_filename = undefined;
	
	// Free layers.
	editor_layers_free();
	
	// Editor width, height.
	editor_width = floor(room_width / 2);
	editor_heigth = floor(room_height / 2);
	
	// Creating default layer and selecting it.
	editor_selected_layer = editor_layer_new("Base");

	// Clearing base layer with white color 
	editor_layer_clear(editor_selected_layer, c_white);
	
	// Updating title.
	editor_project_update_window_title();
}

function editor_project_open(){
	// @function editor_project_open()
	// @description Function that opens project from file.
	
	// Getting selected filename.
	var selected_filename = get_open_filename("Images (PNG)|*.png", "");
	
	if not file_exists(selected_filename){
		// If file we selected is not existing.
		
		// Returning from opening.
		return;
	}
	
	// Project filename.
	editor_project_filename = selected_filename;
	
	// Clearing layers.
	editor_layers_free();
	
	// Loding sprite.
	var loaded_sprite = sprite_add(selected_filename, 1, false, false, 0, 0);
	
	// Resize.
	editor_width = sprite_get_width(loaded_sprite);
	editor_heigth = sprite_get_height(loaded_sprite);
	
	// New layer.
	var _file_layer = editor_layer_new("File");
	
	// Selecting layer.
	editor_layer_select(_file_layer);
	
	// Drawing loaded image.
	surface_set_target(editor_layer_get(_file_layer).surface);
	
	// Drawing sprite.
	draw_sprite(loaded_sprite, 0, 0, 0);
	
	// Resetting.
	surface_reset_target();
	
	// Deleting sprite.
	sprite_delete(loaded_sprite);
	
	// Updating title.
	editor_project_update_window_title();
}

function editor_project_update_window_title(){
	// @function editor_project_update_window_title()
	// @description Function that updates window title.
	
	if is_undefined(editor_project_filename){
		// If not set project filename.
		
		// Caption.
		window_set_caption("Paint Editor (No Project)");
	}else{
		// If set.
		
		// Caption.
		window_set_caption("Paint Editor (Project " + editor_project_filename + ")");
	}
}

function editor_project_save(){
	// @function editor_project_save()
	// @description Function that saves project.
	
	if is_undefined(editor_project_filename){
		// If undefined project filename.
		
		// Getting filename.
		editor_project_filename = get_save_filename("Images (PNG)|*.png", "")
		
		// Update.
		editor_project_update_window_title();
	}
	
	// New surface.
	var result_surface = surface_create(editor_width, editor_heigth);
	
	// Setting surface.
	surface_set_target(result_surface);
	
	for (var current_layer_index = array_length(editor_layers) - 1; current_layer_index >= 0; current_layer_index--){
		// Iterating over all layers.
	
		// Getting layer.
		var current_layer = editor_layer_get(current_layer_index);
		
		if not surface_exists(current_layer.surface){
			// If surface is not exists.
			
			// Loading surface.
			current_layer.surface = surface_create(controller.editor_width, controller.editor_heigth);
			current_layer.surface = buffer_get_surface(self.buffer, self.surface, 0);
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
}

#endregion

#endregion

#region Entry point.

// Lists for window_mouse_queque extension.
editor_mouse_queue_x = ds_list_create()
editor_mouse_queue_y = ds_list_create();
	
// Editor width, height.
editor_width = floor(room_width / 2);
editor_heigth = floor(room_height / 2);

// Editor layers surfaces.
editor_layers = [];

// Current selected layer.
editor_selected_layer = 0;

// Edtir project filename.
editor_project_filename = undefined;

// Current selected tool.
editor_selected_tool = eEDITOR_TOOL.PENCIL;

// Move positions.
editor_move_x = -1;
editor_move_y = -1;

// Current view positions.
editor_view_x = editor_width / 2;
editor_view_y = editor_heigth / 2;

// Opening new file.
editor_project_new();

// Updating title.
editor_project_update_window_title();

window_mouse_queue_init();

#endregion