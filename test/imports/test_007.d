//T compiles:no
//T dependency:m1.d
//T dependency:m3.d
// Import leaks.

module test_007;

import m3 : exportedVal;


int main()
{
	return exportedVal;
}
