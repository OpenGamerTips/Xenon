// Xenon Dumper by H3x0R-OpenGamerTips
// Version: 3.0.0

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using EyeStepPackage;
using Newtonsoft.Json;

namespace XenonDumper
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.Title = "Xenon Dumper";
            if (!Directory.Exists("Dumps"))
            {
                Directory.CreateDirectory("Dumps");
            }

            Process[] Instances = Process.GetProcessesByName("RobloxPlayerBeta");
            if (Instances.Length < 1)
            {
                Console.WriteLine("Please open roblox and restart the program.");
                Console.ReadLine();
                Environment.Exit(-1);
            }
            EyeStep.open("RobloxPlayerBeta.exe");
            
            string RobloxVersion = Path.GetDirectoryName(Instances[0].MainModule.FileName).Split('\\').Last();
            string DumpPath = "Dumps\\" + RobloxVersion;
            if (!Directory.Exists(DumpPath))
            {
                Directory.CreateDirectory(DumpPath);
            }

            Dumper.DumpAddresses();
            File.WriteAllText(DumpPath + "\\BasicFormat.txt", Formatter.BasicFormat());
            File.WriteAllText(DumpPath + "\\HeaderFormat.txt", Formatter.HeaderFormat());
            File.WriteAllText(DumpPath + "\\IDAPython.txt", Formatter.IDAPythonFormat());
        }
    }
}