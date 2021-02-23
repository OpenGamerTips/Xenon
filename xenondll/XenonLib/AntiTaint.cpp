#include "XenonLib.hpp"
using Xenon::AntiTaint;
using Xenon::Utility;

ulong MessageBoxAAddr;
void* OldMB;
int __stdcall MBHook()
{
	Utility::UnDetourFunction(MessageBoxAAddr, OldMB);
	MessageBoxA(NULL, OBFUSCATESTR("We don't really know what happened but Roblox has crashed.\nDont worry though, Xenon blocked the crash dump upload.\n\nPlease report this to H3x0R."), OBFUSCATESTR("Roblox Crashed!"), 0); // lol
	TerminateProcess(GetCurrentProcess(), 0); // Kill the game process before it can create a crash dump and upload it. Roblox is stupid https://h3x0r.likes-throwing.rocks/gg7BJ7.png
	return 1;
}

int AntiTaint::Init()
{
	HMODULE User32 = GetModuleHandleA(OBFUSCATESTR("USER32.DLL"));
	if (User32 == NULL) // Should NEVER get hit
	{
		Console::Info(OBFUSCATESTR("AntiTaint::Init"), OBFUSCATESTR("Failed to get module."));
		return -1;
	}
	MessageBoxAAddr = (ulong)GetProcAddress(User32, OBFUSCATESTR("MessageBoxA"));
	if (MessageBoxAAddr == NULL) // This too
	{
		Console::Info(OBFUSCATESTR("AntiTaint::Init"), OBFUSCATESTR("Failed to find address."));
		return -2;
	}
	OldMB = Utility::DetourFunction(MessageBoxAAddr, (ulong)MBHook);
	Console::Info(OBFUSCATESTR("AntiTaint::Init"), OBFUSCATESTR("Loaded!"));
	return 1;
}