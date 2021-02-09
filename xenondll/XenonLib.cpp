#include "XenonLib.hpp"
void Xenon::Console::OpenConsole(std::string Name)
{
	DWORD _;
	VirtualProtect(&FreeConsole, 1, PAGE_EXECUTE_READWRITE, &_);
	*(byte*)(&FreeConsole) = 0xC3;
	AllocConsole();
	SetConsoleTitleA(Name.c_str());
	freopen("CONOUT$", "w", stdout);
	freopen("CONIN$", "r", stdin);
}