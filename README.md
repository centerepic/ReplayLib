# ReplayLib has been superseded by Calligraph.

# ReplayAttack v2

A Luau library for capturing and logging metamethod calls in Roblox games.
v2 has moved from built-in filters to requiring you to define your own filtering function.

## Features
- Records `__namecall`, `__index`, and `__newindex` metamethod calls
- Filters events based on caller name, arguments, traceback, or function source
- Saves session logs to file with detailed event information
- Supports session management and clean closure

## Usage

```lua
local ReplayAttack = loadstring(game:HttpGet("https://raw.githubusercontent.com/centerepic/ReplayLib/refs/heads/main/ReplayLib.luau"))()

-- Create and start a recording session
local session = ReplayAttack:CreateSession("MySession")

-- Configure your filter function

local TargetScriptName = "Anticheat"

ReplayAttack.Check = function(OldMethods : { Index : (...any) -> any, NewIndex : ((...any) -> ...any), Namecall : ((...any) -> ...any) }, CallType: string, ...)
    
    if CallType == "__namecall" then
		local SelfObj: Instance, Method: string, Args: { any }, Caller: LuaSourceContainer?, Traceback: string, CallingFunction: ((...any) -> ...any)?, CallingFunctionSource: string =
			...

		local ShouldContinue = false

		if Caller then
			if CallingFunctionSource:match(TargetScriptName) then
				ShouldContinue = true
			end
		end

		return ShouldContinue
	elseif CallType == "__index" then
		local T: Instance, K: string, Caller: LuaSourceContainer?, Traceback: string, CallingFunction: ((...any) -> ...any)?, CallingFunctionSource: string = ...

		if Caller then
			if CallingFunctionSource:match(TargetScriptName) then
				ShouldContinue = true
			end
		end

		return ShouldContinue
	elseif CallType == "__newindex" then
		local T: Instance, K: string, V: any, Caller: LuaSourceContainer?, Traceback: string, CallingFunction: ((...any) -> ...any)?, CallingFunctionSource: string = ...

		local ShouldContinue = false
		if Caller then
			if CallingFunctionSource:match(TargetScriptName) then
				ShouldContinue = true
			end
		end

		return ShouldContinue
	else
		return false
	end
end

-- Wait for events to be captured
task.wait(10)

-- End the session
session:Close()

-- Save the recorded events to file
ReplayAttack:SaveSession(session, "output")
