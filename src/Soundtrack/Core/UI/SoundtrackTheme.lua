-- SoundtrackTheme.lua
-- Centralized color and backdrop definitions for the Soundtrack UI.
-- All frames should use these constants for consistent theming.

SoundtrackTheme = {}

-- ── Color palette ────────────────────────────────────────────────────
SoundtrackTheme.Colors = {
	-- Main frame background
	frameBg         = { r = 0.06, g = 0.06, b = 0.09, a = 0.95 },
	-- Sub-panel backgrounds (event list, track list, assigned tracks)
	panelBg         = { r = 0.04, g = 0.04, b = 0.07, a = 0.70 },
	-- Dialog backgrounds (export/import, changelog)
	dialogBg        = { r = 0.06, g = 0.06, b = 0.09, a = 0.95 },

	-- Border/edge colors (applied via SetBackdropBorderColor)
	frameBorder     = { r = 0.20, g = 0.25, b = 0.35, a = 0.80 },
	panelBorder     = { r = 0.18, g = 0.22, b = 0.32, a = 0.60 },
	dialogBorder    = { r = 0.20, g = 0.25, b = 0.35, a = 0.80 },

	-- Accent (used by sidebar active indicator, status bars, highlights)
	accent          = { r = 0.30, g = 0.70, b = 1.00 },
	accentDim       = { r = 0.20, g = 0.50, b = 0.80 },
	accentSubtle    = { r = 0.20, g = 0.60, b = 1.00, a = 0.15 },

	-- Divider lines
	divider         = { r = 0.25, g = 0.28, b = 0.35, a = 0.50 },

	-- Text
	textNormal      = { r = 1.00, g = 1.00, b = 1.00 },
	textActive      = { r = 0.40, g = 0.80, b = 1.00 },
	textDim         = { r = 0.60, g = 0.60, b = 0.65 },
	textHeader      = { r = 0.53, g = 0.53, b = 0.53 },

	-- Status bar
	barFill         = { r = 0.15, g = 0.40, b = 0.70 },
	barBg           = { r = 0.03, g = 0.03, b = 0.06, a = 1.00 },
}

-- ── Backdrop definitions ─────────────────────────────────────────────

-- Main window — thin clean edge, no ornamental border
SoundtrackTheme.FrameBackdrop = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 16,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Sub-panels inside the main frame (event list, track list, etc.)
SoundtrackTheme.PanelBackdrop = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 12,
	insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Pop-up dialogs (export/import, changelog)
SoundtrackTheme.DialogBackdrop = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 16,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- ── Helper: apply a themed backdrop to a frame ───────────────────────
-- Usage: SoundtrackTheme.ApplyFrameBackdrop(self)
--        SoundtrackTheme.ApplyPanelBackdrop(self)
--        SoundtrackTheme.ApplyDialogBackdrop(self)

function SoundtrackTheme.ApplyFrameBackdrop(frame)
	Mixin(frame, BackdropTemplateMixin or {})
	frame:SetBackdrop(SoundtrackTheme.FrameBackdrop)
	local c = SoundtrackTheme.Colors.frameBg
	frame:SetBackdropColor(c.r, c.g, c.b, c.a)
	local b = SoundtrackTheme.Colors.frameBorder
	frame:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
end

function SoundtrackTheme.ApplyPanelBackdrop(frame)
	Mixin(frame, BackdropTemplateMixin or {})
	frame:SetBackdrop(SoundtrackTheme.PanelBackdrop)
	local c = SoundtrackTheme.Colors.panelBg
	frame:SetBackdropColor(c.r, c.g, c.b, c.a)
	local b = SoundtrackTheme.Colors.panelBorder
	frame:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
end

function SoundtrackTheme.ApplyDialogBackdrop(frame)
	Mixin(frame, BackdropTemplateMixin or {})
	frame:SetBackdrop(SoundtrackTheme.DialogBackdrop)
	local c = SoundtrackTheme.Colors.dialogBg
	frame:SetBackdropColor(c.r, c.g, c.b, c.a)
	local b = SoundtrackTheme.Colors.dialogBorder
	frame:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
end
