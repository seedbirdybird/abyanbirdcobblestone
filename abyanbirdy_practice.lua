--[[
    abyanbirdy - purple tabbed GUI library (Luau / LocalScript)
    Put this in StarterPlayerScripts as a LocalScript.
    Toggle the menu with RightShift. Drag the window by its title bar.
]]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
---------------------------------------------------------------------
-- Theme
---------------------------------------------------------------------
local Theme = {
	Background = Color3.fromRGB(13, 11, 20),
	Panel      = Color3.fromRGB(19, 16, 29),
	Element    = Color3.fromRGB(31, 27, 46),
	Accent     = Color3.fromRGB(150, 90, 255),
	AccentDark = Color3.fromRGB(96, 56, 172),
	Text       = Color3.fromRGB(228, 222, 242),
	SubText    = Color3.fromRGB(150, 142, 176),
	Font       = Enum.Font.Gotham,
	FontBold   = Enum.Font.GothamBold,
}
---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 4) }) end
local function stroke(color, thickness)
	return new("UIStroke", { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function padding(p)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
		PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
	})
end
local function list(pad)
	return new("UIListLayout", { Padding = UDim.new(0, pad or 4), SortOrder = Enum.SortOrder.LayoutOrder })
end
local function tween(inst, props, t)
	TweenService:Create(inst, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad), props):Play()
end
local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end
local function label(text, size, color, font, align)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size or 12,
		TextColor3 = color or Theme.Text,
		Font = font or Theme.Font,
		TextXAlignment = align or Enum.TextXAlignment.Left,
	})
end
---------------------------------------------------------------------
-- Library
---------------------------------------------------------------------
local Library = {}
function Library:CreateWindow(title)
	local Window = { Tabs = {}, ActiveTab = nil, Connections = {} }
	local gui = new("ScreenGui", {
		Name = "abyanbirdy",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	local main = new("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(540, 430),
		Position = UDim2.new(0.5, -270, 0.5, -215),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = gui,
	}, { corner(6), stroke(Theme.Accent, 1.5) })
	-- Title bar
	local titleBar = new("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	}, { corner(6) })
	local dot = new("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 12, 0.5, -4),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = titleBar,
	}, { corner(4) })
	local titleLabel = label(title or "abyanbirdy", 13, Theme.Text, Theme.FontBold)
	titleLabel.Size = UDim2.new(1, -40, 1, 0)
	titleLabel.Position = UDim2.fromOffset(28, 0)
	titleLabel.Parent = titleBar
	-- Dragging
	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(input)
			if isPress(input) then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if dragging and isMove(input) then
				local d = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
		UIS.InputEnded:Connect(function(input)
			if isPress(input) then dragging = false end
		end)
	end
	-- Toggle key
	UIS.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightShift then
			main.Visible = not main.Visible
		end
	end)
	-- Tab bar
	local tabBar = new("Frame", {
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 36),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	}, {
		corner(4),
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- Content area
	local content = new("Frame", {
		Size = UDim2.new(1, -16, 1, -76),
		Position = UDim2.fromOffset(8, 68),
		BackgroundTransparency = 1,
		Parent = main,
	})
	local function resizeTabs()
		local n = #Window.Tabs
		for _, tab in ipairs(Window.Tabs) do
			tab.Button.Size = UDim2.new(1 / n, 0, 1, 0)
		end
	end
	local function selectTab(tab)
		for _, t in ipairs(Window.Tabs) do
			local active = (t == tab)
			t.Page.Visible = active
			t.Underline.Visible = active
			tween(t.Button, { TextColor3 = active and Theme.Accent or Theme.SubText })
		end
		Window.ActiveTab = tab
	end
	function Window:AddTab(name)
		local Tab = {}
		local button = new("TextButton", {
			Text = name,
			TextSize = 12,
			Font = Theme.Font,
			TextColor3 = Theme.SubText,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			LayoutOrder = #Window.Tabs + 1,
			Parent = tabBar,
		})
		local underline = new("Frame", {
			Size = UDim2.new(1, -10, 0, 2),
			Position = UDim2.new(0, 5, 1, -2),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = button,
		})
		local page = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = content,
		})
		local function column(xScale)
			return new("ScrollingFrame", {
				Size = UDim2.new(0.5, -4, 1, 0),
				Position = UDim2.new(xScale, xScale == 0 and 0 or 4, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.Accent,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = page,
			}, { list(8) })
		end
		local left, right = column(0), column(0.5)
		Tab.Button, Tab.Page, Tab.Underline = button, page, underline
		table.insert(Window.Tabs, Tab)
		resizeTabs()
		button.MouseButton1Click:Connect(function() selectTab(Tab) end)
		if #Window.Tabs == 1 then selectTab(Tab) end
		-------------------------------------------------------------
		-- Sections
		-------------------------------------------------------------
		function Tab:AddSection(name, side)
			local Section = {}
			local parent = (side == "Right") and right or left
			local frame = new("Frame", {
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
				Parent = parent,
			}, { corner(4), stroke(Theme.AccentDark, 1) })
			local header = label(name, 12, Theme.Accent, Theme.FontBold)
			header.Size = UDim2.new(1, -16, 0, 24)
			header.Position = UDim2.fromOffset(8, 0)
			header.Parent = frame
			local body = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.fromOffset(0, 26),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = frame,
			}, { list(6), padding(8) })
			-- bottom spacing
			new("Frame", { Size = UDim2.fromOffset(1, 4), BackgroundTransparency = 1, LayoutOrder = 9999, Parent = body })
			-- Toggle -----------------------------------------------
			function Section:AddToggle(text, default, callback)
				local state = default and true or false
				local row = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Parent = body,
				})
				local box = new("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.new(0, 0, 0.5, -7),
					BackgroundColor3 = state and Theme.Accent or Theme.Element,
					BorderSizePixel = 0,
					Parent = row,
				}, { corner(3), stroke(Theme.AccentDark, 1) })
				local txt = label(text, 12, Theme.Text)
				txt.Size = UDim2.new(1, -24, 1, 0)
				txt.Position = UDim2.fromOffset(24, 0)
				txt.Parent = row
				local Toggle = {}
				function Toggle:Set(v)
					state = v and true or false
					tween(box, { BackgroundColor3 = state and Theme.Accent or Theme.Element })
					if callback then task.spawn(callback, state) end
				end
				function Toggle:Get() return state end
				row.MouseButton1Click:Connect(function() Toggle:Set(not state) end)
				return Toggle
			end
			-- Slider -----------------------------------------------
			function Section:AddSlider(text, min, max, default, suffix, callback)
				suffix = suffix or ""
				local value = math.clamp(default or min, min, max)
				local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = body })
				local txt = label(text, 12, Theme.Text)
				txt.Size = UDim2.new(0.6, 0, 0, 16)
				txt.Parent = row
				local valLabel = label("", 12, Theme.SubText, Theme.Font, Enum.TextXAlignment.Right)
				valLabel.Size = UDim2.new(0.4, 0, 0, 16)
				valLabel.Position = UDim2.fromScale(0.6, 0)
				valLabel.Parent = row
				local bar = new("Frame", {
					Size = UDim2.new(1, 0, 0, 10),
					Position = UDim2.fromOffset(0, 20),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					Parent = row,
				}, { corner(3) })
				local fill = new("Frame", {
					Size = UDim2.fromScale(0, 1),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = bar,
				}, { corner(3) })
				local Slider = {}
				local function render()
					local alpha = (max == min) and 0 or ((value - min) / (max - min))
					fill.Size = UDim2.fromScale(alpha, 1)
					valLabel.Text = tostring(value) .. suffix
				end
				function Slider:Set(v)
					value = math.clamp(math.floor(v + 0.5), min, max)
					render()
					if callback then task.spawn(callback, value) end
				end
				function Slider:Get() return value end
				local dragging = false
				local function update(x)
					local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					Slider:Set(min + (max - min) * rel)
				end
				bar.InputBegan:Connect(function(input)
					if isPress(input) then dragging = true; update(input.Position.X) end
				end)
				UIS.InputChanged:Connect(function(input)
					if dragging and isMove(input) then update(input.Position.X) end
				end)
				UIS.InputEnded:Connect(function(input)
					if isPress(input) then dragging = false end
				end)
				render()
				return Slider
			end
			-- Dropdown ---------------------------------------------
			function Section:AddDropdown(text, options, default, callback)
				local current = default or options[1]
				local open = false
				local holder = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = body,
				}, { list(3) })
				local txt = label(text, 12, Theme.Text)
				txt.Size = UDim2.new(1, 0, 0, 16)
				txt.LayoutOrder = 1
				txt.Parent = holder
				local header = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					Text = "  " .. tostring(current),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 12,
					Font = Theme.Font,
					TextColor3 = Theme.Text,
					AutoButtonColor = false,
					LayoutOrder = 2,
					Parent = holder,
				}, { corner(3) })
				local arrow = label("v", 11, Theme.SubText, Theme.FontBold, Enum.TextXAlignment.Right)
				arrow.Size = UDim2.new(1, -8, 1, 0)
				arrow.Parent = header
				local optionList = new("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					Visible = false,
					LayoutOrder = 3,
					Parent = holder,
				}, { corner(3), list(0) })
				local Dropdown = {}
				function Dropdown:Set(v)
					current = v
					header.Text = "  " .. tostring(v)
					if callback then task.spawn(callback, v) end
				end
				function Dropdown:Get() return current end
				for _, opt in ipairs(options) do
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundTransparency = 1,
						Text = "  " .. tostring(opt),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 12,
						Font = Theme.Font,
						TextColor3 = Theme.SubText,
						AutoButtonColor = false,
						Parent = optionList,
					})
					b.MouseEnter:Connect(function() b.TextColor3 = Theme.Accent end)
					b.MouseLeave:Connect(function() b.TextColor3 = Theme.SubText end)
					b.MouseButton1Click:Connect(function()
						Dropdown:Set(opt)
						open = false
						optionList.Visible = false
						arrow.Text = "v"
					end)
				end
				header.MouseButton1Click:Connect(function()
					open = not open
					optionList.Visible = open
					arrow.Text = open and "^" or "v"
				end)
				return Dropdown
			end
			-- Button -----------------------------------------------
			function Section:AddButton(text, callback)
				local b = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					Text = text,
					TextSize = 12,
					Font = Theme.Font,
					TextColor3 = Theme.Text,
					AutoButtonColor = false,
					Parent = body,
				}, { corner(3), stroke(Theme.AccentDark, 1) })
				b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.AccentDark }) end)
				b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Element }) end)
				b.MouseButton1Click:Connect(function()
					if callback then task.spawn(callback) end
				end)
				return b
			end
			-- Label ------------------------------------------------
			function Section:AddLabel(text)
				local l = label(text, 12, Theme.SubText)
				l.Size = UDim2.new(1, 0, 0, 16)
				l.Parent = body
				return l
			end
			return Section
		end
		return Tab
	end
	function Window:SetOpacity(percent)
        local alpha = 1 - math.clamp(percent, 20, 100) / 100
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ScrollingFrame") then
                if obj.BackgroundTransparency < 1 then
                    obj.BackgroundTransparency = alpha
                end
            end
        end
    end
    function Window:SetVisible(visible) main.Visible = visible end
    function Window:Destroy()
        for _, connection in ipairs(self.Connections) do connection:Disconnect() end
        gui:Destroy()
    end
	return Window
end
---------------------------------------------------------------------
-- Functional Roblox Studio practice overlay. Does not modify other players or combat.
local Window = Library:CreateWindow("abyanbirdy | Practice")
local overlay = Instance.new("ScreenGui")
overlay.Name = "abyanbirdy_PracticeOverlay"
overlay.ResetOnSpawn = false
overlay.IgnoreGuiInset = true
overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")

local settings = {
    enabled = true, notifications = true, fps = false,
    crosshair = false, fov = false, fovRadius = 120,
    opacity = 100, mode = "Smooth", speed = 50,
    delay = 250, duration = 100,
}

local function overlayFrame(name, size, color)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Size = size
    f.BackgroundColor3 = color or Theme.Accent
    f.BorderSizePixel = 0
    f.Parent = overlay
    return f
end

local fpsText = Instance.new("TextLabel")
fpsText.Name = "FPS"
fpsText.Size = UDim2.fromOffset(110, 28)
fpsText.Position = UDim2.fromOffset(14, 60)
fpsText.BackgroundColor3 = Theme.Panel
fpsText.TextColor3 = Theme.Accent
fpsText.TextSize = 14
fpsText.Font = Theme.FontBold
fpsText.Visible = false
fpsText.Parent = overlay
corner(5).Parent = fpsText

local crossH = overlayFrame("CrosshairHorizontal", UDim2.fromOffset(18, 2))
local crossV = overlayFrame("CrosshairVertical", UDim2.fromOffset(2, 18))
local crossDot = overlayFrame("CrosshairDot", UDim2.fromOffset(3, 3), Color3.new(1, 1, 1))

local circle = Instance.new("Frame")
circle.Name = "PracticeFOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.BackgroundTransparency = 1
circle.Parent = overlay
local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle
local outline = Instance.new("UIStroke")
outline.Color = Theme.Accent
outline.Thickness = 1.5
outline.Transparency = 0.25
outline.Parent = circle

local function refreshOverlay()
    local visible = settings.enabled
    fpsText.Visible = visible and settings.fps
    crossH.Visible = visible and settings.crosshair
    crossV.Visible = visible and settings.crosshair
    crossDot.Visible = visible and settings.crosshair
    circle.Visible = visible and settings.fov
    local diameter = settings.fovRadius * 2
    circle.Size = UDim2.fromOffset(diameter, diameter)
end

local function notify(message)
    if settings.notifications then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "abyanbirdy", Text = message, Duration = 3,
        })
    end
end

local mainTab = Window:AddTab("Main")
local general = mainTab:AddSection("General", "Left")
local enabledToggle = general:AddToggle("Enabled", true, function(v)
    settings.enabled = v
    refreshOverlay()
end)
local notificationToggle = general:AddToggle("Show notifications", true, function(v)
    settings.notifications = v
end)
local modeDropdown = general:AddDropdown("Animation mode", {"Default", "Smooth", "Fast"}, "Smooth", function(v)
    settings.mode = v
end)
local speedSlider = general:AddSlider("Animation speed", 0, 100, 50, "%", function(v)
    settings.speed = v
end)

local timing = mainTab:AddSection("Timing", "Right")
local delaySlider = timing:AddSlider("Notification delay", 0, 500, 250, " ms", function(v)
    settings.delay = v
end)
local durationSlider = timing:AddSlider("Notification duration", 0, 500, 100, " ms", function(v)
    settings.duration = v
end)
timing:AddButton("Test notification", function()
    if not settings.notifications then return end
    task.delay(settings.delay / 1000, function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "abyanbirdy", Text = "Your practice UI is working!",
                Duration = math.max(1, settings.duration / 100),
            })
        end)
    end)
end)

local visuals = Window:AddTab("Visuals")
local look = visuals:AddSection("Appearance", "Left")
local fpsToggle = look:AddToggle("Show FPS", false, function(v)
    settings.fps = v
    refreshOverlay()
end)
local opacitySlider = look:AddSlider("GUI opacity", 20, 100, 100, "%", function(v)
    settings.opacity = v
    Window:SetOpacity(v)
end)
local practice = visuals:AddSection("Practice guides", "Right")
local crosshairToggle = practice:AddToggle("Custom crosshair", false, function(v)
    settings.crosshair = v
    refreshOverlay()
end)
local fovToggle = practice:AddToggle("Show FOV guide", false, function(v)
    settings.fov = v
    refreshOverlay()
end)
local fovSlider = practice:AddSlider("FOV guide radius", 30, 300, 120, " px", function(v)
    settings.fovRadius = v
    refreshOverlay()
end)
practice:AddLabel("Visual guides only; no aim assistance")

local options = Window:AddTab("Settings")
local ui = options:AddSection("Interface", "Left")
ui:AddLabel("Toggle menu: RightShift")
ui:AddButton("Reset settings", function()
    enabledToggle:Set(true)
    notificationToggle:Set(true)
    modeDropdown:Set("Smooth")
    speedSlider:Set(50)
    delaySlider:Set(250)
    durationSlider:Set(100)
    fpsToggle:Set(false)
    opacitySlider:Set(100)
    crosshairToggle:Set(false)
    fovToggle:Set(false)
    fovSlider:Set(120)
    notify("Settings reset")
end)
ui:AddButton("Hide menu", function() Window:SetVisible(false) end)
ui:AddButton("Unload GUI", function()
    overlay:Destroy()
    Window:Destroy()
end)

local frameCount, elapsed = 0, 0
local connection = RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    elapsed += dt
    if elapsed >= 0.5 then
        fpsText.Text = ("FPS: %d"):format(math.floor(frameCount / elapsed + 0.5))
        frameCount, elapsed = 0, 0
    end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    local position = UDim2.fromOffset(center.X, center.Y)
    crossH.Position = position
    crossV.Position = position
    crossDot.Position = position
    circle.Position = position
end)
table.insert(Window.Connections, connection)
refreshOverlay()
return Library
