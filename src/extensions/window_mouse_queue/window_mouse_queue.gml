#define window_mouse_queue_init
switch (window_mouse_queue_init_raw(window_handle())) {
    case 1: break;
    case 0: show_debug_message("window_mouse_queue is not loaded"); break;
}

#define window_mouse_queue_get
/// (xlist:ds_list<number>, ylist:ds_list<number>)->int
var _x_list = argument0, _y_list = argument1;
var _len = window_mouse_queue_get_1();
if (_len == 0) return 0;

var _size = _len * 8;
gml_pragma("global", "global.__window_mouse_queue_buffer = undefined");
var _buf = global.__window_mouse_queue_buffer;
if (_buf == undefined) {
    _buf = buffer_create(_size, buffer_grow, 1);
    global.__window_mouse_queue_buffer = _buf;
} else if (buffer_get_size(_buf) < _size) {
    buffer_resize(_buf, _size);
}

window_mouse_queue_get_2(buffer_get_address(_buf));
buffer_seek(_buf, buffer_seek_start, 0);
for (var i = 0; i < _len; i++) {
    ds_list_add(_x_list, buffer_read(_buf, buffer_s32) - window_get_x());
    ds_list_add(_y_list, buffer_read(_buf, buffer_s32) - window_get_y());
}
return _len;

/*#define window_mouse_queue_prepare_buffer
/// (size:int)->buffer~
#args _size
gml_pragma("global", "global.__window_mouse_queue_buffer = undefined");
var _buf = global.__window_mouse_queue_buffer;
if (_buf == undefined) {
    _buf = buffer_create(_size, buffer_grow, 1);
    global.__window_mouse_queue_buffer = _buf;
} else if (buffer_get_size(_buf) < _size) {
    buffer_resize(_buf, _size);
}
buffer_seek(_buf, buffer_seek_start, 0);
return _buf;*/