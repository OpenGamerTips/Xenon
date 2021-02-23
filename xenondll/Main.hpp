#include <Windows.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <chrono>
#include "XenonLib\XenonLib.hpp"
#include "RLua.h"
#include "EyeStep\eyestep.h"
#include "EyeStep\eyestep_utility.h"
#pragma once

ulong TimeSinceEpoch()
{
	return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
}