#include "Main.hpp"
int main()
{
	Xenon::Console::OpenConsole("Xenon");
	std::cout << "Hello, World!";
}

int __stdcall DllMain(HINSTANCE Instance, DWORD Reason, LPVOID Reserved)
{
	if (Reason == DLL_PROCESS_ATTACH)
	{
		CreateThread(0, 0, (LPTHREAD_START_ROUTINE)main, 0, 0, 0);
		return TRUE;
	}

	return FALSE;
}