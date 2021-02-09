using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
//using static XenonUI.WinAPI;
using static XenonDumper.WinAPI;

namespace XenonDumper
{
    class WinAPI
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int GetProcAddress(int hModule, string lpProcName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int LoadLibraryA(string lpFileName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(int hObject);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int VirtualAllocEx(int hProcess, int lpAddress, int size, uint allocation_type, uint protect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool VirtualFreeEx(int hProcess, int lpAddress, int dwSize, uint dwFreeType);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool WriteProcessMemory(int hProcess, int lpBaseAddress, byte[] lpBuffer, int dwSize, ref int lpNumberOfBytesWritten);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern int CreateRemoteThread(int hProcess, int lpThreadAttributes, uint dwStackSize, int lpStartAddress, int lpParameter, uint dwCreationFlags, int lpThreadId);

        public const int PROCESS_CREATE_THREAD = 0x02;
        public const int PROCESS_QUERY_INFORMATION = 0x400;
        public const int PROCESS_VM_OPERATION = 0x08;
        public const int PROCESS_VM_WRITE = 0x20;
        public const int PROCESS_VM_READ = 0x10;

        public const uint MEM_COMMIT = 0x1000;
        public const uint MEM_RESERVE = 0x2000;
        public const uint PAGE_EXECUTE_READWRITE = 0x40;

        public const uint MEM_RELEASE = 0x8000;
    }
    class Injector
    {
        public static int InjectDLL(string ProcName, string DLLPath)
        {
            if (!File.Exists(DLLPath))
            {
                throw new Exception("DLL does not exist.");
            }

            Process[] Instances = Process.GetProcessesByName(Path.GetFileNameWithoutExtension(ProcName)); // kinda a sketchy way to remove .exe or .programext
            if (Instances.Length > 0)
            {
                int ProcHandle = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, false, Instances.Last().Id);
                if (ProcHandle == 0)
                {
                    CloseHandle(ProcHandle);
                    return -2;
                }

                int Alloc = VirtualAllocEx(ProcHandle, 0, 260, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
                if (Alloc == 0)
                {
                    CloseHandle(ProcHandle);
                    return -3;
                }

                int _ = 0;
                bool HasWritten = WriteProcessMemory(ProcHandle, Alloc, Encoding.ASCII.GetBytes(DLLPath), DLLPath.Length, ref _);
                if ((!HasWritten))
                {
                    CloseHandle(ProcHandle);
                    return -4;
                }

                int LoadLibraryAddr = GetProcAddress(LoadLibraryA("kernel32.dll"), "LoadLibraryA"); // ironic coding at its finest
                if (LoadLibraryAddr == 0)
                {
                    VirtualFreeEx(ProcHandle, Alloc, 260, MEM_RELEASE);
                    CloseHandle(ProcHandle);
                    return -5;
                }

                int CreatedThread = CreateRemoteThread(ProcHandle, 0, 0, LoadLibraryAddr, Alloc, 0, 0);
                if (CreatedThread == 0)
                {
                    VirtualFreeEx(ProcHandle, Alloc, 260, MEM_RELEASE);
                    CloseHandle(ProcHandle);
                    return -6;
                }

                CloseHandle(CreatedThread);
                VirtualFreeEx(ProcHandle, Alloc, 260, MEM_RELEASE);
                CloseHandle(ProcHandle);
                return 0;
            }
            else
            {
                return -1;
            }
        }
    }
}
