// XenonLib.hpp
// Exports the Xenon classes (i.e: Functions from Console.cpp, etc.)
#pragma once

#pragma region Includes
#include <Windows.h>
#include <iostream>
#include <sstream>
#include <conio.h>
#include <thread>
extern "C"
{
	#include "../Lua/lua.h"
	#include "../Lua/lauxlib.h"
	#include "../Lua/lualib.h"
	#include "../Lua/lobject.h"
	#include "../Lua/lstate.h"
	#include "../Lua/lfunc.h"
	#include "../Lua/lopcodes.h"
	#include "../Lua/lstring.h"
	#include "../Lua/ldo.h"
	#include "../Lua/llex.h"
	#include "../Lua/lvm.h"
}
#pragma endregion

#pragma region Definitions
// Console constants
#define CONSOLE_INFO_SUCCESS 1
#define CONSOLE_INFO_NOTICE 0
#define CONSOLE_INFO_ERROR -1

// Make my brain not hurt
#define WriteByte(Address, Value) *(byte*)((DWORD)Address) = (byte)Value
#define WriteInt32(Address, Value) *(int*)((DWORD)Address) = (int)Value
#define ReadByte(Address) *(byte*)((DWORD)Address)
#define ReadInt32(Address) *(int*)((DWORD)Address)
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

	#pragma region Utility
	class Utility
	{
	public:
		static void* DetourAsm32(ulong Point, void* To);
		static bool UnDetourAsm32(ulong Point, void* Backup);
	};
	#pragma endregion
}