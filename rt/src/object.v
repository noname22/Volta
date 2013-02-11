// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module object;

/**
 * This is all up in the air. But here is how its intended to work.
 *
 * @param typeinfo The type to which we should allocate storage for.
 * @param count the number of elements in a array, zero if just the type.
 *
 * The count logic is a bit odd. If count is zero we are allocating the
 * storage for just the type alone, if count is greater then one we are
 * allocating the storage an array of that type. Here how it is done,
 * Thow following shows what happends for some cases.
 *
 * For primitive types:
 * int* ptr = new int;
 * int* ptr = allocDg(typeid(int), 0);
 * // Alloc size == int.sizeof == 4
 *
 * While for arrays:
 * int[] arr; arr.length = 5;
 * int[] arr; { arr.ptr = allocDg(typeid(int), 5); arr.length = 5 }
 * // Alloc size == int.sizeof * 5 == 20
 *
 * Classes are weird, tho in the normal case not so much but notice the -1.
 * Clazz foo = new Clazz();
 * Clazz foo = allocDg(typeid(Clazz), cast(size_t)-1);
 * // Alloc size == Clazz.storage.sizeof
 *
 * Here its where it gets weird: this is because classes are references.
 * Clazz foo = new Clazz;
 * Clazz foo = allocDg(typeid(Clazz), 0);
 * // Alloc size == (void*).sizeof
 *
 * And going from that this makes sense.
 * Clazz[] arr; arr.length = 3;
 * Clazz[] arr; { arr.ptr = allocDg(typeid(Clazz), 3); arr.length = 3 }
 * // Alloc size == (void*).sizeof * 3
 */
alias AllocDg = void* delegate(TypeInfo typeinfo, size_t count);


local AllocDg allocDg;

extern(C) AllocDg vrt_gc_get_alloc_dg();

extern(C) void vrt_gc_init();

struct ArrayStruct
{
	void* ptr;
	size_t length;
}

class TypeInfo
{
	this()
	{
		return;
	}

	size_t size;
	int type;
	char[] mangledName;
	bool mutableIndirection;
	void* classVtable;
}

class Object
{
	this()
	{
		return;
	}

	void* __castTo(TypeInfo tinfo)
	{
		auto list = **cast(TypeInfo[]**)this;
		for (size_t i = 0u; i < list.length; i = i + 1u) {
			if (list[i] is tinfo) {
				return cast(void*) this;
			}
		}
		return null;
	}
}
