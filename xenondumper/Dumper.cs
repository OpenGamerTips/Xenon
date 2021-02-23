using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using EyeStepPackage;

namespace XenonDumper
{
    class Console2
    {
        public static void Info(string From, string Text)
        {
            Console.Write("[");
            Console.ForegroundColor = ConsoleColor.DarkGray;
            Console.Write(From);
            Console.ForegroundColor = ConsoleColor.White;
            Console.Write("] ");
            Console.Write(Text);
            Console.Write("\n");
        }
    }
    class Formatter
    {
        public static string BasicFormat()
        {
            string Basic = "";
            foreach (KeyValuePair<string, int> Entry in Dumper.Functions.OrderBy(Key => Key.Key))
            {
                Basic += string.Format("lua_{0} : 0x{1:X8} : {2}\n", Entry.Key, util.raslr(Entry.Value), Dumper.CallingConventions[Entry.Key]);
            }
            Console2.Info("Formatter.BasicFormat", "Constructed string.");
            return Basic;
        }

        public static string HeaderFormat()
        {
            string Namespace = @"typedef unsigned long ulong;
namespace RLua
{
";
            Namespace += @"    // Offsets need manual updating.
    const ulong ThreadIdentityOffset1 = 1234; // Pseudocode sandboxthread look for "" * (_QWORD*)(v4 + OFFSET) = *(_OWORD*)a2; ""
    const ulong ThreadIdentityOffset2 = 5678; // Pseudocode sandboxthread look for ""v4 = *(_DWORD*)(a1 + OFFSET"");

    static ulong TNIL = 0;
    static ulong TBOOLEAN = 0;
    static ulong TLIGHTUSERDATA = 0;
    static ulong TNUMBER = 0;
    static ulong TSTRING = 0;
    static ulong TTABLE = 0;
    static ulong TFUNCTION = 0;
    static ulong TUSERDATA = 0;
    static ulong TTHREAD = 0;

";
            foreach (KeyValuePair<string, int> Entry in Dumper.Functions.OrderBy(Key => Key.Key))
            {
                Assets.Args Arguments = Assets.FuncArguments[Entry.Key];
                Namespace += ($"    const ulong {Entry.Key}Addr = {string.Format("ASLR(0x{0:X8})", util.raslr(Entry.Value))};\n"); // Why didnt I use /t? Because formatting in the console is retarded.
                Namespace += ($"    typedef {Arguments.Returned}({Dumper.CallingConventions[Entry.Key]}* {Entry.Key}Cast)({Arguments.Passed});\n");
                Namespace += ($"    static {Entry.Key}Cast {Entry.Key} = reinterpret_cast<{Entry.Key}Cast>(unprotect({Entry.Key}Addr));\n\n");
            }
            Console2.Info("Formatter.HeaderFormat", "Added function definitions.");

            foreach (KeyValuePair<string, string> Entry in Assets.Macros.OrderBy(Key => Key.Key))
            {
                Namespace += ($"    static {Entry.Key}\n    {'{'}\n        {Entry.Value}\n    {'}'}\n\n");
            }
            Console2.Info("Formatter.HeaderFormat", "Added macro definitions.");

            Namespace = Namespace.Substring(0, Namespace.Length - 1) + "}\n";
            Console2.Info("Formatter.HeaderFormat", "Constructed string.");
            return Namespace;
        }

        public static string IDAPythonFormat()
        {
            string Python = "";
            foreach (KeyValuePair<string, int> Entry in Dumper.Functions.OrderBy(Key => Key.Key))
            {
                Python += string.Format("MakeName(0x{0:X8}, \"{1}\"); ", Entry.Value, Entry.Key);
            }
            Console2.Info("Formatter.IDAPythonFormat", "Constructed string.");
            return Python;
        }
    }
    class Dumper
    {
        public static Dictionary<string, int> Functions = new Dictionary<string, int>();
        public static Dictionary<string, string> CallingConventions = new Dictionary<string, string>();
        public static Dictionary<string, int> LuaTypes = new Dictionary<string, int>();

        public static void DumpAddresses()
        {
            int TostringRefLocation = scanner.scan_xrefs("tostring")[0];
            int GetTopAddr = util.prevCall(util.prevCall(TostringRefLocation, true));
            Functions.Add("gettop", GetTopAddr);
            CallingConventions.Add("gettop", util.convs[util.getConvention(GetTopAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added gettop.");

            int GetFieldAddr = util.nextCall(TostringRefLocation);
            // This will get added when scanning lol

            int Index2AdrAddr = util.nextCall(GetFieldAddr);
            Functions.Add("index2adr", Index2AdrAddr);
            CallingConventions.Add("index2adr", util.convs[util.getConvention(Index2AdrAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added index2adr.");

            int RetcheckAddr = util.prevCall(util.getEpilogue(GetFieldAddr));
            Functions.Add("retcheck", RetcheckAddr);
            CallingConventions.Add("retcheck", util.convs[util.getConvention(RetcheckAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added retcheck.");

            Console2.Info("Dumper.DumpAddresses", "Scanning index2adr cross references...");
            List<int> Index2AdrAddrs = scanner.scan_xrefs(Index2AdrAddr);
            for (int Idx = 1; Idx < Assets.Index2AdrXRs.Count; Idx++)
            {
                string Name = Assets.Index2AdrXRs[Idx];
                if (!Functions.ContainsKey(Name))
                {
                    int Prologue = util.getPrologue(Index2AdrAddrs[Idx - 1]);
                    Functions.Add(Assets.Index2AdrXRs[Idx], Prologue);
                    CallingConventions.Add(Assets.Index2AdrXRs[Idx], util.convs[util.getConvention(Prologue)]);
                    Console2.Info("Dumper.DumpAddresses", $"Added {Name}.");
                }
            }

            Console2.Info("Dumper.DumpAddresses", "Scanning retcheck cross references...");
            List<int> RetcheckAddrs = scanner.scan_xrefs(RetcheckAddr);
            for (int Idx = 1; Idx < Assets.RetcheckXRs.Count; Idx++)
            {
                string Name = Assets.RetcheckXRs[Idx];
                //Console.WriteLine("rtc: " + Name);
                if (!Functions.ContainsKey(Name))
                {
                    int Prologue = util.getPrologue(RetcheckAddrs[Idx - 1]);
                    Functions.Add(Assets.RetcheckXRs[Idx], Prologue);
                    CallingConventions.Add(Assets.RetcheckXRs[Idx], util.convs[util.getConvention(Prologue)]);
                    Console2.Info("Dumper.DumpAddresses", $"Added {Name}.");
                }
            }
            
            int DeserializeAddr = util.getPrologue(scanner.scan_xrefs(": bytecode version mismatch")[0]);
            Functions.Add("deserialize", DeserializeAddr);
            CallingConventions.Add("deserialize", util.convs[util.getConvention(DeserializeAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added deserialize.");

            int PrintAddr = util.nextCall(scanner.scan_xrefs("Video recording started")[0]);
            Functions.Add("print", PrintAddr);
            CallingConventions.Add("print", util.convs[util.getConvention(PrintAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added print.");

            int SandboxThreadAddr = util.getPrologue(scanner.scan_xrefs("__index")[2]);
            Functions.Add("sandboxthread", SandboxThreadAddr);
            CallingConventions.Add("sandboxthread", util.convs[util.getConvention(SandboxThreadAddr)]);
            Console2.Info("Dumper.DumpAddresses", "Added sandboxthread.");
        }
    }
    class Assets
    {
        public static Dictionary<string, string> Macros = new Dictionary<string, string> // Only for RLua.h
        {
            {
                "void getglobal(ulong rL, const char* Name)",
                @"getfield(rL, -10002, Name);"
            },
            {
                "void setglobal(ulong rL, const char* Name)",
                @"setfield(rL, -10002, Name);"
            },
            {
                "void pop(ulong rL, int Num)",
                @"settop(rL, -(Num)-1);"
            },
            {
                "void spawn(ulong rL)",
                @"getfield(rL, -10002, ""spawn"");
        pushvalue(rL, -2);
        pcall(rL, 1, 0, 0);"
            },
            {
                "void GetTypes(ulong rL)",
                @"getfield(rL, -10002, OBFUSCATESTR(""XenonIsCoolUnlikeYouSkid""));
        TNIL = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""game""));
        getfield(rL, -1, OBFUSCATESTR(""Archivable""));
        TBOOLEAN = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""workspace""));
        getfield(rL, -1, OBFUSCATESTR(""FallenPartsDestroyHeight""));
        TNUMBER = type(rL, -1);
        settop(rL, 0);
        pushlightuserdata(rL, nullptr);
        TLIGHTUSERDATA = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""game""));
        getfield(rL, -1, OBFUSCATESTR(""JobId""));
        TSTRING = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""_G""));
        TTABLE = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""print""));
        TFUNCTION = type(rL, -1);
        settop(rL, 0);
        getfield(rL, -10002, OBFUSCATESTR(""game""));
        TUSERDATA = type(rL, -1);
        settop(rL, 0);
        newthread(rL);
        TTHREAD = type(rL, -1);
        settop(rL, 0);"
            },
            {
                "bool CheckType(ulong rL, int Index, int Type)",
                @"if (type(rL, Index) == Type)
        {
            return true;
        }
        else
        {
            return false;
        }"
            },
            {
                "void setthreadidentity(ulong rL, int Level)",
                "*reinterpret_cast<ulong*>(*reinterpret_cast<ulong*>(rL + ThreadIdentityOffset2) + ThreadIdentityOffset1) = Level;"
            }
        };

        public struct Args
        {
            public string Passed;
            public string Returned;
            public Args(string A = "", string B = "")
            {
                Passed = string.IsNullOrEmpty(A) ? "..." : A;
                Returned = string.IsNullOrEmpty(B) ? "void" : B;
            }
        }

        public static Dictionary<string, Args> FuncArguments = new Dictionary<string, Args> // It took a lot of free will power to write this.
        {
            {
                "idk",
                new Args(null, "void*")
            },
            {
                "callhook",
                new Args("ulong rL, void(__cdecl* Arg2)(int, char*), int Arg3", "int")
            },
            {
                "call",
                new Args("ulong rL, int Nargs, int NResults")
            },
            {
                "checkstack",
                new Args("ulong rL, void(__cdecl* Arg2)(int, char*), int Arg3", "int")
            },
            {
                "concat",
                new Args("ulong rL, int Number")
            },
            {
                "createtable",
                new Args("ulong rL, int NumberArrayAlloc, int NumberNonArrayCalloc")
            },
            {
                "deserialize",
                new Args("ulong rL, const char* ChunkName, const char* Bytecode, size_t BytecodeSize", "int")
            },
            {
                "equal",
                new Args("ulong rL, int Index1, int Index2", "int")
            },
            {
                "f_call",
                new Args("ulong rL, ulong Arg2", "char*")
            },
            {
                "gc",
                new Args("ulong rL, int What, int Data", "int")
            },
            {
                "getargument",
                new Args("ulong rL, int Arg2, int Arg3", "int")
            },
            {
                "getfenv",
                new Args("ulong rL, int Index")
            },
            {
                "getfield",
                new Args("ulong rL, int Index, const char* Name")
            },
            {
                "getmetatable",
                new Args("ulong rL, int Index", "int")
            },
            {
                "gettable",
                new Args("ulong rL, int index")
            },
            {
                "gettop",
                new Args("ulong rL", "int")
            },
            {
                "index2adr",
                new Args("ulong rL, int Index", "int")
            },
            {
                "insert",
                new Args("ulong rL, int Index")
            },
            {
                "iscfunction",
                new Args("ulong rL, int Index", "int")
            },
            {
                "isnumber",
                new Args("ulong rL, int Index", "int")
            },
            {
                "isuserdata",
                new Args("ulong rL, int Index", "int")
            },
            {
                "isstring",
                new Args("ulong rL, int Index", "int")
            },
            {
                "lessthan",
                new Args("ulong rL, int Index1, int Index2", "int")
            },
            {
                "newthread",
                new Args("ulong rL", "ulong")
            },
            {
                "newuserdata",
                new Args("ulong rL, size_t Size")
            },
            {
                "next",
                new Args("ulong rL, int Index", "int")
            },
            {
                "objlen",
                new Args("ulong rL, int Index", "size_t")
            },
            {
                "isboolean",
                new Args("ulong rL, ")
            },
            {
                "pcall",
                new Args("ulong rL, int NArgs, int NResults, int ErrFunc", "int")
            },
            {
                "print",
                new Args("int Type, const char* String, ...", "int")
            },
            {
                "pushboolean",
                new Args("ulong rL, int Bool")
            },
            {
                "pushcclosure",
                new Args("ulong rL, ulong Function, void* Arg3, int Upvalues, int Arg5")
            },
            {
                "pushfstring",
                new Args("ulong rL, const char* Format, ...", "const char*")
            },
            {
                "pushinteger",
                new Args("ulong rL, int Number")
            },
            {
                "pushlightuserdata", // Rant time: WHEN DO WE EVER PUSH POINTERS IN LUA!?
                new Args("ulong rL, void* Pointer")
            },
            {
                "pushlstring",
                new Args("ulong rL, const char* String, size_t Size")
            },
            {
                "pushnil",
                new Args("ulong rL")
            },
            {
                "pushnumber",
                new Args("ulong rL, int Number")
            },
            {
                "pushstring",
                new Args("ulong rL, const char* String")
            },
            {
                "pushthread",
                new Args("ulong rL", "int")
            },
            {
                "pushvalue",
                new Args("ulong rL, int Index")
            },
            {
                "pushvfstring",
                new Args("ulong rL, const char* Format, va_list ArgP", "const char*")
            },
            {
                "rawequal",
                new Args("ulong rL, int Index1, int Index2", "int")
            },
            {
                "rawget",
                new Args("ulong rL, int Index")
            },
            {
                "rawgeti",
                new Args("ulong rL, int Index, int Number")
            },
            {
                "rawset",
                new Args("ulong rL, int Index")
            },
            {
                "rawseti",
                new Args("ulong rL, int Index")
            },
            {
                "rawvalue",
                new Args("ulong rL, int Index", "int")
            },
            {
                "remove",
                new Args("ulong rL, int Index")
            },
            {
                "retcheck",
                new Args("")
            },
            {
                "replace",
                new Args("ulong rL, int Index")
            },
            {
                "resume",
                new Args("ulong rL, int NArg", "int")
            },
            {
                "setfenv",
                new Args("ulong rL, int Index", "int")
            },
            {
                "setfield",
                new Args("ulong rL, int Index, const char* Name")
            },
            {
                "setmetatable",
                new Args("ulong rL, int Index", "int")
            },
            {
                "settable",
                new Args("ulong rL, int Index")
            },
            {
                "settop",
                new Args("ulong rL, int Index")
            },
            {
                "toboolean",
                new Args("ulong rL, int Index", "int")
            },
            {
                "tolstring",
                new Args("ulong rL, int Index, size_t* Size", "const char*") 
            },
            {
                "tonumber",
                new Args("ulong rL, int Index", "double")
            },
            {
                "topointer",
                new Args("ulong rL, int Index", "const void*")
            },
            {
                "tostring",
                new Args("ulong rL, int Index", "const char*")
            },
            {
                "tothread",
                new Args("ulong rL, int Index", "ulong")
            },
            {
                "touserdata",
                new Args("ulong rL, int Index", "void*")
            },
            {
                "type",
                new Args("ulong rL, int Index", "int")
            },
            {
                "typename",
                new Args("ulong rL, int Index", "const char*")
            },
            {
                "setlocal",
                new Args("ulong rL, int Index, ulong Ar, int Number", "const char*")
            },
            {
                "getinfo",
                new Args("ulong rL, const char* What, ulong Ar", "int")
            },
            {
                "getlocal",
                new Args("ulong rL, ulong Ar, int Number", "const char*")
            },
            {
                "getstack", // Helpful lol
                new Args("ulong rL, int Level, ulong Ar", "int")
            },
            {
                "getupvalue",
                new Args("ulong rL, int FuncIndex, int Number", "const char*")
            },
            {
                "setupvalue",
                new Args("ulong rL, int FuncIndex, int Number", "const char*")
            },
            {
                "sandboxthread",
                new Args("ulong rL, int Arg2, int* Arg3", "int")
            },
            {
                "setreadonly",
                new Args("ulong rL, int Index, byte State", "int")
            },
            {
                "setsafeenv",
                new Args("ulong rL, ulong* Arg2, int Arg3, char Arg4")
            },
            {
                "tointeger",
                new Args("ulong rL, int Index", "int")
            },
            {
                "tounsignedx",
                new Args("ulong rL, int Arg2, ulong* Arg3", "int")
            },
            {
                "xmove",
                new Args("ulong rL, int Arg2, int Arg3")
            },
            {
                "yield",
                new Args("ulong rL, int NResults", "int")
            }
        };

        public static List<string> Index2AdrXRs = new List<string> // Index2Adr Cross References. (Easy to update if Roblox shifts the cross references)
        {
            "",                     // 0
            "rawvalue",             // 1
            "getfenv",              // 2
            "getfield",             // 3
            "getmetatable",         // 4
            "gettable",             // 5
            "getupvalue",           // 6
            "insert",               // 7
            "isuserdata",           // 8
            "iscfunction",          // 9
            "isnumber",             // 10
            "isstring",             // 11
            "lessthan",             // 12
            "lessthan",             // 13
            "next",                 // 14
            "objlen",               // 15
            "pcall",                // 16
            "pushvalue",            // 17
            "rawequal",             // 18
            "rawequal",             // 19
            "rawget",               // 20
            "idk",                  // 21 (idk)
            "rawgeti",              // 22
            "rawset",               // 23
            "rawseti",              // 24
            "remove",               // 25
            "replace",              // 26
            "setfenv",              // 27
            "setfield",             // 28
            "setmetatable",         // 29
            "setreadonly",          // 30
            "setsafeenv",           // 31
            "settable",             // 32
            "setupvalue",           // 33
            "toboolean",            // 34
            "tointeger",            // 35
            "tolstring",            // 36
            "tolstring",            // 37
            "tonumber",             // 38
            "topointer",            // 39
            "topointer",            // 40
            "tostring",             // 41
            "idk",                  // 42 (idk)
            "tothread",             // 43
            "tounsignedx",          // 44
            "touserdata",           // 45
            "idk",                  // 46 (idk)
            "idk",                  // 47 (idk)
            "type",                 // 48
            "idk"                   // 49 (idk)
        };

        public static List<string> RetcheckXRs = new List<string> // Retcheck Cross References. This is more subject to shifts.
        {
            "",                  // 0
            "f_call",            // 1
            "call",              // 2
            "checkstack",        // 3
            "concat",            // 4
            "createtable",       // 5
            "gc",                // 6
            "getfenv",           // 7
            "getfield",          // 8
            "getmetatable",      // 9
            "gettable",          // 10
            "getupvalue",        // 11
            "insert",            // 12
            "lessthan",          // 13
            "newthread",         // 14
            "newuserdata",       // 15
            "next",              // 16
            "objlen",            // 17
            "pcall",             // 18
            "pushboolean",       // 19
            "pushcclosure",      // 20
            "pushfstring",       // 21
            "pushinteger",       // 22
            "pushlightuserdata", // 23
            "pushlstring",       // 24
            "pushnil",           // 25
            "pushnumber",        // 26
            "pushstring",        // 27
            "pushthread",        // 28
            "idk",               // 29 (idk)
            "pushvalue",         // 30
            "pushvfstring",      // 31
            "idk",               // 32 (idk)
            "rawget",            // 33
            "idk",               // 34 (idk)
            "rawgeti",           // 35
            "rawset",            // 36
            "rawseti",           // 37
            "remove",            // 38
            "replace",           // 39
            "setfenv",           // 40
            "setfield",          // 41
            "setmetatable",      // 42
            "setreadonly",       // 43
            "setsafeenv",        // 44
            "settable",          // 45
            "settop",            // 46
            "setupvalue",        // 47
            "tolstring",         // 48
            "tolstring",         // 49
            "xmove",             // 50
            "idk",               // 51 (idk)
            "resume",            // 52
            "idk",               // 53 (idk)
            "yield",             // 54
            "resume",            // 55
            "callhook",          // 56
            "getargument",       // 57
            "getinfo",           // 58
            "getlocal",          // 59
            "getstack",          // 60
            "setlocal"           // 61
        };
    }
}
