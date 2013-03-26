// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.semantic.irverifier;

import ir = volt.ir.ir;

import volt.exceptions;
import volt.interfaces;
import volt.token.location;
import volt.visitor.visitor;
import volt.visitor.debugprinter;
import volt.visitor.scopemanager;
import volt.semantic.classify;


/**
 * This verifier is design to catch faulty IR (from the view
 * of the backends) that the LanguagePass generate.
 *
 * Such as implicit casts or parser nodes that should have
 * been cleaned or uninitialized fields (such as magnedName).
 *
 * @ingroup passes passLang
 */
class IrVerifier : ScopeManager, Pass
{
private:
	int[size_t] mNodes;
	int mCount;

public:
	override void transform(ir.Module m)
	{
		mNodes = null;
		mCount = 0;
		accept(m, this);
	}

	override void close()
	{
	}


public:
	override Status debugVisitNode(ir.Node n)
	{
		auto t = *cast(size_t*)&n;
		if (t in mNodes) {
			auto str = format(
				"%s \"%s\" node found more then once in IR",
				getNodeAddressString(n), to!string(n.nodeType));
			throw CompilerPanic(n.location, str);
		}
		mNodes[t] = mCount++;

		return Status.Continue;
	}

	override Status enter(ir.Variable v)
	{
		if (v.storage != ir.Variable.Storage.Invalid) {
			return Continue;
		}
		auto str = format("%s invalid variable found in IR",
		                  getNodeAddressString(v));
		throw CompilerPanic(v.location, str);
	}

	override Status enter(ir.TopLevelBlock tlb)
	{
		foreach (n; tlb.nodes) {
			switch (n.nodeType) with (ir.NodeType) {
			case Import:
				// Check if in top level module.
				goto case;
			case Variable:
			case Function:
			case Alias:
			case Enum:
			case Struct:
			case Class:
			case Interface:
			case MixinFunction:
			case MixinTemplate:
			case MixinStatement:
			case UserAttribute:
			case EnumDeclaration:
				auto s = accept(n, this);
				if (s == Stop)
					return Stop;
				break;
			default:
				auto str = format("%s invalid node '%s' in toplevel block",
				                  getNodeAddressString(n),
				                  to!string(n.nodeType));
				throw CompilerPanic(n.location, str);
			}
		}

		return ContinueParent;
	}

	override Status enter(ir.BlockStatement bs)
	{
		foreach (n; bs.statements) {
			switch (n.nodeType) with (ir.NodeType) {
			case BlockStatement:
			case ReturnStatement:
			case IfStatement:
			case WhileStatement:
			case DoStatement:
			case ForStatement:
			case ContinueStatement:
			case ExpStatement:
			case Variable:
			case MixinStatement:
				auto s = accept(n, this);
				if (s == Stop)
					return Stop;
				break;
			default:
				auto str = format("(%s) invalid node '%s' in block statement",
				                  getNodeAddressString(n),
				                  to!string(n.nodeType));
				throw CompilerPanic(n.location, str);
			}
		}

		return ContinueParent;
	}

	override Status visit(ref ir.Exp exp, ir.IdentifierExp ie)
	{
		auto str = format("%s IdentifierExp '%s' left in IR.",
		                  getNodeAddressString(ie), ie.value);
		throw CompilerPanic(ie.location, str);
	}

	override Status leave(ir.TopLevelBlock tlb) { assert(false); }
	override Status leave(ir.BlockStatement bs) { assert(false); }
}
