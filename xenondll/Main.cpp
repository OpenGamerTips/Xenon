#include "Main.hpp"
int main()
{
	Xenon::Console::Open();
}

int __stdcall DllMain(HINSTANCE Instance, DWORD Reason, LPVOID Reserved)
{
	if (Reason == DLL_PROCESS_ATTACH)
	{
		CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)main, 0, NULL, NULL);
		return TRUE;
	}

	return FALSE;
}