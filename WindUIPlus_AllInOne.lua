--[[
    WindUIPlus All-In-One
    Copy this entire file into your Roblox UI script.

    WindUI source: Footagesus/WindUI v1.6.66 (MIT)
    This file loads WindUI, then adds player + settings dropdown menus.
    Intended only for experiences you own or are authorized to test.
]]

-- =========================
-- EDIT YOUR CONFIGURATION
-- =========================
local APP = {
    Title = "My Script Library",
    Author = "Your name",
    Icon = "sparkles",
    Folder = "MyScriptLibrary",
    Size = UDim2.fromOffset(650, 430),

    -- Optional: URL raw JSON from your HTTPS website. Leave "" to disable.
    -- Example response: {"background":"rbxassetid://123", "font":"rbxassetid://12187365364", "scale":1, "theme":"Light"}
    ConfigEndpoint = "",

    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
}

-- Pin the WindUI version so changes upstream do not unexpectedly break this script.
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"
))()

-- Do not edit the extension block below unless you want to customize the library itself.
local WindUIPlus = (function()
	-- WindUIPlus.lua
	-- Extension layer for Footagesus/WindUI (MIT). It adds player/settings topbar menus,
	-- local movement helpers, a monochrome animated background, and safe JSON config loading.
	-- Intended for experiences that you own or have permission to test.

	local WindUIPlus = {}
	WindUIPlus.__index = WindUIPlus

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local HttpService = game:GetService("HttpService")
	local Lighting = game:GetService("Lighting")

	local LOCAL_PLAYER = Players.LocalPlayer
	local BLACK = Color3.fromRGB(12, 12, 12)
	local WHITE = Color3.fromRGB(255, 255, 255)
	local SOFT_GRAY = Color3.fromRGB(235, 235, 235)

	local function new(className, properties)
		local object = Instance.new(className)
		for key, value in pairs(properties or {}) do
			object[key] = value
		end
		return object
	end

	local function corner(parent, radius)
		return new("UICorner", {
			CornerRadius = UDim.new(0, radius or 8),
			Parent = parent,
		})
	end

	local function stroke(parent, color, thickness, transparency)
		return new("UIStroke", {
			Color = color or BLACK,
			Thickness = thickness or 1,
			Transparency = transparency or 0,
			Parent = parent,
		})
	end

	local function isPointInside(guiObject, point)
		local position = guiObject.AbsolutePosition
		local size = guiObject.AbsoluteSize
		return point.X >= position.X
			and point.Y >= position.Y
			and point.X <= position.X + size.X
			and point.Y <= position.Y + size.Y
	end

	local function safeDisconnect(connection)
		if connection then
			connection:Disconnect()
		end
	end

	local function getExtension(url)
		local clean = (url or ""):match("^([^?#]+)") or ""
		local extension = clean:match("%.([%a%d]+)$")
		if extension then
			extension = extension:lower()
			if extension == "png" or extension == "jpg" or extension == "jpeg" or extension == "webp" then
				return "." .. extension
			end
		end
		return ".png"
	end

	local function sanitizeFileName(text)
		return (text:gsub("[^%w_%-]", "_")):sub(1, 100)
	end

	local function clampNumber(value, minimum, maximum, fallback)
		value = tonumber(value)
		if not value then
			return fallback
		end
		return math.clamp(value, minimum, maximum)
	end

	function WindUIPlus.Attach(WindUI, window, options)
		assert(WindUI and window, "WindUIPlus.Attach requires WindUI and a valid WindUI window")

		options = options or {}
		local self = setmetatable({
			WindUI = WindUI,
			Window = window,
			Options = options,
			Menus = {},
			Connections = {},
			Destroyed = false,
			CurrentFont = options.DefaultFont or "rbxassetid://12187365364",
			State = {
				WalkSpeed = clampNumber(options.DefaultWalkSpeed, 8, 120, 16),
				JumpPower = clampNumber(options.DefaultJumpPower, 25, 150, 50),
				NoClip = false,
				FullBright = false,
			},
			NoClipOriginal = {},
			LightingOriginal = nil,
		}, WindUIPlus)

		self:_createBackgroundLayer()
		self:_createPlayerMenu()
		self:_createSettingsMenu()
		self:_createTopbarButtons()
		self:_connectGlobalInput()
		self:_connectCharacterLifecycle()
		self:_connectWindowLifecycle()

		if options.ConfigEndpoint and options.ConfigEndpoint ~= "" then
			task.spawn(function()
				self:RefreshWebsiteConfig()
			end)
		end

		return self
	end

	function WindUIPlus:_fontFace()
		local ok, font = pcall(function()
			return Font.new(self.CurrentFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		end)
		if ok then
			return font
		end
		return Font.fromEnum(Enum.Font.Gotham)
	end

	function WindUIPlus:_applyFontTo(object)
		local font = self:_fontFace()
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			object.FontFace = font
		end
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				descendant.FontFace = font
			end
		end
	end

	function WindUIPlus:_notify(title, content)
		if self.WindUI and self.WindUI.Notify then
			self.WindUI:Notify({
				Title = title,
				Content = content,
				Icon = "info",
				Duration = 3,
			})
		else
			warn(("[WindUIPlus] %s: %s"):format(title, content))
		end
	end

	-- A black diagonal line moves from the upper-left to lower-right on a white base.
	function WindUIPlus:_createBackgroundLayer()
		local main = self.Window.UIElements and self.Window.UIElements.Main
		local host = main and main:FindFirstChild("Background")
		if not host then
			warn("[WindUIPlus] Window background was not found; animated background is skipped.")
			return
		end

		local backgroundImage = new("ImageLabel", {
			Name = "WindUIPlusBackgroundImage",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = "",
			ImageTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 1,
			Parent = host,
		})
		corner(backgroundImage, self.Window.UICorner or 16)
		self.BackgroundImage = backgroundImage

		local overlay = new("Frame", {
			Name = "WindUIPlusDiagonalOverlay",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
			Parent = host,
		})
		corner(overlay, self.Window.UICorner or 16)

		local line = new("Frame", {
			Name = "MovingBlackLine",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = BLACK,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(-0.30, -0.25),
			Rotation = 45,
			Size = UDim2.new(2.0, 0, 0, 5),
			ZIndex = 3,
			Parent = overlay,
		})
		corner(line, 5)

		TweenService:Create(
			line,
			TweenInfo.new(3.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
			{ Position = UDim2.fromScale(1.30, 1.25) }
		):Play()

		self.DiagonalOverlay = overlay
	end

	function WindUIPlus:_newMenu(name, title, width, height)
		local parent = self.WindUI.DropdownGui or self.WindUI.ScreenGui
		assert(parent, "WindUI dropdown ScreenGui is unavailable")

		local panel = new("Frame", {
			Name = name,
			Active = true,
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.fromOffset(width, height),
			Visible = false,
			ZIndex = 50,
			Parent = parent,
		})
		corner(panel, 12)
		stroke(panel, BLACK, 1, 0.76)

		local header = new("Frame", {
			BackgroundColor3 = BLACK,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 36),
			ZIndex = 51,
			Parent = panel,
		})
		corner(header, 12)

		-- This fills the lower curved part of the header so it has a flat bottom edge.
		new("Frame", {
			BackgroundColor3 = BLACK,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -12),
			Size = UDim2.new(1, 0, 0, 12),
			ZIndex = 51,
			Parent = header,
		})

		local titleLabel = new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Text = title,
			TextColor3 = WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
			Parent = header,
		})
		titleLabel.FontFace = self:_fontFace()

		local content = new("ScrollingFrame", {
			Name = "Content",
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromOffset(0, 0),
			Position = UDim2.fromOffset(0, 38),
			ScrollBarImageColor3 = BLACK,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, -38),
			ZIndex = 51,
			Parent = panel,
		})
		new("UIPadding", {
			PaddingBottom = UDim.new(0, 9),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 9),
			Parent = content,
		})
		new("UIListLayout", {
			Padding = UDim.new(0, 7),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content,
		})

		local menu = {
			Panel = panel,
			Content = content,
			Button = nil,
			Width = width,
			Height = height,
		}
		table.insert(self.Menus, menu)
		return menu
	end

	function WindUIPlus:_addSectionLabel(parent, text, order)
		local label = new("TextLabel", {
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 18),
			Text = string.upper(text),
			TextColor3 = Color3.fromRGB(85, 85, 85),
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 53,
			Parent = parent,
		})
		label.FontFace = self:_fontFace()
		return label
	end

	function WindUIPlus:_addSlider(parent, config)
		local row = new("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = config.Order or 0,
			Size = UDim2.new(1, 0, 0, 55),
			ZIndex = 53,
			Parent = parent,
		})

		local title = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.7, 0, 0, 20),
			Text = config.Title,
			TextColor3 = BLACK,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 54,
			Parent = row,
		})
		title.FontFace = self:_fontFace()

		local valueLabel = new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.7, 0, 0, 0),
			Size = UDim2.new(0.3, 0, 0, 20),
			Text = tostring(config.Default),
			TextColor3 = BLACK,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 54,
			Parent = row,
		})
		valueLabel.FontFace = self:_fontFace()

		local track = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = SOFT_GRAY,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 29),
			Size = UDim2.new(1, 0, 0, 8),
			Text = "",
			ZIndex = 54,
			Parent = row,
		})
		corner(track, 8)

		local fill = new("Frame", {
			BackgroundColor3 = BLACK,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(0, 1),
			ZIndex = 55,
			Parent = track,
		})
		corner(fill, 8)

		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(15, 15),
			ZIndex = 56,
			Parent = track,
		})
		corner(knob, 99)
		stroke(knob, BLACK, 1, 0.15)

		local dragging = false
		local current = config.Default
		local minimum = config.Min
		local maximum = config.Max
		local step = config.Step or 1

		local function setValue(value, fireCallback)
			value = math.clamp(value, minimum, maximum)
			value = math.floor((value - minimum) / step + 0.5) * step + minimum
			value = math.clamp(value, minimum, maximum)
			current = value

			local alpha = (value - minimum) / (maximum - minimum)
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
			valueLabel.Text = config.Format and config.Format(value) or tostring(value)

			if fireCallback ~= false and config.Callback then
				config.Callback(value)
			end
		end

		local function setFromPosition(position)
			if track.AbsoluteSize.X <= 0 then
				return
			end
			local alpha = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			setValue(minimum + (maximum - minimum) * alpha, true)
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFromPosition(input.Position)
			end
		end)

		table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setFromPosition(input.Position)
			end
		end))
		table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		setValue(config.Default, false)
		return {
			Set = setValue,
			Get = function()
				return current
			end,
		}
	end

	function WindUIPlus:_addToggle(parent, config)
		local row = new("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = config.Order or 0,
			Size = UDim2.new(1, 0, 0, 35),
			ZIndex = 53,
			Parent = parent,
		})

		local title = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -58, 1, 0),
			Text = config.Title,
			TextColor3 = BLACK,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 54,
			Parent = row,
		})
		title.FontFace = self:_fontFace()

		local button = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = SOFT_GRAY,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -46, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(40, 21),
			Text = "",
			ZIndex = 54,
			Parent = row,
		})
		corner(button, 99)

		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(15, 15),
			ZIndex = 55,
			Parent = button,
		})
		corner(dot, 99)

		local value = config.Default == true
		local function setValue(nextValue, fireCallback)
			value = nextValue == true
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = value and BLACK or SOFT_GRAY,
			}):Play()
			TweenService:Create(dot, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			}):Play()
			if fireCallback ~= false and config.Callback then
				config.Callback(value)
			end
		end

		button.MouseButton1Click:Connect(function()
			setValue(not value, true)
		end)
		setValue(value, false)

		return {
			Set = setValue,
			Get = function()
				return value
			end,
		}
	end

	function WindUIPlus:_addTextBox(parent, config)
		local row = new("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = config.Order or 0,
			Size = UDim2.new(1, 0, 0, 57),
			ZIndex = 53,
			Parent = parent,
		})

		local label = new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Text = config.Title,
			TextColor3 = BLACK,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 54,
			Parent = row,
		})
		label.FontFace = self:_fontFace()

		local box = new("TextBox", {
			BackgroundColor3 = SOFT_GRAY,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			PlaceholderText = config.Placeholder or "",
			PlaceholderColor3 = Color3.fromRGB(110, 110, 110),
			Position = UDim2.fromOffset(0, 23),
			Size = UDim2.new(1, 0, 0, 26),
			Text = config.Default or "",
			TextColor3 = BLACK,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 54,
			Parent = row,
		})
		box.FontFace = self:_fontFace()
		corner(box, 6)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = box,
		})

		box.FocusLost:Connect(function(enterPressed)
			if config.Callback then
				config.Callback(box.Text, enterPressed)
			end
		end)
		return box
	end

	function WindUIPlus:_addButton(parent, config)
		local button = new("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = config.BackgroundColor3 or BLACK,
			BorderSizePixel = 0,
			LayoutOrder = config.Order or 0,
			Size = UDim2.new(1, 0, 0, 29),
			Text = config.Title,
			TextColor3 = config.TextColor3 or WHITE,
			TextSize = 12,
			ZIndex = 54,
			Parent = parent,
		})
		button.FontFace = self:_fontFace()
		corner(button, 7)

		button.MouseButton1Click:Connect(function()
			if config.Callback then
				config.Callback()
			end
		end)
		return button
	end

	function WindUIPlus:_createPlayerMenu()
		local menu = self:_newMenu("WindUIPlusPlayerMenu", "PLAYER", 286, 350)
		self.PlayerMenu = menu
		local content = menu.Content

		self:_addSectionLabel(content, "Local character", 1)
		self.WalkSpeedControl = self:_addSlider(content, {
			Title = "WalkSpeed",
			Min = 8,
			Max = 120,
			Step = 1,
			Default = self.State.WalkSpeed,
			Order = 2,
			Callback = function(value)
				self.State.WalkSpeed = value
				self:_applyMovement("WalkSpeed", value)
			end,
		})
		self.JumpPowerControl = self:_addSlider(content, {
			Title = "Jump Power",
			Min = 25,
			Max = 150,
			Step = 1,
			Default = self.State.JumpPower,
			Order = 3,
			Callback = function(value)
				self.State.JumpPower = value
				self:_applyMovement("JumpPower", value)
			end,
		})
		self.NoClipControl = self:_addToggle(content, {
			Title = "No Clip",
			Default = false,
			Order = 4,
			Callback = function(value)
				self.State.NoClip = value
				self:_setNoClip(value)
				self:_applyMovement("NoClip", value)
			end,
		})
		self.FullBrightControl = self:_addToggle(content, {
			Title = "Full Bright",
			Default = false,
			Order = 5,
			Callback = function(value)
				self.State.FullBright = value
				self:_setFullBright(value)
				self:_applyMovement("FullBright", value)
			end,
		})
		self:_addButton(content, {
			Title = "Reset character",
			Order = 6,
			BackgroundColor3 = SOFT_GRAY,
			TextColor3 = BLACK,
			Callback = function()
				local humanoid = self:_getHumanoid()
				if humanoid then
					humanoid.Health = 0
				end
			end,
		})
	end

	function WindUIPlus:_createSettingsMenu()
		local menu = self:_newMenu("WindUIPlusSettingsMenu", "SETTINGS", 306, 386)
		self.SettingsMenu = menu
		local content = menu.Content

		self:_addSectionLabel(content, "Appearance", 1)
		self:_addTextBox(content, {
			Title = "Background URL / rbxassetid",
			Placeholder = "https://site.com/background.png",
			Order = 2,
			Callback = function(value)
				if value ~= "" then
					self:SetBackground(value)
				end
			end,
		})
		self:_addTextBox(content, {
			Title = "Font asset ID",
			Placeholder = "rbxassetid://font-id",
			Default = self.CurrentFont,
			Order = 3,
			Callback = function(value)
				if value ~= "" then
					self:SetFont(value)
				end
			end,
		})
		self.UIScaleControl = self:_addSlider(content, {
			Title = "UI Size",
			Min = 0.70,
			Max = 1.30,
			Step = 0.05,
			Default = clampNumber(self.Window:GetUIScale(), 0.70, 1.30, 1),
			Format = function(value)
				return string.format("%.2fx", value)
			end,
			Order = 4,
			Callback = function(value)
				self.Window:SetUIScale(value)
			end,
		})
		self:_addSectionLabel(content, "Text colour", 5)
		self:_addButton(content, {
			Title = "Black text — Light mode",
			Order = 6,
			BackgroundColor3 = SOFT_GRAY,
			TextColor3 = BLACK,
			Callback = function()
				self.WindUI:SetTheme("Light")
			end,
		})
		self:_addButton(content, {
			Title = "White text — Dark mode",
			Order = 7,
			Callback = function()
				self.WindUI:SetTheme("Dark")
			end,
		})
		if self.Options.ConfigEndpoint and self.Options.ConfigEndpoint ~= "" then
			self:_addButton(content, {
				Title = "Refresh website config",
				Order = 8,
				BackgroundColor3 = SOFT_GRAY,
				TextColor3 = BLACK,
				Callback = function()
					task.spawn(function()
						self:RefreshWebsiteConfig()
					end)
				end,
			})
		end
	end

	function WindUIPlus:_createTopbarButtons()
		-- WindUI uses 997 for Minimize. 996 and 995 keep these two icons directly beside it.
		local playerButton = self.Window:CreateTopbarButton("Player utilities", "user-round", function()
			self:_toggleMenu(self.PlayerMenu, self.PlayerMenu.Button)
		end, 996, true)
		self.PlayerMenu.Button = playerButton

		local settingsButton = self.Window:CreateTopbarButton("Appearance settings", "settings", function()
			self:_toggleMenu(self.SettingsMenu, self.SettingsMenu.Button)
		end, 995, true)
		self.SettingsMenu.Button = settingsButton
	end

	function WindUIPlus:_placeMenu(menu)
		if not menu.Button or not menu.Panel.Visible then
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local buttonPosition = menu.Button.AbsolutePosition
		local buttonSize = menu.Button.AbsoluteSize
		local viewport = camera.ViewportSize
		local x = buttonPosition.X + buttonSize.X - menu.Width
		local y = buttonPosition.Y + buttonSize.Y + 7

		x = math.clamp(x, 8, math.max(8, viewport.X - menu.Width - 8))
		if y + menu.Height > viewport.Y - 8 then
			y = math.max(8, buttonPosition.Y - menu.Height - 7)
		end

		menu.Panel.Position = UDim2.fromOffset(x, y)
	end

	function WindUIPlus:_hideAllMenus(except)
		for _, menu in ipairs(self.Menus) do
			if menu ~= except then
				menu.Panel.Visible = false
			end
		end
	end

	function WindUIPlus:_toggleMenu(menu, button)
		if self.Destroyed then
			return
		end
		menu.Button = button or menu.Button
		local shouldOpen = not menu.Panel.Visible
		self:_hideAllMenus(menu)
		menu.Panel.Visible = shouldOpen
		if shouldOpen then
			task.defer(function()
				self:_placeMenu(menu)
			end)
		end
	end

	function WindUIPlus:_connectGlobalInput()
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input)
			if self.Destroyed then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			task.defer(function()
				local point = input.Position
				for _, menu in ipairs(self.Menus) do
					if menu.Panel.Visible and not isPointInside(menu.Panel, point) and not isPointInside(menu.Button, point) then
						menu.Panel.Visible = false
					end
				end
			end)
		end))

		table.insert(self.Connections, RunService.RenderStepped:Connect(function()
			for _, menu in ipairs(self.Menus) do
				if menu.Panel.Visible then
					self:_placeMenu(menu)
				end
			end
		end))
	end

	function WindUIPlus:_connectWindowLifecycle()
		local main = self.Window.UIElements and self.Window.UIElements.Main
		local visibleRoot = main and main:FindFirstChild("Main")
		if visibleRoot then
			table.insert(self.Connections, visibleRoot:GetPropertyChangedSignal("Visible"):Connect(function()
				if not visibleRoot.Visible then
					self:_hideAllMenus()
				end
			end))
		end
	end

	function WindUIPlus:_getHumanoid()
		local character = LOCAL_PLAYER and LOCAL_PLAYER.Character
		if not character then
			return nil
		end
		return character:FindFirstChildOfClass("Humanoid")
	end

	function WindUIPlus:_applyMovement(name, value)
		local humanoid = self:_getHumanoid()
		if humanoid then
			if name == "WalkSpeed" then
				humanoid.WalkSpeed = value
			elseif name == "JumpPower" then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = value
			end
		end

		-- For your published experience, also validate the request on the server.
		if typeof(self.Options.OnMovementChanged) == "function" then
			local ok, errorMessage = pcall(self.Options.OnMovementChanged, name, value)
			if not ok then
				warn("[WindUIPlus] OnMovementChanged failed: " .. tostring(errorMessage))
			end
		end
	end

	function WindUIPlus:_connectCharacterLifecycle()
		if not LOCAL_PLAYER then
			return
		end
		table.insert(self.Connections, LOCAL_PLAYER.CharacterAdded:Connect(function()
			task.wait(0.25)
			if self.Destroyed then
				return
			end
			self:_applyMovement("WalkSpeed", self.State.WalkSpeed)
			self:_applyMovement("JumpPower", self.State.JumpPower)
			if self.State.NoClip then
				self:_setNoClip(true)
			end
		end))
	end

	function WindUIPlus:_setNoClip(enabled)
		if self.NoClipConnection then
			safeDisconnect(self.NoClipConnection)
			self.NoClipConnection = nil
		end

		if not enabled then
			for part, wasCollidable in pairs(self.NoClipOriginal) do
				if part and part.Parent then
					part.CanCollide = wasCollidable
				end
			end
			table.clear(self.NoClipOriginal)
			return
		end

		self.NoClipConnection = RunService.Stepped:Connect(function()
			local character = LOCAL_PLAYER and LOCAL_PLAYER.Character
			if not character then
				return
			end
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("BasePart") then
					if self.NoClipOriginal[descendant] == nil then
						self.NoClipOriginal[descendant] = descendant.CanCollide
					end
					descendant.CanCollide = false
				end
			end
		end)
	end

	function WindUIPlus:_setFullBright(enabled)
		if enabled then
			if not self.LightingOriginal then
				self.LightingOriginal = {
					Ambient = Lighting.Ambient,
					Brightness = Lighting.Brightness,
					ClockTime = Lighting.ClockTime,
					FogEnd = Lighting.FogEnd,
					GlobalShadows = Lighting.GlobalShadows,
					OutdoorAmbient = Lighting.OutdoorAmbient,
				}
			end
			Lighting.Ambient = WHITE
			Lighting.OutdoorAmbient = WHITE
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 100000
			Lighting.GlobalShadows = false
		elseif self.LightingOriginal then
			for property, value in pairs(self.LightingOriginal) do
				Lighting[property] = value
			end
			self.LightingOriginal = nil
		end
	end

	function WindUIPlus:SetFont(fontId)
		if typeof(fontId) ~= "string" or fontId == "" then
			return false, "Font ID is empty."
		end

		local ok, errorMessage = pcall(function()
			Font.new(fontId)
			self.WindUI:SetFont(fontId)
			self.CurrentFont = fontId
			for _, menu in ipairs(self.Menus) do
				self:_applyFontTo(menu.Panel)
			end
		end)
		if not ok then
			self:_notify("Font gagal", "Gunakan asset font Roblox yang valid.")
			return false, tostring(errorMessage)
		end
		self:_notify("Font diterapkan", "Font WindUI telah diperbarui.")
		return true
	end

	function WindUIPlus:_downloadRawImage(url)
		if not (type(writefile) == "function" and (type(getcustomasset) == "function" or type(getsynasset) == "function")) then
			return nil, "Raw URL membutuhkan getcustomasset/getsynasset dan writefile. Di Roblox Studio gunakan rbxassetid://..."
		end
		if not url:match("^https://") then
			return nil, "Hanya URL https yang diizinkan untuk background."
		end

		local folder = "WindUIPlus/assets"
		if type(isfolder) == "function" and type(makefolder) == "function" then
			if not isfolder("WindUIPlus") then
				makefolder("WindUIPlus")
			end
			if not isfolder(folder) then
				makefolder(folder)
			end
		end

		local path = folder .. "/" .. sanitizeFileName(url) .. getExtension(url)
		if type(isfile) ~= "function" or not isfile(path) then
			local success, body = pcall(function()
				if type(game.HttpGet) == "function" then
					return game:HttpGet(url)
				end
				local request = http_request or (syn and syn.request) or request
				assert(type(request) == "function", "Tidak ada HTTP request API pada environment ini.")
				local response = request({ Url = url, Method = "GET" })
				return response.Body
			end)
			if not success or type(body) ~= "string" then
				return nil, "Download image gagal: " .. tostring(body)
			end
			writefile(path, body)
		end

		local assetLoader = getcustomasset or getsynasset
		local success, asset = pcall(assetLoader, path)
		if not success then
			return nil, "Gagal memuat custom asset: " .. tostring(asset)
		end
		return asset
	end

	function WindUIPlus:SetBackground(source)
		if typeof(source) ~= "string" or source == "" then
			return false, "Background source is empty."
		end
		if not self.BackgroundImage then
			return false, "Window background layer is unavailable."
		end

		local asset = source
		if source:match("^https?://") then
			local errorMessage
			asset, errorMessage = self:_downloadRawImage(source)
			if not asset then
				self:_notify("Background gagal", errorMessage)
				return false, errorMessage
			end
		elseif not source:match("^rbxassetid://%d+$") then
			local message = "Gunakan https://... atau rbxassetid://..."
			self:_notify("Background gagal", message)
			return false, message
		end

		self.BackgroundImage.Image = asset
		self.BackgroundImage.ImageTransparency = 0.12
		self:_notify("Background diterapkan", "Tampilan background telah diperbarui.")
		return true
	end

	function WindUIPlus:_httpGet(url)
		if not url:match("^https://") then
			return nil, "Endpoint harus menggunakan https://"
		end
		local success, result = pcall(function()
			if type(game.HttpGet) == "function" then
				return game:HttpGet(url)
			end
			local request = http_request or (syn and syn.request) or request
			assert(type(request) == "function", "HTTP request API tidak tersedia pada client ini.")
			local response = request({
				Url = url,
				Method = "GET",
				Headers = { ["Accept"] = "application/json" },
			})
			assert(response.StatusCode >= 200 and response.StatusCode < 300, "HTTP " .. tostring(response.StatusCode))
			return response.Body
		end)
		if not success then
			return nil, tostring(result)
		end
		return result
	end

	-- Only presentation values are accepted from the website. This deliberately never runs
	-- remote Lua/source code from a web endpoint.
	function WindUIPlus:RefreshWebsiteConfig()
		local endpoint = self.Options.ConfigEndpoint
		if typeof(endpoint) ~= "string" or endpoint == "" then
			return false, "ConfigEndpoint belum diisi."
		end

		local body, fetchError = self:_httpGet(endpoint)
		if not body then
			self:_notify("Website tidak tersambung", fetchError)
			return false, fetchError
		end

		local success, data = pcall(function()
			return HttpService:JSONDecode(body)
		end)
		if not success or typeof(data) ~= "table" then
			self:_notify("Config tidak valid", "Website harus mengembalikan JSON object.")
			return false, "Invalid JSON"
		end

		if typeof(data.background) == "string" then
			self:SetBackground(data.background)
		end
		if typeof(data.font) == "string" and (data.font:match("^rbxassetid://%d+$") or data.font:match("^rbxasset://fonts/")) then
			self:SetFont(data.font)
		end
		if typeof(data.scale) == "number" then
			local scale = clampNumber(data.scale, 0.70, 1.30, 1)
			self.Window:SetUIScale(scale)
			if self.UIScaleControl then
				self.UIScaleControl.Set(scale, false)
			end
		end
		if typeof(data.theme) == "string" and (data.theme == "Light" or data.theme == "Dark") then
			self.WindUI:SetTheme(data.theme)
		end

		self:_notify("Website tersambung", "Konfigurasi tampilan diperbarui.")
		return true, data
	end

	function WindUIPlus:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		self:_setNoClip(false)
		self:_setFullBright(false)

		for _, connection in ipairs(self.Connections) do
			safeDisconnect(connection)
		end
		table.clear(self.Connections)

		for _, menu in ipairs(self.Menus) do
			if menu.Panel then
				menu.Panel:Destroy()
			end
		end
		table.clear(self.Menus)

		if self.BackgroundImage then
			self.BackgroundImage:Destroy()
		end
		if self.DiagonalOverlay then
			self.DiagonalOverlay:Destroy()
		end
	end

	return WindUIPlus

end)()

-- =========================
-- CREATE YOUR WINDOW
-- =========================
local Window = WindUI:CreateWindow({
    Title = APP.Title,
    Author = APP.Author,
    Icon = APP.Icon,
    Folder = APP.Folder,
    Size = APP.Size,
    Theme = "Light", -- white UI + black text by default
    OpenButton = true,
})

local Library = WindUIPlus.Attach(WindUI, Window, {
    DefaultWalkSpeed = APP.DefaultWalkSpeed,
    DefaultJumpPower = APP.DefaultJumpPower,
    ConfigEndpoint = APP.ConfigEndpoint,
})

-- =========================
-- ADD YOUR NORMAL WINDUI TABS BELOW
-- =========================
local MainTab = Window:Tab({
    Title = "Home",
    Icon = "house",
})

MainTab:Paragraph({
    Title = "WindUIPlus aktif",
    Desc = "Klik ikon player atau gear di samping tombol minimize.",
})

MainTab:Button({
    Title = "Test notification",
    Callback = function()
        WindUI:Notify({
            Title = "Berhasil",
            Content = "UI Library siap digunakan.",
            Icon = "check",
            Duration = 3,
        })
    end,
})

-- Add your own tabs, buttons, toggles, and callbacks under this line.
-- Example: local FarmTab = Window:Tab({ Title = "Farm", Icon = "wheat" })

-- Optional cleanup if you ever destroy the UI yourself:
-- Library:Destroy()
