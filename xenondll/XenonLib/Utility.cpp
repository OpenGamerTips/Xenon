#include "XenonLib.hpp"
using Xenon::Utility;

Utility::FuncData* Utility::GetFuncData(ulong Point)
{
	Utility::FuncData* Data = new Utility::FuncData();
	ulong At = Point;
	while (ReadByte(At) != 0x55 && ReadByte(At + 1) != 0x89 && ReadByte(At + 2) != 0xE5) // push ebp; mov ebp, esp
	{
		At--;
	}
	Data->ProloguePoint = At;

	std::vector<byte> Asm;
	uint Counter = 0;
	while (ReadByte(At - 1) != 0x5D && !(ReadByte(At) == 0xC3 || ReadByte(At) == 0xC9)) // pop ebp; ret/leave
	{
		At++;
		Asm.push_back(ReadByte(At));
	}
	Data->EpiloguePoint = At;
	Data->Size = At - Data->ProloguePoint;
	Data->Assembly = Asm;
	return Data;
}

void* Utility::DetourFunction(ulong Point, ulong Loc)
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
	ulong RelAddr = ((ulong)Loc - (ulong)ToHook) - 5; // Include the jmp bytes
	WriteByte(ToHook, 0xE9); // jmp
	WriteInt32(ToHook + 1, RelAddr);
	VirtualProtect(ToHook, 5, OldProtection, &OldProtection);
	return Backup;
}

bool Utility::UnDetourFunction(uint Point, void* Backup)
{
	ulong OldProtection;
	void* ToUnhook = (void*)Point;
	VirtualProtect(ToUnhook, 5, PAGE_EXECUTE_READWRITE, &OldProtection);
	memcpy(ToUnhook, Backup, 5);
	VirtualProtect(ToUnhook, 5, OldProtection, &OldProtection);
	VirtualFree(Backup, 0, MEM_RELEASE);
	return true;
}