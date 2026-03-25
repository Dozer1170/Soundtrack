-- SoundtrackAnimations.lua
-- Provides smooth fade transitions between content pages in the redesigned UI.

SoundtrackAnimations = {}

local FADE_DURATION = 0.2
local activePage = nil

-- Create fade-out and fade-in animation groups on a frame
function SoundtrackAnimations.SetupFrame(frame)
	if frame._stFadeIn then return end

	-- Fade In
	local fadeIn = frame:CreateAnimationGroup()
	local alphaIn = fadeIn:CreateAnimation("Alpha")
	alphaIn:SetFromAlpha(0)
	alphaIn:SetToAlpha(1)
	alphaIn:SetDuration(FADE_DURATION)
	alphaIn:SetSmoothing("OUT")
	fadeIn:SetScript("OnFinished", function()
		frame:SetAlpha(1)
	end)
	frame._stFadeIn = fadeIn

	-- Fade Out
	local fadeOut = frame:CreateAnimationGroup()
	local alphaOut = fadeOut:CreateAnimation("Alpha")
	alphaOut:SetFromAlpha(1)
	alphaOut:SetToAlpha(0)
	alphaOut:SetDuration(FADE_DURATION)
	alphaOut:SetSmoothing("IN")
	fadeOut:SetScript("OnFinished", function()
		frame:SetAlpha(0)
		frame:Hide()
	end)
	frame._stFadeOut = fadeOut
end

-- Show a frame with a fade-in animation
function SoundtrackAnimations.FadeIn(frame)
	if not frame then return end
	SoundtrackAnimations.SetupFrame(frame)
	if frame._stFadeOut:IsPlaying() then
		frame._stFadeOut:Stop()
	end
	frame:SetAlpha(0)
	frame:Show()
	frame._stFadeIn:Play()
end

-- Hide a frame with a fade-out animation
function SoundtrackAnimations.FadeOut(frame)
	if not frame then return end
	if not frame:IsShown() then return end
	SoundtrackAnimations.SetupFrame(frame)
	if frame._stFadeIn:IsPlaying() then
		frame._stFadeIn:Stop()
	end
	frame._stFadeOut:Play()
end

-- Transition from one content page to another with cross-fade
function SoundtrackAnimations.TransitionTo(newPage, oldPage)
	if oldPage and oldPage ~= newPage and oldPage:IsShown() then
		SoundtrackAnimations.FadeOut(oldPage)
	end
	if newPage then
		-- Small delay to let the old page start fading
		C_Timer.After(FADE_DURATION * 0.3, function()
			SoundtrackAnimations.FadeIn(newPage)
		end)
	end
end

-- Instant show without animation (for initial load)
function SoundtrackAnimations.ShowInstant(frame)
	if not frame then return end
	frame:SetAlpha(1)
	frame:Show()
end

-- Instant hide without animation
function SoundtrackAnimations.HideInstant(frame)
	if not frame then return end
	frame:SetAlpha(0)
	frame:Hide()
end
