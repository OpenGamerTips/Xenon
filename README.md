# Merging discontinued project into a private project soon to be a full exploit source.

# Xenon
[![Build status](https://ci.appveyor.com/api/projects/status/w41ccdgt3f2wct84?svg=true)](https://ci.appveyor.com/project/OpenGamerTips/Xenon)
[![Update time](https://badges.pufler.dev/updated/OpenGamerTips/Xenon)](https://github.com/OpenGamerTips/Xenon)

### Development Checklist
- [X] Dumper (Redone)
- [X] DLL (Being Redone)
- [ ] UI
- [ ] Site

### What is it?
Xenon is a Roblox Lua Bytecode Interpreter Written In Lua, C++, and C# all together in an exploit.
[Wiki](https://github.com/OpenGamerTips/Xenon/wiki)

### Why Should I care?
1. It's under the MIT License which means you can use and modify its source and binaries for any reason as long as you include a copyright notice.
2. It's FOSS!

### Specs
---1. We use a custom-coded LBI. Unlike a lot of the other LBI's out there with lazy developers, we chose to write our own LBI.---
2. The source is compile-ready with each update. Automated building and testing makes sure you can download the branch source and have confidence that it will build successfully.
3. Exteremely easy-to-build with only two commands to compile it.

### Building
This project is built with MSBuild. You need MSVC v142 and the .NET Framework 4.7.1 build tools installed to compile successfully.
Here are the steps to building the project:
1. Clone the repo
    ```bash
    git clone "https://github.com/OpenGamerTips/Xenon.git"
    ```
2. Compile with MSBuild or use Visual Studio to build the solution:
    ```bash
    msbuild "Xenon/XenonProject.sln"
    ```
3. Open the built assemblies in the build folder.
