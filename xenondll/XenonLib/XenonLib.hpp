// XenonLib.hpp
// Exports the Xenon classes (i.e: Functions from Console.cpp, etc.)
#pragma once

#pragma region Includes
#include <Windows.h>
#include <iostream>
#include <sstream>
#include <conio.h>
#include <thread>
#include <vector>
extern "C"
{
	#include "..\Lua\lua.h"
	#include "..\Lua\lualib.h"
	#include "..\Lua\lauxlib.h"
	#include "..\Lua\luaconf.h"
	#include "..\Lua\llimits.h"
}
#pragma endregion

#pragma region Definitions
// Console constants
#define CONSOLE_INFO_SUCCESS 1
#define CONSOLE_INFO_NOTICE 0
#define CONSOLE_INFO_ERROR -1

// Make my brain not hurt
#define WriteByte(Address, Value) *(byte*)((ulong)Address) = (byte)Value
#define WriteInt32(Address, Value) *(uint*)((ulong)Address) = (uint)Value
#define ReadByte(Address) *(byte*)((ulong)Address)
#define ReadInt32(Address) *(uint*)((ulong)Address)
#pragma endregion

#pragma region Custom Types
typedef unsigned int uint;
typedef unsigned long ulong;

typedef void(*NamedPipeCallback)(std::string PipeMsg);
#pragma endregion

namespace Xenon
{
	#pragma region Console Class
	class Console
	{
	private:
		// Window Vars
		static bool IsInit;
		static bool IsVisible;
	public:
		// Window Funcs
		static void Open(std::string Name = "");
		static void Show();
		static void Hide();
		static bool ToggleVis();
		static void SetName(std::string Name);

		// Text Funcs
		static std::string ReadLine();
		static char Read();
		static void Write(std::string Message);
		static void WriteHex(uint Message);
		static void WriteLine(std::string Message);
		static void Info(int Type, std::string Message);
	};
	#pragma endregion

	#pragma region NamedPipes Class
	class Pipes
	{
	public:
		static void ListenPipe(std::string PipeName, NamedPipeCallback Callback);
	};
	#pragma endregion

	#pragma region Utility Class
	class Utility
	{
	public:
		struct FuncData
		{
			ulong ProloguePoint;
			ulong EpiloguePoint;
			std::vector<byte> Assembly;
			uint Size;
		};
		static FuncData* GetFuncData(ulong Point);
		static void* DetourFunction(ulong Point, ulong Loc);
		static bool UnDetourFunction(uint Point, void* Backup);
	};
	#pragma endregion
}