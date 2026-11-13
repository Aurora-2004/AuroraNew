--[[
	Umbra UI Library
	-----------------------------------------------------------------
	Layout:  Title bar (title + subtitle)  |  Sidebar tabs  |  Sections with rows
	Features: Themes (live switching), drag to move, drag the bottom-right
	          corner to resize, toggle key, notifications, flags,
	          config save / load, mobile toggle button (tap to show / hide
	          the window, drag to move; auto on touch devices, or set
	          MobileButton = true / false and MobileButtonImage = id in CreateWindow).

	Elements: Toggle, Button, Slider, Dropdown (single / multi, searchable,
	          Options = "Players" for a live player list), Textbox,
	          Keybind, ColorPicker, Label, Paragraph
	          Toggle / Button / Dropdown / Textbox / Keybind / ColorPicker accept
	          an optional Description = "small text under the name".

	Quick start:
		local Library = loadstring(readfile("UmbraUI/Library.lua"))()
		local Window  = Library:CreateWindow({ Title = "My Hub", SubTitle = "Lumber Tycoon 2", Theme = "Nord" })
		local Tab     = Window:CreateTab({ Name = "Player", Icon = "rbxassetid://..." })
		local Section = Tab:CreateSection("Movement")
		Section:CreateToggle({ Name = "Fly", Default = false, Flag = "Fly", Callback = function(v) end })
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Flags        = {},   -- Flag -> current value
	Elements     = {},   -- Flag -> element object
	Themes       = {},
	ThemeOrder   = {},
	CurrentTheme = nil,
	CurrentThemeName = nil,
	ConfigFolder = "UmbraUI",

	_bindings       = {},
	_themeCallbacks = {},
	_connections    = {},
	_gui            = nil,
	_notifHolder    = nil,
}

--==============================================================--
-- Themes
--==============================================================--
-- Every theme must define all of these keys.
-- Background   main window
-- Topbar       title bar
-- Section      section panel
-- Element      element row
-- ElementHover element row (hovered)
-- TabSelected  selected sidebar tab
-- Input        textboxes / dropdown options / key buttons
-- ToggleOff    toggle track (off) and slider track
-- ToggleOn     toggle track (on)  - optional, defaults to Accent
-- Knob        toggle / slider knob
-- Accent       highlight colour
-- Text         main text
-- SubText      secondary text
-- Stroke       outlines / dividers
-- Sidebar      tab list background        - optional, defaults to Background
-- Content      section holder background  - optional, defaults to Background slightly darker

function Library:AddTheme(name, data)
	if not self.Themes[name] then
		table.insert(self.ThemeOrder, name)
	end
	data.ToggleOn = data.ToggleOn or data.Accent
	data.Sidebar  = data.Sidebar or data.Background
	data.Content  = data.Content or data.Background:Lerp(Color3.new(0, 0, 0), 0.06)
	self.Themes[name] = data
end

local rgb = Color3.fromRGB

Library:AddTheme("Pink", {
	Background   = rgb(214, 108, 220),
	Topbar       = rgb(192, 70, 200),  -- title bar
	Sidebar      = rgb(214, 108, 220), -- tab list
	Content      = rgb(206, 98, 213),  -- section holder (slightly darker than the tab list)
	Section      = rgb(204, 84, 211),  -- section boxes
	Element      = rgb(222, 116, 227),
	ElementHover = rgb(231, 136, 235),
	TabSelected  = rgb(221, 112, 226),
	Input        = rgb(200, 78, 207),
	ToggleOff    = rgb(40, 26, 44),
	ToggleOn     = rgb(236, 155, 240),
	Knob         = rgb(255, 255, 255),
	Accent       = rgb(255, 255, 255),
	Text         = rgb(255, 255, 255),
	SubText      = rgb(252, 225, 253),
	Stroke       = rgb(240, 165, 244),
})

-- Default theme. Nord palette, matched to Potassium's Nord theme (#292e39 / #2e3440, Frost #88c0d0)
Library:AddTheme("Nord", {
	Background   = rgb(41, 46, 57),
	Topbar       = rgb(36, 41, 51),
	Sidebar      = rgb(46, 52, 64),
	Content      = rgb(41, 46, 57),
	Section      = rgb(46, 52, 64),
	Element      = rgb(51, 57, 71),
	ElementHover = rgb(59, 66, 82),
	TabSelected  = rgb(59, 66, 82),
	Input        = rgb(36, 41, 51),
	ToggleOff    = rgb(36, 41, 51),
	ToggleOn     = rgb(136, 192, 208),
	Knob         = rgb(236, 239, 244),
	Accent       = rgb(136, 192, 208),
	Text         = rgb(236, 239, 244),
	SubText      = rgb(163, 171, 186),
	Stroke       = rgb(67, 76, 94),
})

-- Amber: warm charcoal, gold accent
Library:AddTheme("Amber", {
	Background   = rgb(31, 28, 23),
	Topbar       = rgb(17, 16, 13),
	Sidebar      = rgb(39, 36, 30),
	Content      = rgb(31, 28, 23),
	Section      = rgb(39, 36, 30),
	Element      = rgb(49, 45, 37),
	ElementHover = rgb(64, 59, 48),
	TabSelected  = rgb(60, 55, 45),
	Input        = rgb(22, 20, 16),
	ToggleOff    = rgb(19, 17, 14),
	ToggleOn     = rgb(245, 184, 62),
	Knob         = rgb(246, 245, 243),
	Accent       = rgb(245, 184, 62),
	Text         = rgb(242, 240, 238),
	SubText      = rgb(176, 167, 150),
	Stroke       = rgb(73, 67, 55),
})

-- Crimson: red-tinted charcoal, red accent
Library:AddTheme("Crimson", {
	Background   = rgb(32, 21, 23),
	Topbar       = rgb(18, 12, 13),
	Sidebar      = rgb(41, 28, 29),
	Content      = rgb(32, 21, 23),
	Section      = rgb(41, 28, 29),
	Element      = rgb(52, 35, 37),
	ElementHover = rgb(67, 45, 48),
	TabSelected  = rgb(63, 42, 45),
	Input        = rgb(23, 15, 16),
	ToggleOff    = rgb(20, 13, 14),
	ToggleOn     = rgb(237, 66, 86),
	Knob         = rgb(247, 243, 243),
	Accent       = rgb(237, 66, 86),
	Text         = rgb(243, 237, 237),
	SubText      = rgb(176, 150, 154),
	Stroke       = rgb(77, 51, 54),
})

-- Dark: neutral charcoal, indigo accent
Library:AddTheme("Dark", {
	Background   = rgb(24, 25, 29),
	Topbar       = rgb(14, 14, 17),
	Sidebar      = rgb(31, 32, 38),
	Content      = rgb(24, 25, 29),
	Section      = rgb(31, 32, 38),
	Element      = rgb(39, 41, 47),
	ElementHover = rgb(51, 53, 61),
	TabSelected  = rgb(48, 49, 57),
	Input        = rgb(17, 18, 21),
	ToggleOff    = rgb(15, 16, 18),
	ToggleOn     = rgb(112, 122, 255),
	Knob         = rgb(244, 244, 246),
	Accent       = rgb(112, 122, 255),
	Text         = rgb(238, 239, 241),
	SubText      = rgb(155, 158, 171),
	Stroke       = rgb(58, 60, 69),
})

-- Forest: green-tinted charcoal, green accent
Library:AddTheme("Forest", {
	Background   = rgb(22, 32, 27),
	Topbar       = rgb(13, 18, 15),
	Sidebar      = rgb(28, 41, 34),
	Content      = rgb(22, 32, 27),
	Section      = rgb(28, 41, 34),
	Element      = rgb(36, 51, 43),
	ElementHover = rgb(46, 66, 56),
	TabSelected  = rgb(43, 62, 52),
	Input        = rgb(16, 23, 19),
	ToggleOff    = rgb(14, 20, 17),
	ToggleOn     = rgb(70, 200, 120),
	Knob         = rgb(243, 247, 245),
	Accent       = rgb(70, 200, 120),
	Text         = rgb(237, 242, 240),
	SubText      = rgb(150, 176, 163),
	Stroke       = rgb(52, 75, 64),
})

-- Grape: purple-tinted charcoal, violet accent
Library:AddTheme("Grape", {
	Background   = rgb(27, 21, 33),
	Topbar       = rgb(16, 12, 19),
	Sidebar      = rgb(35, 27, 42),
	Content      = rgb(27, 21, 33),
	Section      = rgb(35, 27, 42),
	Element      = rgb(44, 34, 53),
	ElementHover = rgb(57, 44, 68),
	TabSelected  = rgb(53, 41, 64),
	Input        = rgb(19, 15, 23),
	ToggleOff    = rgb(17, 13, 20),
	ToggleOn     = rgb(168, 108, 255),
	Knob         = rgb(245, 243, 247),
	Accent       = rgb(168, 108, 255),
	Text         = rgb(240, 237, 243),
	SubText      = rgb(164, 150, 176),
	Stroke       = rgb(65, 50, 78),
})

-- Light: soft grey, indigo accent
Library:AddTheme("Light", {
	Background   = rgb(242, 243, 246),
	Topbar       = rgb(222, 224, 230),
	Sidebar      = rgb(232, 234, 239),
	Content      = rgb(242, 243, 246),
	Section      = rgb(252, 252, 253),
	Element      = rgb(238, 239, 243),
	ElementHover = rgb(228, 230, 236),
	TabSelected  = rgb(218, 221, 229),
	Input        = rgb(255, 255, 255),
	ToggleOff    = rgb(198, 201, 210),
	ToggleOn     = rgb(88, 101, 242),
	Knob         = rgb(255, 255, 255),
	Accent       = rgb(88, 101, 242),
	Text         = rgb(26, 27, 34),
	SubText      = rgb(102, 106, 120),
	Stroke       = rgb(210, 213, 221),
})

-- Midnight: deep navy, blue accent
Library:AddTheme("Midnight", {
	Background   = rgb(13, 17, 27),
	Topbar       = rgb(6, 7, 12),
	Sidebar      = rgb(19, 23, 38),
	Content      = rgb(13, 17, 27),
	Section      = rgb(19, 23, 38),
	Element      = rgb(24, 30, 50),
	ElementHover = rgb(33, 41, 67),
	TabSelected  = rgb(30, 38, 62),
	Input        = rgb(8, 10, 17),
	ToggleOff    = rgb(7, 8, 14),
	ToggleOn     = rgb(84, 140, 255),
	Knob         = rgb(243, 244, 247),
	Accent       = rgb(84, 140, 255),
	Text         = rgb(237, 238, 243),
	SubText      = rgb(150, 156, 176),
	Stroke       = rgb(38, 47, 77),
})

-- Ocean: teal-tinted charcoal, cyan accent
Library:AddTheme("Ocean", {
	Background   = rgb(20, 30, 34),
	Topbar       = rgb(11, 17, 19),
	Sidebar      = rgb(25, 39, 43),
	Content      = rgb(20, 30, 34),
	Section      = rgb(25, 39, 43),
	Element      = rgb(32, 49, 55),
	ElementHover = rgb(42, 63, 71),
	TabSelected  = rgb(39, 59, 66),
	Input        = rgb(14, 21, 24),
	ToggleOff    = rgb(12, 19, 21),
	ToggleOn     = rgb(44, 192, 222),
	Knob         = rgb(243, 246, 247),
	Accent       = rgb(44, 192, 222),
	Text         = rgb(237, 241, 243),
	SubText      = rgb(150, 169, 176),
	Stroke       = rgb(47, 71, 80),
})

-- Sunset: warm charcoal, orange accent
Library:AddTheme("Sunset", {
	Background   = rgb(32, 25, 22),
	Topbar       = rgb(18, 14, 13),
	Sidebar      = rgb(41, 32, 28),
	Content      = rgb(32, 25, 22),
	Section      = rgb(41, 32, 28),
	Element      = rgb(51, 40, 36),
	ElementHover = rgb(66, 52, 46),
	TabSelected  = rgb(62, 49, 43),
	Input        = rgb(23, 18, 16),
	ToggleOff    = rgb(20, 15, 14),
	ToggleOn     = rgb(255, 134, 72),
	Knob         = rgb(247, 244, 243),
	Accent       = rgb(255, 134, 72),
	Text         = rgb(242, 239, 237),
	SubText      = rgb(176, 158, 150),
	Stroke       = rgb(75, 59, 52),
})

Library.CurrentTheme = Library.Themes.Nord
Library.CurrentThemeName = "Nord"

--==============================================================--
-- Helpers
--==============================================================--
local function T()
	return Library.CurrentTheme
end

local function Create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function Tween(inst, time, props, style, dir)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

-- Sets the properties from the current theme and keeps them in sync when the theme changes.
local function Bind(inst, map)
	for prop, key in pairs(map) do
		inst[prop] = T()[key]
		table.insert(Library._bindings, { inst, prop, key })
	end
	return inst
end

local function OnTheme(fn)
	table.insert(Library._themeCallbacks, fn)
end

local function Corner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function Stroke(parent, key, thickness, transparency)
	local s = Create("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
	Bind(s, { Color = key or "Stroke" })
	return s
end

local function Padding(parent, t, b, l, r)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		Parent = parent,
	})
end

local function Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library._connections, c)
	return c
end

local function IsClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function IsTouch(input)
	return input.UserInputType == Enum.UserInputType.Touch
end

-- Click handler that works for mouse, touch and gamepad. Activated is the
-- cross-platform event; MouseButton1Click is unreliable for taps (especially
-- inside ScrollingFrames).
local function OnClick(button, fn)
	return button.Activated:Connect(function(input)
		fn(input)
	end)
end

-- Press-and-drag on `target` (mouse or a single finger). Only the finger that
-- started the drag moves it, so a second finger (e.g. the movement thumbstick)
-- can't hijack or end it.
--   onStart(input) -> return false to ignore this press
--   onMove(input)
--   onEnd()        (optional)
local function TrackDrag(target, onStart, onMove, onEnd)
	local active
	target.InputBegan:Connect(function(input)
		if active or not IsClick(input) then return end
		if onStart(input) == false then return end
		active = input
	end)
	Connect(UserInputService.InputChanged, function(input)
		if not active then return end
		if IsTouch(active) then
			if input ~= active then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		onMove(input)
	end)
	Connect(UserInputService.InputEnded, function(input)
		if not active then return end
		local same = input == active
			or (not IsTouch(active) and input.UserInputType == Enum.UserInputType.MouseButton1)
		if same then
			active = nil
			if onEnd then onEnd() end
		end
	end)
end

-- Product of every UIScale between `inst` and its ScreenGui (window auto-fit).
local function ScaleOf(inst)
	local s, p = 1, inst
	while p and not p:IsA("LayerCollector") do
		local sc = p:FindFirstChildOfClass("UIScale")
		if sc then s *= sc.Scale end
		p = p.Parent
	end
	return s
end

local function SafeCall(fn, ...)
	if typeof(fn) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[UmbraUI] Callback error: " .. tostring(err))
		end
	end)
end

-- MouseEnter / MouseLeave, plus a fix for touch: a tap fires MouseEnter but
-- usually never MouseLeave, which would leave the element stuck highlighted.
-- Any finger lifting clears every hover that is still active.
local touchHovered = {} -- [leaveFn] = true
local touchHoverConn

local function HoverEvents(trigger, enter, leave)
	local hovered = false
	local function onLeave()
		if not hovered then return end
		hovered = false
		touchHovered[onLeave] = nil
		leave()
	end
	trigger.MouseEnter:Connect(function()
		hovered = true
		touchHovered[onLeave] = true
		enter()
	end)
	trigger.MouseLeave:Connect(onLeave)
	if not touchHoverConn then
		touchHoverConn = Connect(UserInputService.InputEnded, function(input)
			if not IsTouch(input) then return end
			for fn in pairs(touchHovered) do fn() end
		end)
	end
	return function() return hovered end
end

local function Hover(trigger, target)
	target = target or trigger
	return HoverEvents(trigger, function()
		Tween(target, 0.15, { BackgroundColor3 = T().ElementHover })
	end, function()
		Tween(target, 0.15, { BackgroundColor3 = T().Element })
	end)
end

local function GetGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local okCore, core = pcall(function()
		local cg = game:GetService("CoreGui")
		local _ = cg.Name -- access check
		return cg
	end)
	if okCore and core then
		local test = Instance.new("Folder")
		local canParent = pcall(function() test.Parent = core end)
		test:Destroy()
		if canParent then
			return core
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function GetGui()
	if Library._gui and Library._gui.Parent then
		return Library._gui
	end
	local parent = GetGuiParent()
	local old = parent:FindFirstChild("UmbraUI")
	if old then old:Destroy() end

	local gui = Create("ScreenGui", {
		Name = "UmbraUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false, -- keeps AbsolutePosition in the same space as mouse input
		DisplayOrder = 999,
	})
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
	end)
	gui.Parent = parent

	Library._notifHolder = Create("Frame", {
		Name = "Notifications",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})

	Library._gui = gui
	return gui
end

--==============================================================--
-- Theme API
--==============================================================--
function Library:SetTheme(theme)
	local data = typeof(theme) == "table" and theme or self.Themes[theme]
	if not data then
		warn("[UmbraUI] Unknown theme: " .. tostring(theme))
		return
	end
	self.CurrentTheme = data
	self.CurrentThemeName = typeof(theme) == "string" and theme or "Custom"

	local alive = {}
	for _, b in ipairs(self._bindings) do
		local inst, prop, key = b[1], b[2], b[3]
		if inst.Parent then
			if inst:IsA("UIStroke") then
				inst[prop] = data[key]
			else
				Tween(inst, 0.25, { [prop] = data[key] })
			end
			table.insert(alive, b)
		end
	end
	self._bindings = alive

	for _, fn in ipairs(self._themeCallbacks) do
		task.spawn(fn, data)
	end
end

function Library:GetThemes()
	return table.clone(self.ThemeOrder)
end

--==============================================================--
-- Notifications (centered dialog with Confirm / Decline)
--==============================================================--
--[[
	Library:Notify({
		Title       = "Error",
		Content     = "Something went wrong...",
		ConfirmText = "Confirm",      -- optional
		DeclineText = "Decline",      -- optional, set to false to show only one button
		Duration    = nil,            -- optional: auto-close after N seconds (Callback gets nil)
		Callback    = function(confirmed) end,  -- true = Confirm, false = Decline
	})
	Only one dialog shows at a time; extra calls wait in a queue.
]]
local NOTIFY_BUTTONS = {
	Confirm = { From = rgb(0, 205, 40), To = rgb(0, 150, 25), StrokeFrom = rgb(90, 255, 120), StrokeTo = rgb(0, 120, 20) },
	Decline = { From = rgb(245, 25, 25), To = rgb(190, 0, 0), StrokeFrom = rgb(255, 110, 110), StrokeTo = rgb(150, 0, 0) },
}

local notifyQueue = {}
local notifyBusy = false

local function NotifyButton(parent, text, style, order, width)
	-- The gradient lives on a separate fill frame: a UIGradient on the button
	-- itself would also tint its text and make it invisible.
	local b = Create("TextButton", {
		Size = width,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		LayoutOrder = order,
		Parent = parent,
	})
	local fill = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = b,
	}, {
		Create("UIGradient", { Color = ColorSequence.new(style.From, style.To) }),
	})
	Corner(fill, 6)
	local stroke = Create("UIStroke", {
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.new(1, 1, 1),
		Parent = fill,
	}, {
		Create("UIGradient", { Rotation = 90, Color = ColorSequence.new(style.StrokeFrom, style.StrokeTo) }),
	})
	Create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = b,
	})
	HoverEvents(b,
		function() Tween(stroke, 0.15, { Thickness = 2.5 }) end,
		function() Tween(stroke, 0.15, { Thickness = 1.5 }) end)
	return b
end

local function ShowNotify(opts, done)
	GetGui()
	local declineText = opts.DeclineText
	if declineText == nil then declineText = "Decline" end
	local confirmText = opts.ConfirmText or "Confirm"

	local card = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 50,
		Parent = Library._notifHolder,
	})
	Bind(card, { BackgroundColor3 = "Background" })
	Corner(card, 8)
	Stroke(card)
	local scale = Create("UIScale", { Scale = 0, Parent = card })
	Padding(card, 14, 16, 16, 16)
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	Bind(Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Text = opts.Title or "Notification",
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = card,
	}), { TextColor3 = "Text" })

	Bind(Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		Text = opts.Content or "",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = card,
	}), { TextColor3 = "Text" })

	-- spacer between the text and the buttons
	Create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 3, Parent = card })

	local buttons = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = card,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	-- inset 2px so the button outlines are not clipped by the card
	Padding(buttons, 2, 2, 2, 2)

	local two = declineText ~= false
	local width = two and UDim2.new(0.5, -4, 1, 0) or UDim2.fromScale(1, 1)
	local confirmBtn = NotifyButton(buttons, confirmText, NOTIFY_BUTTONS.Confirm, 1, width)
	local declineBtn = two and NotifyButton(buttons, declineText, NOTIFY_BUTTONS.Decline, 2, width)

	-- shrink the card on screens narrower than it (phones); 1 everywhere else
	local screen = Library._gui.AbsoluteSize
	local fit = screen.X > 0 and math.clamp((screen.X - 24) / 460, 0.4, 1) or 1
	Tween(scale, 0.3, { Scale = fit }, Enum.EasingStyle.Back)

	local closed = false
	local function close(result)
		if closed then return end
		closed = true
		Tween(scale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.2, function()
			card:Destroy()
			done()
		end)
		SafeCall(opts.Callback, result)
	end

	OnClick(confirmBtn, function() close(true) end)
	if declineBtn then
		OnClick(declineBtn, function() close(false) end)
	end
	if opts.Duration then
		task.delay(opts.Duration, function() close(nil) end)
	end
end

local function NextNotify()
	if notifyBusy then return end
	local opts = table.remove(notifyQueue, 1)
	if not opts then return end
	notifyBusy = true
	ShowNotify(opts, function()
		notifyBusy = false
		NextNotify()
	end)
end

function Library:Notify(opts)
	table.insert(notifyQueue, opts or {})
	NextNotify()
end

--==============================================================--
-- Config
--==============================================================--
local function Encode(v)
	local t = typeof(v)
	if t == "EnumItem" then
		return { __type = "Enum", value = v.Name }
	elseif t == "Color3" then
		return { __type = "Color3", value = v:ToHex() }
	elseif t == "Instance" and v:IsA("Player") then
		-- players are saved by name; a "Players" dropdown turns the name back into the Player
		return { __type = "Player", value = v.Name }
	elseif t == "table" then
		local out = {}
		for k, x in pairs(v) do out[k] = Encode(x) end
		return out
	end
	return v
end

local function Decode(v)
	if typeof(v) ~= "table" then
		return v
	elseif v.__type == "Enum" then
		return Enum.KeyCode[v.value]
	elseif v.__type == "Color3" then
		return Color3.fromHex(v.value)
	elseif v.__type == "Player" then
		return v.value
	end
	local out = {}
	for k, x in pairs(v) do out[k] = Decode(x) end
	return out
end

function Library:SaveConfig(name)
	if not writefile then
		return warn("[UmbraUI] writefile is not supported")
	end
	local data = { __theme = self.CurrentThemeName }
	for flag, el in pairs(self.Elements) do
		data[flag] = Encode(el.Value)
	end
	if isfolder and not isfolder(self.ConfigFolder) then
		makefolder(self.ConfigFolder)
	end
	writefile(self.ConfigFolder .. "/" .. (name or "default") .. ".json", HttpService:JSONEncode(data))
end

function Library:LoadConfig(name)
	if not (readfile and isfile) then
		return warn("[UmbraUI] readfile is not supported")
	end
	local path = self.ConfigFolder .. "/" .. (name or "default") .. ".json"
	if not isfile(path) then
		return warn("[UmbraUI] Config not found: " .. path)
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then
		return warn("[UmbraUI] Failed to read config: " .. path)
	end
	if data.__theme and self.Themes[data.__theme] then
		self:SetTheme(data.__theme)
	end
	for flag, value in pairs(data) do
		local el = self.Elements[flag]
		if el and el.Set then
			el:Set(Decode(value))
		end
	end
end

--==============================================================--
-- Elements (Section methods)
--==============================================================--
local Section = {}
Section.__index = Section

local function RegisterFlag(flag, element)
	if flag then
		Library.Elements[flag] = element
		Library.Flags[flag] = element.Value
	end
end

local ROW_H      = 38 -- row height
local ROW_DESC_H = 52 -- row height when it has a Description line
local TEXT_SIZE  = 15
local DESC_SIZE  = 13
local NAME_Y, NAME_H, DESC_Y = 8, 18, 29 -- name / description placement in rows with a Description
local ROW_RADIUS = 4

local function HeaderHeight(opts)
	return (opts and opts.Description) and ROW_DESC_H or ROW_H
end

local function NewRow(section, height)
	section._count += 1
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height or ROW_H),
		LayoutOrder = section._count,
		Parent = section.Container,
	})
	Bind(row, { BackgroundColor3 = "Element" })
	Corner(row, ROW_RADIUS)
	Stroke(row, "Stroke", 1)
	return row
end

-- Name (bold) + optional Description (small) on the left of a row.
-- Returns nameLabel, descLabel, centerY (where right-side controls should sit).
local function RowLabel(row, text, rightSpace, desc, x)
	x = x or 12
	local headerH = desc and ROW_DESC_H or ROW_H
	local width = UDim2.new(1, -(x + (rightSpace or 12)), 0, 0)

	local name = Bind(Create("TextLabel", {
		Position = UDim2.new(0, x, 0, desc and NAME_Y or 0),
		Size = width + UDim2.fromOffset(0, desc and NAME_H or headerH),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = TEXT_SIZE,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	}), { TextColor3 = "Text" })

	local descLabel
	if desc then
		descLabel = Bind(Create("TextLabel", {
			Position = UDim2.new(0, x, 0, DESC_Y),
			Size = width + UDim2.fromOffset(0, 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = DESC_SIZE,
			Text = desc,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		}), { TextColor3 = "SubText" })
	end
	return name, descLabel, desc and (NAME_Y + NAME_H / 2) or headerH / 2
end

local function ClickArea(row, height)
	return Create("TextButton", {
		Size = height and UDim2.new(1, 0, 0, height) or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
end

-- Toggle ------------------------------------------------------
function Section:CreateToggle(opts)
	opts = opts or {}
	local state = opts.Default == true
	local row = NewRow(self, HeaderHeight(opts))
	local btn = ClickArea(row)
	local _, _, centerY = RowLabel(row, opts.Name or "Toggle", 64, opts.Description)
	Hover(btn, row)

	-- rounded-rectangle switch with a square-ish knob
	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, centerY),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = state and T().ToggleOn or T().ToggleOff,
		Parent = row,
	})
	Corner(track, 6)

	local ON, OFF = UDim2.new(1, -20, 0.5, 0), UDim2.new(0, 2, 0.5, 0)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = state and ON or OFF,
		Size = UDim2.fromOffset(18, 18),
		Parent = track,
	})
	Bind(knob, { BackgroundColor3 = "Knob" })
	Corner(knob, 5)

	local Toggle = { Type = "Toggle", Value = state, Instance = row }

	local function render(time)
		Tween(track, time or 0.2, { BackgroundColor3 = Toggle.Value and T().ToggleOn or T().ToggleOff })
		Tween(knob, time or 0.2, { Position = Toggle.Value and ON or OFF })
	end

	function Toggle:Set(value)
		Toggle.Value = value == true
		if opts.Flag then Library.Flags[opts.Flag] = Toggle.Value end
		render()
		SafeCall(opts.Callback, Toggle.Value)
	end

	function Toggle:Get()
		return Toggle.Value
	end

	OnClick(btn, function()
		Toggle:Set(not Toggle.Value)
	end)
	OnTheme(function() render(0.25) end)

	RegisterFlag(opts.Flag, Toggle)
	if state and opts.CallOnStart ~= false then
		SafeCall(opts.Callback, true)
	end
	return Toggle
end

-- Button ------------------------------------------------------
function Section:CreateButton(opts)
	opts = opts or {}
	local row = NewRow(self, HeaderHeight(opts))
	local btn = ClickArea(row)
	local label = RowLabel(row, opts.Name or "Button", 12, opts.Description)
	local isHovered = Hover(btn, row)

	local Button = { Type = "Button", Instance = row }

	function Button:SetText(text)
		label.Text = text
	end

	OnClick(btn, function()
		row.BackgroundColor3 = T().Stroke
		-- fade back to hover (mouse still over it) or normal (finger lifted)
		Tween(row, 0.35, { BackgroundColor3 = isHovered() and T().ElementHover or T().Element })
		SafeCall(opts.Callback)
	end)

	return Button
end

-- Slider ------------------------------------------------------
function Section:CreateSlider(opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local inc = opts.Increment or 1
	local suffix = opts.Suffix or ""
	local value = math.clamp(opts.Default or min, min, max)

	local row = NewRow(self, 56)
	RowLabel(row, opts.Name or "Slider", 80).Size = UDim2.new(1, -92, 0, 34)

	-- A TextBox so the value can be typed as well as dragged.
	local valueLabel = Bind(Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 2),
		Size = UDim2.new(0, 80, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = "",
		PlaceholderText = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = row,
	}), { TextColor3 = "SubText" })

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 38),
		Size = UDim2.new(1, -24, 0, 7),
		Parent = row,
	})
	Bind(track, { BackgroundColor3 = "ToggleOff" })
	Corner(track, 3)

	local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), Parent = track })
	Bind(fill, { BackgroundColor3 = "Accent" })
	Corner(fill, 3)

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 2,
		Parent = track,
	})
	Bind(knob, { BackgroundColor3 = "Knob" })
	Corner(knob, 7)

	local hit = Create("TextButton", {
		Position = UDim2.new(0, 6, 0, 30),
		Size = UDim2.new(1, -12, 0, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Hover(hit, row)

	local decimals = 0
	local incStr = tostring(inc)
	local dot = incStr:find("%.")
	if dot then decimals = #incStr - dot end

	local Slider = { Type = "Slider", Value = value, Instance = row }

	local function render(time)
		local pct = (max == min) and 0 or (Slider.Value - min) / (max - min)
		Tween(fill, time or 0.1, { Size = UDim2.fromScale(pct, 1) })
		Tween(knob, time or 0.1, { Position = UDim2.fromScale(pct, 0.5) })
		if not valueLabel:IsFocused() then
			valueLabel.Text = string.format("%." .. decimals .. "f", Slider.Value) .. suffix
		end
	end

	-- Typing: show the bare number while editing, apply it on Enter / click-away.
	valueLabel.Focused:Connect(function()
		valueLabel.Text = string.format("%." .. decimals .. "f", Slider.Value)
		valueLabel.CursorPosition = #valueLabel.Text + 1
		valueLabel.SelectionStart = 1
	end)

	valueLabel.FocusLost:Connect(function()
		local typed = tonumber((valueLabel.Text:gsub(",", "."):match("%-?%d*%.?%d+")))
		if typed then
			Slider:Set(typed)
		else
			render()
		end
	end)

	function Slider:Set(v)
		v = math.clamp(tonumber(v) or min, min, max)
		v = math.floor((v - min) / inc + 0.5) * inc + min
		v = math.clamp(v, min, max)
		if v == Slider.Value then
			render()
			return
		end
		Slider.Value = v
		if opts.Flag then Library.Flags[opts.Flag] = v end
		render()
		SafeCall(opts.Callback, v)
	end

	function Slider:Get()
		return Slider.Value
	end

	local function fromX(x)
		local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		Slider:Set(min + (max - min) * pct)
	end

	TrackDrag(hit,
		function(input) fromX(input.Position.X) end,
		function(input) fromX(input.Position.X) end)

	render(0)
	RegisterFlag(opts.Flag, Slider)
	return Slider
end

-- Dropdown ----------------------------------------------------
-- Header row reads "Name" or "Name - Value" with a chevron on the right.
-- Opening it shows a separate outlined box underneath with the options.
-- With Search (on by default) the header has a magnifier: click it and type
-- to filter the options. Enter picks the first match.
--
-- Options = "Players" lists every player in the server and keeps the list up
-- to date as people join / leave. The value is the Player instance itself
-- (or a table of them with Multi). A selected player who leaves is deselected
-- and the Callback fires. ExcludeSelf = true leaves out the LocalPlayer.
-- Default / :Set() also accept a player's name in this mode.
local DROPDOWN_ARROW = "rbxassetid://6031091003"

function Section:CreateDropdown(opts)
	opts = opts or {}
	local multi = opts.Multi == true
	local searchable = opts.Search ~= false
	local name = opts.Name or "Dropdown"
	local desc = opts.Description
	local headerH = HeaderHeight(opts)
	local open, focused = false, false
	local filter = ""

	-- holder = header row + options box
	self._count += 1
	local holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, headerH),
		BackgroundTransparency = 1,
		LayoutOrder = self._count,
		Parent = self.Container,
	})

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, headerH),
		Parent = holder,
	})
	Bind(row, { BackgroundColor3 = "Element" })
	Corner(row, ROW_RADIUS)
	Stroke(row, "Stroke", 1)
	local header = ClickArea(row)
	Hover(header, row)

	local nameY = desc and NAME_Y or 0
	local nameH = desc and NAME_H or headerH
	local centerY = nameY + nameH / 2
	local textX = searchable and 31 or 12

	-- magnifier icon (drawn, so it needs no image asset): 12x12, 12px in from the left edge
	if searchable then
		local icon = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0, centerY),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			Parent = row,
		})
		local ring = Create("Frame", {
			Position = UDim2.fromOffset(1, 1),
			Size = UDim2.fromOffset(7, 7),
			BackgroundTransparency = 1,
			Parent = icon,
		})
		Corner(ring, 4)
		Stroke(ring, "Text", 1.5)
		Bind(Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(9.5, 9.5),
			Size = UDim2.fromOffset(4, 1.5),
			Rotation = 45,
			BorderSizePixel = 0,
			Parent = icon,
		}), { BackgroundColor3 = "Text" })
	end

	local display
	if searchable then
		display = Create("TextBox", {
			Position = UDim2.fromOffset(textX, nameY),
			Size = UDim2.new(1, -(textX + 36), 0, nameH),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = TEXT_SIZE,
			Text = "",
			PlaceholderText = "Search...",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = row,
		})
		Bind(display, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	else
		display = Bind(Create("TextLabel", {
			Position = UDim2.fromOffset(textX, nameY),
			Size = UDim2.new(1, -(textX + 36), 0, nameH),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = TEXT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		}), { TextColor3 = "Text" })
	end

	if desc then
		Bind(Create("TextLabel", {
			Position = UDim2.fromOffset(textX, DESC_Y),
			Size = UDim2.new(1, -(textX + 36), 0, 15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = DESC_SIZE,
			Text = desc,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		}), { TextColor3 = "SubText" })
	end

	-- chevron: points left when closed, turns to point down when open
	local arrow = Bind(Create("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, centerY), -- 12px in from the edge, same as the text on the left
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = DROPDOWN_ARROW,
		ScaleType = Enum.ScaleType.Fit,
		Parent = row,
	}), { ImageColor3 = "Text" })

	-- options box (separate outlined box under the header)
	local box = Create("Frame", {
		Position = UDim2.fromOffset(0, headerH + 6),
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		Parent = holder,
	})
	Bind(box, { BackgroundColor3 = "Element" })
	Corner(box, ROW_RADIUS)
	Stroke(box, "Stroke", 1)

	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = box,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Bind(list, { ScrollBarImageColor3 = "Text" })
	Padding(list, 1, 1, 1, 1)

	local noResults = Bind(Create("TextLabel", {
		Size = UDim2.new(1, -6, 0, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = "No results",
		Visible = false,
		LayoutOrder = 1e6,
		Parent = list,
	}), { TextColor3 = "SubText" })

	local playerMode = opts.Options == "Players"
	local excludeSelf = opts.ExcludeSelf == true

	-- every player in the server (minus one who is leaving right now), sorted by name
	local function playerList(leaving)
		local out = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= leaving and not (excludeSelf and p == LocalPlayer) then
				table.insert(out, p)
			end
		end
		table.sort(out, function(a, b) return a.Name:lower() < b.Name:lower() end)
		return out
	end

	-- in player mode a name is turned into its Player (nil if they aren't here)
	local function resolve(v)
		if playerMode and typeof(v) == "string" then
			local p = Players:FindFirstChild(v)
			return (p and p:IsA("Player")) and p or nil
		end
		return v
	end

	local Dropdown = {
		Type = "Dropdown",
		Options = playerMode and playerList() or (opts.Options or {}),
		Instance = holder,
	}
	if multi then
		Dropdown.Value = {}
		for _, v in ipairs(typeof(opts.Default) == "table" and opts.Default or {}) do
			v = resolve(v)
			if v ~= nil then table.insert(Dropdown.Value, v) end
		end
	else
		Dropdown.Value = resolve(opts.Default)
	end

	local entries = {} -- { Option, Button, Check }
	local visibleCount = 0

	local function isSelected(option)
		if multi then
			return table.find(Dropdown.Value, option) ~= nil
		end
		return Dropdown.Value == option
	end

	local function displayText()
		local value
		if multi then
			if #Dropdown.Value > 0 then
				local parts = {}
				for i, v in ipairs(Dropdown.Value) do parts[i] = tostring(v) end
				value = table.concat(parts, ", ")
			end
		elseif Dropdown.Value ~= nil then
			value = tostring(Dropdown.Value)
		end
		return value and (name .. " - " .. value) or name
	end

	local function updateText()
		if not focused then
			display.Text = displayText()
		end
		for _, e in ipairs(entries) do
			local sel = isSelected(e.Option)
			e.Check.Visible = sel
			Tween(e.Button, 0.15, { BackgroundColor3 = sel and T().ElementHover or T().Input })
		end
	end

	local function matches(option)
		if filter == "" then return true end
		local f = filter:lower()
		if tostring(option):lower():find(f, 1, true) then return true end
		-- players can also be found by display name
		return typeof(option) == "Instance" and option:IsA("Player")
			and option.DisplayName:lower():find(f, 1, true) ~= nil
	end

	local function applyFilter()
		visibleCount = 0
		for _, e in ipairs(entries) do
			local vis = matches(e.Option)
			e.Button.Visible = vis
			if vis then visibleCount += 1 end
		end
		noResults.Visible = visibleCount == 0
	end

	local function boxHeight()
		return math.min(math.max(visibleCount, 1) * 36 - 4, 180) + 2 + 12
	end

	local function setOpen(state)
		open = state
		if not open and filter ~= "" then
			filter = ""
			applyFilter()
		end
		local h = boxHeight()
		if open then box.Visible = true end
		Tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, open and (headerH + 6 + h) or headerH) })
		Tween(box, 0.25, { Size = UDim2.new(1, 0, 0, open and h or 0) })
		Tween(arrow, 0.25, { Rotation = open and -90 or 0 })
		if not open then
			task.delay(0.25, function()
				if not open then box.Visible = false end
			end)
		end
	end

	local function fire()
		if opts.Flag then Library.Flags[opts.Flag] = Dropdown.Value end
		updateText()
		SafeCall(opts.Callback, Dropdown.Value)
	end

	local function choose(option)
		if multi then
			local idx = table.find(Dropdown.Value, option)
			if idx then
				table.remove(Dropdown.Value, idx)
			else
				table.insert(Dropdown.Value, option)
			end
		else
			Dropdown.Value = option
			setOpen(false)
		end
		fire()
	end

	local function build()
		for _, e in ipairs(entries) do e.Button:Destroy() end
		table.clear(entries)
		for i, option in ipairs(Dropdown.Options) do
			local sel = isSelected(option)
			local b = Create("TextButton", {
				Size = UDim2.new(1, -6, 0, 32),
				AutoButtonColor = false,
				BackgroundColor3 = sel and T().ElementHover or T().Input,
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				Text = tostring(option),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = i,
				Parent = list,
			})
			Bind(b, { TextColor3 = "Text" })
			Corner(b, ROW_RADIUS)
			Stroke(b, "Stroke", 1)
			Padding(b, 0, 0, 10, 26)
			local check = Bind(Create("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 18, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				Text = "✓",
				Visible = sel,
				Parent = b,
			}), { TextColor3 = "Text" })

			HoverEvents(b, function()
				Tween(b, 0.15, { BackgroundColor3 = T().ElementHover })
			end, function()
				Tween(b, 0.15, { BackgroundColor3 = isSelected(option) and T().ElementHover or T().Input })
			end)
			OnClick(b, function()
				choose(option)
			end)
			table.insert(entries, { Option = option, Button = b, Check = check })
		end
		applyFilter()
		if open then setOpen(true) end
	end

	-- rebuild the player list; anyone selected who is no longer listed gets deselected
	local function syncPlayers(leaving)
		Dropdown.Options = playerList(leaving)
		local changed = false
		if multi then
			for i = #Dropdown.Value, 1, -1 do
				if not table.find(Dropdown.Options, Dropdown.Value[i]) then
					table.remove(Dropdown.Value, i)
					changed = true
				end
			end
		elseif Dropdown.Value ~= nil and not table.find(Dropdown.Options, Dropdown.Value) then
			Dropdown.Value = nil
			changed = true
		end
		build()
		if changed then fire() else updateText() end
	end

	local watching = false
	local function watchPlayers()
		if watching then return end
		watching = true
		Connect(Players.PlayerAdded, function()
			if playerMode then syncPlayers() end
		end)
		Connect(Players.PlayerRemoving, function(p)
			if playerMode then syncPlayers(p) end
		end)
	end

	function Dropdown:Set(value)
		if multi then
			Dropdown.Value = {}
			for _, v in ipairs(typeof(value) == "table" and value or { value }) do
				v = resolve(v)
				if v ~= nil then table.insert(Dropdown.Value, v) end
			end
		else
			Dropdown.Value = resolve(value)
		end
		fire()
	end

	function Dropdown:Get()
		return Dropdown.Value
	end

	-- :Refresh({ ... })   -> static options
	-- :Refresh("Players") -> switch to the auto-updating player list
	-- :Refresh()          -> in player mode, re-read the player list
	function Dropdown:Refresh(newOptions, keepSelection)
		playerMode = newOptions == "Players" or (newOptions == nil and playerMode)
		if not keepSelection then
			Dropdown.Value = multi and {} or nil
		end
		if playerMode then
			watchPlayers()
			syncPlayers()
			return
		end
		Dropdown.Options = newOptions or {}
		build()
		updateText()
	end

	function Dropdown:Open()
		setOpen(true)
	end

	function Dropdown:Close()
		setOpen(false)
	end

	OnClick(header, function()
		setOpen(not open)
	end)

	if searchable then
		-- Invisible tap targets (no visual change):
		--  * over the text: a mouse click starts searching like before, but a tap
		--    just opens / closes the list so the phone keyboard doesn't pop up
		--  * over the magnifier: always starts searching (how to search on mobile)
		local textHit = Create("TextButton", {
			Position = display.Position,
			Size = display.Size,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = row,
		})
		local searchHit = Create("TextButton", {
			Position = UDim2.fromOffset(0, nameY),
			Size = UDim2.fromOffset(textX, nameH),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = row,
		})
		OnClick(textHit, function(input)
			local touch = (input and IsTouch(input))
				or (not input and UserInputService:GetLastInputType() == Enum.UserInputType.Touch)
			if touch then
				setOpen(not open)
			else
				display:CaptureFocus()
			end
		end)
		OnClick(searchHit, function()
			display:CaptureFocus()
		end)

		display.Focused:Connect(function()
			textHit.Visible = false -- let the mouse place the caret while typing
			focused = true
			display.Text = ""
			if not open then setOpen(true) end
		end)
		display:GetPropertyChangedSignal("Text"):Connect(function()
			if not focused then return end
			filter = display.Text
			applyFilter()
			setOpen(true)
		end)
		display.FocusLost:Connect(function(enter)
			focused = false
			textHit.Visible = true
			if enter then
				for _, e in ipairs(entries) do
					if matches(e.Option) then
						choose(e.Option)
						break
					end
				end
			end
			display.Text = displayText()
		end)
	end

	OnTheme(updateText)

	if playerMode then watchPlayers() end
	build()
	updateText()
	RegisterFlag(opts.Flag, Dropdown)
	return Dropdown
end

-- Textbox -----------------------------------------------------
function Section:CreateTextbox(opts)
	opts = opts or {}
	local row = NewRow(self, HeaderHeight(opts))
	local _, _, centerY = RowLabel(row, opts.Name or "Textbox", 150, opts.Description)

	local MIN_W, MAX_W, PAD = 70, 220, 20 -- box width grows with the text between these

	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0, centerY),
		Size = UDim2.fromOffset(MIN_W, 26),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		Text = opts.Default or "",
		PlaceholderText = opts.Placeholder or "Type here...",
		ClearTextOnFocus = opts.ClearOnFocus == true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClipsDescendants = true,
		Parent = row,
	})
	Bind(box, { BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	Corner(box, ROW_RADIUS)
	local stroke = Stroke(box)
	Padding(box, 0, 0, 8, 8)

	-- Tween the width to fit the text (or the placeholder when empty), capped at
	-- MAX_W and at half the row so it never covers the name.
	local function fit(time)
		local shown = box.Text ~= "" and box.Text or box.PlaceholderText
		local textW = TextService:GetTextSize(shown, box.TextSize, box.Font, Vector2.new(10000, 100)).X
		local maxW = MAX_W
		if row.AbsoluteSize.X > 0 then
			-- AbsoluteSize includes the window's auto-fit scale, Size offsets don't
			maxW = math.min(MAX_W, math.floor(row.AbsoluteSize.X / ScaleOf(row) * 0.5))
		end
		local w = math.clamp(textW + PAD, MIN_W, math.max(MIN_W, maxW))
		Tween(box, time or 0.15, { Size = UDim2.fromOffset(w, 26) })
	end
	box:GetPropertyChangedSignal("Text"):Connect(function() fit() end)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit(0) end)
	fit(0)

	local Textbox = { Type = "Textbox", Value = box.Text, Instance = row }

	function Textbox:Set(text)
		text = tostring(text or "")
		box.Text = text
		Textbox.Value = text
		if opts.Flag then Library.Flags[opts.Flag] = text end
		SafeCall(opts.Callback, text, false)
	end

	function Textbox:Get()
		return Textbox.Value
	end

	box.Focused:Connect(function()
		stroke.Color = T().Accent
	end)
	box.FocusLost:Connect(function(enter)
		stroke.Color = T().Stroke
		local text = box.Text
		if opts.Numeric then
			local n = tonumber(text)
			if not n then
				box.Text = Textbox.Value
				return
			end
		end
		Textbox.Value = text
		if opts.Flag then Library.Flags[opts.Flag] = text end
		SafeCall(opts.Callback, text, enter)
	end)

	RegisterFlag(opts.Flag, Textbox)
	return Textbox
end

-- Keybind -----------------------------------------------------
function Section:CreateKeybind(opts)
	opts = opts or {}
	local row = NewRow(self, HeaderHeight(opts))
	local _, _, centerY = RowLabel(row, opts.Name or "Keybind", 110, opts.Description)

	local keyBtn = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0, centerY),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Parent = row,
	})
	Bind(keyBtn, { BackgroundColor3 = "Input", TextColor3 = "Text" })
	Corner(keyBtn, ROW_RADIUS)
	Stroke(keyBtn)
	Padding(keyBtn, 0, 0, 10, 10)

	local Keybind = { Type = "Keybind", Value = opts.Default, Instance = row }
	local listening = false

	local function render()
		keyBtn.Text = listening and "..." or (Keybind.Value and Keybind.Value.Name or "None")
	end

	function Keybind:Set(key)
		if typeof(key) == "string" then key = Enum.KeyCode[key] end
		Keybind.Value = key
		if opts.Flag then Library.Flags[opts.Flag] = key end
		render()
		SafeCall(opts.ChangedCallback, key)
	end

	function Keybind:Get()
		return Keybind.Value
	end

	-- tapping again cancels (phones have no keyboard to finish with)
	OnClick(keyBtn, function()
		listening = not listening
		render()
	end)

	Connect(UserInputService.InputBegan, function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					Keybind:Set(nil)
				else
					Keybind:Set(input.KeyCode)
				end
			end
			return
		end
		if not processed and Keybind.Value and input.KeyCode == Keybind.Value then
			SafeCall(opts.Callback, Keybind.Value)
		end
	end)

	render()
	RegisterFlag(opts.Flag, Keybind)
	return Keybind
end

-- Color picker ------------------------------------------------
function Section:CreateColorPicker(opts)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = color:ToHSV()
	local open = false

	local headerH = HeaderHeight(opts)
	local row = NewRow(self, headerH)
	row.ClipsDescendants = true
	local header = ClickArea(row, headerH)
	local _, _, centerY = RowLabel(row, opts.Name or "Color", 60, opts.Description)
	Hover(header, row)

	local preview = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, centerY),
		Size = UDim2.fromOffset(36, 18),
		BackgroundColor3 = color,
		Parent = row,
	})
	Corner(preview, ROW_RADIUS)
	Stroke(preview)

	-- Saturation / Value box
	local sv = Create("TextButton", {
		Position = UDim2.new(0, 12, 0, headerH + 6),
		Size = UDim2.new(1, -60, 0, 110),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Parent = row,
	})
	Corner(sv, 5)
	local white = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = sv,
	}, {
		Create("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
	})
	Corner(white, 5)
	local black = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Parent = sv,
	}, {
		Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
	})
	Corner(black, 5)
	local svCursor = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = sv,
	})
	Corner(svCursor, 4)
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = svCursor })

	-- Hue bar
	local hue = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, headerH + 6),
		Size = UDim2.new(0, 22, 0, 110),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = row,
	}, {
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
				ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
				ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
				ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
				ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
				ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
				ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
			}),
		}),
	})
	Corner(hue, 5)
	local hueCursor = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 4, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = hue,
	})
	Corner(hueCursor, 2)
	Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })

	local ColorPicker = { Type = "ColorPicker", Value = color, Instance = row }

	local function render()
		local c = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = c
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0.5, h)
	end

	local function commit()
		ColorPicker.Value = Color3.fromHSV(h, s, v)
		if opts.Flag then Library.Flags[opts.Flag] = ColorPicker.Value end
		render()
		SafeCall(opts.Callback, ColorPicker.Value)
	end

	function ColorPicker:Set(c)
		if typeof(c) ~= "Color3" then return end
		h, s, v = c:ToHSV()
		commit()
	end

	function ColorPicker:Get()
		return ColorPicker.Value
	end

	local function updateSV(pos)
		s = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
		commit()
	end
	local function updateHue(pos)
		h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
		commit()
	end

	TrackDrag(sv,
		function(input) updateSV(input.Position) end,
		function(input) updateSV(input.Position) end)
	TrackDrag(hue,
		function(input) updateHue(input.Position) end,
		function(input) updateHue(input.Position) end)

	OnClick(header, function()
		open = not open
		Tween(row, 0.25, { Size = UDim2.new(1, 0, 0, open and (headerH + 126) or headerH) })
	end)

	render()
	RegisterFlag(opts.Flag, ColorPicker)
	return ColorPicker
end

-- Label -------------------------------------------------------
function Section:CreateLabel(text)
	if typeof(text) == "table" then text = text.Text or text.Name end
	local row = NewRow(self, 26)
	row.BackgroundTransparency = 1
	row:FindFirstChildOfClass("UIStroke"):Destroy()
	local label = Bind(Create("TextLabel", {
		Position = UDim2.new(0, 2, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		Text = text or "Label",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	}), { TextColor3 = "SubText" })

	local Label = { Type = "Label", Instance = row }
	function Label:Set(newText)
		label.Text = tostring(newText)
	end
	return Label
end

-- Paragraph ---------------------------------------------------
function Section:CreateParagraph(opts)
	opts = opts or {}
	self._count += 1
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._count,
		Parent = self.Container,
	})
	Bind(row, { BackgroundColor3 = "Element" })
	Corner(row, ROW_RADIUS)
	Stroke(row, "Stroke", 1)
	Padding(row, 8, 10, 12, 12)
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

	local title = Bind(Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = opts.Title or "Paragraph",
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = row,
	}), { TextColor3 = "Text" })

	local content = Bind(Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		Text = opts.Content or "",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = row,
	}), { TextColor3 = "SubText" })

	local Paragraph = { Type = "Paragraph", Instance = row }
	function Paragraph:Set(newTitle, newContent)
		if newTitle then title.Text = newTitle end
		if newContent then content.Text = newContent end
	end
	return Paragraph
end

-- Handy built-in: theme picker dropdown
function Section:CreateThemeSelector(name)
	return self:CreateDropdown({
		Name = name or "Theme",
		Options = Library:GetThemes(),
		Default = Library.CurrentThemeName,
		Callback = function(theme)
			if theme then Library:SetTheme(theme) end
		end,
	})
end

-- "Add" aliases (Section:AddToggle == Section:CreateToggle, etc.)
for name, fn in pairs(table.clone(Section)) do
	if typeof(fn) == "function" and name:sub(1, 6) == "Create" then
		Section["Add" .. name:sub(7)] = fn
	end
end

--==============================================================--
-- Tabs
--==============================================================--
local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(name)
	if typeof(name) == "table" then name = name.Name end
	self._count += 1

	-- Each section is its own outlined box: header on top, rows underneath
	local frame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._count,
		Parent = self.Page,
	})
	Bind(frame, { BackgroundColor3 = "Section" })
	Corner(frame, 6)
	Stroke(frame, "Stroke", 1)
	Padding(frame, 7, 8, 8, 8)
	Create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame })

	if name and name ~= "" then
		Bind(Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			Text = name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			LayoutOrder = 0,
			Parent = frame,
		}, {
			Create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }),
		}), { TextColor3 = "Text" })
	end

	return setmetatable({ Container = frame, _count = 0 }, Section)
end
Tab.AddSection = Tab.CreateSection

--==============================================================--
-- Window
--==============================================================--
local Window = {}
Window.__index = Window

local TOPBAR_HEIGHT = 58

function Library:CreateWindow(opts)
	opts = opts or {}
	if opts.Theme then self:SetTheme(opts.Theme) end

	-- Default size scales with the screen (about a third of its width) so it is never tiny
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local size = opts.Size or Vector2.new(
		math.max(600, math.floor(viewport.X * 0.32)),
		math.max(380, math.floor(viewport.Y * 0.38))
	)
	local minSize = opts.MinSize or Vector2.new(460, 300)
	local sidebarWidth = opts.SidebarWidth or 150
	local gui = GetGui()

	local self_ = setmetatable({
		Tabs = {},
		ToggleKey = opts.ToggleKey or Enum.KeyCode.RightControl,
		MinSize = minSize,
		Minimized = false,
	}, Window)

	-- Main frame -------------------------------------------------
	local main = Create("Frame", {
		Name = "Main",
		Position = UDim2.new(0.5, -size.X / 2, 0.5, -size.Y / 2),
		Size = UDim2.fromOffset(size.X, size.Y),
		ClipsDescendants = true,
		Active = true, -- touches on the window don't fall through and turn the camera
		Parent = gui,
	})
	Bind(main, { BackgroundColor3 = "Background" })
	Corner(main, 6)
	Stroke(main)
	self_.Main = main

	-- Title bar --------------------------------------------------
	local topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
		Active = true,
		Parent = main,
	})
	Bind(topbar, { BackgroundColor3 = "Topbar" })
	Corner(topbar, 6)
	-- square off the bottom corners of the title bar
	Bind(Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 6),
		BorderSizePixel = 0,
		Parent = topbar,
	}), { BackgroundColor3 = "Topbar" })

	-- Centered title + subtitle (no window buttons)
	Bind(Create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 9),
		Size = UDim2.new(1, -24, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 21,
		Text = opts.Title or "Umbra",
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = topbar,
	}), { TextColor3 = "Text" })

	Bind(Create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 34),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		Text = opts.SubTitle or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = topbar,
	}), { TextColor3 = "Text" })

	-- A background frame that only rounds the given bottom corner (the window's corner),
	-- the other corners are squared off with filler strips.
	local function Panel(frameName, key, position, frameSize, roundRight)
		local panel = Create("Frame", {
			Name = frameName,
			Position = position,
			Size = frameSize,
			BorderSizePixel = 0,
			Parent = main,
		})
		Bind(panel, { BackgroundColor3 = key })
		Corner(panel, 6)
		Bind(Create("Frame", { -- top strip
			Size = UDim2.new(1, 0, 0, 6),
			BorderSizePixel = 0,
			Parent = panel,
		}), { BackgroundColor3 = key })
		Bind(Create("Frame", { -- strip on the inner side
			AnchorPoint = Vector2.new(roundRight and 0 or 1, 0),
			Position = UDim2.fromScale(roundRight and 0 or 1, 0),
			Size = UDim2.new(0, 6, 1, 0),
			BorderSizePixel = 0,
			Parent = panel,
		}), { BackgroundColor3 = key })
		return panel
	end

	-- Sidebar: background frame + invisible scrolling frame for the tabs
	local sidebarFrame = Panel("Sidebar", "Sidebar",
		UDim2.new(0, 0, 0, TOPBAR_HEIGHT), UDim2.new(0, sidebarWidth, 1, -TOPBAR_HEIGHT), false)
	local sidebar = Create("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 2,
		Parent = sidebarFrame,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Padding(sidebar, 6, 10, 8, 8)

	-- Section holder: slightly darker background behind the sections
	local content = Panel("Content", "Content",
		UDim2.new(0, sidebarWidth, 0, TOPBAR_HEIGHT), UDim2.new(1, -sidebarWidth, 1, -TOPBAR_HEIGHT), true)

	-- Resize: invisible button in the bottom-right corner
	local grip = Create("TextButton", {
		Name = "ResizeGrip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
		Parent = main,
	})

	-- Fit to screen ----------------------------------------------
	-- On screens smaller than the window (phones) the whole window is scaled
	-- down uniformly with a UIScale, so the layout looks exactly the same, just
	-- smaller. On normal screens the scale stays 1.
	local scaler = Create("UIScale", { Scale = 1, Parent = main })
	local function fitToScreen(recenter)
		local screen = gui.AbsoluteSize
		if screen.X <= 0 or screen.Y <= 0 then return end
		local w, h = main.Size.X.Offset, main.Size.Y.Offset
		local s = math.clamp(math.min((screen.X - 20) / w, (screen.Y - 20) / h), 0.3, 1)
		scaler.Scale = s
		local sw, sh = w * s, h * s
		if recenter then
			main.Position = UDim2.new(0.5, -sw / 2, 0.5, -sh / 2)
		else
			-- keep the window on screen after a rotation / resize
			local p = main.AbsolutePosition
			local x = math.clamp(p.X, 0, math.max(0, screen.X - sw))
			local y = math.clamp(p.Y, 0, math.max(0, screen.Y - sh))
			main.Position = UDim2.fromOffset(x, y)
		end
	end
	fitToScreen(true)
	Connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		fitToScreen(false)
	end)

	-- Dragging (title bar) --------------------------------------
	local dragStart, startPos
	TrackDrag(topbar, function(input)
		dragStart = input.Position
		startPos = main.Position
	end, function(input)
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end)

	-- Resizing (grip) -------------------------------------------
	local resizeStart, startSize
	TrackDrag(grip, function(input)
		if self_.Minimized then return false end
		resizeStart = input.Position
		startSize = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
	end, function(input)
		-- work in unscaled units so the grip follows the finger / cursor
		local s = scaler.Scale
		local delta = (input.Position - resizeStart) / s
		local screen = gui.AbsoluteSize
		local w = math.clamp(startSize.X + delta.X, self_.MinSize.X, math.max(self_.MinSize.X, (screen.X - 20) / s))
		local h = math.clamp(startSize.Y + delta.Y, self_.MinSize.Y, math.max(self_.MinSize.Y, (screen.Y - 20) / s))
		main.Size = UDim2.fromOffset(w, h)
	end)

	-- Toggle key (show / hide) ---------------------------------
	Connect(UserInputService.InputBegan, function(input, processed)
		if not processed and self_.ToggleKey and input.KeyCode == self_.ToggleKey then
			main.Visible = not main.Visible
		end
	end)

	-- Mobile toggle button --------------------------------------
	-- Small image button on the middle-left of the screen that shows / hides the
	-- window (phones have no toggle key). Tap to toggle, drag to move it out of
	-- the way. Shown automatically on touch-only devices; force it with
	-- MobileButton = true, disable with MobileButton = false.
	local showMobile = opts.MobileButton
	if showMobile == nil then
		showMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	end
	if showMobile then
		local image = opts.MobileButtonImage or "rbxassetid://102393034070924"
		if typeof(image) == "number" then image = "rbxassetid://" .. image end

		-- Lives in the library's ScreenGui: hiding the window only hides `main`,
		-- so the button stays visible, and Unload / re-running cleans it up.
		local toggleButton = Create("ImageButton", {
			Name = "MobileToggle",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(55, 55),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Image = image,
			AutoButtonColor = false,
			ZIndex = 100, -- above the window and notifications
			Parent = gui,
		})
		Corner(toggleButton, 8)
		local toggleStroke = Create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = toggleButton,
		})
		pcall(function() -- newer property, skip on clients that don't have it
			toggleStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		end)

		-- Drag; a press that moves less than 8px counts as a tap.
		local pressStart, buttonStart
		local moved = false
		TrackDrag(toggleButton, function(input)
			pressStart = input.Position
			buttonStart = toggleButton.AbsolutePosition
			moved = false
		end, function(input)
			local delta = input.Position - pressStart
			if not moved and Vector2.new(delta.X, delta.Y).Magnitude < 8 then return end
			moved = true
			-- keep it fully on screen
			local screen, sz = gui.AbsoluteSize, toggleButton.AbsoluteSize
			local x = math.clamp(buttonStart.X + delta.X, 0, math.max(0, screen.X - sz.X))
			local y = math.clamp(buttonStart.Y + delta.Y, 0, math.max(0, screen.Y - sz.Y))
			toggleButton.Position = UDim2.fromOffset(x, y + sz.Y / 2) -- AnchorPoint Y is 0.5
		end)

		Connect(toggleButton.Activated, function()
			if moved then moved = false return end
			main.Visible = not main.Visible
		end)

		self_.MobileButton = toggleButton
	end

	self_._sidebar = sidebar
	self_._content = content

	OnTheme(function()
		self_:_updateTabs(0.25)
	end)

	return self_
end

function Window:_updateTabs(time)
	for _, tab in ipairs(self.Tabs) do
		local selected = tab == self.SelectedTab
		Tween(tab.Label, time or 0.2, { TextColor3 = selected and T().Text or T().SubText })
		if tab.Icon then
			Tween(tab.Icon, time or 0.2, { ImageColor3 = selected and T().Text or T().SubText })
		end
	end
end

function Window:SelectTab(tab)
	if typeof(tab) == "string" then
		for _, t in ipairs(self.Tabs) do
			if t.Name == tab then tab = t break end
		end
	end
	if typeof(tab) ~= "table" then return end
	self.SelectedTab = tab
	for _, t in ipairs(self.Tabs) do
		t.Page.Visible = t == tab
	end
	self:_updateTabs()
end

local DEFAULT_TAB_ICON = "rbxassetid://5012544693"

function Window:CreateTab(opts)
	if typeof(opts) == "string" then opts = { Name = opts } end
	opts = opts or {}
	local name = opts.Name or "Tab"
	local icon = opts.Icon
	if icon == nil then icon = DEFAULT_TAB_ICON end -- Icon = false for no icon
	if typeof(icon) == "number" then icon = "rbxassetid://" .. icon end

	local button = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1, -- no highlight behind the selected tab
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = #self.Tabs + 1,
		Parent = self._sidebar,
	})

	local iconImg
	if icon then
		iconImg = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Image = icon,
			ImageColor3 = T().SubText,
			Parent = button,
		})
	end

	local label = Create("TextLabel", {
		Position = UDim2.new(0, icon and 38 or 10, 0, 0),
		Size = UDim2.new(1, icon and -42 or -14, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = TEXT_SIZE,
		Text = name,
		TextColor3 = T().SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	local page = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 2,
		Parent = self._content,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Bind(page, { ScrollBarImageColor3 = "Stroke" })
	Padding(page, 8, 12, 8, 12) -- gap on every side so sections never touch the tab list or title bar

	local tab = setmetatable({
		Name = name,
		Button = button,
		Label = label,
		Icon = iconImg,
		Page = page,
		_count = 0,
	}, Tab)
	table.insert(self.Tabs, tab)

	HoverEvents(button, function()
		if self.SelectedTab ~= tab then Tween(label, 0.15, { TextColor3 = T().Text }) end
	end, function()
		if self.SelectedTab ~= tab then Tween(label, 0.15, { TextColor3 = T().SubText }) end
	end)
	OnClick(button, function()
		self:SelectTab(tab)
	end)

	if not self.SelectedTab then
		self:SelectTab(tab)
	end
	return tab
end
Window.AddTab = Window.CreateTab

function Window:SetTheme(theme)
	Library:SetTheme(theme)
end

function Window:Notify(opts)
	Library:Notify(opts)
end

function Window:SetToggleKey(key)
	self.ToggleKey = key
end

function Window:Destroy()
	Library:Unload()
end

function Library:Unload()
	for _, c in ipairs(self._connections) do
		c:Disconnect()
	end
	table.clear(self._connections)
	table.clear(touchHovered)
	touchHoverConn = nil
	table.clear(self._bindings)
	table.clear(self._themeCallbacks)
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return Library
