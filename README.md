# ReplayAttack

A Luau library for capturing and logging metamethod calls in Roblox games.

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

-- Configure filters if needed
ReplayAttack.Filters = {
    FilteringEnabled = true,
    LogNilCallers = true,
    FindInCallerName = {"ScriptName"},
    FindInFunctionSource = {"SourcePattern"}
}

-- Wait for events to be captured
task.wait(10)

-- End the session
session:Close()

-- Save the recorded events to file
ReplayAttack:SaveSession(session, "output")
