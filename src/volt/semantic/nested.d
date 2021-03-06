 // Copyright © 2013, Bernard Helyer.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.semantic.nested;

import std.algorithm : remove;
import std.conv : to;

import volt.errors;
import ir = volt.ir.ir;
import volt.ir.copy;
import volt.ir.util;
import volt.interfaces;
import volt.visitor.manip;
import volt.visitor.visitor;
import volt.semantic.lookup;
import volt.semantic.gatherer;

void emitNestedStructs(ir.Function parentFunction, ir.BlockStatement bs)
{
	for (size_t i = 0; i < bs.statements.length; ++i) {
		auto fn = cast(ir.Function) bs.statements[i];
		if (fn is null) {
			continue;
		}
		if (fn.oldname.length == 0) {
			foreach (existingFn; parentFunction.nestedFunctions) {
				if (fn.name == existingFn.oldname) {
					throw makeCannotOverloadNested(fn, fn);
				}
			}
			parentFunction.nestedFunctions ~= fn;
			fn.oldname = fn.name;
			fn.name = fn.name ~ to!string(parentFunction.nestedFunctions.length - 1);
		}
		if (parentFunction.nestStruct is null) {
			parentFunction.nestStruct = createAndAddNestedStruct(parentFunction, bs);
		}
		emitNestedStructs(parentFunction, fn._body);
	}
}

ir.Struct createAndAddNestedStruct(ir.Function fn, ir.BlockStatement bs)
{
	auto s = buildStruct(fn.location, "__Nested", []);
	auto decl = buildVariable(fn.location, buildTypeReference(s.location, s, "__Nested"), ir.Variable.Storage.Function, "__nested");
	fn.nestedVariable = decl;
	bs.statements = s ~ (decl ~ bs.statements);
	return s;
}

bool replaceNested(ref ir.Exp exp, ir.ExpReference eref, ir.Variable nestParam)
{
	if (eref.doNotRewriteAsNestedLookup) {
		return false;
	}
	string name;

	auto fp = cast(ir.FunctionParam) eref.decl;
	if (fp is null || !fp.hasBeenNested) {
		auto var = cast(ir.Variable) eref.decl;
		if (var is null || var.storage != ir.Variable.Storage.Nested) { 
			return false;
		} else {
			name = var.name;
		}
	} else {
		name = fp.name;
	}
	assert(name.length > 0);

	if (nestParam is null) {
		return false;
	}
	exp = buildAccess(exp.location, buildExpReference(nestParam.location, nestParam, nestParam.name), name);
	return true;
}

void insertBinOpAssignsForNestedVariableAssigns(ir.BlockStatement bs)
{
	for (size_t i = 0; i < bs.statements.length; ++i) {
		auto var = cast(ir.Variable) bs.statements[i];
		if (var is null || var.storage != ir.Variable.Storage.Nested) {
			continue;
		}
		if (var.assign is null) {
			bs.statements = remove(bs.statements, i--);
		} else {
			auto assign = buildAssign(var.location, buildExpReference(var.location, var, var.name), var.assign);
			bs.statements[i] = buildExpStat(assign.location, assign);
		}
	}
}

void tagNestedVariables(ir.Scope current, ir.Function[] functionStack, ir.Variable var, ir.IdentifierExp i, ir.Store store, ref ir.Exp e)
{
	if (functionStack.length == 0 || functionStack[$-1].nestStruct is null) {
		return;
	}
	if (current.nestedDepth > store.parent.nestedDepth) {
		assert(functionStack[$-1].nestStruct !is null);
		if (var.storage != ir.Variable.Storage.Field && var.storage != ir.Variable.Storage.Nested) {
			addVarToStructSmart(functionStack[$-1].nestStruct, var);
			var.storage = ir.Variable.Storage.Nested;
		} else if (var.storage == ir.Variable.Storage.Field) {
			assert(functionStack[$-1].nestedHiddenParameter !is null);
			auto nref = buildExpReference(i.location, functionStack[$-1].nestedHiddenParameter, functionStack[$-1].nestedHiddenParameter.name);
			auto a = buildAccess(i.location, nref, "this");
			e = buildAccess(a.location, a, i.value);
		}
		if (var.storage != ir.Variable.Storage.Field) {
			var.storage = ir.Variable.Storage.Nested;
		}
	}
}
