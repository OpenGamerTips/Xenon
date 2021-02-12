#pragma once
#include <Windows.h>
#include <iostream>
#define Seed (__TIME__[0] - '0' + __TIME__[1] - '0' + __TIME__[3] - '0' + __TIME__[4] - '0' + __TIME__[6] - '0' + __TIME__[7] - '0')
template <int Size> struct ObfuscatedString
{
	char Obfuscated[Size] = { 0 };
	constexpr ObfuscatedString(const char* Data)
	{
		for (int Idx = 0; Idx < Size; Idx++)
		{
			Obfuscated[Idx] = Data[Idx] xor Seed;
		}
	}

	void Deobfuscate(char* Data) const
	{
		int Idx = 0;
		for (int Idx = 0; Idx < Size; Idx++)
		{
			Data[Idx] = Obfuscated[Idx] xor Seed;
		}
	}
};

// Found out Roblox scans for the strings "rL" and "Lua State", probably more as well (I found out by removing rL from my strings and Roblox wouldn't crash.) so I have to add this.
#define OBFUSCATESTR(String) \
    []() -> char* { \
        constexpr int Size = sizeof(String) / sizeof(String[0]); \
        constexpr auto Obfuscated = ObfuscatedString<Size>(String); \
        static char Deobfuscated[Size]; \
        Obfuscated.Deobfuscate(reinterpret_cast<char*>(Deobfuscated)); \
        return Deobfuscated; \
    }()

static void SETSEED()
{
	srand(time(0));
}

static int RANDINT(int Lowest, int Highest)
{
	return rand() % Highest + Lowest;
}

static const char Charset[] = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0123456789";
static std::string RANDSTR(int Len)
{
	std::string Rand;
	Rand.reserve(Len);

	for (int Idx = 0; Idx < Len; Idx++)
	{
		int Access = rand() % (sizeof(Charset) - 1);
		Rand += Charset[Access];
	}

	return Rand;
}