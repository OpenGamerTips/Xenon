using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using static XenonClient.WinAPI;

namespace XenonClient
{
    public class WinAPI
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(int hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int GetProcAddress(int hModule, string lpProcName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int LoadLibraryA(string lpFileName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int VirtualAllocEx(int hProcess, int lpAddress, int size, uint allocation_type, uint protect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool VirtualFreeEx(int hProcess, int lpAddress, int dwSize, uint dwFreeType);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteProcessMemory(int hProcess, int lpBaseAddress, byte[] lpBuffer, int dwSize, ref int lpNumberOfBytesWritten);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int CreateRemoteThread(int hProcess, int lpThreadAttributes, uint dwStackSize, int lpStartAddress, int lpParameter, uint dwCreationFlags, int lpThreadId);

        // Process Access Constants (Would be in defined in C++ Windows.h but since we are in C# we have to define them 
        public const int PROCESS_CREATE_THREAD = 0x02;
        public const int PROCESS_QUERY_INFORMATION = 0x400;
        public const int PROCESS_VM_OPERATION = 0x08;
        public const int PROCESS_VM_READ = 0x10;
        public const int PROCESS_VM_WRITE = 0x20;

        // Memory Allocation Constants
        public const uint MEM_COMMIT = 0x1000;
        public const uint MEM_RESERVE = 0x2000;
        public const uint MEM_RELEASE = 0x8000;

        // Protection Constants
        public const uint PAGE_EXECUTE_READWRITE = 0x40;
    }
    public class Injector
    {
        public static bool InjectDLL(Process Proc, string DLLPath)
        {
            if (!File.Exists(DLLPath))
            {
                throw new FileNotFoundException("The specified DLL file does not exist.");
            }

            int ProcHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, Proc.Id);
            if (ProcHandle == 0)
            {
                CloseHandle(ProcHandle);
                return false;
            }

            int Loc = VirtualAllocEx(ProcHandle, 0, 260, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
            if (Loc == 0)
            {
                CloseHandle(ProcHandle);
                return false;
            }

            int _ = 0;
            bool BytesWritten = WriteProcessMemory(ProcHandle, Loc, Encoding.ASCII.GetBytes(DLLPath), DLLPath.Length, ref _);
            if (!BytesWritten)
            {
                CloseHandle(ProcHandle);
                return false;
            }

            int LoadLibraryAddr = GetProcAddress(LoadLibraryA("kernel32.dll"), "LoadLibraryA");
            if (LoadLibraryAddr == 0)
            {
                VirtualFreeEx(ProcHandle, Loc, 0, MEM_RELEASE);
                CloseHandle(ProcHandle);
                return false;
            }

            int NewThread = CreateRemoteThread(ProcHandle, 0, 0, LoadLibraryAddr, Loc, 0, 0);
            if (NewThread == 0)
            {
                VirtualFreeEx(ProcHandle, Loc, 0, MEM_RELEASE);
                CloseHandle(ProcHandle);
                return false;
            }

            CloseHandle(NewThread);
            VirtualFreeEx(ProcHandle, Loc, 0, MEM_RELEASE);
            CloseHandle(ProcHandle);
            return true;
        }
    }
}