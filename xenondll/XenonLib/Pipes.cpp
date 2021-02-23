#include "XenonLib.hpp"
using Xenon::Pipes;

void Pipes::ListenPipe(std::string PipeName, NamedPipeCallback Callback)
{
	char Buffer[1024];
	HANDLE CurrPipe = CreateNamedPipeA(
		(std::string("\\\\.\\pipe\\") + PipeName).c_str(),
		PIPE_ACCESS_DUPLEX | PIPE_TYPE_BYTE | PIPE_READMODE_BYTE,
		PIPE_WAIT,
		1,
		1024,
		1024,
		NMPWAIT_USE_DEFAULT_WAIT,
		NULL
	);

	while (CurrPipe != INVALID_HANDLE_VALUE)
	{
		if (ConnectNamedPipe(CurrPipe, NULL) != FALSE)
		{
			std::string Input;
			ulong BytesRead;
			while (ReadFile(CurrPipe, Buffer, 1023, &BytesRead, NULL) != FALSE)
			{
				Buffer[BytesRead] = '\0';
				Input += Buffer;
			}

			Callback(Input);
		}
		DisconnectNamedPipe(CurrPipe);
	}
}