// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module vrt.eh;


struct TryStore
{
	TryStore* prev;

	version (Linux) {
		version (X86) {
			char[156] buf;
		} else version (X86_64) {
			char[200] buf;
		} else {
			static assert(false);
		}
	} else version (Windows) {
		version (X86) {
			char[64] buf;
		} else {
			static assert(false);
		}
	} else {
		static assert(false);
	}
}

local TryStore* currentTry;
local object.Object currentException;

extern(C) int _setjmp(void*);
extern(C) void longjmp(void*, int);

extern(C) void vrt_eh_throw(object.Object obj)
{
	currentException = obj;

	auto dest = currentTry;
	currentTry = dest.prev;
	longjmp(&dest.buf, 1);
	return;
}

extern(C) void vrt_eh_rethrow()
{
	if (currentException is null)
		return;

	auto dest = currentTry;
	currentTry = dest.prev;
	longjmp(&dest.buf, 1);
	return;
}

extern(C) object.Object vrt_eh_current()
{
	return currentException;
}

extern(C) void vrt_eh_handled()
{
	currentException = null;
	return;
}

extern(C) void vrt_eh_begin_try(TryStore* s)
{
	s.prev = currentTry;
	currentTry = s;
	return;
}

extern(C) void vrt_eh_end_try(TryStore* s)
{
	currentTry = currentTry.prev;
	return;
}
