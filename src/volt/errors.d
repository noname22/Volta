// Copyright © 2013, Bernard Helyer.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.errors;

import std.conv : to;
import std.array : join;
import std.string : format, toLower;

import ir = volt.ir.ir;

import volt.exceptions;
import volt.token.location;

// Not sure of the best home for this guy.
void warning(Location loc, string message)
{
	writefln(format("%s: warning: %s", loc.toString(), message));
}

/*
 *
 *
 * Specific Errors
 *
 *
 */

CompilerException makeStaticAssert(ir.AssertStatement as, string msg, string file = __FILE__, const int line = __LINE__)
{
	string emsg = format("static assert: %s", msg);
	auto e = new CompilerError(as.location, emsg);
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeConstField(ir.Variable v, string file = __FILE__, const int line = __LINE__)
{
	string emsg = format("const or immutable non local/global field '%s' is forbidden.", v.name);
	auto e = new CompilerError(v.location, emsg);
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeAssignToNonStaticField(ir.Variable v, string file = __FILE__, const int line = __LINE__)
{
	string emsg = format("Attempted to assign to non local/global field %s.", v.name);
	auto e = new CompilerError(v.location, emsg);
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeSwitchBadType(ir.Node node, ir.Type type, string file = __FILE__, const int line = __LINE__)
{
	string emsg = format("bad switch type '%s'.", errorString(type));
	auto e = new CompilerError(node.location, emsg);
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeSwitchDuplicateCase(ir.Node node, string file = __FILE__, const int line = __LINE__)
{
	auto e = new CompilerError(node.location, "duplicate case in switch statement.");
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeFinalSwitchBadCoverage(ir.Node node, string file = __FILE__, const int line = __LINE__)
{
	auto e = new CompilerError(node.location, "final switch statement doesn't cover all enum members.");
	e.file = file;
	e.line = line;
	return e;
}

CompilerException makeArchNotSupported(string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError("arch not supported with current platform", file, line);
}

CompilerException makeNotTaggedOut(ir.Exp exp, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(exp.location, "out parameter not tagged as out.", file, line);
}

CompilerException makeNotTaggedRef(ir.Exp exp, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(exp.location, "ref parameter not tagged as ref.", file, line);
}

CompilerException makeFunctionNameOutsideOfFunction(ir.TokenExp fexp, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(fexp.location, format("%s occuring outside of function.", fexp.type == ir.TokenExp.Type.PrettyFunction ? "__PRETTY_FUNCTION__" : "__FUNCTION__"), file, line);
}

CompilerException makeMultipleValidModules(ir.Node node, string[] paths, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("multiple modules are valid %s.", paths), file, line);
}

CompilerException makeCannotOverloadNested(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("cannot overload nested function '%s'.", fn.name), file, line);
}

CompilerException makeUsedBeforeDeclared(ir.Node node, ir.Variable var, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("variable '%s' used before declaration.", var.name), file, line);
}


CompilerException makeStructConstructorsUnsupported(ir.Node node, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "struct constructors are currently unsupported.", file, line);
}

CompilerException makeCallingStaticThroughInstance(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("calling local or global function '%s' through instance variable.", fn.name), file, line);
}

CompilerException makeMarkedOverrideDoesNotOverride(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("function '%s' is marked as override but does not override any functions.", fn.name), file, line);
}

CompilerException makeAbstractHasToBeMember(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("function '%s' is marked as abstract but is not a member of an abstract class.", fn.name), file, line);
}

CompilerException makeAbstractBodyNotEmpty(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("function '%s' is marked as abstract but it has an implementation.", fn.name), file, line);
}

CompilerException makeNewAbstract(ir.Node node, ir.Class _class, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("cannot create instance of abstract class '%s'.", _class.name), file, line);
}

CompilerException makeBadAbstract(ir.Node node, ir.Attribute attr, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "only classes and functions may be marked as abstract.", file, line);
}

CompilerException makeCannotImport(ir.Node node, ir.Import _import, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("can't find module '%s'.", _import.name), file, line);
}

CompilerException makeNotAvailableInCTFE(ir.Node node, ir.Node feature, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("%s is currently unevaluatable at compile time.", to!string(feature.nodeType)), file, line);
}

CompilerException makeShadowsDeclaration(ir.Node a, ir.Node b, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(a.location, format("shadows declaration at %s.", b.location), file, line);
}

CompilerException makeMultipleDefaults(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "multiple default cases defined.", file, line);
}

CompilerException makeFinalSwitchWithDefault(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "final switch with default case.", file, line);
}

CompilerException makeNoDefaultCase(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "no default case.", file, line);
}

CompilerException makeTryWithoutCatch(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "try statement must have a catch block and/or a finally block.", file, line);
}

CompilerException makeMultipleOutBlocks(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "multiple in blocks specified for single function.", file, line);
}

CompilerException makeNeedOverride(ir.Function overrider, ir.Function overridee, string file = __FILE__, size_t line = __LINE__)
{
	string emsg = format("function '%s' overrides function at %s but is not marked with 'override'.", overrider.name, overridee.location);
	return new CompilerError(overrider.location, emsg, file, line);
}

CompilerException makeThrowOnlyThrowable(ir.Exp exp, ir.Type type, string file = __FILE__, size_t line = __LINE__)
{
	string emsg = format("can not throw expression of type '%s'", type.errorString);
	return new CompilerError(exp.location, emsg, file, line);
}

CompilerException makeThrowNoInherits(ir.Exp exp, ir.Class clazz, string file = __FILE__, size_t line = __LINE__)
{
	string emsg = format("can not throw class of type '%s' as it does not inherit from object.Throwable", clazz.errorString);
	return new CompilerError(exp.location, emsg, file, line);
}

CompilerException makeInvalidAAKey(ir.AAType aa, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(aa.location, format("'%s' is an invalid AA key", aa.key.errorString), file, line);
}

CompilerException makeBadAAAssign(Location location, string file = __FILE__, size_t line = __LINE__)
{
    return new CompilerError(location, "assigning AA's to each other is not allowed due to semantic inconsistencies.", file, line);
}

CompilerException makeBadAANullAssign(Location location, string file = __FILE__, size_t line = __LINE__)
{
    return new CompilerError(location, "cannot set AA to null, use [] instead.", file, line);
}


/*
 *
 *
 * General Util
 *
 *
 */

CompilerException makeUnsupported(Location location, string feature, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("unsupported feature, '%s'", feature), file, line);
}

CompilerException makeError(Location location, string s, string file = __FILE__, size_t line = __LINE__)
{
	// A hack for typer, for now.
	return new CompilerError(location, s, file, line);
}

CompilerException makeExpected(ir.Node node, string s, string file = __FILE__, size_t line = __LINE__)
{
	return makeExpected(node.location, s, false, file, line);
}

CompilerException makeExpected(Location location, string s, bool b = false, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("expected %s.", s), b, file, line);
}

CompilerException makeExpected(Location location, string expected, string got, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("expected '%s', got '%s'.", expected, got), file, line);
}

CompilerException makeUnexpected(ir.Location location, string s, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("unexpected %s.", s), file, line);
}

CompilerException makeBadOperation(ir.Node node, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "bad operation.", file, line);
}

CompilerException makeExpectedContext(ir.Node node, ir.Node node2, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "expected context pointer.", file, line);
}


/*
 *
 *
 * Type Conversions
 *
 *
 */

CompilerException makeBadImplicitCast(ir.Node node, ir.Type from, ir.Type to, string file = __FILE__, size_t line = __LINE__)
{
	string emsg = format("cannot implicitly convert '%s' to '%s'.", from.errorString, to.errorString);
	return new CompilerError(node.location, emsg, file, line);
}

CompilerException makeCannotModify(ir.Node node, ir.Type type, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("cannot modify '%s'.", type.errorString), file, line);
}

CompilerException makeNotLValue(ir.Node node, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "expected lvalue.", file, line);
}

CompilerException makeTypeIsNot(ir.Node node, ir.Type from, ir.Type to, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("type '%s' is not '%s' as expected.", from.errorString, to.errorString), file, line);
}

CompilerException makeInvalidType(ir.Node node, ir.Type type, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("bad type '%s'", type.errorString), file, line);
}

CompilerException makeInvalidUseOfStore(ir.Node node, ir.Store store, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("invalid use of store '%s'.", store.name), file, line);
}

/*
 *
 *
 * Look ups
 *
 *
 */

CompilerException makeInvalidThis(ir.Node node, ir.Type was, ir.Type expected, string member, string file = __FILE__, size_t line = __LINE__)
{
	string emsg = format("'this' is of type '%s' expected '%s' to access member '%s'", was.errorString, expected.errorString, member);
	return new CompilerError(node.location, emsg, file, line);
}

CompilerException makeNotMember(ir.Node node, ir.Type aggregate, string member, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("'%s' has no member '%s'", aggregate.errorString, member), file, line);
}

CompilerException makeNotMember(Location location, string aggregate, string member, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("%s has no member '%s'", aggregate, member), file, line);
}

CompilerException makeFailedLookup(ir.Node node, string lookup, string file = __FILE__, size_t line = __LINE__)
{
	return makeFailedLookup(node.location, lookup, file, line);
}

CompilerException makeFailedLookup(Location location, string lookup, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("unidentified identifier '%s'", lookup), file, line);
}

CompilerException makeNonTopLevelImport(Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "Imports only allowed in top scope", file, line);
}

/*
 *
 *
 * Functions
 *
 *
 */

CompilerException makeWrongNumberOfArguments(ir.Node node, size_t got, size_t expected, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("wrong number of arguments; got %s, expected %s.", got, expected), file, line);
}

CompilerException makeBadCall(ir.Node node, ir.Type type, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, format("cannot call '%s'.", type.errorString), file, line);
}

CompilerException makeCannotDisambiguate(ir.Node node, ir.Function[] functions, string file = __FILE__, size_t line = __LINE__)
{
	return makeCannotDisambiguate(node.location, functions, file, line);
}

CompilerException makeCannotDisambiguate(Location location, ir.Function[] functions, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, format("cannot disambiguate between %s functions.", functions.length), file, line);
}

CompilerException makeCannotInfer(ir.Location location, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(location, "not enough information to infer type.", true, file, line);
}

CompilerException makeCannotLoadDynamic(ir.Node node, ir.Function fn, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerError(node.location, "can not @loadDynamic function with body", file, line);
}


/*
 *
 *
 * Panics
 *
 *
 */

CompilerException panicOhGod(ir.Node node, string file = __FILE__, size_t line = __LINE__)
{
	return panic(node.location, "Oh god.", file, line);
}

CompilerException panic(ir.Node node, string msg, string file = __FILE__, size_t line = __LINE__)
{
	return panic(node.location, msg, file, line);
}

CompilerException panic(Location location, string msg, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerPanic(location, msg, file, line);
}

CompilerException panic(string msg, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerPanic(msg, file, line);
}

CompilerException panicUnhandled(ir.Node node, string unhandled, string file = __FILE__, size_t line = __LINE__)
{
	return panicUnhandled(node.location, unhandled, file, line);
}

CompilerException panicUnhandled(Location location, string unhandled, string file = __FILE__, size_t line = __LINE__)
{
	return new CompilerPanic(location, format("unhandled case '%s'", unhandled), file, line);
}

CompilerException panicNotMember(ir.Node node, string aggregate, string field, string file = __FILE__, size_t line = __LINE__)
{
	auto str = format("0x%s no field name '%s' in struct '%s'",
	                  to!string(*cast(size_t*)&node),
	                  field, aggregate);
	return new CompilerPanic(node.location, str, file, line);
}

private:

@property string errorString(ir.Type type)
{

	switch(type.nodeType()) with(ir.NodeType) {
		case PrimitiveType:
			ir.PrimitiveType prim = cast(ir.PrimitiveType)type;
			return toLower(format("%s", prim.type));
		case TypeReference:
			ir.TypeReference tr = cast(ir.TypeReference)type;
			return tr.type.errorString();
		case PointerType:
			ir.PointerType pt = cast(ir.PointerType)type;
			return format("%s*", pt.base.errorString());
		case NullType:
			return "null";
		case ArrayType:
			ir.ArrayType at = cast(ir.ArrayType)type;
			return format("%s[]", at.base.errorString());
		case StaticArrayType:
			ir.StaticArrayType sat = cast(ir.StaticArrayType)type;
			return format("%s[%d]", sat.base.errorString(), sat.length);
		case AAType:
			ir.AAType aat = cast(ir.AAType)type;
			return format("%s[%s]", aat.value.errorString(), aat.key.errorString());
		case FunctionType:
		case DelegateType:
			ir.CallableType c = cast(ir.CallableType)type;

			string ctype = type.nodeType() == FunctionType ? "function" : "delegate";

			string[] params;
			foreach (param; c.params) {
				params ~= param.errorString();
			}

			return format("%s %s(%s)", c.ret.errorString(), ctype, join(params, ", "));
		case StorageType:
			ir.StorageType st = cast(ir.StorageType)type;
			return format("%s(%s)", toLower(format("%s", st.type)), st.base.errorString());
		case TypeOf:
		case FunctionSetType:
		default:
			return type.toString();
	}

	assert(0);
}
