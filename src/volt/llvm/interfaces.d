// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/volt/license.d (BOOST ver. 1.0).
module volt.llvm.interfaces;

import volt.errors;

public import lib.llvm.core;

public import ir = volt.ir.ir;

public import volt.llvm.type;


/**
 * Represents a single LLVMValueRef plus the associated high level type.
 *
 * A Value can be in reference form where it is actually a pointer
 * to the give value, since all variables are stored as alloca'd
 * memory in a function we will not insert loads until needed.
 * This is needed for '&' to work and struct lookups.
 */
class Value
{
public:
	Type type;
	LLVMValueRef value;

	bool isPointer; ///< Is this a reference to the real value?

public:
	this()
	{
	}

	this(Value val)
	{
		this.isPointer = val.isPointer;
		this.type = val.type;
		this.value = val.value;
	}
}

/**
 * Collection of objects used by pretty much all of the translation
 * code. It isn't called Module, Context or Builder because it will
 * collide in meaning with language concepts.
 *
 * One is created for each Volt module that is compiled.
 */
abstract class State
{
public:
	ir.Module irMod;

	LLVMContextRef context;
	LLVMBuilderRef builder;
	LLVMModuleRef mod;

	LLVMBasicBlockRef currentBlock;
	LLVMBasicBlockRef currentBreakBlock; ///< Block to jump to on break.
	LLVMBasicBlockRef currentContinueBlock; ///< Block to jump to on continue.
	LLVMBasicBlockRef currentSwitchDefault;
	LLVMBasicBlockRef[long] currentSwitchCases;

	LLVMValueRef currentFunc;
	ir.Function currentIrFunc;
	bool currentFall; ///< Tracking for auto branch generation.

	/**
	 * Cached type for convenience.
	 * @{
	 */
	VoidType voidType;

	PrimitiveType boolType;
	PrimitiveType byteType;
	PrimitiveType ubyteType;
	PrimitiveType intType;
	PrimitiveType uintType;
	PrimitiveType ulongType;

	PointerType voidPtrType;

	PrimitiveType sizeType;

	FunctionType voidFunctionType;
	/**
	 * @}
	 */

	/**
	 * LLVM intrinsic.
	 * @{
	 */
	LLVMValueRef llvmTrap;
	/**
	 * @}
	 */

public:
	abstract void close();

	/*
	 *
	 * High level building blocks.
	 *
	 */

	/**
	 * Build a complete module with this state.
	 */
	abstract void compile(ir.Module m);

	/**
	 * Builds the given statement class at the current place,
	 * and any sub-expressions & -statements.
	 */
	abstract void evaluateStatement(ir.Node node);

	/*
	 *
	 * Expression value functions.
	 *
	 */

	/**
	 * Returns the LLVMValueRef for the given expression,
	 * evaluated at the current state.builder location.
	 */
	final LLVMValueRef getValue(ir.Exp exp)
	{
		auto v = new Value();
		getValue(exp, v);
		return v.value;
	}

	/**
	 * Returns the value, making sure that the value is not in
	 * reference form, basically inserting load instructions where needed.
	 */
	final void getValue(ir.Exp exp, Value result)
	{
		getValueAnyForm(exp, result);
		if (!result.isPointer)
			return;
		result.value = LLVMBuildLoad(builder, result.value, "");
		result.isPointer = false;
	}

	/**
	 * Returns the value in reference form, basically meaning that
	 * the return value is a pointer to where it is held in memory.
	 */
	final void getValueRef(ir.Exp exp, Value result)
	{
		getValueAnyForm(exp, result);
		if (result.isPointer)
			return;
		throw panic(exp.location, "Value is not a backend reference");
	}

	/**
	 * Returns the value, without doing any checking if it is
	 * in reference form or not.
	 */
	abstract void getValueAnyForm(ir.Exp exp, Value result);

	/**
	 * Returns the LLVMValueRef for the given constant expression,
	 * does not require that state.builder is set.
	 */
	abstract LLVMValueRef getConstant(ir.Exp exp);

	/*
	 *
	 * Value store functions.
	 *
	 */

	/**
	 * Return the LLVMValueRef for the given Function.
	 *
	 * If the value is not defined it will do so.
	 */
	abstract LLVMValueRef getFunctionValue(ir.Function fn, out Type type);

	/**
	 * Return the LLVMValueRef for the given Variable.
	 *
	 * If the value is not defined it will do so.
	 */
	abstract LLVMValueRef getVariableValue(ir.Variable var, out Type type);
	abstract LLVMValueRef getVariableValue(ir.FunctionParam var, out Type type);

	abstract void makeByValVariable(ir.FunctionParam var, LLVMValueRef v);

	abstract void makeThisVariable(ir.Variable var, LLVMValueRef v);
	abstract void makeNestVariable(ir.Variable var, LLVMValueRef v);

	/*
	 *
	 * Type store functions.
	 *
	 */

	abstract void addType(Type type, string mangledName);

	abstract Type getTypeNoCreate(string mangledName);

	/*
	 *
	 * Basic  store functions.
	 *
	 */

	/**
	 * Start using a new basic block, setting currentBlock.
	 *
	 * Side-Effects:
	 *   Will reset currentFall.
	 *   Will set the builder to the end of the given block.
	 */
	void startBlock(LLVMBasicBlockRef b)
	{
		currentFall = true;
		currentBlock = b;
		LLVMPositionBuilderAtEnd(builder, currentBlock);
	}

	/**
	 * Helper function to swap out the currentContineBlock, returns the old one.
	 */
	LLVMBasicBlockRef replaceContinueBlock(LLVMBasicBlockRef b)
	{
		auto t = currentContinueBlock;
		currentContinueBlock = b;
		return t;
	}

	/**
	 * Helper function to swap out the currentBreakBlock, returns the old one.
	 */
	LLVMBasicBlockRef replaceBreakBlock(LLVMBasicBlockRef b)
	{
		auto t = currentBreakBlock;
		currentBreakBlock = b;
		return t;
	}
}
