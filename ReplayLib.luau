local HttpService = cloneref(game:GetService("HttpService")) :: HttpService
local Repr = loadstring(game:HttpGet("https://github.com/Ozzypig/repr/raw/refs/heads/master/repr.lua"))()

local function ReplayAttack.Check(OldMethods : { Index : (...any) -> any, NewIndex : ((...any) -> ...any), Namecall : ((...any) -> ...any) }, CallType: string, ...)
	return false
    -- Add your custom filters here. Return true if this is something you want to log or not.
end

local ReplayAttack = {
	MetaMethodsCaptured = {
		["__namecall"] = true,
		["__index"] = true,
		["__newindex"] = true,
	},
	Details = true,
	Recording = false,
	CurrentSession = nil,
	Filters = {
		FilteringEnabled = true,
		FilterInHook = true,
	},
}

function ReplayAttack:SaveSession(Session, FileName)
	local File = ""

	File = File .. "Session ID: " .. Session.ID .. "\n"
	File = File .. "Session Name: " .. Session.Name .. "\n"
	File = File .. "Session Start: " .. Session.Start .. "\n"
	File = File .. "Session End: " .. Session.End .. "\n"

	for _, Event in next, Session.Events do
		if not self.MetaMethodsCaptured[Event.Metamethod] then
			continue
		end

		File = File .. "##################################################\n"

		File = File .. "\tEvent: " .. Event.Metamethod .. "\n"
		File = File .. "\tTime: " .. Event.Time .. "\n"

		if Event.Metamethod == "__namecall" then
			File = File .. "\tArguments: " .. Repr(Event.Arguments) .. "\n"
			File = File .. "\tMethod: " .. Event.Method .. "\n"
			File = File .. "\tSelf: " .. Repr(Event.Self) .. "\n"
		elseif Event.Metamethod == "__index" then
			File = File .. "\tTable: " .. Repr(Event.Table) .. "\n"
			File = File .. "\tKey: " .. Repr(Event.Key) .. "\n"
			File = File .. "\tCaller: " .. Repr(Event.Caller) .. "\n"
		elseif Event.Metamethod == "__newindex" then
			File = File .. "\tTable: " .. Repr(Event.Table) .. "\n"
			File = File .. "\tKey: " .. Repr(Event.Key) .. "\n"
			File = File .. "\tValue: " .. Repr(Event.Value) .. "\n"
			File = File .. "\tCaller: " .. Repr(Event.Caller) .. "\n"
		end

		if self.Details then
			File = File .. "\tTraceback: " .. Event.Traceback .. "\n"
		end
	end

	File = File .. "##################################################\n"

	writefile(FileName .. ".txt", File)
end

function ReplayAttack:CreateSession(SessionName: string)
	local Session = {
		Name = SessionName,
		Events = {},
		ID = HttpService:GenerateGUID(false),
		Start = os.clock(),
		OldMethodCache = {},
	}

	function Session.GetTime()
		return os.clock() - Session.Start
	end

	function Session:Close()
		local RawMetatable = getrawmetatable(game)
		hookfunction(RawMetatable.__namecall, self.OldMethodCache["__namecall"])
		hookfunction(RawMetatable.__index, self.OldMethodCache["__index"])
		hookfunction(RawMetatable.__newindex, self.OldMethodCache["__newindex"])
		self.End = os.clock()
	end

	if self.CurrentSession then
		warn("A session is already active, ending it.")
		self.CurrentSession:Close()
	end

	local RawMt = getrawmetatable(game)

	local OldNamecall, OldIndex, OldNewindex

	OldNamecall = hookfunction(
		RawMt.__namecall,
		function(...)
			if not checkcaller() then
				local Args = { ... }
				local SelfObj = table.remove(Args, 1)
				local Method = getnamecallmethod()
				local Caller = getcallingscript()
				local Traceback = debug.traceback()
				local CallingFunction = debug.info(3, "f")
				local CallingFunctionSource = debug.info(CallingFunction, "s")

				local ShouldContinue = not self.Filters.FilteringEnabled

				ShouldContinue = ReplayAttack.Check(
					{Index = OldIndex, NewIndex = OldNewindex, Namecall = OldNamecall},
					"__namecall",
					SelfObj,
					Method,
					Args,
					Caller,
					Traceback,
					CallingFunction,
					CallingFunctionSource
				)

				if ShouldContinue then
					table.insert(Session.Events, {
						Metamethod = "__namecall",
						Time = Session.GetTime(),
						Arguments = Args,
						Method = Method,
						Self = SelfObj,
						Caller = Caller,
						Traceback = Traceback,
						CallingFunction = CallingFunction,
						CallingFunctionSource = CallingFunctionSource,
					})
				end
			end

			return OldNamecall(...)
		end
	)

	OldIndex = hookfunction(
		RawMt.__index,
		function(T, K)
			if not checkcaller() then
				local Caller = getcallingscript()
				local Traceback = debug.traceback()
				local CallingFunction = debug.info(3, "f")
				local CallingFunctionSource = debug.info(CallingFunction, "s")

				local ShouldContinue = not self.Filters.FilteringEnabled

				ShouldContinue = ReplayAttack.Check({Index = OldIndex, NewIndex = OldNewindex, Namecall = OldNamecall}, "__index", T, K, Caller, Traceback, CallingFunction, CallingFunctionSource)

				if ShouldContinue then
					table.insert(Session.Events, {
						Metamethod = "__index",
						Time = Session.GetTime(),
						Arguments = {},
						Method = nil,
						Table = T,
						Key = K,
						Caller = Caller,
						Traceback = Traceback,
						CallingFunction = CallingFunction,
						CallingFunctionSource = CallingFunctionSource,
					})
				end
			end

			return OldIndex(T, K)
		end
	)

	OldNewindex = hookfunction(
		RawMt.__newindex,
		function(T, K, V)
			if not checkcaller() then
				local Caller = getcallingscript()
				local Traceback = debug.traceback()
				local CallingFunction = debug.info(3, "f")
				local CallingFunctionSource = debug.info(CallingFunction, "s")

				local ShouldContinue = not self.Filters.FilteringEnabled

				ShouldContinue = ReplayAttack.Check({Index = OldIndex, NewIndex = OldNewindex, Namecall = OldNamecall}, "__newindex", T, K, V, Caller, Traceback, CallingFunction, CallingFunctionSource)

				if ShouldContinue then
					table.insert(Session.Events, {
						Metamethod = "__newindex",
						Time = Session.GetTime(),
						Arguments = {},
						Method = nil,
						Table = T,
						Key = K,
						Value = V,
						Caller = Caller,
						Traceback = Traceback,
						CallingFunction = CallingFunction,
						CallingFunctionSource = CallingFunctionSource,
					})
				end
			end

			return OldNewindex(T, K, V)
		end
	)

	Session.OldMethodCache["__namecall"] = OldNamecall
	Session.OldMethodCache["__index"] = OldIndex
	Session.OldMethodCache["__newindex"] = OldNewindex

	self.CurrentSession = Session
	return Session
end

return ReplayAttack
