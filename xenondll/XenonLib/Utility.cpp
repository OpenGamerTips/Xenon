#include "XenonLib.hpp"
using Xenon::Utility;

void* Xenon::Utility::DetourAsm32(ulong Point, void* To)
{
	ulong OldProtection;
	void* Backup = VirtualAlloc(0, 5, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
	if (Backup == NULL)
	{
		return FALSE;
	}

	void* ToHook = (void*)Point;
	VirtualProtect(ToHook, 5, PAGE_EXECUTE_READWRITE, &OldProtection);
	memcpy(Backup, ToHook, 5);
	ulong RelAddr = ((ulong)To - (ulong)ToHook) - 5; // Include the jmp bytes
	WriteByte(ToHook, 0xE9); // jmp
	WriteInt32(ToHook + 1, RelAddr);
	VirtualProtect(ToHook, 5, OldProtection, &OldProtection);
	return Backup;
}

bool Xenon::Utility::UnDetourAsm32(ulong Point, void* Backup)
{
	ulong OldProtection;
	void* ToUnhook = (void*)Point;
	VirtualProtect(ToUnhook, 5, PAGE_EXECUTE_READWRITE, &OldProtection);
	memcpy(ToUnhook, Backup, 5);
	VirtualProtect(ToUnhook, 5, OldProtection, &OldProtection);
	return true;
}