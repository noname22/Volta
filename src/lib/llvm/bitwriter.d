// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice and license in src/lib/llvm/core.d.
module lib.llvm.bitwriter;

import lib.llvm.core;
public import lib.llvm.c.BitWriter;


void LLVMWriteBitcodeToFile(LLVMModuleRef mod, string filename)
{
	char[1024] stack;
	auto ptr = nullTerminate(stack, filename);
	lib.llvm.c.BitWriter.LLVMWriteBitcodeToFile(mod, ptr);
}
