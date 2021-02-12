#pragma once
#include "XenonLib\XenonLib.hpp"
#include "Retcheck.h"
#define ASLR(Address) (Address - 0x400000 + (DWORD)GetModuleHandleA(0))
using Xenon::Console;
namespace RLua
{
	const ulong gettop_offset_1 = 8;  // Gettop "(*(_DWORD*)(a1 + OFFSET1"
	const ulong gettop_offset_2 = 16; // Gettop ") - *(_DWORD*)(a1 + OFFSET2"
	const ulong gettop_offset_3 = 4;  // Gettop ")) >> OFFSET3"
	#define gettop_emu(rL) ((*(ulong*)(rL + RLua::gettop_offset_1) - *(ulong*)(rL + RLua::gettop_offset_2)) >> RLua::gettop_offset_3)

	const ulong thread_offset_1 = 24;  // Sandboxthread "*(_QWORD *)(v4 + OFFSET2) = *(_OWORD*)a2;"
	const ulong thread_offset_2 = 112; // Sandboxthread "v4 = *(_DWORD*)(a1 + OFFSET1");
	#define setthreadidentity(rL, ContextLevel) (*(ulong*)(*(ulong*)(rL + RLua::thread_offset_1) + RLua::thread_offset_2) = ContextLevel)

	const ulong GettopAddr = ASLR(0x01381EA0);
	typedef int(__cdecl* gettop_cast)(ulong rL);
	static gettop_cast gettop = reinterpret_cast<gettop_cast>(unprotect(GettopAddr));

	const ulong NewThreadAddr = ASLR(0x013821D0);
	typedef ulong(__cdecl* newthread_cast)(ulong rL);
	static newthread_cast newthread = reinterpret_cast<newthread_cast>(unprotect(NewThreadAddr));

	const ulong GetFieldAddr = ASLR(0x01381CD0);
	typedef void(__fastcall* getfield_cast)(ulong rL, int Index, const char* Name);
	static getfield_cast getfield = reinterpret_cast<getfield_cast>(unprotect(GetFieldAddr));

	const ulong SetFieldAddr = ASLR(0x01383160);
	typedef void(__cdecl* setfield_cast)(ulong rL, int Index, const char* Name);
	static setfield_cast setfield = reinterpret_cast<setfield_cast>(unprotect(SetFieldAddr));

	const ulong PcallAddr = ASLR(0x01382440);
	typedef int(__cdecl* pcall_cast)(ulong rL, int Nargs, int Nresults, int ErrFunc);
	static pcall_cast pcall = reinterpret_cast<pcall_cast>(unprotect(PcallAddr));

	const ulong PushValueAddr = ASLR(0x013829F0);
	typedef void(__cdecl* pushvalue_cast)(ulong rL, int Index);
	static pushvalue_cast pushvalue = reinterpret_cast<pushvalue_cast>(unprotect(PushValueAddr));

	const ulong SettopAddr = ASLR(0x01383480);
	typedef void(__fastcall* settop_cast)(ulong rL, int Index);
	static settop_cast settop = reinterpret_cast<settop_cast>(unprotect(SettopAddr));

	const ulong PushNumberAddr = ASLR(0x01382820);
	typedef void(__fastcall* pushnumber_cast)(ulong rL, int Num);
	static pushnumber_cast pushnumber = reinterpret_cast<pushnumber_cast>(unprotect(PushNumberAddr));

	const ulong PushLStringAddr = ASLR(0x01382750);
	typedef void(__thiscall* pushlstring_cast)(ulong rL, const char* String, size_t Length);
	static pushlstring_cast pushlstring = reinterpret_cast<pushlstring_cast>(unprotect(PushLStringAddr));

	const ulong DeserializeAddr = ASLR(0x0138D270);
	typedef int(__cdecl* deserialize_cast)(ulong rL, const char* ChunkName, const char* Bytecode, size_t Size);
	static deserialize_cast deserialize = reinterpret_cast<deserialize_cast>(unprotect(DeserializeAddr));

	static void getglobal(ulong rL, const char* name) { getfield(rL, -10002, name); };
	static void setglobal(ulong rL, const char* name) { setfield(rL, -10002, name); };
	static void pop(ulong rL, int num) { settop(rL, -(num)-1); }
	static void pushstring(ulong rL, const char* _String) { std::string String = _String; int Length = String.size(); pushlstring(rL, _String, Length); }
	static void call(ulong rL, int nargs, int nresults) { pcall(rL, nargs, nresults, 0); }
	static void spawn(ulong rL) { getfield(rL, -10002, "spawn"); pushvalue(rL, -2); pcall(rL, 1, 0, 0); }
}