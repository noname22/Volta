// Copyright © 2012-2013, Bernard Helyer.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.semantic.typeidreplacer;

import std.string : format;

import ir = volt.ir.ir;
import volt.ir.util;

import volt.exceptions;
import volt.interfaces;
import volt.visitor.visitor;
import volt.semantic.classify;
import volt.semantic.lookup;
import volt.semantic.mangle;


/**
 * Replaces typeid(...) expressions with a call
 * to the TypeInfo's constructor.
 */
class TypeidReplacer : NullVisitor, Pass
{
public:
	LanguagePass lp;

	ir.Class typeinfo;
	ir.Struct typeinfoVtable;
	ir.Module thisModule;

public:
	this(LanguagePass lp)
	{
		this.lp = lp;
	}

	override void transform(ir.Module m)
	{
		thisModule = m;
		typeinfo = retrieveTypeInfo(lp, m.myScope, m.location);
		assert(typeinfo !is null);
		accept(m, this);
	}

	override void close()
	{
	}

	override Status enter(ref ir.Exp exp, ir.Typeid _typeid)
	{
		assert(_typeid.type !is null);

		_typeid.type.mangledName = mangle(_typeid.type);
		string name = "_V__TypeInfo_" ~ _typeid.type.mangledName;
		auto typeidStore = lookupOnlyThisScope(lp, thisModule.myScope, exp.location, name);
		if (typeidStore !is null) {
			auto asVar = cast(ir.Variable) typeidStore.node;
			exp = buildExpReference(exp.location, asVar, asVar.name);
			return Continue;
		}

		int typeSize = size(_typeid.location, lp, _typeid.type);
		auto typeConstant = buildSizeTConstant(_typeid.location, lp, typeSize);

		int typeTag = _typeid.type.nodeType;
		auto typeTagConstant = new ir.Constant();
		typeTagConstant.location = _typeid.location;
		typeTagConstant._int = typeTag;
		typeTagConstant.type = new ir.PrimitiveType(ir.PrimitiveType.Kind.Int);
		typeTagConstant.type.location = _typeid.location;

		auto mangledNameConstant = new ir.Constant();
		mangledNameConstant.location = _typeid.location;
		auto _scope = getScopeFromType(_typeid.type);
		mangledNameConstant._string = mangle(_typeid.type);
		mangledNameConstant.arrayData = cast(void[]) mangledNameConstant._string;
		mangledNameConstant.type = new ir.ArrayType(new ir.PrimitiveType(ir.PrimitiveType.Kind.Char));

		bool mindirection = mutableIndirection(_typeid.type);
		auto mindirectionConstant = new ir.Constant();
		mindirectionConstant.location = _typeid.location;
		mindirectionConstant._bool = mindirection;
		mindirectionConstant.type = new ir.PrimitiveType(ir.PrimitiveType.Kind.Bool);
		mindirectionConstant.type.location = _typeid.location;

		auto literal = new ir.ClassLiteral();
		literal.location = _typeid.location;
		literal.useBaseStorage = true;
		literal.type = copyTypeSmart(typeinfo.location, typeinfo);

		literal.exps ~= typeConstant;
		literal.exps ~= typeTagConstant;
		literal.exps ~= mangledNameConstant;
		literal.exps ~= mindirectionConstant;

		auto asTR = cast(ir.TypeReference) _typeid.type;
		ir.Class asClass;
		if (asTR !is null) {
			asClass = cast(ir.Class) asTR.type;
		}
		if (asClass !is null) {
			literal.exps ~= buildCast(_typeid.location, buildVoidPtr(_typeid.location),
				buildAddrOf(_typeid.location, buildExpReference(_typeid.location, asClass.vtableVariable, "__vtable_instance")));
			literal.exps ~= buildSizeTConstant(_typeid.location, lp, classSize(_typeid.location, lp, asClass));
		} else {
			literal.exps ~= buildConstantNull(_typeid.location, buildVoidPtr(_typeid.location));
			literal.exps ~= buildSizeTConstant(_typeid.location, lp, 0);
		}

		auto literalVar = new ir.Variable();
		literalVar.location = _typeid.location;
		literalVar.assign = literal;
		literalVar.mangledName = literalVar.name = name;
		literalVar.type = buildTypeReference(_typeid.location, typeinfo, typeinfo.name);
		literalVar.isWeakLink = true;
		literalVar.useBaseStorage = true;
		literalVar.storage = ir.Variable.Storage.Global;
		thisModule.children.nodes = literalVar ~ thisModule.children.nodes;
		thisModule.myScope.addValue(literalVar, literalVar.name);

		auto literalRef = new ir.ExpReference();
		literalRef.location = literalVar.location;
		literalRef.idents ~= literalVar.name;
		literalRef.decl = literalVar;

		exp = literalRef;

		return Continue;
	}
}
