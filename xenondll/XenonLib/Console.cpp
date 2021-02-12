#pragma warning (disable: 6031)
#include "XenonLib.hpp"
using Xenon::Console;

// Window Vars
bool Console::IsInit = false;
bool Console::IsVisible = false;

// Window Funcs
void Console::Open(std::string Name)
{
	DWORD _;
	VirtualProtect(&FreeConsole, 1, PAGE_EXECUTE_READWRITE, &_);
	*(byte*)(&FreeConsole) = 0xC3;
	AllocConsole();
	Console::SetName(Name);
	freopen("CONOUT$", "w", stdout);
	freopen("CONIN$", "r", stdin);
	Console::IsInit = true;
}

bool Console::ToggleVis()
{
	if (!Console::IsInit)
	{
		Console::Open();
		return true;
	}
	else if (Console::IsVisible)
	{
		Console::Hide();
		return false;
	}
	else
	{
		Console::Show();
		return true;
	}
}

void Console::Show()
{
	ShowWindow(GetConsoleWindow(), SW_SHOW);
}

void Console::Hide()
{
	ShowWindow(GetConsoleWindow(), SW_HIDE);
}

void Console::SetName(std::string Name)
{
	SetConsoleTitleA(Name.c_str());
}


// Text Funcs
std::string Console::ReadLine()
{
	std::string Input;
	std::getline(std::cin, Input);
	return Input;
}

char Console::Read()
{
	return (char)_getch();
}

void Console::Write(std::string Message)
{
	std::cout << Message;
}

void Console::WriteHex(uint Message)
{
	std::cout << std::hex << Message;
}

void Console::WriteLine(std::string Message)
{
	std::cout << Message << "\n";
}

void Console::Info(int Type, std::string Message)
{
	void* ConsoleHandle = GetStdHandle(STD_OUTPUT_HANDLE);
	if (!ConsoleHandle)
	{
		return;
	}

	CONSOLE_SCREEN_BUFFER_INFO SavedInfo; // SavedInfo.wAttributes is the integer for text attributes.
	GetConsoleScreenBufferInfo(ConsoleHandle, &SavedInfo);

	if (Type == 1)
	{
		SetConsoleTextAttribute(ConsoleHandle, 10);
		std::cout << "[+] ";
	}
	if (Type == 0)
	{
		SetConsoleTextAttribute(ConsoleHandle, 14);
		std::cout << "[=] ";
	}
	else if (Type == -1)
	{
		SetConsoleTextAttribute(ConsoleHandle, 12);
		std::cout << "[-] ";
	}
	
	SetConsoleTextAttribute(ConsoleHandle, 7);
	std::cout << Message << "\n";
	SetConsoleTextAttribute(ConsoleHandle, SavedInfo.wAttributes); // Revert color
}