/// @description Initialising.
// @author Kirill Zhosul (@kirillzhosul)

#region Structs.

#region Layer.

function __editor_layer(_name) constructor{
	// Layer struct.
	
	// Layer name.
	self.layer_name = _name;
	
	// Layer surface.
	self.layer_surface = surface_create(controller.__editor_width, controller.__editor_heigth);
	
	// Layer buffer.
	self.layer_buffer = buffer_create(1, buffer_grow, 1);
	
	// Layer is visible.
	self.layer_is_visible = true;

	self.show = function(){
		// @function __editor_layer.show()
		// @description Function that shows (draws) layer.
		
		// Retunring if not visible.
		if not self.layer_is_visible return;
		
		if not surface_exists(self.layer_surface){
			// If surface is not exists.
			
			// Loading surface.
			self.layer_surface = surface_create(controller.__editor_width, controller.__editor_heigth);
			self.layer_surface = buffer_get_surface(self.layer_buffer, self.layer_surface, 0);
		}else{
			// If all OK.
			
			// Buffering surface.
			buffer_set_surface(self.layer_buffer, self.layer_surface, 0);
		}
		
		// Drawing.
		draw_surface(self.layer_surface, controller.__editor_view_x, controller.__editor_view_y);
	}
	
	self.free = function(){
		// @function __editor_layer.free()
		// @description Function that frees layer.
		
		// Free layer.
		surface_free(self.layer_surface);
		buffer_delete(self.layer_buffer);
	}
}

#endregion

#endregion

#region Macros, enums.

// Editor tools.
enum __editor_tool{
	PENCIL,
	ERASER
}

#endregion

#region Functions.

#region Layers.

function __editor_layer_new(_layer_name){
	// @function __editor_layer_new(_layer_name)
	// @description Function that creates new layer in editor.
	// @param {string} _layer_name Name for layer.
	// @returns {real} Layer index.
	
	// Adding layer in editor layers.
	array_push(__editor_layers, new __editor_layer(_layer_name));
	
	// Returning layer index.
	return array_length(__editor_layers) - 1;
}

function __editor_layer_get(_layer_index){
	// @function __editor_layer_get(_layer_index)
	// @description Function that returns editor layer with given index.
	// @returns {array} Layer.
	
	// Returning layer.
	return array_get(__editor_layers, _layer_index);
}

function __editor_layer_clear(_layer_index, _clear_color){
	// @function __editor_layer_clear(_layer_index, _clear_color)
	// @description Function that clears layer with given color.
	// @param {real} _layer_index Layer index to clear.
	// @param {color} _clear_color With what color clear.
	
	// Getting layer surface.
	surface_set_target(__editor_layer_get(_layer_index).layer_surface)

	// Clearing.
	draw_clear(_clear_color)
	
	// Resetting current surface.
	surface_reset_target();
}

function __editor_layer_select(_layer_index){
	// @function __editor_layer_select(_layer_index)
	// @description Function that selects layer.
	// @param {real} _layer_index Layer index to select.
	
	// Selecting.
	__editor_selected_layer = _layer_index;
}

function __editor_layer_switch_visibility(_layer_index){
	// @function __editor_layer_switch_visibility(_layer_index)
	// @description Function that switch layer visibility.
	// @param {real} _layer_index Layer index to switch visibility..
	
	// Getting layer.
	var _layer = __editor_layer_get(_layer_index);
	
	// Switching visibility.
	_layer.layer_is_visible = not _layer.layer_is_visible;
}

function __editor_layers_free(){
	// @function __editor_layers_free()
	// @description Function that frees all layers.
	
	for (var _current_layer_index = 0;_current_layer_index < array_length(__editor_layers); _current_layer_index++){
		// Iterate over all layers.
		
		// Free.
		__editor_layer_get(_current_layer_index).free();
	}
	
	// Clearing.
	__editor_layers = [];
}

function __editor_layer_delete(_layer_index){
	// @function __editor_layer_delete(_layer_index)
	// @description Function that deletes layer.
	
	if __editor_selected_layer == _layer_index and _layer_index != 0{
		// If deleting selected layer.
		
		// Selecting moved.
		__editor_selected_layer = _layer_index - 1;
	}
	
	// Deleting layer.
	array_delete(__editor_layers, _layer_index, 1);
}

function __editor_layer_move_up(_layer_index){
	// @function __editor_layer_move_up(_layer_index)
	// @description Function that moves layer up.
	
	// Returning if first already.
	if _layer_index == 0 return;
	
	if __editor_selected_layer == _layer_index{
		// If moving selected layer.
		
		// Selecting new index.
		__editor_selected_layer = _layer_index - 1;
	}
	
	// Moving layer.
	__editor_layer_move(_layer_index, _layer_index - 1);
}

function __editor_layer_move_down(_layer_index){
	// @function __editor_layer_move_up(_layer_index)
	// @description Function that moves layer up.
	
	// Returning if first already.
	if _layer_index == array_length(__editor_layers) - 1 return;
	
	if __editor_selected_layer == _layer_index{
		// If moving selected layer.
		
		// Selecting new index.
		__editor_selected_layer = _layer_index + 1;
	}
	
	// Moving layer.
	__editor_layer_move(_layer_index, _layer_index + 1);
}

function __editor_layer_move(_index_one, _index_two){
	// @function __editor_layer_move(_index_one, _index_two)
	// @description Function that swaps layers.
	
	// Swap buffer.
	var _swap_buffer = __editor_layers[@ _index_one];
	
	// Swapping.
	__editor_layers[@ _index_one] = __editor_layers[@ _index_two];
	__editor_layers[@ _index_two] = _swap_buffer;
}

#endregion

#region Drawing.

function __editor_draw(){
	// @function __editor_draw()
	// @description Function that draws editor.
	
	// Drawing layers.
	__editor_draw_layers();
	
	// Drawing interface.
	__editor_draw_interface();
}

function __editor_draw_layers(){
	// @function __editor_draw_layers()
	// @description Function that draws editor layers.

	for (var _current_layer_index = array_length(__editor_layers) - 1;_current_layer_index >= 0; _current_layer_index--){
		// Iterating over all layers.
	
		// Showing layer.
		__editor_layer_get(_current_layer_index).show();
	}
}

function __editor_draw_interface(){
	// @function __editor_draw_interface()
	// @description Function that draws editor interface.
	
	// Drawing color, font.
	draw_set_color(c_white);
	draw_set_font(ui_interface_font);

	// Draw offset, y.
	var _offset = 3;
	var _y = 3;
	
	// Layer buttons.
	
	// New layer.
	var _x = 0;
	if draw_button_sprite(_x, _y, ui_button_layer_new){
		__editor_selected_layer = __editor_layer_new("Layer " + string(array_length(__editor_layers)));
	}
	// Delete layer.
	var _x = sprite_get_width(ui_button_layer_new) + _offset;
	if draw_button_sprite(_x, _y, ui_button_layer_delete){
		__editor_layer_delete(__editor_selected_layer);
	}
	// Layer up.
	var _x = _x + sprite_get_width(ui_button_layer_delete) + _offset;
	if draw_button_sprite(_x, _y, ui_button_layer_up){
		__editor_layer_move_up(__editor_selected_layer);
	}
	// Layer down.
	var _x = _x + sprite_get_width(ui_button_layer_up) + _offset;
	if draw_button_sprite(_x, _y, ui_button_layer_down){
		__editor_layer_move_down(__editor_selected_layer);
	}
	// Layer visibility.
	var _x = _x + sprite_get_width(ui_button_layer_down) + _offset;
	if draw_button_sprite(_x, _y, ui_button_layer_visibility){
		__editor_layer_switch_visibility(__editor_selected_layer);
	}
	
	// Draw offset, y.
	var _offset = 3;
	var _y = room_height - sprite_get_width(ui_button_layer_tool_pencil) - 3;
	
	// Tools buttons.
	
	// Pencil tool.
	var _x = 0;
	if draw_button_sprite(_x, _y, ui_button_layer_tool_pencil){
		// Current selected tool.
		__editor_selected_tool = __editor_tool.PENCIL;
	}
	// Eraser tool.
	var _x = sprite_get_width(ui_button_layer_tool_pencil) + _offset;
	if draw_button_sprite(_x, _y, ui_button_layer_tool_eraser){
		// Current selected tool.
		__editor_selected_tool = __editor_tool.ERASER;
	}
	
	// Drawing layers text.
	draw_text(_offset, sprite_get_height(ui_button_layer_new) + _offset, "Layers: ");
	
	// Layers position.
	var _y = (sprite_get_height(ui_button_layer_new) + _offset + string_height("Layers"));
	var _offset = 20;
	
	if array_length(__editor_layers) == 0{
		// If empty.
		
		// No layers.
		draw_text(floor(_offset * .5), _y, "...No layers!");
	}
	
	for (var _current_layer_index = 0;_current_layer_index < array_length(__editor_layers); _current_layer_index++){
		// Iterating over all layers.
		
		// Getting layer.
		var _layer = __editor_layer_get(_current_layer_index);
		
		if _current_layer_index == __editor_selected_layer{
			// If selected layer.
			
			if _layer.layer_is_visible{
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
			
			if _layer.layer_is_visible{
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
		var _layer_name = "\"" + _layer.layer_name + "\""
		
		// Drawing layer.
		if draw_button_text(floor(_offset * .5), _y + _offset * _current_layer_index, _layer_name){
			// If clicked.
			
			// Selecting layer.
			__editor_layer_select(_current_layer_index);
		}
	}
}

function draw_button_sprite(_x, _y, _sprite){
	// @function draw_button_sprite(_x, _y, _sprite)
	// @description Function that draws sprite and returns is pressed or not.
	// @param {real} _x X position to draw on.
	// @param {real} _y Y position to draw on.
	// @param {sprite} _sprite Sprite to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_sprite(_sprite, image_index, _x, _y);
	
	// Returning.
	if point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + sprite_get_width(_sprite), _y + sprite_get_height(_sprite)){
		// If hovered.
		
		// Returning.
		if mouse_check_button_pressed(mb_left) return true;
	}
	
	// Returning.
	return false;
}

function draw_button_text(_x, _y, _string){
	// @function draw_button_text(_x, _y, _string)
	// @description Function that draws text and returns is pressed or not.
	// @param {real} _x X position to draw on.
	// @param {real} _y Y position to draw on.
	// @param {string} _string String to draw.
	// @returns {bool} Is clicked or not.
	
	// Drawing.
	draw_text(_x, _y, _string);
	
	// Returning.
	if point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + string_width(_string), _y + string_height(_string)){
		// If hovered.
		
		// Returning.
		if mouse_check_button_pressed(mb_left) return true;
	}
	
	// Returning.
	return false;
}

#endregion

#region Updating.

function __editor_update(){
	// @function __editor_update()
	// @description Function that updates editor.
	
	// Updating move.
	__editor_update_move();
	
	// Updating draw.
	__editor_update_draw();
	
	// Updating hotkeys.
	__editor_update_hotkeys();
}

function __editor_update_hotkeys(){
	// @function __editor_update_hotkeys()
	// @description Function that updates hotkeys.
	
	// Open hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("O")) return __editor_project_open();
	
	// New hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("N")) return  __editor_project_new();
	
	// Save hotkey.
	if keyboard_check(vk_control) and keyboard_check_pressed(ord("S")) return  __editor_project_save()
}

function __editor_update_draw(){
	// @function __editor_update_draw()
	// @description Function that updates editor draw.
	
	if mouse_check_button(mb_left){
		// If pressed.
		
		// Getting layer draw positions.
		var _draw_x = mouse_x - __editor_view_x;
		var _draw_y = mouse_y - __editor_view_y;
		
		// Previous draw positions.
		var _draw_x_previous = __editor_previous_mouse_x - __editor_view_x;
		var _draw_y_previous = __editor_previous_mouse_y - __editor_view_y;
		
		if (_draw_x > 0 and _draw_x < __editor_width) and (_draw_y > 0 and _draw_y < __editor_heigth){
			// If valid.
			
			// Getting layer.
			var _layer = __editor_layer_get(__editor_selected_layer);
			
			// Setting surface.
			surface_set_target(_layer.layer_surface);
		
			switch(__editor_selected_tool){
				// Selecting tool.
				
				case __editor_tool.ERASER:
					// If eraser.
					
					// GPU Blendbmode.
					gpu_set_blendmode(bm_subtract);
					
					// Drawing.
					draw_line_width(_draw_x_previous, _draw_y_previous, _draw_x, _draw_y, 5);

					// GPU Blendbmode.
					gpu_set_blendmode(bm_normal);
					
				break;
				case __editor_tool.PENCIL:
					// If pencil.
					
					// Drawing color.
					draw_set_color(c_green);
	
					// Drawing.
					draw_line_width(_draw_x_previous, _draw_y_previous, _draw_x, _draw_y, 5);
				break;
			}
			
			// Resetting surface.
			surface_reset_target();
		}
	}
	
	// Mouse pos previous.
	__editor_previous_mouse_x = mouse_x;
	__editor_previous_mouse_y = mouse_y;
}

function __editor_update_move(){
	// @function __editor_update_move()
	// @description Function that updates editor move.
	
	if mouse_check_button_pressed(mb_right){
		// If click.
		
		// Remebmer editor move pos.
		__editor_move_x = mouse_x;
		__editor_move_y = mouse_y;
	}else{
		// If not click.
		
		if mouse_check_button(mb_right){
			// If hold.
			
			// Moving.
			__editor_view_x += mouse_x - __editor_move_x;
			__editor_view_y += mouse_y - __editor_move_y;
			
			// Remember position.
			__editor_move_x = mouse_x;
			__editor_move_y = mouse_y;
		}
	}
}

#endregion

#region Projects.

function __editor_project_new(){
	// @function __editor_project_new()
	// @description Function that opens new project.
	
	// Undefined project filename.
	__editor_project_filename = undefined;
	
	// Free layers.
	__editor_layers_free();
	
	// Editor width, height.
	__editor_width = floor(room_width / 2);
	__editor_heigth = floor(room_height / 2);
	
	// Creating default layer and selecting it.
	__editor_selected_layer = __editor_layer_new("Base");

	// Clearing base layer with white color 
	__editor_layer_clear(__editor_selected_layer, c_white);
	
	// Updating title.
	__editor_project_update_window_title();
}

function __editor_project_open(){
	// @function __editor_project_open()
	// @description Function that opens project from file.
	
	// Getting selected filename.
	var _selected_filename = get_open_filename("Images (PNG)|*.png", "");
	
	if not file_exists(_selected_filename){
		// If file we selected is not existing.
		
		// Returning from opening.
		return;
	}
	
	// Project filename.
	__editor_project_filename = _selected_filename;
	
	// Clearing layers.
	__editor_layers_free();
	
	// Loding sprite.
	var _loaded_sprite = sprite_add(_selected_filename, 1, false, false, 0, 0);
	
	// Resize.
	__editor_width = sprite_get_width(_loaded_sprite);
	__editor_heigth = sprite_get_height(_loaded_sprite);
	
	// New layer.
	var _file_layer = __editor_layer_new("File");
	
	// Selecting layer.
	__editor_layer_select(_file_layer);
	
	// Drawing loaded image.
	surface_set_target(__editor_layer_get(_file_layer).layer_surface);
	
	// Drawing sprite.
	draw_sprite(_loaded_sprite, 0, 0, 0);
	
	// Resetting.
	surface_reset_target();
	
	// Deleting sprite.
	sprite_delete(_loaded_sprite);
	
	// Updating title.
	__editor_project_update_window_title();
}

function __editor_project_update_window_title(){
	// @function __editor_project_update_window_title()
	// @description Function that updates window title.
	
	if is_undefined(__editor_project_filename){
		// If not set project filename.
		
		// Caption.
		window_set_caption("Paint Editor (No Project)");
	}else{
		// If set.
		
		// Caption.
		window_set_caption("Paint Editor (Project " + __editor_project_filename + ")");
	}
}

function __editor_project_save(){
	// @function __editor_project_save()
	// @description Function that saves project.
	
	if is_undefined(__editor_project_filename){
		// If undefined project filename.
		
		// Getting selected filename.
		var _selected_filename = get_open_filename("Images (PNG)|*.png", "");

		if not file_exists(_selected_filename){
			// If file we selected is not existing.
		
			// Returning from opening.
			return;
		}
		
		// Setting filename.
		__editor_project_filename = _selected_filename;
	
		// Update.
		__editor_project_update_window_title();
	}
	
	// New surface.
	var _result_surface = surface_create(__editor_width, __editor_heigth);
	
	// Setting surface.
	surface_set_target(_result_surface);
	
	for (var _current_layer_index = array_length(__editor_layers) - 1; _current_layer_index >= 0; _current_layer_index--){
		// Iterating over all layers.
	
		// Getting layer.
		var _layer = __editor_layer_get(_current_layer_index);
		
		if not surface_exists(_layer.layer_surface){
			// If surface is not exists.
			
			// Loading surface.
			_layer.layer_surface = surface_create(controller.__editor_width, controller.__editor_heigth);
			_layer.layer_surface = buffer_get_surface(self.layer_buffer, self.layer_surface, 0);
		}
		
		// Drawing.
		draw_surface(_layer.layer_surface, 0, 0);
	}
	
	// Resetting surface target.
	surface_reset_target();
	
	// Saving.
	surface_save(_result_surface, __editor_project_filename);
	
	// Free memory.
	surface_free(_result_surface);
}

#endregion

#endregion

#region Entry point.

// Editor width, height.
__editor_width = floor(room_width / 2);
__editor_heigth = floor(room_height / 2);

// Editor layers surfaces.
__editor_layers = [];

// Current selected layer.
__editor_selected_layer = 0;

// Edtir project filename.
__editor_project_filename = undefined;

// Current selected tool.
__editor_selected_tool = __editor_tool.PENCIL;

// Move positions.
__editor_move_x = -1;
__editor_move_y = -1;

// Mouse pos previous.
__editor_previous_mouse_x = mouse_x;
__editor_previous_mouse_y = mouse_y;

// Current view positions.
__editor_view_x = __editor_width / 2;
__editor_view_y = __editor_heigth / 2;

// Opening new file.
__editor_project_new();

// Updating title.
__editor_project_update_window_title();

#endregion