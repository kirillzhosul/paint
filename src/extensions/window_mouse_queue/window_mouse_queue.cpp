#pragma once
#include "stdafx.h"
#include <vector>
#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
#include <optional>
#endif
#include <stdint.h>
#include <cstring>
#include <tuple>
using namespace std;

#define dllg /* tag */

#if defined(WIN32)
#define dllx extern "C" __declspec(dllexport)
#elif defined(GNUC)
#define dllx extern "C" __attribute__ ((visibility("default"))) 
#else
#define dllx extern "C"
#endif

#ifdef _WINDEF_
typedef HWND GAME_HWND;
#endif

struct gml_buffer {
private:
	uint8_t* _data;
	int32_t _size;
	int32_t _tell;
public:
	gml_buffer() : _data(nullptr), _tell(0), _size(0) {}
	gml_buffer(uint8_t* data, int32_t size, int32_t tell) : _data(data), _size(size), _tell(tell) {}

	inline uint8_t* data() { return _data; }
	inline int32_t tell() { return _tell; }
	inline int32_t size() { return _size; }
};

class gml_istream {
	uint8_t* pos;
	uint8_t* start;
public:
	gml_istream(void* origin) : pos((uint8_t*)origin), start((uint8_t*)origin) {}

	template<class T> T read() {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be read");
		T result{};
		std::memcpy(&result, pos, sizeof(T));
		pos += sizeof(T);
		return result;
	}

	char* read_string() {
		char* r = (char*)pos;
		while (*pos != 0) pos++;
		pos++;
		return r;
	}

	template<class T> std::vector<T> read_vector() {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be read");
		auto n = read<uint32_t>();
		std::vector<T> vec(n);
		std::memcpy(vec.data(), pos, sizeof(T) * n);
		pos += sizeof(T) * n;
		return vec;
	}

	gml_buffer read_gml_buffer() {
		auto _data = (uint8_t*)read<int64_t>();
		auto _size = read<int32_t>();
		auto _tell = read<int32_t>();
		return gml_buffer(_data, _size, _tell);
	}

	#pragma region Tuples
	#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
	template<typename... Args>
	std::tuple<Args...> read_tuple() {
		std::tuple<Args...> tup;
		std::apply([this](auto&&... arg) {
			((
				arg = this->read<std::remove_reference_t<decltype(arg)>>()
				), ...);
			}, tup);
		return tup;
	}

	template<class T> optional<T> read_optional() {
		if (read<bool>()) {
			return read<T>;
		} else return {};
	}
	#else
	template<class A, class B> std::tuple<A, B> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		return std::tuple<A, B>(a, b);
	}

	template<class A, class B, class C> std::tuple<A, B, C> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		C c = read<C>();
		return std::tuple<A, B, C>(a, b, c);
	}

	template<class A, class B, class C, class D> std::tuple<A, B, C, D> read_tuple() {
		A a = read<A>();
		B b = read<B>();
		C c = read<C>();
		D d = read<d>();
		return std::tuple<A, B, C, D>(a, b, c, d);
	}
	#endif
};

class gml_ostream {
	uint8_t* pos;
	uint8_t* start;
public:
	gml_ostream(void* origin) : pos((uint8_t*)origin), start((uint8_t*)origin) {}

	template<class T> void write(T val) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		memcpy(pos, &val, sizeof(T));
		pos += sizeof(T);
	}

	void write_string(const char* s) {
		for (int i = 0; s[i] != 0; i++) write<char>(s[i]);
		write<char>(0);
	}

	template<class T> void write_vector(std::vector<T>& vec) {
		static_assert(std::is_trivially_copyable_v<T>, "T must be trivially copyable to be write");
		auto n = vec.size();
		write<uint32_t>(n);
		memcpy(pos, vec.data(), n * sizeof(T));
		pos += n * sizeof(T);
	}

	#if ((defined(_MSVC_LANG) && _MSVC_LANG >= 201703L) || __cplusplus >= 201703L)
	template<typename... Args>
	void write_tuple(std::tuple<Args...> tup) {
		std::apply([this](auto&&... arg) {
			(this->write(arg), ...);
			}, tup);
	}

	template<class T> void write_optional(optional<T>& val) {
		auto hasValue = val.has_value();
		write<bool>(hasValue);
		if (hasValue) write<T>(val.value());
	}
	#else
	template<class A, class B> void write_tuple(std::tuple<A, B>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
	}
	template<class A, class B, class C> void write_tuple(std::tuple<A, B, C>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
		write<C>(std::get<2>(tup));
	}
	template<class A, class B, class C, class D> void write_tuple(std::tuple<A, B, C, D>& tup) {
		write<A>(std::get<0>(tup));
		write<B>(std::get<1>(tup));
		write<C>(std::get<2>(tup));
		write<D>(std::get<3>(tup));
	}
	#endif
};
//{{NO_DEPENDENCIES}}
// Microsoft Visual C++ generated include file.
// Used by window_mouse_queue.rc

// Next default values for new objects
// 
#ifdef APSTUDIO_INVOKED
#ifndef APSTUDIO_READONLY_SYMBOLS
#define _APS_NEXT_RESOURCE_VALUE        101
#define _APS_NEXT_COMMAND_VALUE         40001
#define _APS_NEXT_CONTROL_VALUE         1001
#define _APS_NEXT_SYMED_VALUE           101
#endif
#endif
// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#ifdef _WINDOWS
	#include "targetver.h"
	
	#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
	#include <windows.h>
#endif

#if defined(WIN32)
#define dllx extern "C" __declspec(dllexport)
#elif defined(GNUC)
#define dllx extern "C" __attribute__ ((visibility("default"))) 
#else
#define dllx extern "C"
#endif

#define _trace // requires user32.lib;Kernel32.lib

#ifdef _trace
#ifdef _WINDOWS
void trace(const char* format, ...);
#else
#define trace(...) { printf("[window_mouse_queue:%d] ", __LINE__); printf(__VA_ARGS__); printf("\n"); fflush(stdout); }
#endif
#endif

#include "gml_ext.h"

// TODO: reference additional headers your program requires here

void yal_memset(void* at, int fill, size_t len);

void* yal_alloc(size_t bytes);
template<typename T> T* yal_alloc_arr(size_t count = 1) {
	return (T*)yal_alloc(sizeof(T) * count);
}
void* yal_realloc(void* thing, size_t bytes);
template<typename T> T* yal_realloc_arr(T* arr, size_t count) {
	return (T*)yal_realloc(arr, sizeof(T) * count);
}
bool yal_free(void* thing);

template<typename T> class yal_vector {
private:
	T* arr = nullptr;
	size_t len = 0;
	size_t capacity = 0;
public:
	yal_vector() {
		//
	}
	void init(size_t _capacity = 4) {
		arr = yal_alloc_arr<T>(_capacity);
		capacity = _capacity;
		len = 0;
	}
	void clear() {
		len = 0;
	}
	T* data() {
		return arr;
	}
	size_t size() {
		return len;
	}
	void push_back(T val) {
		if (len >= capacity) {
			capacity *= 2;
			arr = yal_realloc_arr(arr, capacity);
		}
		arr[len++] = val;
	}
};#pragma once

// Including SDKDDKVer.h defines the highest available Windows platform.

// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.

#include <SDKDDKVer.h>
#include "gml_ext.h"
// stdafx.cpp : source file that includes just the standard includes
// window_mouse_queue.pch will be the pre-compiled header
// stdafx.obj will contain the pre-compiled type information

#include "stdafx.h"
#include <strsafe.h>

#if _WINDOWS
// http://computer-programming-forum.com/7-vc.net/07649664cea3e3d7.htm
extern "C" int _fltused = 0;
#endif

// TODO: reference any additional headers you need in STDAFX.H
// and not in this file
#ifdef _trace
#ifdef _WINDOWS
// https://yal.cc/printf-without-standard-library/
void trace(const char* pszFormat, ...) {
	char buf[1025];
	va_list argList;
	va_start(argList, pszFormat);
	wvsprintfA(buf, pszFormat, argList);
	va_end(argList);
	DWORD done;
	auto len = strlen(buf);
	buf[len] = '\n';
	buf[++len] = 0;
	WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), buf, len, &done, NULL);
}
#endif
#endif

void yal_memset(void* at, int fill, size_t len) {
	auto ptr = (uint8_t*)at;
	while (len != 0) {
		*ptr++ = (uint8_t)fill;
		len = (len - 1) & 0x7FFFFFFFu; // can't be just len-- or compiler will optimize this to a std memset
	}
}

void* yal_alloc(size_t bytes) {
	return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, bytes);
}
void* yal_realloc(void* thing, size_t bytes) {
	return HeapReAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, thing, bytes);
}
bool yal_free(void* thing) {
	return HeapFree(GetProcessHeap(), 0, thing);
}
/// @author YellowAfterlife

#include "stdafx.h"
#include <Windowsx.h>

struct mouse_point {
	int x;
	int y;
};
yal_vector<mouse_point> window_mouse_queue{};
POINT ptLast;
DWORD tmLast;

static WNDPROC wndProc_base = NULL;
static LRESULT wndProc_hook(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	if (msg == WM_MOUSEMOVE) {
		int nVirtualWidth = GetSystemMetrics(SM_CXVIRTUALSCREEN);
		int nVirtualHeight = GetSystemMetrics(SM_CYVIRTUALSCREEN);
		int nVirtualLeft = GetSystemMetrics(SM_XVIRTUALSCREEN);
		int nVirtualTop = GetSystemMetrics(SM_YVIRTUALSCREEN);
		int mode = GMMP_USE_DISPLAY_POINTS;

		POINT localPoint;
		localPoint.x = GET_X_LPARAM(lParam);
		localPoint.y = GET_Y_LPARAM(lParam);
		POINT screenPoint = localPoint;
		ClientToScreen(hwnd, &screenPoint);

		MOUSEMOVEPOINT mp_in;
		mp_in.x = screenPoint.x & 0x0000FFFF; // "Ensure that this number will pass through."?
		mp_in.y = screenPoint.y & 0x0000FFFF;
		mp_in.time = GetMessageTime();

		MOUSEMOVEPOINT mp_out[64];
		//yal_memset(mp_out, 0, sizeof mp_out);

		int cpt = GetMouseMovePointsEx(sizeof MOUSEMOVEPOINT, &mp_in, mp_out, 64, mode);
		for (int i = cpt - 1; i >= 0; i--) {
			auto& mp = mp_out[i];
			auto ok = mp.time >= tmLast;
			//trace("tm_out %d: %d,%d t=%d lt=%d %d", i, mp.x, mp.y, mp.time, tmLast, ok);
			if (!ok) continue;
			if (mode == GMMP_USE_DISPLAY_POINTS) {
				if (mp.x >= 0x8000) mp.x -= 0x10000;
				if (mp.y >= 0x8000) mp.y -= 0x10000;
			} else if (mode == GMMP_USE_HIGH_RESOLUTION_POINTS) {
				mp.x = ((mp.x * (nVirtualWidth - 1)) - (nVirtualLeft * 65536)) / nVirtualWidth;
				mp.y = ((mp.y * (nVirtualHeight - 1)) - (nVirtualTop * 65536)) / nVirtualHeight;
			}
			//
			mouse_point p;
			p.x = mp.x;
			p.y = mp.y;
			window_mouse_queue.push_back(p);
		}
		tmLast = mp_in.time;
		ptLast.x = mp_in.x;
		ptLast.y = mp_in.y;
	}
	return wndProc_base(hwnd, msg, wParam, lParam);
}

dllx double window_mouse_queue_init_raw(void* hwnd) {
	tmLast = 0;
	ptLast = {};
	window_mouse_queue.init(16);
	wndProc_base = (WNDPROC)SetWindowLongPtr((HWND)hwnd, GWLP_WNDPROC, (LONG_PTR)wndProc_hook);
	return 1;
}
dllx double window_mouse_queue_get_1() {
	return window_mouse_queue.size();
}
dllx double window_mouse_queue_get_2(mouse_point* dst) {
	auto src = window_mouse_queue.data();
	auto len = window_mouse_queue.size();
	for (auto i = 0u; i < len; i++) {
		dst[i] = src[i];
	}
	window_mouse_queue.clear();
	return len;
}
///
dllx double window_mouse_queue_clear() {
	window_mouse_queue.clear();
	return 1;
}