-- Project: Xenon Lua Bytecode Interpreter
-- Developer: H3x0R
-- Version: 1.1
-- Changelog: Large bugfixes. Feature additions.
-- License: MIT (See script epilogue for more information.)
local StripDebugInfo = false
local StripInstructionInfo = false

-- SECTION 0: PROLOGUE --
local InstructionNames = {
[0] = "MOVE",     "LOADK",     "LOADBOOL", "LOADNIL",
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

local InstructionConstArgs = {
[0] = {B = false, C = false},
	{Bx = true},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{Bx = true},
	{B = false, C = true},
	{Bx = true},
	{B = false, C = false},
	{B = true,  C = true},
	{B = false, C = false},
	{B = false, C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = true,  C = true},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{B = false, C = false},
	{Bx = false},
	{B = false, C = false},
}

-- SECTION 1: OPTIMIZATION --
local bit = bit or bit32 or require("bit")
local rshift, lshift, band = bit.rshift, bit.lshift, bit.band
local sub, gsub, byte, reverse, concat, match = string.sub, string.gsub, string.byte, string.reverse, table.concat, string.match

-- SECTION 2: STREAM LIBRARY --
local Stream = {}
local function ReadByte()
	local Byte = byte(sub(Stream.Source, Stream.Position, Stream.Position))
	Stream.Position = Stream.Position + 1
	return Byte
end

local function ReadInt32()
	local A, B, C, D = ReadByte(), ReadByte(), ReadByte(), ReadByte()
	if Stream.LittleEndian then
		return (D * 16777216) + (C * 65536) + (B * 256) + A
	else
		return (A * 16777216) + (B * 65536) + (C * 256) + D
	end
end

local function ReadLong()
	if Stream.LittleEndian then
		return ReadInt32() * 4294967296 + ReadInt32()
	else
		return ReadInt32() + ReadInt32() * 4294967296
	end
end

local function ReadSingle()
	local A, B, C, D;
	if Stream.LittleEndian then
		A, B, C, D = ReadByte(), ReadByte(), ReadByte(), ReadByte()
	else
		D, C, B, A = ReadByte(), ReadByte(), ReadByte(), ReadByte()
	end

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
	local A, B, C, D, E, F, G, H;
	if Stream.LittleEndian then
		A, B, C, D, E, F, G, H = ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte()
	else
		H, G, F, E, D, C, B, A = ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte(), ReadByte()
	end

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

local function ReadFloat()
	if Stream.FlSize == 4 then return ReadSingle() elseif Stream.FlSize == 8 then return ReadDouble() else error("Invalid floating point size.", 2) end
end

local function ReadInt() -- Based on what integer size it uses.
	if Stream.IntSize == 4 then return ReadInt32() elseif Stream.IntSize == 8 then return ReadLong() else error("Invalid int size.", 2) end
end

local function ReadInstruction()
	if Stream.SizeI == 4 then return ReadInt32() elseif Stream.SizeI == 8 then return ReadLong() else error("Invalid instruction size.", 2) end
end

local function ReadNumber()
	if Stream.FlSize == 0 then
		if Stream.SizeNum == 4 then return ReadInt32() elseif Stream.SizeNum == 8 then return ReadLong() else error("Invalid number size.", 2) end
	else
		return ReadFloat()
	end
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
	assert(ReadByte() == 0, "Lua bytecode format must be official.") -- FormatVersion
	Stream.LittleEndian = ReadByte() ~= 0
	Stream.IntSize = ReadByte()
	Stream.Size_T = ReadByte()
	Stream.SizeI = ReadByte() -- SizeInstruction
	Stream.SizeNum = ReadByte() -- SizeLuaNumber
	if ReadByte() == 0 then -- Floating point number
		Stream.FlSize = Stream.SizeNum
	end

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
	local Instructions = {} -- ADDED! Local tables (maybe a performance boost?)
	for Idx = 1, ReadInt() do
		local InstD8A = ReadInstruction() -- ADDED! Use iSize for x64 compiling
		local OpCode = band(InstD8A, 0x3F)
		local Type = InstructionTypes[OpCode]
		local KstArgs = InstructionConstArgs[OpCode]
		local Inst = {Opcode = OpCode, A = band(rshift(InstD8A, 6), 0xFF)}
		if Type == 1 then -- TODO: Add constant optimization
			Inst.Type = "iABC"
			Inst.B = band(rshift(InstD8A, 23), 0x1FF)
			Inst.C = band(rshift(InstD8A, 14), 0x1FF)
			Inst.B_KstArg = KstArgs.B and Inst.B > 0xFF
			Inst.C_KstArg = KstArgs.C and Inst.C > 0xFF
		elseif Type == 2 then
			Inst.Type = "iABx"
			Inst.Bx = band(rshift(InstD8A, 14), 0x3FFFF)  -- C A N C E R
			Inst.Bx_KstArg = KstArgs.Bx
		elseif Type == 3 then
			Inst.Type = "iAsBx"
			Inst.sBx = band(rshift(InstD8A, 14), 0x3FFFF) - 131071 -- sBx = Signed Bx
		end

		if not StripInstructionInfo then Inst.Name = InstructionNames[OpCode] end
		Instructions[Idx] = Inst
	end

	-- Constants
	local Constants = {}
	for Idx = 1, ReadInt() do
		local Kst;
		local KstType = ReadByte()
		if KstType == 1 then -- LUA_TBOOLEAN
			Kst = ReadByte() ~= 0
		elseif KstType == 3 then -- LUA_TNUMBER
			Kst = ReadNumber() -- ADDED! Add integral flag.
		elseif KstType == 4 then -- LUA_TSTRING
			Kst = sub(ReadString(), 1, -2)
		end

		Constants[Idx - 1] = Kst
	end

	for _, I in pairs(Instructions) do
		if I.Bx_KstArg then
			I.Bx_Constant = Constants[I.Bx + 1]
		else
			if I.B_KstArg then
				--warn(I.Name, Constants[I.C - 0xFF])
				I.B_Constant = Constants[I.B - 0xFF]
			end

			if I.C_KstArg then
				print(I.Name, Constants[I.C - 0xFF])
				I.C_Constant = Constants[I.C - 0xFF]
			end
		end
	end

	Chunk.Instructions = Instructions
	Chunk.Constants = Constants

	-- Protos
	local Protos = {}
	for Idx = 1, ReadInt() do
		Protos[Idx - 1] = DeserializeChunk(Stream)
	end
	Chunk.Protos = Protos

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
	Stream = {
		Position = 1,
		Size_T = 0,
		SizeI = 0,
		SizeNum = 0,
		IntSize = 0,
		FlSize = 0,
		LittleEndian = true,
		Source = nil
	}

	Stream.Source = Bytecode
	ParseBytecodeHeader()
	return DeserializeChunk()
end

local function OpenUpvalue(UpvalueList, Idx, Stack)
	local Last = UpvalueList[Idx] or {Index = Idx; Loc = Stack;}
	UpvalueList[Idx] = Last
	return Last
end

local function CloseUpvalues(UpvalueList, Idx)
	for Edx, Upvalue in pairs(UpvalueList) do
		if Upvalue.Index >= Idx then
			Upvalue.Value = Upvalue.Loc[Upvalue.Index] -- store value
			Upvalue.Loc = Upvalue
			Upvalue.Index = nil
			UpvalueList[Edx] = nil
		end
	end
end

local function LuaVarargs(...)
	return select('#', ...), {...} -- Number of args, args packed.
end

local function WrapFunction(Chunk, Upvalues)
	local InstructionList, Instruction = Chunk.Instructions, 1
	local Protos, Constants = Chunk.Protos, Chunk.Constants
	local Environment, Stack, StackTop = nil, {}, 0
	local VarArg, VarArgSize = {}, 0
	local OpenUpvalues = {}

	-- Yoinked from my old LBI and optimized because too much localizing can slow down performance by over 70% after I did a test on it.
	local function Interpret()
		local Return;
		while not Return do
			local I = Chunk.Instructions[Instruction]
			--print("xd "..type(Stack[1]).." "..Inst.Name)
			if I then
				local Op = I.Opcode
				if Op == 0 then-- MOVE
					Stack[I.A] = Stack[I.B]
				elseif Op == 1 then -- LOADK
					Stack[I.A] = Constants[I.Bx]
				elseif Op == 2 then -- LOADBOOL
					Stack[I.A] = I.B ~= 0 -- If B == 1 then load true onto the stack vice versa
					if I.C ~= 0 then -- If C is non-zero then JMP 1 instruction
						Instruction = Instruction + 1
					end
				elseif Op == 3 then -- LOADNIL
					for Index = I.A, I.B do -- Load nil values onto the stack in the range A-B
						Stack[Index] = nil
					end
				elseif Op == 4 then -- GETUPVAL
					local Upvalue = Upvalues[I.B]
					Stack[I.A] = Upvalue.Loc[Upvalue.Index]
				elseif Op == 5 then -- GETGLOBAL
					--print(I.A, I.Bx, Constants[I.Bx])
					-- CONCEPT: Maybe use this for something idk but it would be cool.
					Stack[I.A] = Environment[Constants[I.Bx]]
				elseif Op == 6 then -- GETTABLE
					local Index = I.C_Constant or Stack[I.C]
					Stack[I.A] = Stack[I.B][Index]
				elseif Op == 7 then -- SETGLOBAL
					Environment[Constants[I.Bx]] = Stack[I.A]
				elseif Op == 8 then -- SETUPVAL
					local Upvalue = Upvalues[I.B]
					Upvalue.Loc[Upvalue.Index] = Stack[I.A]
				elseif Op == 9 then -- SETTABLE
					local Index = I.B_Constant or Stack[I.B]
					local Value = I.C_Constant or Stack[I.C]
					Stack[I.A][Index] = Value
				elseif Op == 10 then -- NEWTABLE
					Stack[I.A] = {} -- I'm not gonna add table allocation it's too hard and would add more performance drag if I did in the first place.
				elseif Op == 11 then -- SELF
					local A = I.A -- Example when it would speed up if locals were used.
					local B = I.B
					Stack[A + 1] = Stack[B]
					Stack[A] = Stack[B][(I.C_Constant or Stack[I.C])]
				elseif Op == 12 then -- ADD
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) + (I.C_Constant or Stack[I.C]))
				elseif Op == 13 then -- SUB
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) - (I.C_Constant or Stack[I.C]))
				elseif Op == 14 then -- MUL
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) * (I.C_Constant or Stack[I.C]))
				elseif Op == 15 then -- DIV
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) / (I.C_Constant or Stack[I.C]))
				elseif Op == 16 then -- MOD
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) % (I.C_Constant or Stack[I.C]))
				elseif Op == 17 then -- POW
					Stack[I.A] = ((I.B_Constant or Stack[I.B]) ^ (I.C_Constant or Stack[I.C]))
				elseif Op == 18 then -- UNM (NEGATE)
					Stack[I.A] = -Stack[I.B]
				elseif Op == 19 then -- NOT
					Stack[I.A] = not Stack[I.B]
				elseif Op == 20 then-- LEN
					Stack[I.A] = #Stack[I.B]
				elseif Op == 21 then -- CONCAT
					local Concatenated = {} -- Used to use a string but tables are faster
					for Index = I.B, I.C do -- Concatenate items in the stack from range B-C
						Concatenated[#Concatenated + 1] = Stack[Index]
					end
					Stack[I.A] = concat(Concatenated)
				elseif Op == 22 then -- JMP
					Instruction = Instruction + I.sBx
				elseif Op == 23 then -- EQ
					if ((I.B_Constant or Stack[I.B]) == (I.C_Constant or Stack[I.C])) ~= (I.A ~= 0) then -- if ((RK(B) == RK(C)) ~= A) then PC++
						Instruction = Instruction + 1
					end
				elseif Op == 24 then -- LT
					if ((I.B_Constant or Stack[I.B]) < (I.C_Constant or Stack[I.C])) ~= (I.A ~= 0) then -- if ((RK(B) < RK(C)) ~= A) then PC++
						Instruction = Instruction + 1
					end
				elseif Op == 25 then -- LE
					if ((I.B_Constant or Stack[I.B]) <= (I.C_Constant or Stack[I.C])) ~= (I.A ~= 0) then -- if ((RK(B) <= RK(C)) ~= A) then PC++
						Instruction = Instruction + 1
					end
				elseif Op == 26 then-- TEST
					if (not not I.A) == (I.C == 0) then
						Instruction = Instruction + 1
					end
				elseif Op == 27 then -- TESTSET
					local B = I.B
					if (not not B) == (I.C == 0) then
						Instruction = Instruction + 1
					else
						Stack[I.A] = Stack[B]
					end
				elseif Op == 28 then -- CALL
					local A = I.A
					local B = I.B
					local C = I.C
					local ParametersCount, ReturnArgsCount, ReturnArgs;
					if B == 0 then
						ParametersCount = StackTop - A
					else
						ParametersCount = B - 1
					end
					ReturnArgsCount, ReturnArgs = LuaVarargs(Stack[A](unpack(Stack, A + 1, A + ParametersCount)))
					if C == 0 then
						StackTop = A + ReturnArgsCount - 1
					else
						ReturnArgsCount = C - 1
					end

					for Idx = 1, ReturnArgsCount do -- Push arguments to stack
						Stack[A + Idx - 1] = ReturnArgs[Idx]
					end
				elseif Op == 29 then -- TAILCALL
					local A = I.A
					local B = I.B
					local ParametersCount;
					if B == 0 then
						ParametersCount = StackTop - A
					else
						ParametersCount = B - 1
					end
					CloseUpvalues(OpenUpvalues, 0)

					local ReturnArgsCount, ReturnArgs = LuaVarargs(Stack[A](unpack(Stack, A + 1, A + ParametersCount)))
					return ReturnArgs -- yay done
				elseif Op == 30 then -- RETURN
					local A = I.A
					local B = I.B
					local Args, ArgCount = {} -- Return Arguments
					if B == 0 then
						ArgCount = StackTop - A + 1
					else
						ArgCount = B - 1
					end

					for Idx = 1, ArgCount do
						Args[Idx] = Stack[A + Idx - 1]
					end
					CloseUpvalues(OpenUpvalues, 0)
					return Args -- yay done
				elseif Op == 31 then -- FORLOOP
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
				elseif Op == 32 then -- FORPREP
					local A = I.A
					Stack[A] = Stack[A] - Stack[A + 2]
					Instruction = Instruction + I.sBx
				elseif Op == 33 then -- TFORLOOP
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
				elseif Op == 34 then -- SETLIST
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
				elseif Op == 35 then -- CLOSE
					CloseUpvalues(OpenUpvalues, I.A) -- ADDED! Support for closing and opening upvalues.
				elseif Op == 36 then -- CLOSURE
					local Proto = Protos[I.Bx]
					local UpvalueList = {}
					local Nups = Proto.Nups

					if Nups ~= 0 then
						for Idx = 1, Nups do
							local Psuedo = InstructionList[Instruction + Idx]
							if Psuedo.Opcode == 0 then -- OP_MOVE
								UpvalueList[Idx - 1] = OpenUpvalue(OpenUpvalues, Psuedo.B, Stack)
							else -- OP_GETUPVAL
								UpvalueList[Idx - 1] = Upvalues[Psuedo.B]
							end

							Instruction = Instruction + Nups
						end
					end

					Stack[I.A] = WrapFunction(Proto, UpvalueList) -- Push closure onto the stack
				elseif Op == 37 then -- VARARG
					local A = I.A
					local B = I.B
					for Index = A, A + (B > 0 and (B - 1) or VarArgSize) do
						Stack[Index] = VarArg[Index - A]
					end
				end;
			else
				return
			end

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
			-- Idk how I would do a traceback on an LBI without wasting an hour lol.
			print(Line)
			warn(Chunk.Name..":"..(Chunk.Debug.Lines[Instruction] or "?")..": "..ErrMsg) -- BUGFIX: Added error support for stripped debug info.
		end
	end
end

local function loadbytecode(Bytecode)
	local MainChunk = DeserializeBytecode(Bytecode)
	return WrapFunction(MainChunk)
end

-- Xenon Script Scheduler
local remove = table.remove
local RenderStepped = game:GetService("RunService").RenderStepped
local LastExecution = tick()
local QueueList = {}
local function schedulebytecode(Bytecode)
	spawn(function()
		if (tick() - LastExecution) < 0.10 then
			repeat
				RenderStepped:Wait()
			until (tick() - LastExecution > 0.09)
		end
		LastExecution = tick()
		QueueList[#QueueList + 1] = Bytecode
	end)
end

spawn(function() -- Script Scheduler Runtime
	while RenderStepped:Wait() do
		local NextInLine = QueueList[1]
		if NextInLine then
			remove(QueueList, 1)
			spawn(function()
				loadbytecode(NextInLine)()
			end)
		end
	end
end)

-- Export functions.
getgenv().loadbytecode = loadbytecode
getgenv().schedulebytecode = schedulebytecode

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
