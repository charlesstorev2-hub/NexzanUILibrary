-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════
-- LIBRARY MODULE
-- ═══════════════════════════════════════════════════════════
local NexzanLib = {}
NexzanLib.__index = NexzanLib

-- ═══════════════════════════════════════════════════════════
-- HELPER: Create Dropdown Panel
-- ═══════════════════════════════════════════════════════════
local function CreateDropdownPanel(title, position, parent)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = title .. "_Dropdown"
    mainFrame.Size = UDim2.new(0, 260, 0, 0)
    mainFrame.Position = position
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Visible = false
    mainFrame.ZIndex = 1000
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = parent

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = mainFrame

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.ZIndex = 999
    shadow.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 1001
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    titleFix.BackgroundTransparency = 0.1
    titleFix.BorderSizePixel = 0
    titleFix.ZIndex = 1001
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 1002
    titleLabel.Parent = titleBar

    -- Scrollable content
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -10, 1, -40)
    contentFrame.Position = UDim2.new(0, 5, 0, 37)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 3
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.ZIndex = 1001
    contentFrame.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 2)
    padding.Parent = contentFrame

    return mainFrame, contentFrame
end

-- ═══════════════════════════════════════════════════════════
-- HELPER: Dropdown Elements
-- ═══════════════════════════════════════════════════════════
local DropdownElements = {}

function DropdownElements:CreateLabel(text, parent, order)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = "  " .. text
    label.TextColor3 = Color3.fromRGB(160, 160, 190)
    label.TextSize = 11
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order or 0
    label.ZIndex = 1001
    label.Parent = parent
    return label
end

function DropdownElements:CreateSlider(title, min, max, default, callback, parent, order)
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. title
    container.Size = UDim2.new(1, -4, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order or 0
    container.ZIndex = 1001
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0.6, 0, 0, 18)
    titleLbl.Position = UDim2.new(0, 8, 0, 3)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamSemibold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1002
    titleLbl.Parent = container

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0.35, 0, 0, 18)
    valueLbl.Position = UDim2.new(0.65, -8, 0, 3)
    valueLbl.AnchorPoint = Vector2.new(1, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(default)
    valueLbl.TextColor3 = Color3.fromRGB(130, 130, 220)
    valueLbl.TextSize = 12
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.ZIndex = 1002
    valueLbl.Parent = container

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    track.BorderSizePixel = 0
    track.ZIndex = 1002
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 1003
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Name = "SliderButton"
    sliderBtn.Size = UDim2.new(1, 0, 1, 6)
    sliderBtn.Position = UDim2.new(0, 0, 0, -3)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 1004
    sliderBtn.Parent = track

    local dragging = false

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackAbsPos = track.AbsolutePosition.X
            local trackAbsSize = track.AbsoluteSize.X
            local mouseX = input.Position.X
            
            local relative = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
            local value = math.floor(min + (max - min) * relative)
            
            fill.Size = UDim2.new(relative, 0, 1, 0)
            valueLbl.Text = tostring(value)
            
            if callback then
                callback(value)
            end
        end
    end)

    return container, valueLbl
end

function DropdownElements:CreateToggle(title, default, callback, parent, order)
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. title
    container.Size = UDim2.new(1, -4, 0, 36)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order or 0
    container.ZIndex = 1001
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamSemibold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1002
    titleLbl.Parent = container

    local toggleBg = Instance.new("Frame")
    toggleBg.Name = "ToggleBg"
    toggleBg.Size = UDim2.new(0, 38, 0, 20)
    toggleBg.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBg.BorderSizePixel = 0
    toggleBg.ZIndex = 1002
    toggleBg.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBg

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Name = "ToggleCircle"
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.ZIndex = 1003
    toggleCircle.Parent = toggleBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 1004
    toggleBtn.Parent = container

    local isOn = default
    local function updateVisual()
        if isOn then
            toggleBg.BackgroundColor3 = Color3.fromRGB(80, 80, 220)
            toggleCircle.Position = UDim2.new(1, -18, 0.5, -8)
        else
            toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
        end
    end

    updateVisual()

    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateVisual()
        if callback then
            callback(isOn)
        end
    end)

    return container
end

function DropdownElements:CreateButton(title, color, callback, parent, order)
    local container = Instance.new("Frame")
    container.Name = "Btn_" .. title
    container.Size = UDim2.new(1, -4, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order or 0
    container.ZIndex = 1001
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Size = UDim2.new(1, -12, 1, -6)
    btn.Position = UDim2.new(0, 6, 0, 3)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 100)
    btn.BackgroundTransparency = 0.2
    btn.Text = title
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.ZIndex = 1002
    btn.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
    end)

    return container
end

function DropdownElements:CreateInput(title, placeholder, callback, parent, order)
    local container = Instance.new("Frame")
    container.Name = "Input_" .. title
    container.Size = UDim2.new(1, -4, 0, 55)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order or 0
    container.ZIndex = 1001
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 18)
    titleLbl.Position = UDim2.new(0, 8, 0, 3)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamSemibold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1002
    titleLbl.Parent = container

    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -16, 0, 26)
    inputBg.Position = UDim2.new(0, 8, 0, 23)
    inputBg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    inputBg.BorderSizePixel = 0
    inputBg.ZIndex = 1002
    inputBg.Parent = container

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBg

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(60, 60, 80)
    inputStroke.Thickness = 1
    inputStroke.Parent = inputBg

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -12, 1, 0)
    textBox.Position = UDim2.new(0, 6, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.PlaceholderText = placeholder or "Enter..."
    textBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(220, 220, 240)
    textBox.TextSize = 11
    textBox.Font = Enum.Font.Gotham
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 1003
    textBox.Parent = inputBg

    textBox.FocusLost:Connect(function(enterPressed)
        if callback then
            callback(textBox.Text)
        end
    end)

    return container, textBox
end

function DropdownElements:CreateDropdown(title, options, default, callback, parent, order)
    local container = Instance.new("Frame")
    container.Name = "DD_" .. title
    container.Size = UDim2.new(1, -4, 0, 55)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order or 0
    container.ZIndex = 1001
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 8)
    containerCorner.Parent = container

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 18)
    titleLbl.Position = UDim2.new(0, 8, 0, 3)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamSemibold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 1002
    titleLbl.Parent = container

    local ddBtn = Instance.new("TextButton")
    ddBtn.Name = "DDButton"
    ddBtn.Size = UDim2.new(1, -16, 0, 26)
    ddBtn.Position = UDim2.new(0, 8, 0, 23)
    ddBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    ddBtn.Text = "  " .. (default or options[1] or "Select...")
    ddBtn.TextColor3 = Color3.fromRGB(180, 180, 220)
    ddBtn.TextSize = 11
    ddBtn.Font = Enum.Font.Gotham
    ddBtn.TextXAlignment = Enum.TextXAlignment.Left
    ddBtn.BorderSizePixel = 0
    ddBtn.ZIndex = 1002
    ddBtn.Parent = container

    local ddBtnCorner = Instance.new("UICorner")
    ddBtnCorner.CornerRadius = UDim.new(0, 6)
    ddBtnCorner.Parent = ddBtn

    local ddStroke = Instance.new("UIStroke")
    ddStroke.Color = Color3.fromRGB(60, 60, 80)
    ddStroke.Thickness = 1
    ddStroke.Parent = ddBtn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(120, 120, 160)
    arrow.TextSize = 10
    arrow.Font = Enum.Font.GothamBold
    arrow.ZIndex = 1003
    arrow.Parent = ddBtn

    local ddList = Instance.new("ScrollingFrame")
    ddList.Name = "DDList"
    ddList.Size = UDim2.new(1, 0, 0, 0)
    ddList.Position = UDim2.new(0, 0, 1, 2)
    ddList.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    ddList.BorderSizePixel = 0
    ddList.ScrollBarThickness = 3
    ddList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
    ddList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ddList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ddList.ClipsDescendants = true
    ddList.Visible = false
    ddList.ZIndex = 1005
    ddList.Parent = container

    local ddListCorner = Instance.new("UICorner")
    ddListCorner.CornerRadius = UDim.new(0, 6)
    ddListCorner.Parent = ddList

    local ddListStroke = Instance.new("UIStroke")
    ddListStroke.Color = Color3.fromRGB(60, 60, 80)
    ddListStroke.Thickness = 1
    ddListStroke.Parent = ddList

    local ddLayout = Instance.new("UIListLayout")
    ddLayout.Padding = UDim.new(0, 1)
    ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ddLayout.Parent = ddList

    local isOpen = false
    local totalHeight = 0

    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        optBtn.BackgroundTransparency = 0.1
        optBtn.Text = "  " .. option
        optBtn.TextColor3 = Color3.fromRGB(180, 180, 220)
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.BorderSizePixel = 0
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 1006
        optBtn.Parent = ddList

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
            optBtn.BackgroundTransparency = 0
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
            optBtn.BackgroundTransparency = 0.1
        end)

        optBtn.MouseButton1Click:Connect(function()
            ddBtn.Text = "  " .. option
            isOpen = false
            ddList.Visible = false
            arrow.Text = "▼"
            TweenService:Create(ddList, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            if callback then
                callback(option)
            end
        end)

        totalHeight = totalHeight + 25
    end

    ddBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            ddList.Visible = true
            arrow.Text = "▲"
            TweenService:Create(ddList, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, math.min(totalHeight, 120))}):Play()
        else
            arrow.Text = "▼"
            TweenService:Create(ddList, TweenInfo.new(0.15), {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.wait(0.15)
            ddList.Visible = false
        end
    end)

    return container
end

-- ═══════════════════════════════════════════════════════════
-- WINDOW WRAPPER (with custom dropdowns)
-- ═══════════════════════════════════════════════════════════
local WindowWrapper = {}
WindowWrapper.__index = WindowWrapper

function WindowWrapper:Init(winduiWindow, winduiLib, config)
    local self = setmetatable({}, WindowWrapper)
    self.WindUI = winduiLib
    self.Window = winduiWindow
    self.Config = config
    self.DropdownContainer = nil
    self.PlayerDropdown = nil
    self.SettingsDropdown = nil
    self.PlayerDropdownVisible = false
    self.SettingsDropdownVisible = false
    
    self:_SetupDropdowns()
    return self
end

function WindowWrapper:_SetupDropdowns()
    -- Find ScreenGui
    local ScreenGui = nil
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name == "WindUI" or gui:FindFirstChild("Main") then
            ScreenGui = gui
            break
        end
    end
    
    if not ScreenGui then
        for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
            if gui.Name == "WindUI" or gui:FindFirstChild("Main") then
                ScreenGui = gui
                break
            end
        end
    end
    
    -- Create dropdown container
    self.DropdownContainer = Instance.new("Frame")
    self.DropdownContainer.Name = "NexzanDropdowns"
    self.DropdownContainer.Size = UDim2.new(1, 0, 1, 0)
    self.DropdownContainer.Position = UDim2.new(0, 0, 0, 0)
    self.DropdownContainer.BackgroundTransparency = 1
    self.DropdownContainer.ZIndex = 999
    
    if ScreenGui then
        self.DropdownContainer.Parent = ScreenGui
    else
        local NewGui = Instance.new("ScreenGui")
        NewGui.Name = "NexzanLib_Custom"
        NewGui.ResetOnSpawn = false
        NewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NewGui.DisplayOrder = 100
        NewGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        self.DropdownContainer.Parent = NewGui
    end
    
    -- Create Player Dropdown
    local playerDD, playerContent = CreateDropdownPanel(
        "⚡ Player Features",
        UDim2.new(0.5, 50, 0, 36),
        self.DropdownContainer
    )
    self.PlayerDropdown = playerDD
    self.PlayerContent = playerContent
    
    -- Create Settings Dropdown
    local settingsDD, settingsContent = CreateDropdownPanel(
        "⚙️ Settings",
        UDim2.new(0.5, 50, 0, 36),
        self.DropdownContainer
    )
    self.SettingsDropdown = settingsDD
    self.SettingsContent = settingsContent
    
    -- Add topbar buttons
    self.Window:CreateTopbarButton("NexzanPlayer", "user", function()
        self:TogglePlayerDropdown()
    end, 1, true)
    
    self.Window:CreateTopbarButton("NexzanSettings", "settings", function()
        self:ToggleSettingsDropdown()
    end, 2, true)
    
    -- Close dropdowns on outside click
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:CloseAllDropdowns()
        end
    end)
end

function WindowWrapper:TogglePlayerDropdown()
    self.SettingsDropdownVisible = false
    self.SettingsDropdown.Visible = false
    
    self.PlayerDropdownVisible = not self.PlayerDropdownVisible
    
    if self.PlayerDropdownVisible then
        self.PlayerDropdown.Visible = true
        TweenService:Create(self.PlayerDropdown, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 420)
        }):Play()
    else
        TweenService:Create(self.PlayerDropdown, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        self.PlayerDropdown.Visible = false
    end
end

function WindowWrapper:ToggleSettingsDropdown()
    self.PlayerDropdownVisible = false
    self.PlayerDropdown.Visible = false
    
    self.SettingsDropdownVisible = not self.SettingsDropdownVisible
    
    if self.SettingsDropdownVisible then
        self.SettingsDropdown.Visible = true
        TweenService:Create(self.SettingsDropdown, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 520)
        }):Play()
    else
        TweenService:Create(self.SettingsDropdown, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        self.SettingsDropdown.Visible = false
    end
end

function WindowWrapper:CloseAllDropdowns()
    if self.PlayerDropdownVisible then
        self.PlayerDropdownVisible = false
        TweenService:Create(self.PlayerDropdown, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        self.PlayerDropdown.Visible = false
    end
    if self.SettingsDropdownVisible then
        self.SettingsDropdownVisible = false
        TweenService:Create(self.SettingsDropdown, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        self.SettingsDropdown.Visible = false
    end
end

-- Player Dropdown methods
function WindowWrapper:AddPlayerLabel(text)
    return DropdownElements:CreateLabel(text, self.PlayerContent, #self.PlayerContent:GetChildren())
end

function WindowWrapper:AddPlayerSlider(title, min, max, default, callback)
    return DropdownElements:CreateSlider(title, min, max, default, callback, self.PlayerContent, #self.PlayerContent:GetChildren())
end

function WindowWrapper:AddPlayerToggle(title, default, callback)
    return DropdownElements:CreateToggle(title, default, callback, self.PlayerContent, #self.PlayerContent:GetChildren())
end

function WindowWrapper:AddPlayerButton(title, color, callback)
    return DropdownElements:CreateButton(title, color, callback, self.PlayerContent, #self.PlayerContent:GetChildren())
end

function WindowWrapper:AddPlayerInput(title, placeholder, callback)
    return DropdownElements:CreateInput(title, placeholder, callback, self.PlayerContent, #self.PlayerContent:GetChildren())
end

-- Settings Dropdown methods
function WindowWrapper:AddSettingsLabel(text)
    return DropdownElements:CreateLabel(text, self.SettingsContent, #self.SettingsContent:GetChildren())
end

function WindowWrapper:AddSettingsSlider(title, min, max, default, callback)
    return DropdownElements:CreateSlider(title, min, max, default, callback, self.SettingsContent, #self.SettingsContent:GetChildren())
end

function WindowWrapper:AddSettingsToggle(title, default, callback)
    return DropdownElements:CreateToggle(title, default, callback, self.SettingsContent, #self.SettingsContent:GetChildren())
end

function WindowWrapper:AddSettingsButton(title, color, callback)
    return DropdownElements:CreateButton(title, color, callback, self.SettingsContent, #self.SettingsContent:GetChildren())
end

function WindowWrapper:AddSettingsInput(title, placeholder, callback)
    return DropdownElements:CreateInput(title, placeholder, callback, self.SettingsContent, #self.SettingsContent:GetChildren())
end

function WindowWrapper:AddSettingsDropdown(title, options, default, callback)
    return DropdownElements:CreateDropdown(title, options, default, callback, self.SettingsContent, #self.SettingsContent:GetChildren())
end

-- Pass-through methods to WindUI Window
function WindowWrapper:Tab(config)
    return self.Window:Tab(config)
end

function WindowWrapper:SetTitle(title)
    self.Window:SetTitle(title)
end

function WindowWrapper:SetBackgroundImage(url)
    self.Window:SetBackgroundImage(url)
end

function WindowWrapper:SetBackgroundImageTransparency(value)
    self.Window:SetBackgroundImageTransparency(value)
end

function WindowWrapper:SetUIScale(scale)
    self.Window:SetUIScale(scale)
end

function WindowWrapper:SetTheme(theme)
    self.Window:SetTheme(theme)
end

function WindowWrapper:ToggleAcrylic(enabled)
    self.Window:ToggleAcrylic(enabled)
end

function WindowWrapper:ToggleTransparency(enabled)
    self.Window:ToggleTransparency(enabled)
end

function WindowWrapper:SetToTheCenter()
    self.Window:SetToTheCenter()
end

-- ═══════════════════════════════════════════════════════════
-- LIBRARY METHODS
-- ═══════════════════════════════════════════════════════════

function NexzanLib:CreateWindow(config)
    config = config or {}
    
    -- Create WindUI window
    local winduiWindow = self.WindUI:CreateWindow(config)
    
    -- Wrap it with our custom dropdown system
    local window = WindowWrapper:Init(winduiWindow, self.WindUI, config)
    
    return window
end

function NexzanLib:Notify(config)
    self.WindUI:Notify(config)
end

function NexzanLib:SetFont(fontId)
    self.WindUI:SetFont(fontId)
end

function NexzanLib:GetWindow()
    return self.WindUI
end

-- ═══════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
NexzanLib.WindUI = WindUI

return NexzanLib
