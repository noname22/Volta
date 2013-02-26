//T compiles:yes
//T retval:42
// Most basic test.
module test_001;

import object;



struct vrt_eh_try_store
{
	vrt_eh_try_store* prev;
	char[200] jmp_buf;
}

extern(C) int _setjmp(void*);

class Exception
{
	this() { return; }
}

import core.stdc.stdio;

void test(int i)
{
	/*
	try {
		printf("try\n".ptr);
		if (i == 1)
			throw new Exception();
		printf("no throw\n".ptr);
	} catch (Exception e) {
		printf("catch %p\n".ptr, e);
	} finally {
		printf("finally\n".ptr);
	}
	*/

	vrt_eh_try_store s;
	vrt_eh_begin_try(&s);
	if (!_setjmp(&s.jmp_buf)) {
		printf("try\n".ptr);
		if (i == 1)
			vrt_eh_throw(new Exception());
		printf("no throw\n".ptr);
		vrt_eh_end_try(&s);
	} else {
		auto obj = vrt_eh_current();
		auto e = cast(Exception)obj;
		if (e !is null) {
			vrt_eh_handled();
			printf("catch %p\n".ptr, e);
		}
	}
	{
		printf("finally\n".ptr);
		vrt_eh_rethrow();
	}
	return;
}

int main()
{
	test(1);
	test(2);
	return 42;
}
