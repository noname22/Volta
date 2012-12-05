// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// Copyright © 2012, Bernard Helyer.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.ir.declaration;

import volt.ir.base;
import volt.ir.type;
import volt.ir.expression;
import volt.ir.statement;
import volt.ir.context;


/**
 * @defgroup irDecl IR Declaration Nodes
 *
 * Declarations associate names with types.
 *
 * Broadly speaking, there are variables and functions.
 * Both of which (essentially) associated a name with a typed
 * piece of memory.
 *
 * Aliases are different. While still associating a name
 * with a type, it's not an _instance_ of a type, but rather
 * a symbolic representation of the type (so the underlying
 * type may be changed transparently, or perhaps the real
 * type is long winded, or exposes implementation details).
 *
 * @ingroup irNode
 */

/**
 * Base class for all declarations.
 *
 * @ingroup irNode irDecl
 */
abstract class Declaration : Node
{
	enum Kind {
		Function = NodeType.Function,
		Variable = NodeType.Variable
	}

	@property Kind declKind() { return cast(Kind)nodeType; }
	this(NodeType nt) { super(nt); }
}

/**
 * Represents an instance of a type.
 *
 * A Variable has a type and a single name that is an
 * instance of that type. It may also have an expression
 * that represents a value to assign to it.
 *
 * @p Variables are mangled as type + parent names + name.
 *
 * @ingroup irNode irDecl
 */
class Variable : Declaration
{
public:
	enum Storage
	{
		None,
		Local,
		Global,
	}

public:
	/// The access level of this @p Variable, which determines how it interacts with other modules.
	Access access;

	/// The underlying @p Type this @p Variable is an instance of.
	Type type;
	/// The name of the instance of the type. This is not be mangled.
	string name;
	/// An optional mangled name for this Variable.
	string mangledName;
	
	/// An expression that is assigned to the instance if present.
	Exp assign;  // Optional.

	Storage storage;


public:
	this() { super(NodeType.Variable); }
	/// Construct a @p Variable with a given type and name.
	this(Type t, string name)
	{
		this();
		this.type = t;
		this.name = name;
	}
}

/**
 * An @p Alias associates names with a @p Type. Once declared, using that name is 
 * as using that @p Type directly.
 *
 * @todo This uses the old Declaration format of multiple names per Alias. 
 * It should probably be changed to be parsed into multiple Alias nodes.
 * Also, we need to support the new alias name = type syntax.
 *
 * @ingroup irNode irDecl
 */
class Alias : Node
{
public:
	Access access;

	/// The @p Type names are associated with.
	Type type;
	/// The names to associate with the type. There is at least one.
	string[] names;


public:
	this() { super(NodeType.Alias); }
}

/**
 * A function is a block of code that takes parameters, and may return a value.
 * There may be additional implied context, depending on where it's defined.
 *
 * @p Functions are mangled as type + parent names + name.
 *
 * @ingroup irNode irDecl
 */
class Function : Declaration
{
public:
	/**
	 * Used to specify function type.
	 *
	 * Some types have hidden arguemnts, like the this arguement
	 * for member functions, constructors and destructors.
	 *
	 * @todo move to FunctionType.
	 */
	enum Kind {
		Function,  ///< foo()
		Member,  ///< this.foo()
		LocalMember,  ///< Clazz.foo()
		GlobalMember,  ///< Clazz.foo()
		Constructor,  ///< auto foo = new Clazz()
		Destructor,  ///< delete foo
		LocalConstructor,  ///< local this() {}
		LocalDestructor,  ///< local ~this() {}
		GlobalConstructor,  ///< global this() {}
		GlobalDestructor,  ///< global ~this() {}
	}


public:
	Access access;  ///< defalt public.

	Kind kind;  ///< What kind of function.
	FunctionType type;  ///< Prototype.

	string name;  ///< Pre mangling.
	string mangledName;

	/**
	 * For use with the out contract.
	 *
	 * out (result)
	 *  ^ that's outParameter (optional).
	 */
	string outParameter;


	/// @todo Make these @p BlockStatements?
	Node[] inContract;  ///< Optional.
	Node[] outContract;  ///< Optional.
	Node[] _body;  ///< Optional.

	/// The @p Scope for the body of the function. @todo What about the contracts?
	Scope myScope;

	bool defined;


public:
	this() { super(NodeType.Function); }
}
