--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                   NEXZAN HUB v1.0                        ║
    ║          Modified WindUI Library + Custom Features       ║
    ║                                                          ║
    ║  Fitur:                                                  ║
    ║  - Player Dropdown (WalkSpeed, JumpPower, NoClip, dll)  ║
    ║  - Settings Dropdown (Background, Font, UI Size)         ║
    ║  - Berbasis WindUI Library                               ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- LOAD WINDUI LIBRARY
-- ═══════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════════
-- STATE VARIABLES
-- ═══════════════════════════════════════════════════════════
local State = {
    WalkSpeed = 16,
    JumpPower = 50,
    NoClip = false,
    FullBright = false,
    InfiniteJump = false,
    AntiAFK = false,
    ESP = false,
    NoclipConn = nil,
    JumpConn = nil,
    AntiAFKConn = nil,
}

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- NoClip Function
local function setNoClip(enabled)
    if State.NoclipConn then
        State.NoclipConn:Disconnect()
        State.NoclipConn = nil
    end
    if enabled then
        State.NoclipConn = RunService.Stepped:Connect(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    State.NoClip = enabled
end

-- FullBright Function
local savedAmbient = nil
local savedBrightness = nil
local savedClockTime = nil
local savedFogEnd = nil
local savedGlobalShadows = nil

local function setFullBright(enabled)
    if enabled then
        savedAmbient = Lighting.Ambient
        savedBrightness = Lighting.Brightness
        savedClockTime = Lighting.ClockTime
        savedFogEnd = Lighting.FogEnd
        savedGlobalShadows = Lighting.GlobalShadows
        
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        if savedAmbient then Lighting.Ambient = savedAmbient end
        if savedBrightness then Lighting.Brightness = savedBrightness end
        if savedClockTime then Lighting.ClockTime = savedClockTime end
        if savedFogEnd then Lighting.FogEnd = savedFogEnd end
        if savedGlobalShadows ~= nil then Lighting.GlobalShadows = savedGlobalShadows end
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    State.FullBright = enabled
end

-- Infinite Jump Function
local function setInfiniteJump(enabled)
    if State.JumpConn then
        State.JumpConn:Disconnect()
        State.JumpConn = nil
    end
    if enabled then
        State.JumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
    State.InfiniteJump = enabled
end

-- AntiAFK Function
local virtualUser = game:GetService("VirtualUser")
local function setAntiAFK(enabled)
    if State.AntiAFKConn then
        State.AntiAFKConn:Disconnect()
        State.AntiAFKConn = nil
    end
    if enabled then
        State.AntiAFKConn = LocalPlayer.Idled:Connect(function()
            virtualUser:Button2Click()
        end)
    end
    State.AntiAFK = enabled
end

-- Reset Player Stats
local function resetPlayerStats()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.JumpHeight = 7.2
    end
    State.WalkSpeed = 16
    State.JumpPower = 50
end

-- ═══════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════════════════════
local Window = WindUI:CreateWindow({
    Title = "Nexzan Hub",
    Icon = "zap",
    Author = "by Nexzan",
    Size = UDim2.new(0, 550, 0, 420),
    Theme = "midnight",
    Acrylic = false,
    Resizable = true,
})

-- Center the window
Window:SetToTheCenter()

-- ═══════════════════════════════════════════════════════════
-- CUSTOM DROPDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════
-- This creates custom dropdown panels that hang below topbar buttons

local ScreenGui = nil
local function getScreenGui()
    -- Find the WindUI ScreenGui
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name == "WindUI" or gui:FindFirstChild("Main") then
            return gui
        end
    end
    -- Fallback: check PlayerGui
    for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
        if gui.Name == "WindUI" or gui:FindFirstChild("Main") then
            return gui
        end
    end
    return nil
end

-- Wait a bit for WindUI to fully load
task.wait(1)
ScreenGui = getScreenGui()

-- Create a container for our dropdowns
local DropdownContainer = Instance.new("Frame")
DropdownContainer.Name = "NexzanDropdowns"
DropdownContainer.Size = UDim2.new(1, 0, 1, 0)
DropdownContainer.Position = UDim2.new(0, 0, 0, 0)
DropdownContainer.BackgroundTransparency = 1
DropdownContainer.ZIndex = 999

if ScreenGui then
    DropdownContainer.Parent = ScreenGui
else
    -- Create our own ScreenGui if WindUI's can't be found
    local NewGui = Instance.new("ScreenGui")
    NewGui.Name = "NexzanHub_Custom"
    NewGui.ResetOnSpawn = false
    NewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NewGui.DisplayOrder = 100
    NewGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    DropdownContainer.Parent = NewGui
    ScreenGui = NewGui
end

-- ═══════════════════════════════════════════════════════════
-- CREATE PLAYER DROPDOWN PANEL
-- ═══════════════════════════════════════════════════════════
local function createDropdownPanel(title, position, parent)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = title .. "_Dropdown"
    mainFrame.Size = UDim2.new(0, 260, 0, 0) -- Start collapsed
    mainFrame.Position = position
    mainFrame.AnchorPoint = Vector2.new(0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Visible = false
    mainFrame.ZIndex = 1000
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = parent

    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Stroke border
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

    -- Fix bottom corners of title bar
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

    -- Scrollable content area
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

    -- Layout for content
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
-- CUSTOM UI ELEMENTS FOR DROPDOWNS
-- ═══════════════════════════════════════════════════════════
local function createDropdownLabel(text, parent, order)
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

local function createDropdownSlider(title, min, max, default, callback, parent, order)
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

    -- Title
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

    -- Value display
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

    -- Slider track
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

    -- Slider fill
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

    -- Slider button (draggable)
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

local function createDropdownToggle(title, default, callback, parent, order)
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

    -- Title
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

    -- Toggle background
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

    -- Toggle circle
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

    -- Toggle button (invisible clickable area)
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

local function createDropdownButton(title, color, callback, parent, order)
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

    -- Button
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

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
    end)

    return container
end

local function createDropdownInput(title, placeholder, callback, parent, order)
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

    -- Title
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

    -- Input box
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

local function createDropdownDropdown(title, options, default, callback, parent, order)
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

    -- Title
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

    -- Dropdown button
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

    -- Arrow
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

    -- Dropdown list
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
-- CREATE PLAYER DROPDOWN
-- ═══════════════════════════════════════════════════════════
local playerDropdown, playerContent = createDropdownPanel(
    "⚡ Player Features",
    UDim2.new(0.5, 50, 0, 36),  -- Position below the player icon
    DropdownContainer
)

-- Player features
createDropdownLabel("🏃 MOVEMENT", playerContent, 1)

createDropdownSlider("WalkSpeed", 16, 500, 16, function(value)
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = value
        State.WalkSpeed = value
    end
end, playerContent, 2)

createDropdownSlider("JumpPower", 0, 500, 50, function(value)
    local hum = getHumanoid()
    if hum then
        hum.JumpPower = value
        hum.UseJumpPower = true
        State.JumpPower = value
    end
end, playerContent, 3)

createDropdownToggle("Infinite Jump", false, function(enabled)
    setInfiniteJump(enabled)
end, playerContent, 4)

createDropdownToggle("Fly (Space)", false, function(enabled)
    -- Simple fly toggle
    if enabled then
        local hrp = getRootPart()
        local hum = getHumanoid()
        if hrp and hum then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.Name = "NexzanFly"
            bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVel.Velocity = Vector3.new(0, 0, 0)
            bodyVel.Parent = hrp

            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Name = "NexzanFlyGyro"
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 1e4
            bodyGyro.Parent = hrp

            hum.PlatformStand = true

            -- Store references for cleanup
            local flyConn
            flyConn = RunService.RenderStepped:Connect(function()
                if not hrp.Parent or not hum.Parent then
                    flyConn:Disconnect()
                    return
                end
                local camera = workspace.CurrentCamera
                local direction = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    direction = direction - Vector3.new(0, 1, 0)
                end

                if direction.Magnitude > 0 then
                    bodyVel.Velocity = direction.Unit * 50
                else
                    bodyVel.Velocity = Vector3.new(0, 0, 0)
                end
                bodyGyro.CFrame = camera.CFrame
            end)

            -- Cleanup on toggle off stored as upvalue
            getfenv().NexzanFlyCleanup = function()
                flyConn:Disconnect()
                if hrp and hrp:FindFirstChild("NexzanFly") then
                    hrp.NexzanFly:Destroy()
                end
                if hrp and hrp:FindFirstChild("NexzanFlyGyro") then
                    hrp.NexzanFlyGyro:Destroy()
                end
                if hum then
                    hum.PlatformStand = false
                end
            end
        end
    else
        if getfenv().NexzanFlyCleanup then
            getfenv().NexzanFlyCleanup()
            getfenv().NexzanFlyCleanup = nil
        end
    end
end, playerContent, 5)

createDropdownLabel("👁 VISUAL", playerContent, 6)

createDropdownToggle("NoClip", false, function(enabled)
    setNoClip(enabled)
end, playerContent, 7)

createDropdownToggle("FullBright", false, function(enabled)
    setFullBright(enabled)
end, playerContent, 8)

createDropdownToggle("ESP Players", false, function(enabled)
    -- Simple ESP using highlights
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "NexzanESP"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.OutlineTransparency = 0
                highlight.Parent = player.Character
            end
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                local esp = player.Character:FindFirstChild("NexzanESP")
                if esp then esp:Destroy() end
            end
        end
    end
    State.ESP = enabled
end, playerContent, 9)

createDropdownLabel("🔧 OTHER", playerContent, 10)

createDropdownToggle("Anti-AFK", false, function(enabled)
    setAntiAFK(enabled)
end, playerContent, 11)

createDropdownButton("🔄 Reset Stats", Color3.fromRGB(180, 60, 60), function()
    resetPlayerStats()
    WindUI:Notify({
        Title = "Nexzan Hub",
        Content = "Player stats telah direset!",
        Icon = "refresh-cw",
        Duration = 3,
    })
end, playerContent, 12)

createDropdownButton("💀 Respawn", Color3.fromRGB(180, 60, 60), function()
    LocalPlayer.Character:BreakJoints()
end, playerContent, 13)

-- ═══════════════════════════════════════════════════════════
-- CREATE SETTINGS DROPDOWN
-- ═══════════════════════════════════════════════════════════
local settingsDropdown, settingsContent = createDropdownPanel(
    "⚙️ Settings",
    UDim2.new(0.5, 50, 0, 36),  -- Position below the settings icon
    DropdownContainer
)

createDropdownLabel("🖼 BACKGROUND", settingsContent, 1)

createDropdownInput("Background URL", "Masukkan raw URL gambar...", function(url)
    if url and url ~= "" then
        -- Validate URL
        if string.find(url, "http") and (string.find(url, "raw") or string.find(url, ".png") or string.find(url, ".jpg") or string.find(url, "rbxassetid")) then
            Window:SetBackgroundImage(url)
            WindUI:Notify({
                Title = "Background Changed",
                Content = "Background berhasil diubah!",
                Icon = "image",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "URL tidak valid! Gunakan raw URL (png/jpg).",
                Icon = "alert-circle",
                Duration = 4,
            })
        end
    end
end, settingsContent, 2)

createDropdownInput("Background Transparansi", "0 - 1 (default: 0)", function(value)
    local num = tonumber(value)
    if num and num >= 0 and num <= 1 then
        Window:SetBackgroundImageTransparency(num)
    end
end, settingsContent, 3)

createDropdownButton("🗑 Remove Background", Color3.fromRGB(180, 60, 60), function()
    Window:SetBackgroundImage("")
    Window:SetBackgroundImageTransparency(1)
    WindUI:Notify({
        Title = "Background Removed",
        Content = "Background telah dihapus.",
        Icon = "trash-2",
        Duration = 3,
    })
end, settingsContent, 4)

createDropdownLabel("🔤 FONT", settingsContent, 5)

createDropdownDropdown("Ganti Font", {
    "Gotham (Default)",
    "SourceSans",
    "SourceSansBold",
    "BuilderSans",
    "BuilderSansBold",
    "Ubuntu",
    "Roboto",
    "FredokaOne",
    "LuckiestGuy",
    "Arcade",
    "Custom ID (pakai input)",
}, "Gotham (Default)", function(selected)
    local fontMap = {
        ["Gotham (Default)"] = "rbxasset://fonts/families/GothamSSm.css",
        ["SourceSans"] = "rbxasset://fonts/families/SourceSansPro.css",
        ["SourceSansBold"] = "rbxasset://fonts/families/SourceSansPro.css",
        ["BuilderSans"] = "rbxasset://fonts/families/BuilderSans.css",
        ["BuilderSansBold"] = "rbxasset://fonts/families/BuilderSans.css",
        ["Ubuntu"] = "rbxasset://fonts/families/Ubuntu.css",
        ["Roboto"] = "rbxasset://fonts/families/Roboto.css",
        ["FredokaOne"] = "rbxasset://fonts/families/FredokaOne.css",
        ["LuckiestGuy"] = "rbxasset://fonts/families/LuckiestGuy.css",
        ["Arcade"] = "rbxasset://fonts/families/Arcade.css",
        ["Custom ID (pakai input)"] = nil,
    }
    local fontId = fontMap[selected]
    if fontId then
        WindUI:SetFont(fontId)
        WindUI:Notify({
            Title = "Font Changed",
            Content = "Font diubah ke: " .. selected,
            Icon = "type",
            Duration = 3,
        })
    end
end, settingsContent, 6)

createDropdownInput("Custom Font ID", "rbxassetid://123456...", function(id)
    if id and id ~= "" then
        local fontId = "rbxassetid://" .. id:gsub("rbxassetid://", "")
        WindUI:SetFont(fontId)
        WindUI:Notify({
            Title = "Custom Font",
            Content = "Font custom diterapkan!",
            Icon = "type",
            Duration = 3,
        })
    end
end, settingsContent, 7)

createDropdownLabel("📐 UI SIZE", settingsContent, 8)

createDropdownSlider("UI Scale", 50, 200, 100, function(value)
    local scale = value / 100
    Window:SetUIScale(scale)
end, settingsContent, 9)

createDropdownLabel("🎨 THEME", settingsContent, 10)

createDropdownDropdown("Ganti Tema", {
    "midnight",
    "amber",
    "blue",
    "green",
    "gray",
    "red",
    "purple",
}, "midnight", function(selected)
    Window:SetTheme(selected)
    WindUI:Notify({
        Title = "Theme Changed",
        Content = "Tema diubah ke: " .. selected,
        Icon = "palette",
        Duration = 3,
    })
end, settingsContent, 11)

createDropdownLabel("🔧 OTHER SETTINGS", settingsContent, 12)

createDropdownToggle("Acrylic Effect", false, function(enabled)
    Window:ToggleAcrylic(enabled)
end, settingsContent, 13)

createDropdownToggle("Transparency Mode", false, function(enabled)
    Window:ToggleTransparency(enabled)
end, settingsContent, 14)

createDropdownButton("📍 Center Window", Color3.fromRGB(60, 100, 180), function()
    Window:SetToTheCenter()
end, settingsContent, 15)

createDropdownButton("🔄 Reset All Settings", Color3.fromRGB(180, 60, 60), function()
    Window:SetUIScale(1)
    Window:SetBackgroundImage("")
    Window:SetBackgroundImageTransparency(1)
    Window:SetTheme("midnight")
    WindUI:Notify({
        Title = "Settings Reset",
        Content = "Semua setting telah direset!",
        Icon = "refresh-cw",
        Duration = 3,
    })
end, settingsContent, 16)

-- ═══════════════════════════════════════════════════════════
-- ADD TOPBAR BUTTONS
-- ═══════════════════════════════════════════════════════════
-- Player Icon Button
local playerDropdownVisible = false
local settingsDropdownVisible = false

Window:CreateTopbarButton("NexzanPlayer", "user", function()
    playerDropdownVisible = not playerDropdownVisible
    settingsDropdownVisible = false
    settingsDropdown.Visible = false
    
    if playerDropdownVisible then
        playerDropdown.Visible = true
        TweenService:Create(playerDropdown, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 420)
        }):Play()
    else
        TweenService:Create(playerDropdown, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        playerDropdown.Visible = false
    end
end, 1, true)

-- Settings/Gear Icon Button
Window:CreateTopbarButton("NexzanSettings", "settings", function()
    settingsDropdownVisible = not settingsDropdownVisible
    playerDropdownVisible = false
    playerDropdown.Visible = false
    
    if settingsDropdownVisible then
        settingsDropdown.Visible = true
        TweenService:Create(settingsDropdown, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 520)
        }):Play()
    else
        TweenService:Create(settingsDropdown, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 260, 0, 0)
        }):Play()
        task.wait(0.15)
        settingsDropdown.Visible = false
    end
end, 2, true)

-- Close dropdowns when clicking outside
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if playerDropdownVisible then
            playerDropdownVisible = false
            TweenService:Create(playerDropdown, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 260, 0, 0)
            }):Play()
            task.wait(0.15)
            playerDropdown.Visible = false
        end
        if settingsDropdownVisible then
            settingsDropdownVisible = false
            TweenService:Create(settingsDropdown, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 260, 0, 0)
            }):Play()
            task.wait(0.15)
            settingsDropdown.Visible = false
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- MAIN TABS - Hub Content
-- ═══════════════════════════════════════════════════════════

-- ─── PLAYER TAB ───
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

local playerMainSection = PlayerTab:Section({
    Title = "Player Stats",
    Icon = "activity",
    Box = true,
    BoxBorder = true,
})

playerMainSection:Slider({
    Title = "WalkSpeed",
    Desc = "Ubah kecepatan jalan karakter",
    Value = { Min = 16, Max = 500, Default = 16 },
    Step = 1,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = value
            State.WalkSpeed = value
        end
    end
})

playerMainSection:Slider({
    Title = "JumpPower",
    Desc = "Ubah kekuatan lompat karakter",
    Value = { Min = 0, Max = 500, Default = 50 },
    Step = 1,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = value
            hum.UseJumpPower = true
            State.JumpPower = value
        end
    end
})

playerMainSection:Slider({
    Title = "Gravity",
    Desc = "Ubah gravitasi karakter",
    Value = { Min = 0, Max = 196, Default = 196 },
    Step = 1,
    Callback = function(value)
        workspace.Gravity = value
    end
})

local playerToggleSection = PlayerTab:Section({
    Title = "Player Toggles",
    Icon = "toggle-right",
    Box = true,
    BoxBorder = true,
})

playerToggleSection:Toggle({
    Title = "NoClip",
    Desc = "Berjalan menembus dinding",
    Icon = "ghost",
    Callback = function(enabled)
        setNoClip(enabled)
    end
})

playerToggleSection:Toggle({
    Title = "FullBright",
    Desc = "Terangi seluruh map",
    Icon = "sun",
    Callback = function(enabled)
        setFullBright(enabled)
    end
})

playerToggleSection:Toggle({
    Title = "Infinite Jump",
    Desc = "Lompat tanpa batas",
    Icon = "arrow-up-circle",
    Callback = function(enabled)
        setInfiniteJump(enabled)
    end
})

playerToggleSection:Toggle({
    Title = "Anti-AFK",
    Desc = "Mencegah kick karena AFK",
    Icon = "shield",
    Callback = function(enabled)
        setAntiAFK(enabled)
    end
})

playerToggleSection:Toggle({
    Title = "ESP Players",
    Desc = "Highlight semua pemain",
    Icon = "eye",
    Callback = function(enabled)
        if enabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "NexzanESP"
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0
                    highlight.Parent = player.Character
                end
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local esp = player.Character:FindFirstChild("NexzanESP")
                    if esp then esp:Destroy() end
                end
            end
        end
    end
})

local playerActionSection = PlayerTab:Section({
    Title = "Quick Actions",
    Icon = "zap",
    Box = true,
    BoxBorder = true,
})

playerActionSection:Button({
    Title = "Reset WalkSpeed & JumpPower",
    Desc = "Kembalikan ke default",
    Icon = "rotate-ccw",
    Callback = function()
        resetPlayerStats()
        workspace.Gravity = 196
        WindUI:Notify({
            Title = "Reset",
            Content = "Semua stats player direset!",
            Icon = "check-circle",
            Duration = 3,
        })
    end
})

playerActionSection:Button({
    Title = "Respawn",
    Desc = "Respawn karakter kamu",
    Icon = "heart",
    Callback = function()
        LocalPlayer.Character:BreakJoints()
    end
})

-- ─── VISUAL TAB ───
local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "eye",
})

local visualSection = VisualTab:Section({
    Title = "Lighting & Visual",
    Icon = "sun",
    Box = true,
    BoxBorder = true,
})

visualSection:Slider({
    Title = "Time of Day",
    Desc = "Ubah waktu dalam game",
    Value = { Min = 0, Max = 24, Default = 14 },
    Step = 0.5,
    Callback = function(value)
        Lighting.ClockTime = value
    end
})

visualSection:Slider({
    Title = "Brightness",
    Desc = "Ubah brightness lighting",
    Value = { Min = 0, Max = 10, Default = 1 },
    Step = 0.1,
    Callback = function(value)
        Lighting.Brightness = value
    end
})

visualSection:Toggle({
    Title = "FullBright",
    Desc = "Max terang seluruh map",
    Icon = "sun",
    Callback = function(enabled)
        setFullBright(enabled)
    end
})

visualSection:Toggle({
    Title = "Disable Shadows",
    Desc = "Matikan semua shadow",
    Icon = "moon",
    Callback = function(enabled)
        Lighting.GlobalShadows = not enabled
    end
})

visualSection:Toggle({
    Title = "No Fog",
    Desc = "Hilangkan fog di map",
    Icon = "cloud-off",
    Callback = function(enabled)
        if enabled then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        else
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        end
    end
})

-- ─── TELEPORT TAB ───
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "navigation",
})

local tpSection = TeleportTab:Section({
    Title = "Teleport to Player",
    Icon = "users",
    Box = true,
    BoxBorder = true,
})

-- Get player list for teleport
local playerList = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(playerList, p.Name)
    end
end

if #playerList > 0 then
    tpSection:Dropdown({
        Title = "Pilih Player",
        Desc = "Teleport ke player yang dipilih",
        List = playerList,
        Callback = function(selected)
            local targetPlayer = Players:FindFirstChild(selected)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = getRootPart()
                if hrp then
                    hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                    WindUI:Notify({
                        Title = "Teleported",
                        Content = "Berhasil teleport ke " .. selected,
                        Icon = "navigation",
                        Duration = 3,
                    })
                end
            end
        end
    })
end

tpSection:Button({
    Title = "Teleport to Spawn",
    Desc = "Pergi ke spawn point",
    Icon = "home",
    Callback = function()
        local hrp = getRootPart()
        if hrp then
            local spawns = workspace:GetDescendants()
            for _, obj in ipairs(spawns) do
                if obj.Name == "SpawnLocation" or obj:IsA("SpawnLocation") then
                    hrp.CFrame = obj.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end
    end
})

tpSection:Input({
    Title = "Teleport ke Koordinat",
    Desc = "Format: X, Y, Z (contoh: 100, 50, 200)",
    Placeholder = "100, 50, 200",
    Callback = function(text)
        local hrp = getRootPart()
        if hrp then
            local x, y, z = text:match("(%-?%d+%.?%d*),%s*(%-?%d+%.?%d*),%s*(%-?%d+%.?%d*)")
            if x and y and z then
                hrp.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
                WindUI:Notify({
                    Title = "Teleported",
                    Content = string.format("Teleport ke (%s, %s, %s)", x, y, z),
                    Icon = "navigation",
                    Duration = 3,
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Format salah! Gunakan: X, Y, Z",
                    Icon = "alert-circle",
                    Duration = 4,
                })
            end
        end
    end
})

-- ─── INFO TAB ───
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local infoSection = InfoTab:Section({
    Title = "About Nexzan Hub",
    Icon = "award",
    Box = true,
    BoxBorder = true,
})

infoSection:Paragraph({
    Title = "Nexzan Hub v1.0",
    Content = "UI Library berbasis WindUI yang dimodifikasi.\nDibuat oleh Nexzan.\n\nFitur utama:\n• Player Features (WalkSpeed, JumpPower, dll)\n• Visual Features (FullBright, NoFog, dll)\n• Teleport System\n• Custom Background & Font\n• ESP & NoClip\n\nGunakan tombol Player (icon user) dan Settings (icon gear) di topbar untuk akses cepat!"
})

local gameInfoSection = InfoTab:Section({
    Title = "Game Info",
    Icon = "gamepad-2",
    Box = true,
    BoxBorder = true,
})

gameInfoSection:Button({
    Title = "Copy Game ID",
    Desc = "Salin PlaceID game ini",
    Icon = "copy",
    Callback = function()
        local placeId = game.PlaceId
        setclipboard and setclipboard(tostring(placeId))
        WindUI:Notify({
            Title = "Copied!",
            Content = "PlaceID: " .. tostring(placeId),
            Icon = "clipboard",
            Duration = 3,
        })
    end
})

gameInfoSection:Button({
    Title = "Copy JobID",
    Desc = "Salin JobID server ini",
    Icon = "copy",
    Callback = function()
        local jobId = game.JobId
        setclipboard and setclipboard(tostring(jobId))
        WindUI:Notify({
            Title = "Copied!",
            Content = "JobID berhasil disalin!",
            Icon = "clipboard",
            Duration = 3,
        })
    end
})

-- ═══════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- ═══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Re-apply settings after respawn
    task.wait(1)
    
    if State.WalkSpeed ~= 16 then
        Humanoid.WalkSpeed = State.WalkSpeed
    end
    if State.JumpPower ~= 50 then
        Humanoid.JumpPower = State.JumpPower
        Humanoid.UseJumpPower = true
    end
    if State.NoClip then
        setNoClip(true)
    end
    if State.InfiniteJump then
        setInfiniteJump(true)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- WELCOME NOTIFICATION
-- ═══════════════════════════════════════════════════════════
WindUI:Notify({
    Title = "Nexzan Hub",
    Content = "Selamat datang! Gunakan icon Player & Settings di topbar.",
    Icon = "zap",
    Duration = 5,
})

-- Return the library for external use
return {
    WindUI = WindUI,
    Window = Window,
    State = State,
    Version = "1.0",
}
