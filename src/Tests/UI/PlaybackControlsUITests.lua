if not Tests then
	return
end

local Tests = Tests("PlaybackControlsUI", "PLAYER_ENTERING_WORLD")

local function MockButton(name)
	local obj = {
		_visible = true,
		_mouseEnabled = true,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
		IsVisible = function(self) return self._visible end,
		EnableMouse = function(self, enabled) self._mouseEnabled = enabled end,
		SetPoint = function() end,
		ClearAllPoints = function() end,
		SetAlpha = function() end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function SetupAllControlButtons()
	MockButton("SoundtrackControlFrame_NextButton")
	MockButton("SoundtrackControlFrame_PlayButton")
	MockButton("SoundtrackControlFrame_StopButton")
	MockButton("SoundtrackControlFrame_PreviousButton")
	MockButton("SoundtrackControlFrame_TrueStopButton")
	MockButton("SoundtrackControlFrame_InfoButton")
end

local function SetupFrameButtons()
	MockButton("SoundtrackFrame_PlayButton")
	MockButton("SoundtrackFrame_StopButton")
end

-- HideControlButtons Tests

function Tests:HideControlButtons_HidesAllButtons_WhenSettingIsTrue()
	SetupAllControlButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = true

	SoundtrackFrame_HideControlButtons()

	IsFalse(SoundtrackControlFrame_NextButton._visible, "Next button hidden")
	IsFalse(SoundtrackControlFrame_PlayButton._visible, "Play button hidden")
	IsFalse(SoundtrackControlFrame_StopButton._visible, "Stop button hidden")
	IsFalse(SoundtrackControlFrame_PreviousButton._visible, "Previous button hidden")
	IsFalse(SoundtrackControlFrame_TrueStopButton._visible, "True stop button hidden")
	IsFalse(SoundtrackControlFrame_InfoButton._visible, "Info button hidden")
end

function Tests:HideControlButtons_ShowsAllButtons_WhenSettingIsFalse()
	SetupAllControlButtons()
	-- Start all hidden
	SoundtrackControlFrame_NextButton._visible = false
	SoundtrackControlFrame_PlayButton._visible = false
	SoundtrackControlFrame_StopButton._visible = false
	SoundtrackControlFrame_PreviousButton._visible = false
	SoundtrackControlFrame_TrueStopButton._visible = false
	SoundtrackControlFrame_InfoButton._visible = false
	SoundtrackAddon.db.profile.settings.HideControlButtons = false

	SoundtrackFrame_HideControlButtons()

	IsTrue(SoundtrackControlFrame_NextButton._visible, "Next button shown")
	IsTrue(SoundtrackControlFrame_PlayButton._visible, "Play button shown")
	IsTrue(SoundtrackControlFrame_StopButton._visible, "Stop button shown")
	IsTrue(SoundtrackControlFrame_PreviousButton._visible, "Previous button shown")
	IsTrue(SoundtrackControlFrame_TrueStopButton._visible, "True stop button shown")
	IsTrue(SoundtrackControlFrame_InfoButton._visible, "Info button shown")
end

function Tests:HideControlButtons_DisablesMouse_WhenHiddenIsTrue()
	SetupAllControlButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = true

	SoundtrackFrame_HideControlButtons()

	IsFalse(SoundtrackControlFrame_NextButton._mouseEnabled, "Next button mouse disabled")
	IsFalse(SoundtrackControlFrame_PlayButton._mouseEnabled, "Play button mouse disabled")
end

function Tests:HideControlButtons_EnablesMouse_WhenHiddenIsFalse()
	SetupAllControlButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = false

	SoundtrackFrame_HideControlButtons()

	IsTrue(SoundtrackControlFrame_NextButton._mouseEnabled, "Next button mouse enabled")
end

-- RefreshPlaybackControls Tests

function Tests:RefreshPlaybackControls_ShowsPlayButton_WhenPaused()
	SetupAllControlButtons()
	SetupFrameButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = false
	Replace(SoundtrackUI, "RefreshEventStack", function() end)
	Soundtrack.Events.Paused = true

	SoundtrackFrame_RefreshPlaybackControls()

	IsTrue(SoundtrackControlFrame_PlayButton._visible, "Play button visible when paused")
	IsFalse(SoundtrackControlFrame_StopButton._visible, "Stop button hidden when paused")
end

function Tests:RefreshPlaybackControls_ShowsStopButton_WhenNotPaused()
	SetupAllControlButtons()
	SetupFrameButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = false
	Replace(SoundtrackUI, "RefreshEventStack", function() end)
	Soundtrack.Events.Paused = false

	SoundtrackFrame_RefreshPlaybackControls()

	IsFalse(SoundtrackControlFrame_PlayButton._visible, "Play button hidden when not paused")
	IsTrue(SoundtrackControlFrame_StopButton._visible, "Stop button visible when not paused")
end

function Tests:RefreshPlaybackControls_ShowsFramePlayButton_WhenPaused()
	SetupAllControlButtons()
	SetupFrameButtons()
	SoundtrackAddon.db.profile.settings.HideControlButtons = false
	Replace(SoundtrackUI, "RefreshEventStack", function() end)
	Soundtrack.Events.Paused = true

	SoundtrackFrame_RefreshPlaybackControls()

	IsTrue(SoundtrackFrame_PlayButton._visible, "Frame play button visible when paused")
	IsFalse(SoundtrackFrame_StopButton._visible, "Frame stop button hidden when paused")
end
