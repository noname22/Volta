// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.ir.util;

import std.conv : to;

import volt.exceptions;
import volt.interfaces;
import volt.token.location;
import ir = volt.ir.ir;


/**
 * Builds a QualifiedName from a string.
 */
ir.QualifiedName buildQualifiedName(Location loc, string value)
{
	auto i = new ir.Identifier(value);
	i.location = loc;
	auto q = new ir.QualifiedName();
	q.identifiers = [i];
	q.location = loc;
	return q;
}

/**
 * Builds a QualifiedName from a Identifier.
 */
ir.QualifiedName buildQualifiedNameSmart(ir.Identifier i)
{
	auto q = new ir.QualifiedName();
	q.identifiers = [new ir.Identifier(i)];
	q.location = i.location;
	return q;
}

/**
 * Return the scope from the given type if it is,
 * a aggregate or a derivative from one.
 */
ir.Scope getScopeFromType(ir.Type type)
{
	switch (type.nodeType) with (ir.NodeType) {
	case TypeReference:
		auto asTypeRef = cast(ir.TypeReference) type;
		assert(asTypeRef !is null);
		assert(asTypeRef.type !is null);
		return getScopeFromType(asTypeRef.type);
	case ArrayType:
		auto asArray = cast(ir.ArrayType) type;
		assert(asArray !is null);
		return getScopeFromType(asArray.base);
	case PointerType:
		auto asPointer = cast(ir.PointerType) type;
		assert(asPointer !is null);
		return getScopeFromType(asPointer.base);
	case Struct:
		auto asStruct = cast(ir.Struct) type;
		assert(asStruct !is null);
		return asStruct.myScope;
	case Class:
		auto asClass = cast(ir.Class) type;
		assert(asClass !is null);
		return asClass.myScope;
	case Interface:
		auto asInterface = cast(ir._Interface) type;
		assert(asInterface !is null);
		return asInterface.myScope;
	default:
		return null;
	}
}

/**
 * For the give store get the scoep that it introduces.
 *
 * Returns null for Values and non-scope types.
 */
ir.Scope getScopeFromStore(ir.Store store)
{
	final switch(store.kind) with (ir.Store.Kind) {
	case Scope:
		return store.s;
	case Type:
		auto type = cast(ir.Type)store.node;
		assert(type !is null);
		return getScopeFromType(type);
	case Value:
	case Function:
		return null;
	case Alias:
		throw CompilerPanic(store.node.location, "unresolved alias");
	}
}

/**
 * Does a smart copy of a type.
 *
 * Meaning that well copy all types, but skipping
 * TypeReferences, but inserting one when it comes
 * across a named type.
 */
ir.Type copyTypeSmart(Location loc, ir.Type type)
{
	switch (type.nodeType) with (ir.NodeType) {
	case PrimitiveType:
		auto pt = cast(ir.PrimitiveType)type;
		pt.location = loc;
		pt = new ir.PrimitiveType(pt.type);
		return pt;
	case PointerType:
		auto pt = cast(ir.PointerType)type;
		pt.location = loc;
		pt = new ir.PointerType(copyTypeSmart(loc, pt.base));
		return pt;
	case ArrayType:
		auto at = cast(ir.ArrayType)type;
		at.location = loc;
		at = new ir.ArrayType(copyTypeSmart(loc, at.base));
		return at;
	case StaticArrayType:
		auto asSat = cast(ir.StaticArrayType)type;
		auto sat = new ir.StaticArrayType();
		sat.location = loc;
		sat.base = copyTypeSmart(loc, asSat.base);
		sat.length = asSat.length;
		return sat;
	case AAType:
		auto asAA = cast(ir.AAType)type;
		auto aa = new ir.AAType();
		aa.location = loc;
		aa.value = copyTypeSmart(loc, asAA.value);
		aa.key = copyTypeSmart(loc, asAA.key);
		return aa;
	case FunctionType:
		auto asFt = cast(ir.FunctionType)type;
		auto ft = new ir.FunctionType(asFt);
		ft.location = loc;
		ft.ret = copyTypeSmart(loc, ft.ret);
		foreach(ref var; ft.params) {
			auto t = copyTypeSmart(loc, var.type);
			var = new ir.Variable();
			var.location = loc;
			var.type = t;
		}
		return ft;
	case DelegateType:
		auto asDg = cast(ir.DelegateType)type;
		auto dg = new ir.DelegateType(asDg);
		dg.location = loc;
		dg.ret = copyTypeSmart(loc, dg.ret);
		foreach(ref var; dg.params) {
			auto t = copyTypeSmart(loc, var.type);
			var = new ir.Variable();
			var.location = loc;
			var.type = t;
		}
		return dg;
	case StorageType:
		auto asSt = cast(ir.StorageType)type;
		auto st = new ir.StorageType();
		st.location = loc;
		st.base = copyTypeSmart(loc, asSt.base);
		st.type = asSt.type;
		return st;
	case TypeReference:
		auto tr = cast(ir.TypeReference)type;
		return copyTypeSmart(loc, tr.type);
	case Interface:
	case Struct:
	case Class:
	case Enum:
		auto s = getScopeFromType(type);
		auto tr = new ir.TypeReference(type, null);
		tr.location = loc;
		/// @todo Get fully qualified name for type.
		if (s !is null)
			tr.names = [s.name];
		return tr;
	default:
		assert(false);
	}
}

ir.StorageType buildStorageType(Location loc, ir.StorageType.Kind kind, ir.Type base)
{
	auto storage = new ir.StorageType();
	storage.location = loc;
	storage.type = kind;
	storage.base = base;
	return storage;
}

/**
 * Build a PrimitiveType.
 */
ir.PrimitiveType buildPrimitiveType(Location loc, ir.PrimitiveType.Kind kind)
{
	auto pt = new ir.PrimitiveType(kind);
	pt.location = loc;
	return pt;
}

ir.PrimitiveType buildVoid(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Void); }
ir.PrimitiveType buildBool(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Bool); }
ir.PrimitiveType buildChar(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Char); }
ir.PrimitiveType buildByte(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Byte); }
ir.PrimitiveType buildUbyte(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Ubyte); }
ir.PrimitiveType buildShort(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Short); }
ir.PrimitiveType buildUshort(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Ushort); }
ir.PrimitiveType buildInt(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Int); }
ir.PrimitiveType buildUint(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Uint); }
ir.PrimitiveType buildLong(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Long); }
ir.PrimitiveType buildUlong(Location loc) { return buildPrimitiveType(loc, ir.PrimitiveType.Kind.Ulong); }
ir.PrimitiveType buildSizeT(Location loc, LanguagePass lp) { return lp.settings.getSizeT(loc); }

/**
 * Build a void* type.
 */
ir.PointerType buildVoidPtr(Location loc)
{
	auto pt = new ir.PointerType(buildVoid(loc));
	pt.location = loc;

	return pt;
}

ir.PointerType buildPtrSmart(Location loc, ir.Type base)
{
	auto pt = new ir.PointerType(copyTypeSmart(loc, base));
	pt.location = loc;

	return pt;
}

ir.ArrayLiteral buildArrayLiteralSmart(Location loc, ir.Type type, ir.Exp[] exps...)
{
	auto literal = new ir.ArrayLiteral();
	literal.location = loc;
	literal.type = copyTypeSmart(loc, type);
	literal.values = exps.dup;
	return literal;
}

/**
 * Build a Variable, while not being smart about its type.
 */
ir.Variable buildVariable(Location loc, ir.Type type, string name)
{
	auto var = new ir.Variable();
	var.location = loc;
	var.name = name;
	var.type = type;

	return var;
}

/**
 * Copy a Variable, while being smart about its type, does
 * not copy the the assign exp on the Variable.
 */
ir.Variable copyVariableSmart(Location loc, ir.Variable right)
{
	return buildVariable(loc, copyTypeSmart(loc, right.type), right.name);
}

ir.Variable[] copyVariablesSmart(Location loc, ir.Variable[] vars)
{
	auto outVars = new ir.Variable[vars.length];
	foreach (i, var; vars) {
		outVars[i] = copyVariableSmart(loc, var);
	}
	return outVars;
}

/**
 * Get ExpReferences from a list of variables.
 */
ir.Exp[] getExpRefs(Location loc, ir.Variable[] vars)
{
	auto erefs = new ir.Exp[vars.length];
	foreach (i, var; vars) {
		erefs[i] = buildExpReference(loc, var, var.name);
	}
	return erefs;
}

/**
 * Build a Variable, while being smart about its type.
 */
ir.Variable buildVariableSmart(Location loc, ir.Type type, string name)
{
	return buildVariable(loc, copyTypeSmart(loc, type), name);
}

/**
 * Builds a usable ExpReference.
 */
ir.ExpReference buildExpReference(Location loc, ir.Declaration decl, string[] names...)
{
	auto varRef = new ir.ExpReference();
	varRef.location = loc;
	varRef.decl = decl;
	varRef.idents ~= names;

	return varRef;
}

/**
 * Builds a constant int.
 */
ir.Constant buildConstantInt(Location loc, int value)
{
	auto c = new ir.Constant();
	c.location = loc;
	c._int = value;
	c.type = buildInt(loc);

	return c;
}

/**
 * Builds a constant bool.
 */
ir.Constant buildConstantBool(Location loc, bool val)
{
	auto c = new ir.Constant();
	c.location = loc;
	c._bool = val;
	c.type = buildBool(loc);

	return c;
}

ir.Constant buildConstantNull(Location loc, ir.Type base)
{
	auto c = new ir.Constant();
	c.location = loc;
	c._pointer = null;
	c.type = copyTypeSmart(loc, base);
	c.type.location = loc;
	c.isNull = true;
	return c;
}

/**
 * Gets a size_t Constant and fills it with a value.
 */
ir.Constant buildSizeTConstant(Location loc, LanguagePass lp, int val)
{
	auto c = new ir.Constant();
	c.location = loc;
	auto prim = lp.settings.getSizeT(loc);
	// Uh, I assume just c._uint = val would work, but I can't test it here, so just be safe.
	if (prim.type == ir.PrimitiveType.Kind.Ulong) {
		c._ulong = val;
	} else {
		c._uint = val;
	}
	c.type = prim;
	return c;
}

ir.Constant buildTrue(Location loc) { return buildConstantBool(loc, true); }
ir.Constant buildFalse(Location loc) { return buildConstantBool(loc, false); }

/**
 * Build a cast and sets the location, does not call copyTypeSmart.
 */
ir.Unary buildCast(Location loc, ir.Type type, ir.Exp exp)
{
	auto cst = new ir.Unary(type, exp);
	cst.location = loc;
	return cst;
}

/**
 * Build a cast, sets the location and calling copyTypeSmart
 * on the type, to avoid duplicate nodes.
 */
ir.Unary buildCastSmart(Location loc, ir.Type type, ir.Exp exp)
{
	return buildCast(loc, copyTypeSmart(loc, type), exp);
}

ir.Unary buildCastToBool(Location loc, ir.Exp exp) { return buildCast(loc, buildBool(loc), exp); }
ir.Unary buildCastToVoidPtr(Location loc, ir.Exp exp) { return buildCast(loc, buildVoidPtr(loc), exp); }

/**
 * Builds an AddrOf expression.
 */
ir.Unary buildAddrOf(Location loc, ir.Exp exp)
{
	auto addr = new ir.Unary();
	addr.location = loc;
	addr.op = ir.Unary.Op.AddrOf;
	addr.value = exp;
	return addr;
}

/**
 * Builds a ExpReference and a AddrOf from a Variable.
 */
ir.Unary buildAddrOf(Location loc, ir.Variable var, string[] names...)
{
	return buildAddrOf(loc, buildExpReference(loc, var, names));
}

/**
 * Builds a Dereference expression.
 */
ir.Unary buildDeref(Location loc, ir.Exp exp)
{
	auto deref = new ir.Unary();
	deref.location = loc;
	deref.op = ir.Unary.Op.Dereference;
	deref.value = exp;
	return deref;
}

/**
 * Builds a typeid with type smartly.
 */
ir.Typeid buildTypeidSmart(Location loc, ir.Type type)
{
	auto t = new ir.Typeid();
	t.location = loc;
	t.type = copyTypeSmart(loc, type);
	return t;
}

/**
 * Build a postfix Identifier expression.
 */
ir.Postfix buildAccess(Location loc, ir.Exp exp, string name)
{
	auto access = new ir.Postfix();
	access.location = loc;
	access.op = ir.Postfix.Op.Identifier;
	access.child = exp;
	access.identifier = new ir.Identifier();
	access.identifier.location = loc;
	access.identifier.value = name;

	return access;
}

/**
 * Builds a postfix slice.
 */
ir.Postfix buildSlice(Location loc, ir.Exp child, ir.Exp[] args)
{
	auto slice = new ir.Postfix();
	slice.location = loc;
	slice.op = ir.Postfix.Op.Slice;
	slice.child = child;
	slice.arguments = args;

	return slice;
}

/**
 * Builds a postfix call.
 */
ir.Postfix buildCall(Location loc, ir.Exp child, ir.Exp[] args)
{
	auto call = new ir.Postfix();
	call.location = loc;
	call.op = ir.Postfix.Op.Call;
	call.child = child;
	call.arguments = args;

	return call;
}

ir.Postfix buildMemberCall(Location loc, ir.Exp child, ir.ExpReference fn, string name, ir.Exp[] args)
{
	auto lookup = new ir.Postfix();
	lookup.location = loc;
	lookup.op = ir.Postfix.Op.CreateDelegate;
	lookup.child = child;
	lookup.identifier = new ir.Identifier();
	lookup.identifier.location = loc;
	lookup.identifier.value = name;
	lookup.memberFunction = fn;

	auto call = new ir.Postfix();
	call.location = loc;
	call.op = ir.Postfix.Op.Call;
	call.child = lookup;
	call.arguments = args;

	return call;
}

/**
 * Builds a postfix call.
 */
ir.Postfix buildCall(Location loc, ir.Declaration decl, ir.Exp[] args, string[] names...)
{
	return buildCall(loc, buildExpReference(loc, decl, names), args);
}


/**
 * Builds an add BinOp.
 */
ir.BinOp buildAdd(Location loc, ir.Exp left, ir.Exp right)
{
	return buildBinOp(loc, ir.BinOp.Type.Add, left, right);
}

/**
 * Builds an assign BinOp.
 */
ir.BinOp buildAssign(Location loc, ir.Exp left, ir.Exp right)
{
	return buildBinOp(loc, ir.BinOp.Type.Assign, left, right);
}

/**
 * Builds an BinOp.
 */
ir.BinOp buildBinOp(Location loc, ir.BinOp.Type op, ir.Exp left, ir.Exp right)
{
	auto binop = new ir.BinOp();
	binop.location = loc;
	binop.op = op;
	binop.left = left;
	binop.right = right;
	return binop;
}

/**
 * Adds a variable argument to a function, also adds it to the scope.
 */
ir.Variable addParam(Location loc, ir.Function fn, ir.Type type, string name)
{
	auto var = buildVariable(loc, type, name);
	fn.type.params ~= var;
	fn.myScope.addValue(var, name);
	return var;
}

/**
 * Adds a variable argument to a function, also adds it to the scope.
 */
ir.Variable addParamSmart(Location loc, ir.Function fn, ir.Type type, string name)
{
	return addParam(loc, fn, copyTypeSmart(loc, type), name);
}

/**
 * Builds a variable statement smartly, inserting at the end of the
 * block statements and inserting it in the scope.
 */
ir.Variable buildVarStatSmart(Location loc, ir.BlockStatement block, ir.Scope _scope, ir.Type type, string name)
{
	auto var = buildVariableSmart(loc, type, name);
	block.statements ~= var;
	_scope.addValue(var, name);
	return var;
}

/**
 * Build a exp statement.
 */
ir.ExpStatement buildExpStat(Location loc, ir.BlockStatement block, ir.Exp exp)
{
	auto ret = new ir.ExpStatement();
	ret.location = loc;
	ret.exp = exp;

	block.statements ~= ret;

	return ret;
}
/**
 * Build a return statement.
 */
ir.ReturnStatement buildReturn(Location loc, ir.BlockStatement block, ir.Exp exp = null)
{
	auto ret = new ir.ReturnStatement();
	ret.location = loc;
	ret.exp = exp;

	block.statements ~= ret;

	return ret;
}

/**
 * Builds a completely useable Function and insert it into the
 * various places it needs to be inserted.
 */
ir.Function buildFunction(Location loc, ir.TopLevelBlock tlb, ir.Scope _scope, string name, bool buildBody = true)
{
	auto fn = new ir.Function();
	fn.name = name;
	fn.myScope = new ir.Scope(_scope, fn, name);
	fn.location = loc;

	fn.type = new ir.FunctionType();
	fn.type.location = loc;
	fn.type.ret = new ir.PrimitiveType(ir.PrimitiveType.Kind.Void);
	fn.type.ret.location = loc;

	if (buildBody) {
		fn._body = new ir.BlockStatement();
		fn._body.location = loc;
	}

	// Insert the struct into all the places.
	_scope.addFunction(fn, fn.name);
	tlb.nodes ~= fn;
	return fn;
}

/**
 * Builds a alias from a string and a Identifier.
 */
ir.Alias buildAliasSmart(Location loc, string name, ir.Identifier i)
{
	auto a = new ir.Alias();
	a.name = name;
	a.location = loc;
	a.id = buildQualifiedNameSmart(i);
	return a;
}

/**
 * Builds a alias from two strings.
 */
ir.Alias buildAlias(Location loc, string name, string from)
{
	auto a = new ir.Alias();
	a.name = name;
	a.location = loc;
	a.id = buildQualifiedName(loc, from);
	return a;
}

/**
 * Builds a completely useable struct and insert it into the
 * various places it needs to be inserted.
 *
 * The members list is used directly in the new struct; be wary not to duplicate IR nodes.
 */
ir.Struct buildStruct(Location loc, ir.TopLevelBlock tlb, ir.Scope _scope, string name, ir.Variable[] members...)
{
	auto s = new ir.Struct();
	s.name = name;
	s.myScope = new ir.Scope(_scope, s, name);
	s.location = loc;

	s.members = new ir.TopLevelBlock();
	s.members.location = loc;

	foreach (member; members) {
		s.members.nodes ~= member;
		s.myScope.addValue(member, member.name);
	}

	// Insert the struct into all the places.
	_scope.addType(s, s.name);
	tlb.nodes ~= s;
	return s;
}

/*
 * Functions who takes the location from the given exp.
 */
ir.Unary buildCastSmart(ir.Type type, ir.Exp exp) { return buildCastSmart(exp.location, type, exp); }
ir.Unary buildAddrOf(ir.Exp exp) { return buildAddrOf(exp.location, exp); }
ir.Unary buildCastToBool(ir.Exp exp) { return buildCastToBool(exp.location, exp); }
