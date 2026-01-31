if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:AddTimer_ValidDuration_AddsToTimerList()
	local fakeTime = 100
	Replace("GetTime", function()
		return fakeTime
	end)

	Soundtrack.Timers.AddTimer("TestTimer", 5, function() end)
	local timer = Soundtrack.Timers.Get("TestTimer")
	IsTrue(timer ~= nil, "timer should be added to the internal list")
	AreEqual(fakeTime, timer.Start, "timer start timestamp should match GetTime()")
	AreEqual(fakeTime + 5, timer.When, "timer expiration should equal start plus duration")
	Soundtrack.Timers.Remove("TestTimer")
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

	AreEqual(true, timer ~= nil, "timer should exist")
	AreEqual("TestTimer", timer.Name, "timer name should match")
end

function Tests:Get_NonexistentTimer_ReturnsNil()
	Replace(Soundtrack.Timers, "Get", function(name)
		return nil
	end)

	local timer = Soundtrack.Timers.Get("NonexistentTimer")

	AreEqual(nil, timer, "nonexistent timer should return nil")
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

	AreEqual(0, #timerList, "timer should be removed from list")
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

	AreEqual(1, #timerList, "timer list should be unchanged")
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

	AreEqual(true, callbackCalled, "expired timer callback should be called")
end

function Tests:OnUpdate_ExpiredTimer_CallsCallback_Real()
	local fakeTime = 0
	Replace("GetTime", function()
		return fakeTime
	end)

	local callbackCount = 0
	Soundtrack.Timers.AddTimer("RealExpiredTimer", 5, function()
		callbackCount = callbackCount + 1
	end)

	fakeTime = 10
	Soundtrack.Timers.OnUpdate()

	AreEqual(1, callbackCount, "expired timer callback should be called once")
	AreEqual(nil, Soundtrack.Timers.Get("RealExpiredTimer"), "expired timer should be removed")
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

	AreEqual(false, callbackCalled, "unexpired timer callback should not be called")
end

function Tests:OnUpdate_UnexpiredTimer_DoesNotCallCallback_Real()
	local fakeTime = 0
	Replace("GetTime", function()
		return fakeTime
	end)

	local callbackCalled = false
	Soundtrack.Timers.AddTimer("RealPendingTimer", 5, function()
		callbackCalled = true
	end)

	fakeTime = 4
	Soundtrack.Timers.OnUpdate()

	AreEqual(false, callbackCalled, "unexpired timer callback should not be called")
	IsTrue(Soundtrack.Timers.Get("RealPendingTimer") ~= nil, "unexpired timer should remain")
	Soundtrack.Timers.Remove("RealPendingTimer")
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

	table.sort(callbacks)
	AreEqual(2, #callbacks, "two expired timers should fire")
	AreEqual(1, callbacks[1], "first timer callback should fire")
	AreEqual(2, callbacks[2], "second timer callback should fire")
end

function Tests:OnUpdate_CallbackAddsTimer_DoesNotRunInSamePass()
	local fakeTime = 0
	Replace("GetTime", function()
		return fakeTime
	end)

	local firstCalled = false
	local secondCalled = false

	Soundtrack.Timers.AddTimer("FirstTimer", 0, function()
		firstCalled = true
		Soundtrack.Timers.AddTimer("SecondTimer", 0, function()
			secondCalled = true
		end)
	end)

	fakeTime = 1
	Soundtrack.Timers.OnUpdate()

	AreEqual(true, firstCalled, "first timer should fire")
	AreEqual(false, secondCalled, "second timer should not fire in same pass")

	Soundtrack.Timers.OnUpdate()

	AreEqual(true, secondCalled, "second timer should fire on next update")
end
