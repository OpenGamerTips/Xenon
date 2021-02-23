#pragma once
#include <unordered_map>
#include "XenonLib\XenonLib.hpp"
#include "EyeStep\eyestep.h"
#include "EyeStep\eyestep_utility.h"
#include "Retcheck.h"

#define ASLR(Address) (Address - 0x400000 + reinterpret_cast<ulong>(GetModuleHandleA(0)))
using Xenon::Console;
typedef unsigned long ulong;
namespace RLua
{
    // Offsets need manual updating.
    const ulong ThreadIdentityOffset1 = 24; // Pseudocode sandboxthread look for " * (_QWORD*)(v4 + OFFSET) = *(_OWORD*)a2; "
    const ulong ThreadIdentityOffset2 = 104; // Pseudocode sandboxthread look for "v4 = *(_DWORD*)(a1 + OFFSET");

    static ulong TNIL = 0;
    static ulong TBOOLEAN = 0;
    static ulong TLIGHTUSERDATA = 0;
    static ulong TNUMBER = 0;
    static ulong TSTRING = 0;
    static ulong TTABLE = 0;
    static ulong TFUNCTION = 0;
    static ulong TUSERDATA = 0;
    static ulong TTHREAD = 0;

    const ulong callAddr = ASLR(0x0138DB60);
    typedef void(__cdecl* callCast)(ulong rL, int Nargs, int NResults);
    static callCast call = reinterpret_cast<callCast>(unprotect(callAddr));

    const ulong callhookAddr = ASLR(0x01399220);
    typedef int(__cdecl* callhookCast)(ulong rL, void(__cdecl* Arg2)(int, char*), int Arg3);
    static callhookCast callhook = reinterpret_cast<callhookCast>(unprotect(callhookAddr));

    const ulong checkstackAddr = ASLR(0x0138DBD0);
    typedef int(__cdecl* checkstackCast)(ulong rL, void(__cdecl* Arg2)(int, char*), int Arg3);
    static checkstackCast checkstack = reinterpret_cast<checkstackCast>(unprotect(checkstackAddr));

    const ulong concatAddr = ASLR(0x0138DC70);
    typedef void(__cdecl* concatCast)(ulong rL, int Number);
    static concatCast concat = reinterpret_cast<concatCast>(unprotect(concatAddr));

    const ulong createtableAddr = ASLR(0x0138DD20);
    typedef void(__cdecl* createtableCast)(ulong rL, int NumberArrayAlloc, int NumberNonArrayCalloc);
    static createtableCast createtable = reinterpret_cast<createtableCast>(unprotect(createtableAddr));

    const ulong deserializeAddr = ASLR(0x013993B0);
    typedef int(__cdecl* deserializeCast)(ulong rL, const char* ChunkName, const char* Bytecode, size_t BytecodeSize);
    static deserializeCast deserialize = reinterpret_cast<deserializeCast>(unprotect(deserializeAddr));

    const ulong f_callAddr = ASLR(0x0138DA10);
    typedef char* (__cdecl* f_callCast)(ulong rL, ulong Arg2);
    static f_callCast f_call = reinterpret_cast<f_callCast>(unprotect(f_callAddr));

    const ulong gcAddr = ASLR(0x0138DE70);
    typedef int(__cdecl* gcCast)(ulong rL, int What, int Data);
    static gcCast gc = reinterpret_cast<gcCast>(unprotect(gcAddr));

    const ulong getargumentAddr = ASLR(0x0139AFA0);
    typedef int(__cdecl* getargumentCast)(ulong rL, int Arg2, int Arg3);
    static getargumentCast getargument = reinterpret_cast<getargumentCast>(unprotect(getargumentAddr));

    const ulong getfenvAddr = ASLR(0x0138DF90);
    typedef void(__cdecl* getfenvCast)(ulong rL, int Index);
    static getfenvCast getfenv = reinterpret_cast<getfenvCast>(unprotect(getfenvAddr));

    const ulong getfieldAddr = ASLR(0x0138E030);
    typedef void(__cdecl* getfieldCast)(ulong rL, int Index, const char* Name);
    static getfieldCast getfield = reinterpret_cast<getfieldCast>(unprotect(getfieldAddr));

    const ulong getinfoAddr = ASLR(0x0139B060);
    typedef int(__cdecl* getinfoCast)(ulong rL, const char* What, ulong Ar);
    static getinfoCast getinfo = reinterpret_cast<getinfoCast>(unprotect(getinfoAddr));

    const ulong getlocalAddr = ASLR(0x0139B130);
    typedef const char* (__cdecl* getlocalCast)(ulong rL, ulong Ar, int Number);
    static getlocalCast getlocal = reinterpret_cast<getlocalCast>(unprotect(getlocalAddr));

    const ulong getmetatableAddr = ASLR(0x0138E0E0);
    typedef int(__stdcall* getmetatableCast)(ulong rL, int Index);
    static getmetatableCast getmetatable = reinterpret_cast<getmetatableCast>(unprotect(getmetatableAddr));

    const ulong getstackAddr = ASLR(0x0139B1E0);
    typedef int(__cdecl* getstackCast)(ulong rL, int Level, ulong Ar);
    static getstackCast getstack = reinterpret_cast<getstackCast>(unprotect(getstackAddr));

    const ulong gettableAddr = ASLR(0x0138E1A0);
    typedef void(__cdecl* gettableCast)(ulong rL, int index);
    static gettableCast gettable = reinterpret_cast<gettableCast>(unprotect(gettableAddr));

    const ulong gettopAddr = ASLR(0x0138E210);
    typedef int(__cdecl* gettopCast)(ulong rL);
    static gettopCast gettop = reinterpret_cast<gettopCast>(unprotect(gettopAddr));

    const ulong getupvalueAddr = ASLR(0x0138E230);
    typedef const char* (__cdecl* getupvalueCast)(ulong rL, int FuncIndex, int Number);
    static getupvalueCast getupvalue = reinterpret_cast<getupvalueCast>(unprotect(getupvalueAddr));

    const ulong idkAddr = ASLR(0x0138EFC0);
    typedef void* (__cdecl* idkCast)(...);
    static idkCast idk = reinterpret_cast<idkCast>(unprotect(idkAddr));

    const ulong index2adrAddr = ASLR(0x0138DA60);
    typedef int(__cdecl* index2adrCast)(ulong rL, int Index);
    static index2adrCast index2adr = reinterpret_cast<index2adrCast>(unprotect(index2adrAddr));

    const ulong insertAddr = ASLR(0x0138E2C0);
    typedef void(__cdecl* insertCast)(ulong rL, int Index);
    static insertCast insert = reinterpret_cast<insertCast>(unprotect(insertAddr));

    const ulong iscfunctionAddr = ASLR(0x0138E390);
    typedef int(__cdecl* iscfunctionCast)(ulong rL, int Index);
    static iscfunctionCast iscfunction = reinterpret_cast<iscfunctionCast>(unprotect(iscfunctionAddr));

    const ulong isnumberAddr = ASLR(0x0138E3E0);
    typedef int(__cdecl* isnumberCast)(ulong rL, int Index);
    static isnumberCast isnumber = reinterpret_cast<isnumberCast>(unprotect(isnumberAddr));

    const ulong isstringAddr = ASLR(0x0138E440);
    typedef int(__cdecl* isstringCast)(ulong rL, int Index);
    static isstringCast isstring = reinterpret_cast<isstringCast>(unprotect(isstringAddr));

    const ulong isuserdataAddr = ASLR(0x0138E340);
    typedef int(__cdecl* isuserdataCast)(ulong rL, int Index);
    static isuserdataCast isuserdata = reinterpret_cast<isuserdataCast>(unprotect(isuserdataAddr));

    const ulong lessthanAddr = ASLR(0x0138E490);
    typedef int(__cdecl* lessthanCast)(ulong rL, int Index1, int Index2);
    static lessthanCast lessthan = reinterpret_cast<lessthanCast>(unprotect(lessthanAddr));

    const ulong newthreadAddr = ASLR(0x0138E540);
    typedef ulong(__cdecl* newthreadCast)(ulong rL);
    static newthreadCast newthread = reinterpret_cast<newthreadCast>(unprotect(newthreadAddr));

    const ulong newuserdataAddr = ASLR(0x0138E5D0);
    typedef void(__cdecl* newuserdataCast)(ulong rL, size_t Size);
    static newuserdataCast newuserdata = reinterpret_cast<newuserdataCast>(unprotect(newuserdataAddr));

    const ulong nextAddr = ASLR(0x0138E650);
    typedef int(__cdecl* nextCast)(ulong rL, int Index);
    static nextCast next = reinterpret_cast<nextCast>(unprotect(nextAddr));

    const ulong objlenAddr = ASLR(0x0138E6E0);
    typedef size_t(__cdecl* objlenCast)(ulong rL, int Index);
    static objlenCast objlen = reinterpret_cast<objlenCast>(unprotect(objlenAddr));

    const ulong pcallAddr = ASLR(0x0138E7C0);
    typedef int(__cdecl* pcallCast)(ulong rL, int NArgs, int NResults, int ErrFunc);
    static pcallCast pcall = reinterpret_cast<pcallCast>(unprotect(pcallAddr));

    const ulong printAddr = ASLR(0x00669C50);
    typedef int(__cdecl* printCast)(int Type, const char* String, ...);
    static printCast print = reinterpret_cast<printCast>(unprotect(printAddr));

    const ulong pushbooleanAddr = ASLR(0x0138E880);
    typedef void(__cdecl* pushbooleanCast)(ulong rL, int Bool);
    static pushbooleanCast pushboolean = reinterpret_cast<pushbooleanCast>(unprotect(pushbooleanAddr));

    const ulong pushcclosureAddr = ASLR(0x0138E8D0);
    typedef void(__cdecl* pushcclosureCast)(ulong rL, ulong Function, void* Arg3, int Upvalues, int Arg5);
    static pushcclosureCast pushcclosure = reinterpret_cast<pushcclosureCast>(unprotect(pushcclosureAddr));

    const ulong pushfstringAddr = ASLR(0x0138E9B0);
    typedef const char* (__cdecl* pushfstringCast)(ulong rL, const char* Format, ...);
    static pushfstringCast pushfstring = reinterpret_cast<pushfstringCast>(unprotect(pushfstringAddr));

    const ulong pushintegerAddr = ASLR(0x0138EA20);
    typedef void(__cdecl* pushintegerCast)(ulong rL, int Number);
    static pushintegerCast pushinteger = reinterpret_cast<pushintegerCast>(unprotect(pushintegerAddr));

    const ulong pushlightuserdataAddr = ASLR(0x0138EA80);
    typedef void(__cdecl* pushlightuserdataCast)(ulong rL, void* Pointer);
    static pushlightuserdataCast pushlightuserdata = reinterpret_cast<pushlightuserdataCast>(unprotect(pushlightuserdataAddr));

    const ulong pushlstringAddr = ASLR(0x0138EAD0);
    typedef void(__cdecl* pushlstringCast)(ulong rL, const char* String, size_t Size);
    static pushlstringCast pushlstring = reinterpret_cast<pushlstringCast>(unprotect(pushlstringAddr));

    const ulong pushnilAddr = ASLR(0x0138EB50);
    typedef void(__cdecl* pushnilCast)(ulong rL);
    static pushnilCast pushnil = reinterpret_cast<pushnilCast>(unprotect(pushnilAddr));

    const ulong pushnumberAddr = ASLR(0x0138EBA0);
    typedef void(__stdcall* pushnumberCast)(ulong rL, double Number);
    static pushnumberCast pushnumber = reinterpret_cast<pushnumberCast>(unprotect(pushnumberAddr));

    const ulong pushstringAddr = ASLR(0x0138EC00);
    typedef void(__fastcall* pushstringCast)(ulong rL, const char* String);
    static pushstringCast pushstring = reinterpret_cast<pushstringCast>(unprotect(pushstringAddr));

    const ulong pushthreadAddr = ASLR(0x0138ECA0);
    typedef int(__cdecl* pushthreadCast)(ulong rL);
    static pushthreadCast pushthread = reinterpret_cast<pushthreadCast>(unprotect(pushthreadAddr));

    const ulong pushvalueAddr = ASLR(0x0138ED70);
    typedef void(__stdcall* pushvalueCast)(ulong rL, int Index);
    static pushvalueCast pushvalue = reinterpret_cast<pushvalueCast>(unprotect(pushvalueAddr));

    const ulong pushvfstringAddr = ASLR(0x0138EDE0);
    typedef const char* (__cdecl* pushvfstringCast)(ulong rL, const char* Format, va_list ArgP);
    static pushvfstringCast pushvfstring = reinterpret_cast<pushvfstringCast>(unprotect(pushvfstringAddr));

    const ulong rawequalAddr = ASLR(0x0138EEC0);
    typedef int(__cdecl* rawequalCast)(ulong rL, int Index1, int Index2);
    static rawequalCast rawequal = reinterpret_cast<rawequalCast>(unprotect(rawequalAddr));

    const ulong rawgetAddr = ASLR(0x0138EF40);
    typedef void(__cdecl* rawgetCast)(ulong rL, int Index);
    static rawgetCast rawget = reinterpret_cast<rawgetCast>(unprotect(rawgetAddr));

    const ulong rawgetiAddr = ASLR(0x0138F070);
    typedef void(__cdecl* rawgetiCast)(ulong rL, int Index, int Number);
    static rawgetiCast rawgeti = reinterpret_cast<rawgetiCast>(unprotect(rawgetiAddr));

    const ulong rawsetAddr = ASLR(0x0138F0F0);
    typedef void(__cdecl* rawsetCast)(ulong rL, int Index);
    static rawsetCast rawset = reinterpret_cast<rawsetCast>(unprotect(rawsetAddr));

    const ulong rawsetiAddr = ASLR(0x0138F1C0);
    typedef void(__cdecl* rawsetiCast)(ulong rL, int Index);
    static rawsetiCast rawseti = reinterpret_cast<rawsetiCast>(unprotect(rawsetiAddr));

    const ulong rawvalueAddr = ASLR(0x0138DB10);
    typedef int(__cdecl* rawvalueCast)(ulong rL, int Index);
    static rawvalueCast rawvalue = reinterpret_cast<rawvalueCast>(unprotect(rawvalueAddr));

    const ulong removeAddr = ASLR(0x0138F290);
    typedef void(__cdecl* removeCast)(ulong rL, int Index);
    static removeCast remove = reinterpret_cast<removeCast>(unprotect(removeAddr));

    const ulong replaceAddr = ASLR(0x0138F320);
    typedef void(__cdecl* replaceCast)(ulong rL, int Index);
    static replaceCast replace = reinterpret_cast<replaceCast>(unprotect(replaceAddr));

    const ulong resumeAddr = ASLR(0x013911B0);
    typedef int(__cdecl* resumeCast)(ulong rL, int NArg);
    static resumeCast resume = reinterpret_cast<resumeCast>(unprotect(resumeAddr));

    const ulong retcheckAddr = ASLR(0x006D7950);
    typedef void(__cdecl* retcheckCast)(...);
    static retcheckCast retcheck = reinterpret_cast<retcheckCast>(unprotect(retcheckAddr));

    const ulong sandboxthreadAddr = ASLR(0x007A6560);
    typedef int(__cdecl* sandboxthreadCast)(ulong rL, int Arg2, int* Arg3);
    static sandboxthreadCast sandboxthread = reinterpret_cast<sandboxthreadCast>(unprotect(sandboxthreadAddr));

    const ulong setfenvAddr = ASLR(0x0138F420);
    typedef int(__cdecl* setfenvCast)(ulong rL, int Index);
    static setfenvCast setfenv = reinterpret_cast<setfenvCast>(unprotect(setfenvAddr));

    const ulong setfieldAddr = ASLR(0x0138F4F0);
    typedef void(__stdcall* setfieldCast)(ulong rL, int Index, const char* Name);
    static setfieldCast setfield = reinterpret_cast<setfieldCast>(unprotect(setfieldAddr));

    const ulong setlocalAddr = ASLR(0x0139B270);
    typedef const char* (__cdecl* setlocalCast)(ulong rL, int Index, ulong Ar, int Number);
    static setlocalCast setlocal = reinterpret_cast<setlocalCast>(unprotect(setlocalAddr));

    const ulong setmetatableAddr = ASLR(0x0138F5A0);
    typedef int(__cdecl* setmetatableCast)(ulong rL, int Index);
    static setmetatableCast setmetatable = reinterpret_cast<setmetatableCast>(unprotect(setmetatableAddr));

    const ulong setreadonlyAddr = ASLR(0x0138F6B0);
    typedef int(__cdecl* setreadonlyCast)(ulong rL, int Index, byte State);
    static setreadonlyCast setreadonly = reinterpret_cast<setreadonlyCast>(unprotect(setreadonlyAddr));

    const ulong setsafeenvAddr = ASLR(0x0138F720);
    typedef void(__cdecl* setsafeenvCast)(ulong rL, ulong* Arg2, int Arg3, char Arg4);
    static setsafeenvCast setsafeenv = reinterpret_cast<setsafeenvCast>(unprotect(setsafeenvAddr));

    const ulong settableAddr = ASLR(0x0138F790);
    typedef void(__cdecl* settableCast)(ulong rL, int Index);
    static settableCast settable = reinterpret_cast<settableCast>(unprotect(settableAddr));

    const ulong settopAddr = ASLR(0x0138F810);
    typedef void(__cdecl* settopCast)(ulong rL, int Index);
    static settopCast settop = reinterpret_cast<settopCast>(unprotect(settopAddr));

    const ulong setupvalueAddr = ASLR(0x0138F890);
    typedef const char* (__cdecl* setupvalueCast)(ulong rL, int FuncIndex, int Number);
    static setupvalueCast setupvalue = reinterpret_cast<setupvalueCast>(unprotect(setupvalueAddr));

    const ulong tobooleanAddr = ASLR(0x0138F940);
    typedef int(__cdecl* tobooleanCast)(ulong rL, int Index);
    static tobooleanCast toboolean = reinterpret_cast<tobooleanCast>(unprotect(tobooleanAddr));

    const ulong tointegerAddr = ASLR(0x0138F990);
    typedef int(__cdecl* tointegerCast)(ulong rL, int Index);
    static tointegerCast tointeger = reinterpret_cast<tointegerCast>(unprotect(tointegerAddr));

    const ulong tolstringAddr = ASLR(0x0138FA10);
    typedef const char* (__fastcall* tolstringCast)(ulong rL, int Index, size_t* Size);
    static tolstringCast tolstring = reinterpret_cast<tolstringCast>(unprotect(tolstringAddr));

    const ulong tonumberAddr = ASLR(0x0138FB40);
    typedef double(__cdecl* tonumberCast)(ulong rL, int Index);
    static tonumberCast tonumber = reinterpret_cast<tonumberCast>(unprotect(tonumberAddr));

    const ulong topointerAddr = ASLR(0x0138FBC0);
    typedef const void* (__cdecl* topointerCast)(ulong rL, int Index);
    static topointerCast topointer = reinterpret_cast<topointerCast>(unprotect(topointerAddr));

    const ulong tostringAddr = ASLR(0x0138FC80);
    typedef const char* (__cdecl* tostringCast)(ulong rL, int Index);
    static tostringCast tostring = reinterpret_cast<tostringCast>(unprotect(tostringAddr));

    const ulong tothreadAddr = ASLR(0x0138FD00);
    typedef ulong(__cdecl* tothreadCast)(ulong rL, int Index);
    static tothreadCast tothread = reinterpret_cast<tothreadCast>(unprotect(tothreadAddr));

    const ulong tounsignedxAddr = ASLR(0x0138FD40);
    typedef int(__cdecl* tounsignedxCast)(ulong rL, int Arg2, ulong* Arg3);
    static tounsignedxCast tounsignedx = reinterpret_cast<tounsignedxCast>(unprotect(tounsignedxAddr));

    const ulong touserdataAddr = ASLR(0x0138FDD0);
    typedef void* (__cdecl* touserdataCast)(ulong rL, int Index);
    static touserdataCast touserdata = reinterpret_cast<touserdataCast>(unprotect(touserdataAddr));

    const ulong typeAddr = ASLR(0x0138FEC0);
    typedef int(__cdecl* typeCast)(ulong rL, int Index);
    static typeCast type = reinterpret_cast<typeCast>(unprotect(typeAddr));

    const ulong xmoveAddr = ASLR(0x0138FF60);
    typedef void(__cdecl* xmoveCast)(ulong rL, int Arg2, int Arg3);
    static xmoveCast xmove = reinterpret_cast<xmoveCast>(unprotect(xmoveAddr));

    const ulong yieldAddr = ASLR(0x01391410);
    typedef int(__cdecl* yieldCast)(ulong rL, int NResults);
    static yieldCast yield = reinterpret_cast<yieldCast>(unprotect(yieldAddr));

    static bool CheckType(ulong rL, int Index, int Type)
    {
        if (type(rL, Index) == Type)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    static void getglobal(ulong rL, const char* Name)
    {
        getfield(rL, -10002, Name);
    }

    static void GetTypes(ulong rL)
    {
        getfield(rL, -10002, OBFUSCATESTR("XenonIsCoolUnlikeYouSkid"));
        TNIL = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("game"));
        getfield(rL, -1, OBFUSCATESTR("Archivable"));
        TBOOLEAN = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("workspace"));
        getfield(rL, -1, OBFUSCATESTR("FallenPartsDestroyHeight"));
        TNUMBER = type(rL, -1);
        settop(rL, 0);
        pushlightuserdata(rL, nullptr);
        TLIGHTUSERDATA = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("game"));
        getfield(rL, -1, OBFUSCATESTR("JobId"));
        TSTRING = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("_G"));
        TTABLE = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("print"));
        TFUNCTION = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR("game"));
        TUSERDATA = type(rL, -1);
        settop(rL, 0);
        newthread(rL);
        TTHREAD = type(rL, -1);
        settop(rL, 0);
    }

    static void pop(ulong rL, int Num)
    {
        settop(rL, -(Num)-1);
    }

    static void setglobal(ulong rL, const char* Name)
    {
        setfield(rL, -10002, Name);
    }

    static void setthreadidentity(ulong rL, int Level)
    {
        *reinterpret_cast<ulong*>(*reinterpret_cast<ulong*>(rL + ThreadIdentityOffset2) + ThreadIdentityOffset1) = Level;
    }

    static void spawn(ulong rL)
    {
        getfield(rL, -10002, "spawn");
        pushvalue(rL, -2);
        pcall(rL, 1, 0, 0);
    }
}

namespace Callcheck
{
	static byte Int3BreakpointAOB[8] = { 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC };
	struct Register
	{
		ulong Int3Address;
		ulong FuncAddress;
	};

	std::vector<ulong> Breakpoints = {};
	std::vector<Register> Registers = {};

	LONG __stdcall CallcheckVEH(PEXCEPTION_POINTERS Exception) 
	{
		if (Exception->ExceptionRecord->ExceptionCode == 0x80000003L)
		{
			for (int Idx = 0; Idx < Registers.size(); Idx++) // Idk what the word 'fast' is lol. (I'm pretty sure this is slow compared to others.)
			{
				if (Exception->ContextRecord->Eip == Registers[Idx].Int3Address)
				{
					Exception->ContextRecord->Eip = Registers[Idx].FuncAddress;
					return -1;
				}
			}
			return 0;
		}
	}

	static ulong Bypass(ulong Address)
	{
		if (Breakpoints.size() < 1) // Initialize the breakpoint list and VEH
		{
			ulong Findings = 0;
			ulong Base = 0x400000 + reinterpret_cast<ulong>(GetModuleHandleA(0));
			for (ulong Idx = 0; Idx < 2147483647; Idx++)
			{
				if (Findings >= 100) // Increase if more than 100 functions are added.
				{
					break;
				}

				ulong At = Base + Idx;
				if (memcmp(reinterpret_cast<void*>(At), Int3BreakpointAOB, 8) == 0)
				{
					Breakpoints.push_back(At);
					Findings++;
				}
			}
			Console::Info(OBFUSCATESTR("Callcheck::Bypass"), OBFUSCATESTR("Found ") + std::to_string(Findings) + OBFUSCATESTR(" int3 breakpoints."));
			AddVectoredExceptionHandler(1, CallcheckVEH);
		}

		for (int Idx = 0; Idx < Registers.size(); Idx++)
		{
			if (Address == Registers[Idx].FuncAddress)
			{
				return Registers[Idx].Int3Address;
			}
		}

		ulong Next = Breakpoints[Registers.size()];
		Register New;
		New.Int3Address = Next;
		New.FuncAddress = Address;
		Registers.push_back(New);
		return Next;
	}

    static void PushCFunction(ulong rL, int Upvs, void* F)
    {
        RLua::pushcclosure(rL, Bypass((ulong)F), NULL, Upvs, NULL);
    }

	static void RegisterGlobalFunction(ulong rL, const char* RoutineName, void* F)
	{
		RLua::pushcclosure(rL, Bypass((ulong)F), NULL, NULL, NULL);
		RLua::setfield(rL, -10002, RoutineName);
		std::string RoutineCPPStr(RoutineName);
		Console::Info(OBFUSCATESTR("Callcheck::RegisterGlobalFunction"), RoutineCPPStr);
	}
}

namespace RFunctions
{
	int getgenv(ulong rL)
	{
		RLua::pushvalue(rL, LUA_GLOBALSINDEX);
		return 1;
	}

	int getregistry(ulong rL)
	{
		RLua::pushvalue(rL, LUA_REGISTRYINDEX);
		return 1;
	}

	int rconsoleprint(ulong rL)
	{
        if (RLua::CheckType(rL, 1, RLua::TSTRING))
        {
            Console::Write(RLua::tolstring(rL, 1, 0));
            RLua::pushboolean(rL, true);
            return 1;
        }
        RLua::pushboolean(rL, false);
		return 1;
	}

	int rconsoleclear(ulong rL)
	{
		Console::Clear();
		return 0;
	}

	int getrawmetatable(ulong rL)
	{
        if (RLua::CheckType(rL, 1, RLua::TUSERDATA) || RLua::CheckType(rL, 1, RLua::TSTRING) || RLua::CheckType(rL, 1, RLua::TTABLE))
        {
            if (RLua::getmetatable(rL, 1) == 0)
            {
                RLua::pushnumber(rL, 1); // 1: Failed to fetch metatable
                return 1;
            }
            return 1; // Return metatable
        }
        RLua::pushnumber(rL, 0xFF); // 255: Invalid type (Should be handled on initialization.)
        return 1;
	}

	int setreadonly(ulong rL)
	{
        if (RLua::CheckType(rL, 1, RLua::TTABLE) && RLua::CheckType(rL, 2, RLua::TBOOLEAN))
        {
            byte Is = RLua::toboolean(rL, 2);
            RLua::setreadonly(rL, 1, Is);
            RLua::pushnumber(rL, 1); // 1: Success
            return 1;
        }
        RLua::pushnumber(rL, 0xFF); // 255: Invalid type (Should be handled on initialization.)
		return 0;
	}

    int newcclosureh(ulong rL) // Handles wrapping the function in C
    {
        int NArgs = RLua::gettop(rL); // Amount of args passed
        RLua::pushvalue(rL, lua_upvalueindex(1)); // Alright, let's fetch this function so we can call it.
        RLua::insert(rL, 1);

        int Return = RLua::pcall(rL, NArgs, -1, 0); // Multiple results
        if (Return != 0)
        {
            size_t ErrSize;
            const char* Err = RLua::tolstring(rL, -1, &ErrSize);
            std::string ErrorCPPStr(Err);
            if (ErrorCPPStr.find("attempt to yield across metamethod/C-call boundary") != std::string::npos) // Keep roblox from crashing if you attempt to yield
            {
                return RLua::yield(rL, 0);
            }
            RLua::pushstring(rL, Err); // String: Error
            return 1;
        }
        RLua::pushnumber(rL, 1); // 1: Success
        return 1;
    }

    int newcclosure(ulong rL)
    {
        if (RLua::CheckType(rL, 1, RLua::TFUNCTION))
        {
            RLua::pushvalue(rL, 1);
            Callcheck::PushCFunction(rL, 1, newcclosureh);
            return 1;
        }
        
        RLua::pushnumber(rL, 0xFF); // 255: Invalid type (Should be handled on initialization.)
        return 1;
    }

	void Init(ulong rL)
	{
		Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("getgenv"), getgenv);
		Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("getregistry"), getregistry);

		Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("rconsoleprint"), rconsoleprint);
		Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("rconsoleclear"), rconsoleclear);

		Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("getrawmetatable"), getrawmetatable);
        Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("setreadonly"), setreadonly);

        Callcheck::RegisterGlobalFunction(rL, OBFUSCATESTR("newcclosure"), newcclosure);
	}
}