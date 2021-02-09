-- Project: Xenon Lua Bytecode Interpreter
-- Developer: H3x0R
-- Version: 1.0
-- License: MIT (See script epilogue for more information.)

local StripDebugInfo = false

-- SECTION 0: PROLOGUE --
local InstructionNames = {
[0] = "MOVE",      "LOADK",     "LOADBOOL", "LOADNIL",
      "GETUPVAL",   "GETGLOBAL", "GETTABLE", "SETGLOBAL",
      "SETUPVAL",   "SETTABLE",  "NEWTABLE", "SELF",
      "ADD",        "SUB",       "MUL",      "DIV",
      "MOD",        "POW",       "UNM",      "NOT",
      "LEN",        "CONCAT",    "JMP",      "EQ",
      "LT",         "LE",        "TEST",     "TESTSET",
      "CALL",       "TAILCALL",  "RETURN",   "FORLOOP",
      "FORPREP",    "TFORLOOP",  "SETLIST",  "CLOSE",
      "CLOSURE",    "VARARG"
}

local InstructionTypes = { -- iABC, iABx, iAsBx in that strict order.
[0] = 1, 2, 1, 1,
      1, 2, 1, 2,
      1, 1, 1, 1,
      1, 1, 1, 1,
      1, 1, 1, 1,
      1, 1, 3, 1,
      1, 1, 1, 1,
      1, 1, 1, 3,
      3, 1, 1, 1,
      2, 1
}

-- SECTION 1: OPTIMIZATION --
local bit = bit or bit32 or require("bit")
local rshift, lshift, band = bit.rshift, bit.lshift, bit.band
local sub, gsub, byte, reverse, concat, match = string.sub, string.gsub, string.byte, string.reverse, table.concat, string.match

-- SECTION 2: STREAM LIBRARY --
local Stream = {
    Position = 1,
    Size_T = 4,
    IntSize = 4,
    Source = nil
}

local function ReadByte()
    local Byte = byte(sub(Stream.Source, Stream.Position, Stream.Position))
    Stream.Position = Stream.Position + 1
    return Byte
end

local function ReadInt32() -- Screw it, little endian is default in Lua bytecode.
    local A, B, C, D = ReadByte(), ReadByte(), ReadByte(), ReadByte()
    return (D * 16777216) + (C * 65536) + (B * 256) + A
end

local function ReadLong()
    return ReadInt32() * 4294967296 + ReadInt32()
end

local function ReadFloat()
    local A, B, C, D = ReadByte(), ReadByte(), ReadByte(), ReadByte()
    local Sign, Exponent, Fraction = (-1 ^ rshift(D, 7)), (rshift(C, 7) + lshift(band(D, 0x7F), 1)), (A + lshift(B, 8) + lshift(band(C, 0x7F), 16))
    local Normal = 1
    if Exponent == 0 then
        if Fraction == 0 then
            return Sign * 0
        else
            Normal = 0
            Exponent = 1
        end
    elseif Exponent == 0x7F then
        if Fraction == 0 then
            return Sign * (1 / 0)
        else
            return Sign * (0 / 0)
        end
    end

    return Sign * 2 ^ (Exponent - 127) * (1 + Normal / 2 ^ 23)
end

local function ReadDouble()
    local A, B, C, D, E, F, G, H = ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte()
    local Sign, Exponent, Fraction = (1 ^ rshift(H, 7)), (lshift(band(H, 0x7F), 4) + rshift(G, 4)), (band(G, 0x0F) * 2 ^ 48)
    local Normal = 1

    Fraction = Fraction + (F * 2 ^ 40) + (E * 2 ^ 32) + (D * 2 ^ 24) + (C * 2 ^ 16) + (B * 2 ^ 8) + A
    if Exponent == 0 then
        if Fraction == 0 then
            return Sign * 0
        else
            Normal = 0
            Exponent = 1
        end
    elseif Exponent == 0x7FF then
        if Fraction == 0 then
            return Sign * (1 / 0)
        else
            return Sign * (0 / 0)
        end
    end

    return Sign * 2 ^ (Exponent - 1023) * (Normal + Fraction / 2 ^ 52)
end

local function ReadInt() -- Based on what integer size it uses.
    if Stream.IntSize == 4 then return ReadInt32() elseif Stream.IntSize == 8 then return ReadLong() else error("Invalid int size.", 2) end
end

local function GetSizeT()
    if Stream.Size_T == 4 then return ReadInt32() elseif Stream.Size_T == 8 then return ReadLong() else error("Invalid size_t size.", 2) end
end

local function ReadString(Len)
    if not Len then Len = GetSizeT() end
    if Len == 0 then return "" end

    local String = sub(Stream.Source, Stream.Position, (Stream.Position + Len - 1))
    Stream.Position = Stream.Position + Len
    return String
end

-- SECTION 3: PARSING --
local function ParseBytecodeHeader() -- x86 Header Bytes: 1B4C7561 51000104 04040800
    assert(ReadInt32() == 1635077147, "Invalid bytecode signature.") -- Representation for the Lua bytecode header in integer32 form.
    assert(ReadByte() == 0x51, "Lua bytecode version needs to be 5.1.") -- 0x51 would represent version 5.1 and 0x52 for version 5.2.
    ReadByte() -- FormatVersion, I don't need to check if it's official or not.
    assert(ReadByte() == 0x01, "Bytecode format must be in little endian format.")
    Stream.IntSize = ReadByte()
    Stream.Size_T = ReadByte()
    -- Nothing below is needed because Xenon compiles Lua bytecode on an x86 application
    -- Maybe some day I will revise this to add x64 support if Roblox migrates to it.
    ReadByte() -- SizeInstruction
    ReadByte() -- SizeLuaNumber
    ReadByte() -- Integral Flag
    return true
end

local DeserializeChunk;
DeserializeChunk = function()
    local Chunk = {}
    Chunk.Name = sub(ReadString(), 1, -2)
    Chunk.StartLine = ReadInt()
    Chunk.EndLine = ReadInt()
    Chunk.Nups = ReadByte()
    Chunk.Nparams = ReadByte()
    Chunk.IsVararg = ReadByte()
    Chunk.MaxStackSize = ReadByte()

    -- Instructions (Only took ten years to figure out how to bitmask)
    Chunk.Instructions = {} -- TODO: Local tables (maybe a performance boost?)
    for Idx = 1, ReadInt() do
        local InstD8A = ReadInt32() -- TODO: Use iSize for x64 compiling
        local OpCode = band(InstD8A, 0x3F)
        local Type = InstructionTypes[OpCode]
        local Inst = {Opcode = OpCode, Type = nil, A = band(rshift(InstD8A, 6), 0xFF)}
        if Type == 1 then -- TODO: Add constant optimization
            Inst.B = band(rshift(InstD8A, 23), 0x1FF)
            Inst.C = band(rshift(InstD8A, 14), 0x1FF)
        elseif Type == 2 then
            Inst.Bx = band(rshift(InstD8A, 14), 0x3FFFF)  -- C A N C E R
        elseif Type == 3 then
            Inst.sBx = band(rshift(InstD8A, 14), 0x3FFFF) - 131071 -- sBx = Signed Bx
        end

        Inst.Name = InstructionNames[OpCode]
        Chunk.Instructions[Idx] = Inst
    end

    -- Constants
    Chunk.Constants = {}
    for Idx = 1, ReadInt() do
        local Kst;
        local KstType = ReadByte()
        if KstType == 1 then -- LUA_TBOOLEAN
            Kst = ReadByte() ~= 0
        elseif KstType == 3 then -- LUA_TNUMBER
            Kst = ReadDouble()
        elseif KstType == 4 then -- LUA_TSTRING
            Kst = sub(ReadString(), 1, -2)
        end

        Chunk.Constants[Idx - 1] = Kst
    end

    -- Protos
    Chunk.Protos = {}
    for Idx = 1, ReadInt() do
        Chunk.Protos[Idx - 1] = DeserializeChunk(Stream)
    end

    -- Debug Info
    Chunk.Debug = {Lines = {}, Locals = {}, Upvalues = {}}
    for Idx = 1, ReadInt() do -- Line Numbers
        local LineNo = ReadInt32()
        if not StripDebugInfo then Chunk.Debug.Lines[Idx] = LineNo end
    end

    for Idx = 1, ReadInt() do -- Locals
        local LocalName = ReadString()
        Stream.Position = Stream.Position + 8 -- TODO: Add more debug information in place of this.
        if not StripDebugInfo then Chunk.Debug.Locals[Idx] = LocalName end
    end

    for Idx = 1, ReadInt() do -- Upvalues
        local UpvalueName = ReadString()
        if not StripDebugInfo then Chunk.Debug.Upvalues[Idx] = UpvalueName end
    end

    return Chunk
end

local function DeserializeBytecode(Bytecode)
    Stream.Source = Bytecode
    ParseBytecodeHeader()
    return DeserializeChunk()
end

local function WrapFunction(Chunk, Upvalues)
    local InstructionList, Instruction = Chunk.Instructions, 1
    local Protos, Constants = Chunk.Protos, Chunk.Constants
    local Environment, Stack, StackTop = nil, {}, 0
    local VarArg, VarArgSize = {}, 0
    local function GetRegisteredValue(I) -- Gets a value that could either be on the stack or in the constant pool.
        if I <= 255 then
            return Stack[I]
        else
            return Constants[I - 256]
        end
    end

    -- Yoinked from my old LBI and optimized because too much localizing can slow down performance by over 70% after I did a test on it.
    local OpFuncs = {
        [0] = function(I) -- MOVE
            Stack[I.A] = Stack[I.B]
        end;
        [1] = function(I) -- LOADK
            Stack[I.A] = Constants[I.Bx]
        end;
        [2] = function(I) -- LOADBOOL
            Stack[I.A] = I.B ~= 0 -- If B == 1 then load true onto the stack vice versa
            if I.C ~= 0 then -- If C is non-zero then JMP 1 instruction
                Instruction = Instruction + 1
            end
        end;
        [3] = function(I) -- LOADNIL
            for Index = I.A, I.B do -- Load nil values onto the stack in the range A-B
                Stack[Index] = nil
            end
        end;
        [4] = function(I) -- GETUPVAL
            Stack[I.A] = Upvalues[I.B]
        end;
        [5] = function(I) -- GETGLOBAL
            --print(I.A, I.Bx, Constants[I.Bx])
            Stack[I.A] = Environment[Constants[I.Bx]]
        end;
        [6] = function(I) -- GETTABLE
            Stack[I.A] = Stack[I.B][GetRegisteredValue(I.C)]
        end;
        [7] = function(I) -- SETGLOBAL
            Environment[Constants[I.Bx]] = Stack[I.A]
        end;
        [8] = function(I) -- SETUPVAL
            Upvalues[I.B] = Stack[I.A]
        end;
        [9] = function(I) -- SETTABLE
            Stack[I.A][GetRegisteredValue(I.B)] = GetRegisteredValue(I.C)
        end;
        [10] = function(I) -- NEWTABLE
            Stack[I.A] = {} -- I'm not gonna add table allocation its too hard and would add more performance drag.
        end;
        [11] = function(I) -- SELF
            local A = I.A -- Example when it would speed up if locals were used.
            local B = I.B
            local Key = GetRegisteredValue(I.C)
            Stack[A + 1] = Stack[B]
            Stack[A] = Stack[B][Key]
        end;
        [12] = function(I) -- ADD
            Stack[I.A] = (GetRegisteredValue(I.B) + GetRegisteredValue(I.C))
        end;
        [13] = function(I) -- SUB
            Stack[I.A] = (GetRegisteredValue(I.B) - GetRegisteredValue(I.C))
        end;
        [14] = function(I) -- MUL
            Stack[I.A] = (GetRegisteredValue(I.B) * GetRegisteredValue(I.C))
        end;
        [15] = function(I) -- DIV
            Stack[I.A] = (GetRegisteredValue(I.B) / GetRegisteredValue(I.C))
        end;
        [16] = function(I) -- MOD
            Stack[I.A] = (GetRegisteredValue(I.B) % GetRegisteredValue(I.C))
        end;
        [17] = function(I) -- POW
            Stack[I.A] = (GetRegisteredValue(I.B) ^ GetRegisteredValue(I.C))
        end;
        [18] = function(I) -- UNM (NEGATE)
            Stack[I.A] = -Stack[I.B]
        end;
        [19] = function(I) -- NOT
            Stack[I.A] = not Stack[I.B]
        end;
        [20] = function(I) -- LEN
            Stack[I.A] = #Stack[I.B]
        end;
        [21] = function(I) -- CONCAT
            local Concatenated = {} -- Used to use a string but tables are faster
            for Index = I.B, I.C do -- Concatenate items in the stack from range B-C
                Concatenated[#Concatenated + 1] = Stack[Index]
            end
            Stack[I.A] = concat(Concatenated)
        end;
        [22] = function(I) -- JMP
            Instruction = Instruction + I.sBx
        end;
        [23] = function(I) -- EQ
            if (GetRegisteredValue(I.B) == GetRegisteredValue(I.C)) ~= (I.A ~= 0) then -- if ((RK(B) == RK(C)) ~= A) then PC++
                Instruction = Instruction + 1
            end
        end;
        [24] = function(I) -- LT
            if (GetRegisteredValue(I.B) < GetRegisteredValue(I.C)) ~= (I.A ~= 0) then -- if ((RK(B) < RK(C)) ~= A) then PC++
                Instruction = Instruction + 1
            end
        end;
        [25] = function(I) -- LE
            if (GetRegisteredValue(I.B) <= GetRegisteredValue(I.C)) ~= (I.A ~= 0) then -- if ((RK(B) <= RK(C)) ~= A) then PC++
                Instruction = Instruction + 1
            end
        end;
        [26] = function(I) -- TEST
            if (not not I.A) == (I.C == 0) then
                Instruction = Instruction + 1
            end
        end;
        [27] = function(I) -- TESTSET
            local B = I.B
            if (not not B) == (I.C == 0) then
                Instruction = Instruction + 1
            else
                Stack[I.A] = Stack[B]
            end
        end;
        [28] = function(I) -- CALL
            local A = I.A
            local B = I.B
            local C = I.C
            local Args, ArgCount = {}
            local AIndex, Ret = 0
            if B == 1 then -- Get Arguments and Call (If B is 1, the function has no parameters)
                Ret = {Stack[A]()}
                ArgCount = #Ret
            else
                if B ~= 0 then
                    ArgCount = A + B - 1 --  If B is 2 or more, there are (B-1) parameters.
                else
                    ArgCount = StackTop -- If B is 0, the function parameters range from R(A+1) to the top of the stack.
                end

                for SIndex = (A + 1), ArgCount do
                    AIndex = AIndex + 1
                    Args[AIndex] = Stack[SIndex]
                end

                Ret = {Stack[A](unpack(Args, 1, (ArgCount - A)))}
                ArgCount = #Ret
            end

            AIndex = 0
            StackTop = (A - 1)
            if C ~= 1 then -- Push Arguments to Stack (If C is 1, no return results are saved)
                if C ~= 0 then
                    ArgCount = A + C - 2
                else
                    ArgCount = ArgCount + A
                end

                for SIndex = A, ArgCount do
                    AIndex = AIndex + 1
                    Stack[SIndex] = Ret[AIndex]
                end
            end
        end;
        [29] = function(I) -- TAILCALL
            local A = I.A
            local B = I.B
            local Args, ArgCount = {}
            local Ret = 0
            if B == 1 then -- Get Arguments and Call (If B is 1, the function has no parameters)
                Ret = {Stack[A]()}
            else
                if B ~= 0 then
                    ArgCount = A + B - 1 --  If B is 2 or more, there are (B-1) parameters.
                else
                    ArgCount = StackTop -- If B is 0, the function parameters range from R(A+1) to the top of the stack.
                end

                for Index = (A + 1), ArgCount do
                    Args[#Args + 1] = Stack[Index]
                end

                Ret = {Stack[A](unpack(Args, 1, (ArgCount - A)))}
            end

            return Ret -- yay done
        end;
        [30] = function(I) -- RETURN
            local A = I.A
            local B = I.B
            local Args, AIndex, ArgCount = {}, 0 -- Return Arguments
            if B == 0 then
                ArgCount = StackTop
            elseif B == 1 then
                return {nil}
            else
                ArgCount = A + B - 2
            end

            for Index = A, ArgCount do
                AIndex = AIndex + 1
                Args[AIndex] = Stack[Index]
            end
            return Args -- yay done
        end;
        [31] = function(I) -- FORLOOP
            local A = I.A
            local Step = Stack[A + 2]
            local Index = Stack[A] + Step
            Stack[A] = Index

            if Step > 0 then
                if Index <= Stack[A + 1] then
                    Instruction = Instruction + I.sBx
                    Stack[A + 3] = Index
                end
            else
                if Index >= Stack[A + 1] then
                    Instruction = Instruction + I.sBx
                    Stack[A + 3] = Index
                end
            end
        end;
        [32] = function(I) -- FORPREP
            local A = I.A
            Stack[A] = Stack[A] - Stack[A + 2]
            Instruction = Instruction + I.sBx
        end;
        [33] = function(I) -- TFORLOOP
            local A = I.A
            local Offset = (A + 2)
            local Ret = {Stack[A](Stack[A + 1], Stack[A + 2])}
            for Index = 1, I.C do
                Stack[Offset + Index] = Ret[Index]
            end

            if Stack[A + 3] then
                Stack[A + 2] = Stack[A + 3]
            else
                Instruction = Instruction + 1
            end
        end;
        [34] = function(I) -- SETLIST
            local A = I.A
            local B = I.B
            local C = I.C
            if C ~= 0 then
                local Offset = ((C - 1) * 50)
                for Index = 1, (B == 0 and StackTop or B) do
                    Stack[A][Offset + Index] = Stack[A + Index]
                end
            else
                error("Bytecode has a pre-compilation error.")
            end
        end;
        [35] = function(I) -- CLOSE
            -- TODO: Add support for closing upvalues.
        end;
        [36] = function(I) -- CLOSURE
            local Proto = Protos[I.Bx]
            local UpvaLib = {}
            local ProtoUpvalues = setmetatable({}, {
                __index = function(_, Key)
                    local Upvalue = UpvaLib[Key]
                    return Upvalue.Parent[Upvalue.Index]
                end;
                __newindex = function(_, Key, Value)
                    local Upvalue = UpvaLib[Key]
                    Upvalue.Parent[Upvalue.Index] = Value
                end
            })

            for Index = 1, Proto.Upvalues do
                local Inst = InstructionList[Instruction]
                if Inst.Opcode == 0 then -- OP_MOVE
                    UpvaLib[Index - 1] = {
                        Parent = Stack;
                        Index = Inst.B;
                    }
                else -- OP_GETUPVAL
                    UpvaLib[Index - 1] = {
                        Parent = Upvalues;
                        Index = Inst.B;
                    }
                end

                Instruction = Instruction + 1
            end

            Stack[I.A] = WrapFunction(Proto, ProtoUpvalues) -- Push closure onto the stack
        end;
        [37] = function(I) -- VARARG
            local A = I.A
            local B = I.B
            for Index = A, A + (B > 0 and (B - 1) or VarArgSize) do
                Stack[Index] = VarArg[Index - A]
            end
        end;
    }

    local function Interpret()
        local Return;
        while not Return do
            local Inst = Chunk.Instructions[Instruction]
            --print("xd "..type(Stack[1]).." "..Inst.Name)
            if not Inst then
                return
            end

            Return = OpFuncs[Inst.Opcode](Inst)
            Instruction = Instruction + 1
        end
        return Return
    end

    return function(...)
        local Args = {...}
        VarArg = {}
        VarArgSize = #Args - 1
        Environment = getfenv()

        local EStack, Ghost = {}, {}
        StackTop = -1
        Stack = setmetatable(EStack, {
            __index = Ghost;
            __newindex = function(self, Key, Value)
                if Key > StackTop and Value then
                    StackTop = Key
                end
                Ghost[Key] = Value
            end;
        })

        for Index = 0, VarArgSize do
            EStack[Index] = Args[Index + 1]
            VarArg[Index] = Args[Index + 1]
        end

        Instruction = 1 -- Reset Position
        local Success, Return = pcall(Interpret)
        if Success then
            return type(Return) == "table" and unpack(Return) or Return
        else
            local Src, Line, ErrMsg = match(Return, "^(.-):(%d+):%s+(.+)")
            error(Chunk.Name..":"..(Chunk.Debug.Lines[Instruction] or "?")..": "..ErrMsg, 0) -- BUGFIX: Added error support for stripped debug info.
        end
    end
end

-- Made to simulate loadstring
local function loadbytecode(Bytecode, ...)
    local MainChunk = DeserializeBytecode(Bytecode)
    return WrapFunction(MainChunk)(...)
end

-- Just A Quick Call Test:
--loadbytecode("\27\76\117\97\81\0\1\4\4\4\8\0\51\0\0\0\64\99\58\92\85\115\101\114\115\92\110\105\99\104\111\92\68\101\115\107\116\111\112\92\76\117\97\92\78\111\114\109\97\108\92\100\117\109\112\99\108\111\115\117\114\101\46\108\117\97\0\1\0\0\0\5\0\0\0\0\0\0\2\10\0\0\0\5\0\0\0\65\64\0\0\28\64\0\1\5\128\0\0\65\192\0\0\28\64\0\1\5\0\1\0\65\64\1\0\28\64\0\1\30\0\128\0\6\0\0\0\4\6\0\0\0\112\114\105\110\116\0\4\13\0\0\0\72\101\108\108\111\32\112\114\105\110\116\33\0\4\5\0\0\0\119\97\114\110\0\4\12\0\0\0\72\101\108\108\111\32\119\97\114\110\33\0\4\6\0\0\0\101\114\114\111\114\0\4\16\0\0\0\79\32\78\79\69\83\32\72\69\32\67\79\77\73\78\0\0\0\0\0\10\0\0\0\2\0\0\0\2\0\0\0\2\0\0\0\3\0\0\0\3\0\0\0\3\0\0\0\4\0\0\0\4\0\0\0\4\0\0\0\5\0\0\0\0\0\0\0\0\0\0\0")

-- Performance Test:
--loadbytecode("\27\76\117\97\81\0\1\4\4\4\8\0\51\0\0\0\64\99\58\92\85\115\101\114\115\92\110\105\99\104\111\92\68\101\115\107\116\111\112\92\76\117\97\92\78\111\114\109\97\108\92\100\117\109\112\99\108\111\115\117\114\101\46\108\117\97\0\1\0\0\0\9\0\0\0\0\0\0\7\22\0\0\0\5\0\0\0\28\128\128\0\65\64\0\0\129\128\0\0\193\64\0\0\96\0\2\128\23\128\64\2\22\128\0\128\69\193\0\0\129\1\1\0\92\65\0\1\69\65\1\0\92\129\128\0\70\129\193\2\73\1\129\131\95\64\253\127\69\0\2\0\133\0\0\0\156\128\128\0\141\0\0\1\92\64\0\1\30\0\128\0\9\0\0\0\4\5\0\0\0\116\105\99\107\0\3\0\0\0\0\0\0\240\63\3\0\0\0\0\128\132\46\65\4\6\0\0\0\112\114\105\110\116\0\4\20\0\0\0\119\101\119\32\97\108\109\111\115\116\32\100\111\110\101\32\98\111\105\0\4\8\0\0\0\103\101\116\102\101\110\118\0\4\3\0\0\0\95\71\0\3\0\0\0\0\0\0\89\64\4\5\0\0\0\119\97\114\110\0\0\0\0\0\22\0\0\0\2\0\0\0\2\0\0\0\3\0\0\0\3\0\0\0\3\0\0\0\3\0\0\0\4\0\0\0\4\0\0\0\4\0\0\0\4\0\0\0\4\0\0\0\5\0\0\0\5\0\0\0\5\0\0\0\6\0\0\0\3\0\0\0\8\0\0\0\8\0\0\0\8\0\0\0\8\0\0\0\8\0\0\0\9\0\0\0\6\0\0\0\4\0\0\0\110\111\119\0\2\0\0\0\21\0\0\0\12\0\0\0\40\102\111\114\32\105\110\100\101\120\41\0\5\0\0\0\16\0\0\0\12\0\0\0\40\102\111\114\32\108\105\109\105\116\41\0\5\0\0\0\16\0\0\0\11\0\0\0\40\102\111\114\32\115\116\101\112\41\0\5\0\0\0\16\0\0\0\2\0\0\0\105\0\6\0\0\0\15\0\0\0\2\0\0\0\112\0\14\0\0\0\15\0\0\0\0\0\0\0")
_G.loadbytecode = loadbytecode

--[[
    Xenon's LBI is under the MIT License. In order to legally use this you must
    add this notice to your license:
    Copyright (c) 2021 H3x0R (OpenGamerTips)

    MIT License:
    Copyright (c) 2021 H3x0R (OpenGamerTips)
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the “Software”), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
]]
