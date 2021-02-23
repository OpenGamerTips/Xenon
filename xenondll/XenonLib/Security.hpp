#pragma once
#include <Windows.h>
#include <iostream>

#define SEED (__TIME__[0] + __TIME__[1] + __TIME__[3] + __TIME__[4] + __TIME__[6] + __TIME__[7])
template <int Size, int Key>
class ObfuscatedString
{
private:
	char Obfuscated[Size];
	char Deobfuscated[Size];
public:
	constexpr ObfuscatedString(const char* Data)
	{
		for (int Idx = 0; Idx < Size; Idx++)
		{
			Obfuscated[Idx] = Data[Idx] ^ SEED;
		}
	}

	const char* Deobfuscate()
	{
		int Idx = 0;
		for (int Idx = 0; Idx < Size; Idx++)
		{
			Deobfuscated[Idx] = Obfuscated[Idx] ^ SEED;
		}
		return &Deobfuscated[0];
	}
};

#define OBFUSCATESTRKEY(String, Key) \
    []() -> const char* { \
        constexpr unsigned int Len = sizeof(String) / sizeof(String[0]); \
        static auto Encrypted = ObfuscatedString<Len, Key>(String); \
        return Encrypted.Deobfuscate(); \
    }()
#define OBFUSCATESTR(String) OBFUSCATESTRKEY(String, SEED)

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