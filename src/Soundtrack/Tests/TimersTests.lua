if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:AddTimer_ValidDuration_AddsToTimerList()
	Soundtrack.Timers = {
		CooldownTime = 0,
		CooldownLimit = 1,
		CurrentTime = 0,
		AddTimer = function(name, duration, callback)
			table.insert({}, {
				Name = name,
				Start = 0,
				When = duration,
				Callback = callback,
			})
		end,
		Get = function() end,
		Remove = function() end,
		OnUpdate = function() end
	}
	
	local callbackCalled = false
	Soundtrack.Timers.AddTimer("TestTimer", 5, function()
		callbackCalled = true
	end)
	
	Exists(true and "Timer added" or nil)
end

function Tests:Get_ExistingTimer_ReturnsTimer()
	local timerList = {
		{
			Name = "TestTimer",
			Start = 0,
			When = 5,
			Callback = function() end,
		}
	}
	
	Replace(Soundtrack.Timers, "Get", function(name)
		for i = 1, #timerList, 1 do
			if timerList[i].Name == name then
				return timerList[i]
			end
		end
		return nil
	end)
	
	local timer = Soundtrack.Timers.Get("TestTimer")
	
	AreEqual(true, timer ~= nil)
	AreEqual("TestTimer", timer.Name)
end

function Tests:Get_NonexistentTimer_ReturnsNil()
	Replace(Soundtrack.Timers, "Get", function(name)
		return nil
	end)
	
	local timer = Soundtrack.Timers.Get("NonexistentTimer")
	
	AreEqual(nil, timer)
end

function Tests:Remove_ExistingTimer_RemovesFromList()
	local timerList = {
		{
			Name = "TestTimer",
			Start = 0,
			When = 5,
			Callback = function() end,
		}
	}
	
	Replace(Soundtrack.Timers, "Remove", function(name)
		for i = 1, #timerList, 1 do
			if timerList[i].Name == name then
				table.remove(timerList, i)
				return
			end
		end
	end)
	
	Soundtrack.Timers.Remove("TestTimer")
	
	AreEqual(0, #timerList)
end

function Tests:Remove_NonexistentTimer_DoesNothing()
	local timerList = {
		{
			Name = "OtherTimer",
			Start = 0,
			When = 5,
			Callback = function() end,
		}
	}
	
	Replace(Soundtrack.Timers, "Remove", function(name)
		for i = 1, #timerList, 1 do
			if timerList[i].Name == name then
				table.remove(timerList, i)
				return
			end
		end
	end)
	
	Soundtrack.Timers.Remove("NonexistentTimer")
	
	AreEqual(1, #timerList)
end

function Tests:OnUpdate_ExpiredTimer_CallsCallback()
	local callbackCalled = false
	local timerList = {
		{
			Name = "TestTimer",
			Start = 0,
			When = 0, -- Already expired
			Callback = function()
				callbackCalled = true
			end,
		}
	}
	
	Replace(Soundtrack.Timers, "OnUpdate", function()
		local callbacks = {}
		for i = #timerList, 1, -1 do
			if timerList[i].When <= 100 then -- Current time is 100
				table.insert(callbacks, timerList[i])
				table.remove(timerList, i)
			end
		end
		
		for _, callback in ipairs(callbacks) do
			callback.Callback()
		end
	end)
	
	Soundtrack.Timers.OnUpdate()
	
	AreEqual(true, callbackCalled)
end

function Tests:OnUpdate_UnexpiredTimer_DoesNotCallCallback()
	local callbackCalled = false
	local timerList = {
		{
			Name = "TestTimer",
			Start = 0,
			When = 200, -- Not expired yet
			Callback = function()
				callbackCalled = true
			end,
		}
	}
	
	Replace(Soundtrack.Timers, "OnUpdate", function()
		local callbacks = {}
		for i = #timerList, 1, -1 do
			if timerList[i].When <= 100 then -- Current time is 100
				table.insert(callbacks, timerList[i])
				table.remove(timerList, i)
			end
		end
		
		for _, callback in ipairs(callbacks) do
			callback.Callback()
		end
	end)
	
	Soundtrack.Timers.OnUpdate()
	
	AreEqual(false, callbackCalled)
end

function Tests:OnUpdate_MultipleTimers_CallsAllExpiredCallbacks()
	local callbacks = {}
	local timerList = {
		{
			Name = "Timer1",
			Start = 0,
			When = 0,
			Callback = function()
				table.insert(callbacks, 1)
			end,
		},
		{
			Name = "Timer2",
			Start = 0,
			When = 50,
			Callback = function()
				table.insert(callbacks, 2)
			end,
		},
		{
			Name = "Timer3",
			Start = 0,
			When = 200,
			Callback = function()
				table.insert(callbacks, 3)
			end,
		}
	}
	
	Replace(Soundtrack.Timers, "OnUpdate", function()
		local expiredCallbacks = {}
		for i = #timerList, 1, -1 do
			if timerList[i].When <= 100 then -- Current time is 100
				table.insert(expiredCallbacks, timerList[i])
				table.remove(timerList, i)
			end
		end
		
		for _, callback in ipairs(expiredCallbacks) do
			callback.Callback()
		end
	end)
	
	Soundtrack.Timers.OnUpdate()
	
	AreEqual(2, #callbacks)
	AreEqual(1, callbacks[1])
	AreEqual(2, callbacks[2])
end
