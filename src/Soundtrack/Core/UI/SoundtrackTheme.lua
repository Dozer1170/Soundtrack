-- SoundtrackTheme.lua
-- Centralized color and backdrop definitions for the Soundtrack UI.
-- All frames should use these constants for consistent theming.

SoundtrackTheme = {}

-- ── Available theme names (ordered for the dropdown) ─────────────────
SoundtrackTheme.ThemeNames = {
	"Cosmic Blue",
	"Class Color",
	"Forest",
	"Crimson",
	"Arcane",
	"Gold",
	"Blizzard",
}

-- ── Theme accent definitions ──────────────────────────────────────────
-- Each entry overrides the accent-derived color keys on SoundtrackTheme.Colors.
-- Background/layout keys (frameBg, panelBg, etc.) stay the same across themes.
local THEME_DEFS = {
	["Cosmic Blue"] = {
		accent         = { r = 0.30, g = 0.70, b = 1.00 },
		accentDim      = { r = 0.20, g = 0.50, b = 0.80 },
		accentSubtle   = { r = 0.20, g = 0.60, b = 1.00, a = 0.15 },
		textActive     = { r = 0.40, g = 0.80, b = 1.00 },
		barFill        = { r = 0.15, g = 0.40, b = 0.70 },
		btnBg          = { r = 0.08, g = 0.13, b = 0.22, a = 0.92 },
		btnBorder      = { r = 0.20, g = 0.50, b = 0.80, a = 0.80 },
		btnHoverBg     = { r = 0.15, g = 0.28, b = 0.48, a = 0.95 },
		btnHoverBorder = { r = 0.30, g = 0.70, b = 1.00, a = 1.00 },
	},
	["Forest"] = {
		accent         = { r = 0.20, g = 0.82, b = 0.30 },
		accentDim      = { r = 0.14, g = 0.56, b = 0.21 },
		accentSubtle   = { r = 0.10, g = 0.72, b = 0.22, a = 0.15 },
		textActive     = { r = 0.42, g = 1.00, b = 0.52 },
		barFill        = { r = 0.10, g = 0.45, b = 0.16 },
		btnBg          = { r = 0.06, g = 0.16, b = 0.08, a = 0.92 },
		btnBorder      = { r = 0.14, g = 0.56, b = 0.24, a = 0.80 },
		btnHoverBg     = { r = 0.10, g = 0.26, b = 0.14, a = 0.95 },
		btnHoverBorder = { r = 0.20, g = 0.82, b = 0.30, a = 1.00 },
	},
	["Crimson"] = {
		accent         = { r = 1.00, g = 0.20, b = 0.20 },
		accentDim      = { r = 0.70, g = 0.14, b = 0.14 },
		accentSubtle   = { r = 1.00, g = 0.12, b = 0.12, a = 0.15 },
		textActive     = { r = 1.00, g = 0.46, b = 0.46 },
		barFill        = { r = 0.65, g = 0.08, b = 0.08 },
		btnBg          = { r = 0.18, g = 0.06, b = 0.06, a = 0.92 },
		btnBorder      = { r = 0.70, g = 0.14, b = 0.14, a = 0.80 },
		btnHoverBg     = { r = 0.30, g = 0.08, b = 0.08, a = 0.95 },
		btnHoverBorder = { r = 1.00, g = 0.20, b = 0.20, a = 1.00 },
	},
	["Arcane"] = {
		accent         = { r = 0.76, g = 0.30, b = 1.00 },
		accentDim      = { r = 0.52, g = 0.20, b = 0.76 },
		accentSubtle   = { r = 0.66, g = 0.20, b = 1.00, a = 0.15 },
		textActive     = { r = 0.86, g = 0.56, b = 1.00 },
		barFill        = { r = 0.40, g = 0.10, b = 0.66 },
		btnBg          = { r = 0.12, g = 0.06, b = 0.20, a = 0.92 },
		btnBorder      = { r = 0.52, g = 0.20, b = 0.76, a = 0.80 },
		btnHoverBg     = { r = 0.22, g = 0.10, b = 0.38, a = 0.95 },
		btnHoverBorder = { r = 0.76, g = 0.30, b = 1.00, a = 1.00 },
	},
	["Gold"] = {
		accent         = { r = 1.00, g = 0.80, b = 0.10 },
		accentDim      = { r = 0.74, g = 0.56, b = 0.06 },
		accentSubtle   = { r = 1.00, g = 0.76, b = 0.00, a = 0.15 },
		textActive     = { r = 1.00, g = 0.90, b = 0.42 },
		barFill        = { r = 0.64, g = 0.46, b = 0.02 },
		btnBg          = { r = 0.18, g = 0.14, b = 0.04, a = 0.92 },
		btnBorder      = { r = 0.74, g = 0.56, b = 0.10, a = 0.80 },
		btnHoverBg     = { r = 0.28, g = 0.22, b = 0.06, a = 0.95 },
		btnHoverBorder = { r = 1.00, g = 0.80, b = 0.10, a = 1.00 },
	},
	["Blizzard"] = {
		accent         = { r = 1.00, g = 0.82, b = 0.00 },
		accentDim      = { r = 1.00, g = 0.72, b = 0.10 },
		accentSubtle   = { r = 1.00, g = 0.80, b = 0.00, a = 0.15 },
		textActive     = { r = 1.00, g = 0.90, b = 0.30 },
		barFill        = { r = 0.70, g = 0.50, b = 0.00 },
		btnBg          = { r = 0.16, g = 0.12, b = 0.05, a = 0.92 },
		btnBorder      = { r = 0.78, g = 0.61, b = 0.22, a = 0.80 },
		btnHoverBg     = { r = 0.26, g = 0.19, b = 0.07, a = 0.95 },
		btnHoverBorder = { r = 1.00, g = 0.82, b = 0.00, a = 1.00 },
	},
}

-- ── Color palette ────────────────────────────────────────────────────
SoundtrackTheme.Colors = {
	-- Main frame background
	frameBg        = { r = 0.06, g = 0.06, b = 0.09, a = 0.95 },
	-- Sub-panel backgrounds (event list, track list, assigned tracks)
	panelBg        = { r = 0.04, g = 0.04, b = 0.07, a = 0.70 },
	-- Dialog backgrounds (export/import, changelog)
	dialogBg       = { r = 0.06, g = 0.06, b = 0.09, a = 0.95 },

	-- Border/edge colors (applied via SetBackdropBorderColor)
	frameBorder    = { r = 0.20, g = 0.25, b = 0.35, a = 0.80 },
	panelBorder    = { r = 0.18, g = 0.22, b = 0.32, a = 0.60 },
	dialogBorder   = { r = 0.20, g = 0.25, b = 0.35, a = 0.80 },

	-- Accent (used by sidebar active indicator, status bars, highlights)
	accent         = { r = 0.30, g = 0.70, b = 1.00 },
	accentDim      = { r = 0.20, g = 0.50, b = 0.80 },
	accentSubtle   = { r = 0.20, g = 0.60, b = 1.00, a = 0.15 },

	-- Divider lines
	divider        = { r = 0.25, g = 0.28, b = 0.35, a = 1.0 },

	-- Text
	textNormal     = { r = 1.00, g = 1.00, b = 1.00 },
	textActive     = { r = 0.40, g = 0.80, b = 1.00 },
	textDim        = { r = 0.60, g = 0.60, b = 0.65 },
	textHeader     = { r = 0.53, g = 0.53, b = 0.53 },

	-- Status bar
	barFill        = { r = 0.15, g = 0.40, b = 0.70 },
	barBg          = { r = 0.03, g = 0.03, b = 0.06, a = 1.00 },

	-- Themed button states
	btnBg          = { r = 0.08, g = 0.13, b = 0.22, a = 0.92 },
	btnBorder      = { r = 0.20, g = 0.50, b = 0.80, a = 0.80 },
	btnHoverBg     = { r = 0.15, g = 0.28, b = 0.48, a = 0.95 },
	btnHoverBorder = { r = 0.30, g = 0.70, b = 1.00, a = 1.00 },
	btnPressedBg   = { r = 0.04, g = 0.08, b = 0.16, a = 0.95 },
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

local ButtonBackdrop                    = {
	bgFile   = "Interface/Buttons/WHITE8X8",
	edgeFile = "Interface/Buttons/WHITE8X8",
	edgeSize = 1,
}

-- ── Styled-element tracking ───────────────────────────────────────────
-- Elements styled at frame-creation time (XML OnLoad) whose colors are
-- "baked in" and won't pick up live Colors changes automatically.
-- StyleXxx functions push each element here so RefreshStyledElements()
-- can re-apply colors when the theme changes.
SoundtrackTheme._styledCheckboxes       = {}
SoundtrackTheme._styledButtons          = {}
SoundtrackTheme._styledScrollFrames     = {}
SoundtrackTheme._styledEventButtons     = {}
SoundtrackTheme._styledTrackButtons     = {}
SoundtrackTheme._styledStatusBarBorders = {}
SoundtrackTheme._styledStatusBars       = {}
SoundtrackTheme._styledSectionLabels    = {}
SoundtrackTheme._styledDividers         = {}
SoundtrackTheme._styledDropDowns        = {}

-- Internal apply helpers (no tracking side-effect, safe to call on refresh).
local function _applyCheckBoxStyle(checkBtn)
	local ac = SoundtrackTheme.Colors.accent
	checkBtn:SetCheckedTexture("Interface/Buttons/UI-CheckBox-Check")
	local t = checkBtn:GetCheckedTexture()
	t:SetDesaturated(true)
	t:SetVertexColor(ac.r, ac.g, ac.b)
	if checkBtn.Text then
		checkBtn.Text:SetTextColor(1, 1, 1)
	end
end

local function _applyButtonStyle(btn)
	btn:SetBackdrop(ButtonBackdrop)
	SoundtrackTheme.SetButtonStateNormal(btn)
	local h = btn:GetHighlightTexture()
	local ac = SoundtrackTheme.Colors.accent
	if h then h:SetVertexColor(ac.r, ac.g, ac.b, 0.10) end
end

local function _applyScrollArrowStyle(scrollFrame)
	local ac = SoundtrackTheme.Colors.accentDim
	local function StyleArrow(btn, up)
		btn:SetNormalTexture("Interface/Buttons/Arrow-Up-Up")
		btn:SetPushedTexture("Interface/Buttons/Arrow-Up-Down")
		btn:SetDisabledTexture("Interface/Buttons/Arrow-Up-Up")
		btn:SetHighlightTexture("Interface/Buttons/WHITE8X8")
		local tc = up and { 0, 1, 0, 1 } or { 0, 1, 1, 0 }
		local n, p, d = btn:GetNormalTexture(), btn:GetPushedTexture(), btn:GetDisabledTexture()
		n:SetTexCoord(unpack(tc)); p:SetTexCoord(unpack(tc)); d:SetTexCoord(unpack(tc))
		n:SetDesaturated(true); n:SetVertexColor(ac.r, ac.g, ac.b)
		d:SetDesaturated(true); d:SetVertexColor(ac.r * 0.4, ac.g * 0.4, ac.b * 0.4)
		local h = btn:GetHighlightTexture()
		if h then h:SetVertexColor(1, 1, 1, 0.1) end
	end
	StyleArrow(scrollFrame.ScrollBar.ScrollUpButton, true)
	StyleArrow(scrollFrame.ScrollBar.ScrollDownButton, false)
end

local function _applyEventButtonStyle(btn)
	local h = btn:GetHighlightTexture()
	local c = SoundtrackTheme.Colors.textNormal
	if h then h:SetVertexColor(c.r, c.g, c.b, 0.08) end
end

local function _applyTrackButtonStyle(btn)
	local h = btn:GetHighlightTexture()
	local c = SoundtrackTheme.Colors.accentSubtle
	if h then h:SetVertexColor(c.r, c.g, c.b, c.a) end
end

local function _applyStatusBarBorderStyle(btn)
	local h = btn:GetHighlightTexture()
	local ac = SoundtrackTheme.Colors.accent
	if h then h:SetVertexColor(ac.r, ac.g, ac.b, 0.25) end
end

local function _applyStatusBarStyle(bar)
	local c = SoundtrackTheme.Colors
	local tex = bar:GetStatusBarTexture()
	if tex then tex:SetDesaturated(true) end
	bar:SetStatusBarColor(c.accent.r, c.accent.g, c.accent.b)
	local fill = _G[bar:GetName() .. "FillBar"]
	if fill then fill:SetVertexColor(c.accent.r, c.accent.g, c.accent.b, 0.5) end
	local bg = _G[bar:GetName() .. "Background"]
	if bg then bg:SetVertexColor(c.barBg.r, c.barBg.g, c.barBg.b, c.barBg.a) end
end

local function _applySectionLabelStyle(fontString)
	local c = SoundtrackTheme.Colors.textNormal
	fontString:SetTextColor(c.r, c.g, c.b)
end

local function _applyDividerStyle(texture)
	local d = SoundtrackTheme.Colors.divider
	texture:SetVertexColor(d.r, d.g, d.b, d.a)
end

local function _applyDropDownStyle(frame)
	local ac = SoundtrackTheme.Colors.accentDim
	local function tintTex(tex)
		if tex then
			tex:SetDesaturated(true)
			tex:SetVertexColor(ac.r, ac.g, ac.b)
		end
	end
	tintTex(frame.Left)
	tintTex(frame.Middle)
	tintTex(frame.Right)
	if frame.Button and frame.Button.NormalTexture then
		frame.Button.NormalTexture:SetDesaturated(true)
		frame.Button.NormalTexture:SetVertexColor(ac.r, ac.g, ac.b)
	end
end

function SoundtrackTheme.StyleButton(btn)
	_applyButtonStyle(btn)
	table.insert(SoundtrackTheme._styledButtons, btn)
end

function SoundtrackTheme.SetButtonStateNormal(btn)
	local c = SoundtrackTheme.Colors
	btn:SetBackdropColor(c.btnBg.r, c.btnBg.g, c.btnBg.b, c.btnBg.a)
	btn:SetBackdropBorderColor(c.btnBorder.r, c.btnBorder.g, c.btnBorder.b, c.btnBorder.a)
	local fs = btn:GetFontString()
	if fs then fs:SetTextColor(1, 1, 1, 1) end
end

function SoundtrackTheme.SetButtonStateDisabled(btn)
	btn:SetBackdropColor(0.05, 0.05, 0.08, 0.70)
	btn:SetBackdropBorderColor(0.25, 0.25, 0.30, 0.50)
	local fs = btn:GetFontString()
	if fs then fs:SetTextColor(0.45, 0.45, 0.50, 1) end
end

function SoundtrackTheme.SetButtonStateHover(btn)
	local c = SoundtrackTheme.Colors
	btn:SetBackdropColor(c.btnHoverBg.r, c.btnHoverBg.g, c.btnHoverBg.b, c.btnHoverBg.a)
	btn:SetBackdropBorderColor(c.btnHoverBorder.r, c.btnHoverBorder.g, c.btnHoverBorder.b, c.btnHoverBorder.a)
end

function SoundtrackTheme.SetButtonStatePressed(btn)
	local c = SoundtrackTheme.Colors
	btn:SetBackdropColor(c.btnPressedBg.r, c.btnPressedBg.g, c.btnPressedBg.b, c.btnPressedBg.a)
	btn:SetBackdropBorderColor(c.btnHoverBorder.r, c.btnHoverBorder.g, c.btnHoverBorder.b, c.btnHoverBorder.a)
end

function SoundtrackTheme.StyleCheckBox(checkBtn)
	_applyCheckBoxStyle(checkBtn)
	table.insert(SoundtrackTheme._styledCheckboxes, checkBtn)
end

function SoundtrackTheme.StyleScrollArrows(scrollFrame)
	_applyScrollArrowStyle(scrollFrame)
	table.insert(SoundtrackTheme._styledScrollFrames, scrollFrame)
end

function SoundtrackTheme.StyleEventButton(btn)
	_applyEventButtonStyle(btn)
	table.insert(SoundtrackTheme._styledEventButtons, btn)
end

function SoundtrackTheme.StyleTrackButton(btn)
	_applyTrackButtonStyle(btn)
	table.insert(SoundtrackTheme._styledTrackButtons, btn)
end

function SoundtrackTheme.StyleStatusBarBorder(btn)
	_applyStatusBarBorderStyle(btn)
	table.insert(SoundtrackTheme._styledStatusBarBorders, btn)
end

function SoundtrackTheme.StyleStatusBar(bar)
	_applyStatusBarStyle(bar)
	table.insert(SoundtrackTheme._styledStatusBars, bar)
end

function SoundtrackTheme.StyleSectionLabel(fontString)
	_applySectionLabelStyle(fontString)
	table.insert(SoundtrackTheme._styledSectionLabels, fontString)
end

function SoundtrackTheme.StyleDivider(texture)
	_applyDividerStyle(texture)
	table.insert(SoundtrackTheme._styledDividers, texture)
end

function SoundtrackTheme.StyleDropDown(frame)
	_applyDropDownStyle(frame)
	table.insert(SoundtrackTheme._styledDropDowns, frame)
end

-- Re-applies styles to all elements previously passed through StyleXxx.
-- Called automatically by SetTheme before firing registered callbacks.
function SoundtrackTheme.RefreshStyledElements()
	for _, cb in ipairs(SoundtrackTheme._styledCheckboxes) do
		pcall(_applyCheckBoxStyle, cb)
	end
	for _, btn in ipairs(SoundtrackTheme._styledButtons) do
		pcall(_applyButtonStyle, btn)
	end
	for _, sf in ipairs(SoundtrackTheme._styledScrollFrames) do
		pcall(_applyScrollArrowStyle, sf)
	end
	for _, btn in ipairs(SoundtrackTheme._styledEventButtons) do
		pcall(_applyEventButtonStyle, btn)
	end
	for _, btn in ipairs(SoundtrackTheme._styledTrackButtons) do
		pcall(_applyTrackButtonStyle, btn)
	end
	for _, btn in ipairs(SoundtrackTheme._styledStatusBarBorders) do
		pcall(_applyStatusBarBorderStyle, btn)
	end
	for _, bar in ipairs(SoundtrackTheme._styledStatusBars) do
		pcall(_applyStatusBarStyle, bar)
	end
	for _, fs in ipairs(SoundtrackTheme._styledSectionLabels) do
		pcall(_applySectionLabelStyle, fs)
	end
	for _, tex in ipairs(SoundtrackTheme._styledDividers) do
		pcall(_applyDividerStyle, tex)
	end
	for _, dd in ipairs(SoundtrackTheme._styledDropDowns) do
		pcall(_applyDropDownStyle, dd)
	end
end

-- ── Theme switching ───────────────────────────────────────────────────

local refreshCallbacks = {}

-- Register a callback to be called when the theme changes.
-- Use this to re-apply colors to frames whose colors are baked at creation time.
function SoundtrackTheme.RegisterRefreshCallback(fn)
	table.insert(refreshCallbacks, fn)
end

-- Copy all fields from src color table into dest color table in-place.
local function CopyColorTable(dest, src)
	for k, v in pairs(src) do
		dest[k] = v
	end
end

-- Apply a theme by name, mutating SoundtrackTheme.Colors in-place.
-- Fires all registered refresh callbacks so live frames update immediately.
function SoundtrackTheme.SetTheme(name)
	local def = THEME_DEFS[name]
	if not def then return end
	for key, colorTable in pairs(def) do
		if SoundtrackTheme.Colors[key] then
			CopyColorTable(SoundtrackTheme.Colors[key], colorTable)
		else
			SoundtrackTheme.Colors[key] = {}
			CopyColorTable(SoundtrackTheme.Colors[key], colorTable)
		end
	end
	-- Re-style all tracked elements (checkboxes, buttons, scroll arrows)
	-- before firing registered callbacks so callbacks see fresh colors.
	SoundtrackTheme.RefreshStyledElements()
	for _, fn in ipairs(refreshCallbacks) do
		pcall(fn)
	end
end

-- Build (or rebuild) the Class Color theme entry based on the logged-in character's class.
function SoundtrackTheme.BuildClassColorTheme()
	if not UnitClass then return end
	local _, className = UnitClass("player")
	if not className then return end
	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]
	if not classColor then return end
	local r, g, b = classColor.r, classColor.g, classColor.b
	local function clamp(v) return math.max(0, math.min(1, v)) end
	THEME_DEFS["Class Color"] = {
		accent         = { r = r, g = g, b = b },
		accentDim      = { r = r * 0.68, g = g * 0.68, b = b * 0.68 },
		accentSubtle   = { r = r, g = g, b = b, a = 0.15 },
		textActive     = { r = clamp(r * 1.3 + 0.10), g = clamp(g * 1.3 + 0.10), b = clamp(b * 1.3 + 0.10) },
		barFill        = { r = r * 0.55, g = g * 0.55, b = b * 0.55 },
		btnBg          = { r = r * 0.12, g = g * 0.12, b = b * 0.12, a = 0.92 },
		btnBorder      = { r = r * 0.65, g = g * 0.65, b = b * 0.65, a = 0.80 },
		btnHoverBg     = { r = r * 0.25, g = g * 0.25, b = b * 0.25, a = 0.95 },
		btnHoverBorder = { r = r, g = g, b = b, a = 1.00 },
	}
end

-- Apply the theme stored in the addon DB. Call this before the UI is built.
function SoundtrackTheme.ApplyFromSettings()
	local themeName = "Cosmic Blue"
	if SoundtrackAddon and SoundtrackAddon.db then
		themeName = SoundtrackAddon.db.profile.settings.UITheme or "Cosmic Blue"
	end
	if themeName == "Class Color" then
		SoundtrackTheme.BuildClassColorTheme()
	end
	SoundtrackTheme.SetTheme(themeName)
end
